import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../core/network/realtime_client.dart';
import '../core/utils/place_coords.dart';
import '../data/models/ride_models.dart';
import '../data/repositories/ride_repository.dart';
import '../services/app_state.dart';
import '../services/location_service.dart';
import '../shared/models/models.dart';
import '../viewmodels/auth_view_model.dart';
import 'chat_view_model.dart';

/// MVVM rides layer — passenger booking + driver offers/lifecycle over scotland-backend.
class RideViewModel extends ChangeNotifier {
  RideViewModel({
    required AuthViewModel auth,
    required AppState appState,
    required RealtimeClient realtime,
    ChatViewModel? chat,
  })  : _auth = auth,
        _app = appState,
        _realtime = realtime,
        _chat = chat,
        _rides = RideRepository(auth.repository.client) {
    _auth.addListener(_onAuthChanged);
    _subs.add(_realtime.onRideOffer.listen(_onRideOffer));
    _subs.add(_realtime.onRideStatus.listen(_onRideStatus));
    if (_auth.isLoggedIn) unawaited(_realtime.connect());
  }

  final AuthViewModel _auth;
  final AppState _app;
  final RealtimeClient _realtime;
  final RideRepository _rides;
  ChatViewModel? _chat;
  final List<StreamSubscription<dynamic>> _subs = [];

  Timer? _passengerPoll;
  Timer? _driverPoll;
  bool _loading = false;
  String? _error;
  RideEstimate? _lastEstimate;
  String? _activeRideId;

  void attachChat(ChatViewModel chat) => _chat = chat;

  bool get isLoading => _loading;
  String? get error => _error;
  RideEstimate? get lastEstimate => _lastEstimate;
  String? get activeRideId => _activeRideId ?? _app.apiActiveRideId;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<String?> refreshEstimate() async {
    if (_app.pickup.trim().isEmpty || _app.destination.trim().isEmpty) {
      return 'Set pickup and destination first.';
    }
    return _run(() async {
      final pickup = await _place(_app.pickup, lat: _app.pickupLat, lng: _app.pickupLng);
      final drop = await _place(_app.destination, lat: _app.dropLat, lng: _app.dropLng);
      final estimate = await _rides.estimate(
        pickup: pickup,
        drop: drop,
        rideType: RideWire.rideType(_app.rideType),
        bookingMode: RideWire.bookingMode(_app.bookMode),
        vehicleCategory: RideWire.vehicleCategory(_app.vehicleCategory),
        scheduledAt: _app.bookMode == BookMode.later ? _app.scheduledAt?.toUtc().toIso8601String() : null,
      );
      _lastEstimate = estimate;
      _app.setApiEstimate(farePence: estimate.fareEstimatePence, distanceM: estimate.distanceM);
    });
  }

  /// Passenger Book Now / Later → POST /rides.
  Future<String?> bookRide() async {
    if (_app.pickup.trim().isEmpty) return 'Set a pickup location.';
    if (_app.destination.trim().isEmpty) return 'Set a destination.';
    if (_app.bookMode == BookMode.later && _app.scheduledAt == null) {
      return 'Pick a date & time for Book Later.';
    }

    return _run(() async {
      final pickup = await _place(_app.pickup, lat: _app.pickupLat, lng: _app.pickupLng);
      final drop = await _place(_app.destination, lat: _app.dropLat, lng: _app.dropLng);
      _app.setRouteCoords(
        pickupLat: pickup.lat,
        pickupLng: pickup.lng,
        dropLat: drop.lat,
        dropLng: drop.lng,
      );

      final ride = await _rides.create(
        pickup: pickup,
        drop: drop,
        rideType: RideWire.rideType(_app.rideType),
        bookingMode: RideWire.bookingMode(_app.bookMode),
        vehicleCategory: RideWire.vehicleCategory(_app.vehicleCategory),
        scheduledAt: _app.bookMode == BookMode.later ? _app.scheduledAt?.toUtc().toIso8601String() : null,
      );
      _activeRideId = ride.id;
      _app.setApiEstimate(
        farePence: ride.fareEstimatePence,
        distanceM: ride.distanceM ?? _lastEstimate?.distanceM ?? 0,
      );

      if (ride.bookingMode == 'later') {
        _app.applyApiRide(
          rideId: ride.id,
          status: ride.status,
          pickup: ride.pickup.address,
          drop: ride.drop.address,
          farePounds: ride.farePounds,
          pickupLat: ride.pickup.lat,
          pickupLng: ride.pickup.lng,
          dropLat: ride.drop.lat,
          dropLng: ride.drop.lng,
          passengerName: ride.passengerName,
          type: RideWire.parseRideType(ride.rideType),
        );
        // Scheduled rides stay requested until dispatch time.
        return;
      }

      _app.beginApiRideFinding(
        rideId: ride.id,
        farePounds: ride.farePounds,
        pickup: ride.pickup.address,
        drop: ride.drop.address,
        pickupLat: ride.pickup.lat,
        pickupLng: ride.pickup.lng,
        dropLat: ride.drop.lat,
        dropLng: ride.drop.lng,
      );
      _startPassengerPoll(ride.id);
    });
  }

  Future<String?> cancelActiveRide({String? reason}) async {
    final id = activeRideId;
    if (id == null) {
      _app.cancelBooking();
      return null;
    }
    return _run(() async {
      await _rides.cancel(id, reason: reason ?? 'Cancelled by user');
      _stopPassengerPoll();
      _activeRideId = null;
      _app.cancelBooking();
    });
  }

  Future<String?> rateActiveRide(double stars) async {
    final id = activeRideId;
    if (id == null) {
      _app.completePassengerRide(stars);
      return null;
    }
    return _run(() async {
      await _rides.rate(id, score: stars.round().clamp(1, 5));
      _stopPassengerPoll();
      _activeRideId = null;
      _app.completePassengerRide(stars);
    });
  }

  /// Driver: go online on API + poll offers.
  Future<String?> startDriverSession() async {
    if (!_auth.isDriverMode) return 'Sign in as a driver first.';
    return _run(() async {
      await _rides.setOnlineStatus('online');
      _app.setOnline(true);
      final here = await LocationService.currentLatLng();
      if (here != null) {
        await _rides.postLocation(lat: here.latitude, lng: here.longitude);
      }
      _startDriverPoll();
      await _refreshOffers();
    });
  }

  Future<String?> stopDriverSession() async {
    return _run(() async {
      await _rides.setOnlineStatus('offline');
      _stopDriverPoll();
      _app.setOnline(false);
      _app.clearApiOffers();
    });
  }

  Future<String?> acceptOffer(String rideId) async {
    return _run(() async {
      final ride = await _rides.accept(rideId);
      _activeRideId = ride.id;
      _app.applyApiRide(
        rideId: ride.id,
        status: ride.status,
        pickup: ride.pickup.address,
        drop: ride.drop.address,
        farePounds: ride.farePounds,
        pickupLat: ride.pickup.lat,
        pickupLng: ride.pickup.lng,
        dropLat: ride.drop.lat,
        dropLng: ride.drop.lng,
        driverName: ride.driverName ?? _auth.user?.name,
        passengerName: ride.passengerName,
        passengerPhone: ride.passengerPhone,
        type: RideWire.parseRideType(ride.rideType),
      );
      _app.clearApiOffers();
      _chat?.onRideAssigned(ride);
      _startPassengerPoll(ride.id); // backup poll; realtime ride.status is primary
    });
  }

  Future<String?> rejectOffer(String rideId) async {
    return _run(() async {
      await _rides.reject(rideId);
      await _refreshOffers();
    });
  }

  Future<String?> markArrived() async {
    final id = activeRideId;
    if (id == null) return 'No active ride.';
    return _run(() async {
      final ride = await _rides.arrive(id);
      _apply(ride);
    });
  }

  Future<String?> startTrip() async {
    final id = activeRideId;
    if (id == null) return 'No active ride.';
    return _run(() async {
      final ride = await _rides.start(id);
      _apply(ride);
    });
  }

  Future<String?> completeTrip({int? distanceM}) async {
    final id = activeRideId;
    if (id == null) return 'No active ride.';
    return _run(() async {
      final ride = await _rides.complete(id, distanceM: distanceM ?? _lastEstimate?.distanceM);
      _apply(ride);
      _stopPassengerPoll();
      _activeRideId = null;
    });
  }

  Future<List<ApiRide>> listTrips({required String role}) {
    return _rides.list(role: role);
  }

  void _apply(ApiRide ride) {
    _app.applyApiRide(
      rideId: ride.id,
      status: ride.status,
      pickup: ride.pickup.address,
      drop: ride.drop.address,
      farePounds: ride.farePounds,
      pickupLat: ride.pickup.lat,
      pickupLng: ride.pickup.lng,
      dropLat: ride.drop.lat,
      dropLng: ride.drop.lng,
      driverName: ride.driverName,
      passengerName: ride.passengerName,
      passengerPhone: ride.passengerPhone,
      type: RideWire.parseRideType(ride.rideType),
    );
  }

  Future<ApiPlace> _place(String address, {double? lat, double? lng}) async {
    if (lat != null && lng != null) {
      return ApiPlace(address: address, lat: lat, lng: lng);
    }
    final coords = await PlaceCoords.resolve(address);
    return ApiPlace(address: address, lat: coords.latitude, lng: coords.longitude);
  }

  void _startPassengerPoll(String rideId) {
    _stopPassengerPoll();
    // Slower backup when WebSocket is up; faster when offline from socket.
    final every = _realtime.isConnected ? const Duration(seconds: 8) : const Duration(seconds: 3);
    _passengerPoll = Timer.periodic(every, (_) async {
      try {
        final ride = await _rides.getById(rideId);
        _apply(ride);
        if (ride.status == 'assigned' || ride.status == 'arrived' || ride.status == 'in_progress') {
          _chat?.onRideAssigned(ride);
        }
        if (ride.status == 'completed' || ride.status == 'cancelled') {
          _stopPassengerPoll();
          if (ride.status == 'cancelled') _activeRideId = null;
        }
      } catch (_) {}
    });
  }

  void _stopPassengerPoll() {
    _passengerPoll?.cancel();
    _passengerPoll = null;
  }

  void _startDriverPoll() {
    _stopDriverPoll();
    final every = _realtime.isConnected ? const Duration(seconds: 10) : const Duration(seconds: 4);
    _driverPoll = Timer.periodic(every, (_) async {
      try {
        final here = await LocationService.currentLatLng();
        if (here != null) {
          await _rides.postLocation(lat: here.latitude, lng: here.longitude);
        }
        // Offers also arrive via ride.offer; poll remains a safety net.
        await _refreshOffers();
      } catch (_) {}
    });
  }

  Future<void> _onRideOffer(Map<String, dynamic> raw) async {
    if (!_auth.isDriverMode || !_app.isOnline) return;
    if (_app.activeTrip != null || _app.activeRide != null) return;
    try {
      // Prefer full offers list (includes distance); fall back to raw event.
      await _refreshOffers();
      if (_app.availableJobs.any((j) => j.id == '${raw['rideId']}')) return;
      final pickup = raw['pickup'];
      final drop = raw['drop'];
      if (pickup is! Map || drop is! Map) return;
      final farePence = (raw['fareEstimatePence'] as num?)?.toInt() ?? 0;
      _app.setApiOffers([
        ..._app.availableJobs,
        IncomingRequest(
          id: '${raw['rideId']}',
          passengerName: 'Passenger',
          pickup: '${pickup['address'] ?? ''}',
          destination: '${drop['address'] ?? ''}',
          type: RideWire.parseRideType('${raw['rideType'] ?? 'standard'}'),
          fare: farePence / 100.0,
          distance: '—',
          eta: '—',
          passengerPhone: '',
        ),
      ]);
    } catch (_) {}
  }

  Future<void> _onRideStatus(Map<String, dynamic> raw) async {
    final rideId = '${raw['rideId'] ?? ''}';
    if (rideId.isEmpty) return;
    try {
      final ride = await _rides.getById(rideId);
      _activeRideId = ride.isActive ? ride.id : _activeRideId;
      if (ride.status == 'cancelled') _activeRideId = null;
      if (ride.status == 'completed') _activeRideId = null;
      _apply(ride);
      if (ride.driverId != null) _chat?.onRideAssigned(ride);
      if (ride.status == 'completed' || ride.status == 'cancelled') {
        _stopPassengerPoll();
      }
    } catch (_) {}
  }

  void _onAuthChanged() {
    if (_auth.isLoggedIn) {
      unawaited(_realtime.connect());
    } else {
      _stopPassengerPoll();
      _stopDriverPoll();
      unawaited(_realtime.disconnect());
      _activeRideId = null;
    }
  }

  void _stopDriverPoll() {
    _driverPoll?.cancel();
    _driverPoll = null;
  }

  Future<void> _refreshOffers() async {
    if (_app.activeTrip != null || _app.activeRide != null) {
      _app.clearApiOffers();
      return;
    }
    final offers = await _rides.offers();
    final mapped = offers.map((o) {
      final miles = (o.distanceToPickupM ?? 0) / 1609.344;
      return IncomingRequest(
        id: o.rideId,
        passengerName: 'Passenger',
        pickup: o.pickup.address,
        destination: o.drop.address,
        type: RideWire.parseRideType(o.rideType),
        fare: o.farePounds,
        distance: miles > 0 ? '${miles.toStringAsFixed(1)} mi' : '—',
        eta: '—',
        passengerPhone: '',
      );
    }).toList();
    _app.setApiOffers(mapped);
  }

  Future<String?> _run(Future<void> Function() action) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      return null;
    } on ApiException catch (e) {
      _error = e.message;
      return e.message;
    } catch (e) {
      final msg = e.toString().contains('SocketException') ||
              e.toString().contains('Connection refused') ||
              e.toString().contains('Failed host lookup')
          ? 'Cannot reach rides API. Is the backend running?'
          : 'Something went wrong. Please try again.';
      _error = msg;
      return msg;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    for (final s in _subs) {
      s.cancel();
    }
    _stopPassengerPoll();
    _stopDriverPoll();
    super.dispose();
  }
}
