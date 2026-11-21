import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../core/maps_config.dart';
import '../shared/models/models.dart';
import 'location_service.dart';
import 'mock_repository.dart';
import 'session_store.dart';

class AppState extends ChangeNotifier {
  AppUser? _user;
  UserRole? _pendingRole = UserRole.passenger;
  bool _sessionReady = false;
  final Map<String, _LocalAccount> _accounts = {
    'smith@demo.local': _LocalAccount(
      password: 'demo',
      user: const AppUser(
        id: 'p1',
        name: 'ayaz',
        email: 'smith@demo.local',
        phone: '+44 7700 900123',
        role: UserRole.passenger,
      ),
    ),
    'ayazaslam66@gmail.com': _LocalAccount(
      password: 'demo',
      user: const AppUser(
        id: 'p2',
        name: 'ayaz',
        email: 'ayazaslam66@gmail.com',
        phone: '+44 7700 900786',
        role: UserRole.passenger,
      ),
    ),
    'driver@demo.local': _LocalAccount(
      password: 'demo',
      user: const AppUser(
        id: 'd0',
        name: 'ayaz',
        email: 'driver@demo.local',
        phone: '+44 7700 900456',
        role: UserRole.driver,
        vehicle: 'Toyota Prius',
        licenceNumber: 'AYAZ123456',
      ),
      documentsComplete: true,
    ),
  };

  DriverOnlineStatus _online = DriverOnlineStatus.offline;
  String _pickup = '';
  String _destination = '';
  RideType _rideType = RideType.standard;
  BookMode _bookMode = BookMode.now;
  VehicleCategory _vehicleCategory = VehicleCategory.fourSeater;
  String? _stop;
  DateTime? _scheduledAt;
  bool _mapView = true;
  String? _selectedDriverId = 'd1';
  bool _searching = false;
  bool _rideBooked = false;
  bool _tracking = false;
  bool _driverMatched = false;
  PassengerRidePhase _ridePhase = PassengerRidePhase.idle;
  int _driversSeen = 0;
  int _findGeneration = 0;
  final List<RideRecord> _extraScheduled = [];
  final List<RideRecord> _driverScheduled = [];
  final List<RideRecord> _completedPassengerTrips = [];
  final List<RideRecord> _completedDriverTrips = [];
  final List<String> _liveAlerts = [];
  final List<IncomingRequest> _availableJobs = [];
  IncomingRequest? _activeTrip;
  ActiveRide? _activeRide;
  Timer? _rideTicker;
  StreamSubscription<Position>? _locationSub;
  String? _pendingPassengerJobId;
  final _rng = Random();
  int _alerts = 1;
  final int _retainedClients = 1;
  final Set<String> _blocked = {};
  double _lastRating = 0;
  List<DriverDocument> _driverDocs = const [];

  static const requiredDriverDocs = [
    DriverDocument(
      id: 'licence',
      title: "Driver's Licence",
      hint: 'Photo of both sides',
      status: DriverDocStatus.missing,
    ),
    DriverDocument(
      id: 'council_licence',
      title: 'Council License',
      hint: 'Private hire / hackney licence',
      status: DriverDocStatus.missing,
    ),
    DriverDocument(
      id: 'council_plate',
      title: 'Council Vehicle Plate Number',
      hint: 'Include expiry date when uploading',
      status: DriverDocStatus.missing,
    ),
    DriverDocument(
      id: 'insurance',
      title: 'Car Insurance Document',
      hint: 'Valid hire & reward cover',
      status: DriverDocStatus.missing,
    ),
    DriverDocument(
      id: 'v5',
      title: 'Vehicle Registration Document',
      hint: 'V5C / logbook photo',
      status: DriverDocStatus.missing,
    ),
  ];

  static const operatingZones = [
    'Glenrothes',
    'Kirkcaldy',
    'Dunfermline',
    'Levenmouth',
    'St Andrews',
    'Cupar',
    'Cowdenbeath',
    'All Fife',
  ];

  AppUser? get user => _user;
  UserRole? get pendingRole => _pendingRole;
  bool get sessionReady => _sessionReady;
  bool get isLoggedIn => _user != null;

  /// Whether a local account already exists for [email] (post-signup login).
  bool hasAccount(String email) => _accounts.containsKey(email.trim().toLowerCase());

  /// Restore last login — once signed in, stay signed in across restarts.
  Future<void> restoreSession() async {
    final data = await SessionStore.read();
    final email = data?['email'] as String?;
    if (data != null && email != null && email.isNotEmpty) {
      final roleName = '${data['role'] ?? 'passenger'}';
      final role = roleName == 'driver' ? UserRole.driver : UserRole.passenger;
      final docsComplete = data['docs'] == true || role == UserRole.passenger;
      final user = AppUser(
        id: '${data['id'] ?? 'u-restored'}',
        name: '${data['name'] ?? email.split('@').first}',
        email: email,
        phone: '${data['phone'] ?? '+44 7000 000000'}',
        role: role,
        vehicle: data['vehicle'] as String?,
        licenceNumber: data['licence'] as String?,
      );
      final existing = _accounts[email.toLowerCase()];
      _accounts[email.toLowerCase()] = _LocalAccount(
        password: existing?.password ?? 'demo',
        user: user,
        documentsComplete: docsComplete,
      );
      await _activateUser(
        user,
        forceDocsIncomplete: role == UserRole.driver && !docsComplete,
        persist: false,
      );
    }
    _sessionReady = true;
    notifyListeners();
  }

  Future<void> _persistSession() async {
    final u = _user;
    if (u == null) {
      await SessionStore.write(null);
      return;
    }
    final docs = _accounts[u.email.toLowerCase()]?.documentsComplete ??
        (u.role == UserRole.passenger || driverDocumentsComplete);
    await SessionStore.write({
      'loggedIn': true,
      'email': u.email.toLowerCase(),
      'role': u.role.name,
      'name': u.name,
      'phone': u.phone,
      'id': u.id,
      'vehicle': u.vehicle,
      'licence': u.licenceNumber,
      'docs': docs,
    });
  }
  bool get isPassenger => _user?.role == UserRole.passenger;
  bool get isDriver => _user?.role == UserRole.driver;
  DriverOnlineStatus get onlineStatus => _online;
  bool get isOnline => _online != DriverOnlineStatus.offline;
  String get pickup => _pickup;
  String get destination => _destination;
  RideType get rideType => _rideType;
  BookMode get bookMode => _bookMode;
  VehicleCategory get vehicleCategory => _vehicleCategory;
  String? get stop => _stop;
  DateTime? get scheduledAt => _scheduledAt;
  bool get mapView => _mapView;
  String? get selectedDriverId => _selectedDriverId;
  bool get searching => _searching;
  bool get rideBooked => _rideBooked;
  bool get tracking => _tracking;
  bool get driverMatched => _driverMatched;
  PassengerRidePhase get ridePhase => _ridePhase;
  bool get isFindingDriver => _ridePhase == PassengerRidePhase.finding;
  bool get isDriverApproaching => _ridePhase == PassengerRidePhase.approaching;
  bool get isDriverArrived => _ridePhase == PassengerRidePhase.arrived;
  bool get isRideInProgress => _ridePhase == PassengerRidePhase.inProgress;
  bool get isRideRating => _ridePhase == PassengerRidePhase.rating;
  int get driversSeen => _driversSeen;
  List<IncomingRequest> get availableJobs => List.unmodifiable(_availableJobs);

  /// Single ride currently offered to this driver (not a public feed of all users).
  IncomingRequest? get offeredJob =>
      _activeTrip != null || _availableJobs.isEmpty ? null : _availableJobs.first;

  IncomingRequest? get activeTrip => _activeTrip;
  IncomingRequest? get activeRequest => _activeTrip;
  ActiveRide? get activeRide => _activeRide;
  bool get requestAccepted => _activeTrip != null;
  int get unreadMessages => _chatThreads.fold(0, (s, t) => s + t.unread);
  int get alerts => _alerts + _liveAlerts.length;
  int get retainedClients => _retainedClients;
  Set<String> get blocked => _blocked;
  double get lastRating => _lastRating;

  List<NearbyDriver> get nearbyDrivers => MockRepository.nearbyDrivers;
  List<RideRecord> get passengerTrips => [..._completedPassengerTrips, ...MockRepository.passengerTrips];
  List<RideRecord> get scheduledRides => [..._extraScheduled, ...MockRepository.scheduledRides];
  List<RideRecord> get driverScheduledRides => List.unmodifiable(_driverScheduled);
  List<String> get passengerAlerts => [..._liveAlerts, ...MockRepository.passengerAlerts];
  List<(String, String)> get supportTopics => MockRepository.supportTopics;
  List<RideRecord> get driverTrips => [..._completedDriverTrips, ...MockRepository.driverTrips];
  List<String> get clients => MockRepository.clientNames;
  List<ChatMessage> get messages => MockRepository.messages;
  List<ChatThread> get chatThreads => List.unmodifiable(_chatThreads);
  List<String> get alertItems => [..._liveAlerts, ...MockRepository.driverAlerts];
  List<DriverDocument> get driverDocuments => List.unmodifiable(_driverDocs);

  final List<ChatThread> _chatThreads = List<ChatThread>.from(MockRepository.chatThreads);

  bool get driverDocumentsComplete =>
      _driverDocs.isNotEmpty && _driverDocs.every((d) => d.status == DriverDocStatus.verified);

  int get driverDocumentsMissing =>
      _driverDocs.where((d) => d.status != DriverDocStatus.verified).length;

  bool get canGoOnline => isDriver && driverDocumentsComplete;

  int get completedPassengerTrips =>
      passengerTrips.where((t) => t.status == RideStatus.completed).length;
  int get cancelledPassengerTrips =>
      passengerTrips.where((t) => t.status == RideStatus.cancelled).length;
  double get passengerSpend => passengerTrips
      .where((t) => t.status == RideStatus.completed)
      .fold(0.0, (s, t) => s + t.fare);

  NearbyDriver? get selectedDriver {
    final ride = _activeRide;
    if (ride != null) {
      return NearbyDriver(
        id: 'active-driver',
        name: ride.driverName,
        vehicle: ride.vehicle,
        plate: ride.plate,
        distanceKm: ride.remainingMiles * 1.609,
        rating: ride.driverRating,
        eta: '${ride.etaMinutes} min',
        fareEstimate: ride.fare,
        mapOffset: Offset(0.12 + ride.progress * 0.55, 0.78 - ride.progress * 0.4),
      );
    }
    final id = _selectedDriverId;
    if (id == null) return null;
    try {
      return nearbyDrivers.firstWhere((d) => d.id == id);
    } catch (_) {
      return nearbyDrivers.isEmpty ? null : nearbyDrivers.first;
    }
  }

  double get todayEarnings =>
      driverTrips.where((t) => t.dateLabel == 'Today').fold(0.0, (s, t) => s + t.fare);

  double get weekEarnings => driverTrips.fold(0.0, (s, t) => s + t.fare);

  int get completedDriverTrips =>
      driverTrips.where((t) => t.status == RideStatus.completed).length;

  String get fareEstimateLabel => '£${fareEstimate.toStringAsFixed(2)}';

  /// Mock fare from vehicle + whether a full route is set.
  double get fareEstimate {
    final hasRoute = _pickup.trim().isNotEmpty && _destination.trim().isNotEmpty;
    final base = switch (_vehicleCategory) {
      VehicleCategory.fourSeater => 17.70,
      VehicleCategory.sixSeater => 22.50,
      VehicleCategory.eightSeater => 28.00,
      VehicleCategory.wheelchair => 24.00,
    };
    if (!hasRoute) return base * 0.55;
    if (_bookMode == BookMode.later) return base * 1.05;
    return base;
  }

  String get fareMilesLabel =>
      (_pickup.isNotEmpty && _destination.isNotEmpty) ? '6 miles' : '— miles';

  String get fareMinsLabel =>
      (_pickup.isNotEmpty && _destination.isNotEmpty) ? '14 min' : '— min';

  bool get hasBookingRoute =>
      _pickup.trim().isNotEmpty && _destination.trim().isNotEmpty;

  void selectRole(UserRole role) {
    _pendingRole = role;
    notifyListeners();
  }

  /// Switch Passenger ↔ Driver from drawer — stays logged in (no re-login).
  void switchMode(UserRole role) {
    final current = _user;
    if (current == null) {
      _pendingRole = role;
      notifyListeners();
      return;
    }
    if (current.role == role) return;
    final next = AppUser(
      id: current.id,
      name: current.name,
      email: current.email,
      phone: current.phone,
      role: role,
      vehicle: current.vehicle ?? (role == UserRole.driver ? 'Toyota Prius' : null),
      licenceNumber: current.licenceNumber ?? (role == UserRole.driver ? 'AYAZ123456' : null),
    );
    final email = current.email.toLowerCase();
    final acc = _accounts[email];
    if (acc != null) {
      _accounts[email] = _LocalAccount(
        password: acc.password,
        user: next,
        documentsComplete: role == UserRole.passenger ? true : acc.documentsComplete,
      );
    }
    // ignore: unawaited_futures
    _activateUser(
      next,
      forceDocsIncomplete: role == UserRole.driver && !(acc?.documentsComplete ?? false),
    );
  }

  void swapPickupDrop() {
    final a = _pickup;
    _pickup = _destination;
    _destination = a;
    notifyListeners();
  }

  Future<String?> signIn({
    required String email,
    required String password,
    String preferredName = '',
  }) async {
    final e = email.trim().toLowerCase();
    final p = password.trim();
    final n = preferredName.trim();
    if (e.isEmpty || p.isEmpty) return 'Enter email and password.';
    if (p.length < 6) return 'Password must be at least 6 characters.';

    // Role chosen on welcome (Passenger / Driver). Existing accounts keep their registered role.
    final selectedRole = _pendingRole ?? UserRole.passenger;

    final existing = _accounts[e];
    if (existing != null) {
      if (existing.password != p) return 'Incorrect password.';
      final role = existing.user.role;
      if (selectedRole != role) {
        return role == UserRole.driver
            ? 'This email is registered as a Driver. Select Driver on the welcome screen.'
            : 'This email is registered as a Passenger. Select Passenger on the welcome screen.';
      }
      final user = AppUser(
        id: existing.user.id,
        name: n.isNotEmpty ? n : existing.user.name,
        email: existing.user.email,
        phone: existing.user.phone,
        role: role,
        vehicle: existing.user.vehicle,
        licenceNumber: existing.user.licenceNumber,
        vehiclePlate: existing.user.vehiclePlate,
        operatingZone: existing.user.operatingZone,
      );
      await _activateUser(
        user,
        forceDocsIncomplete: role == UserRole.driver && !existing.documentsComplete,
        driverDocs: role == UserRole.driver && existing.driverDocs.isNotEmpty
            ? existing.driverDocs
            : null,
      );
      return null;
    }

    // Must complete Create Account / Driver Application first — no silent create.
    return selectedRole == UserRole.driver
        ? 'No driver account found. Please submit a Driver Application first.'
        : 'No passenger account found. Please create an account first.';
  }

  Future<String?> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    required bool acceptedTerms,
    String vehicle = '',
    String licence = '',
    String vehiclePlate = '',
    String operatingZone = '',
    List<DriverDocument>? initialDriverDocs,
  }) async {
    final role = _pendingRole ?? UserRole.passenger;
    final n = name.trim();
    final e = email.trim().toLowerCase();
    final ph = phone.trim();
    final p = password.trim();
    if (n.length < 2) return 'Enter your full name.';
    if (!e.contains('@')) return 'Enter a valid email.';
    if (ph.length < 8) return 'Enter a valid phone number.';
    if (p.length < 6) return 'Password must be at least 6 characters.';
    if (p != confirmPassword.trim()) return 'Passwords do not match.';
    if (!acceptedTerms) return 'Please accept Terms & Privacy Policy.';
    if (role == UserRole.driver) {
      if (vehicle.trim().isEmpty) return 'Enter your vehicle make and model.';
      if (vehiclePlate.trim().length < 2) return 'Enter your vehicle registration plate.';
      if (operatingZone.trim().isEmpty) return 'Select your operating zone.';
    }
    if (_accounts.containsKey(e)) {
      return 'An account with this email already exists. Log in instead.';
    }

    final user = AppUser(
      id: 'u-${DateTime.now().millisecondsSinceEpoch}',
      name: n,
      email: e,
      phone: ph,
      role: role,
      vehicle: role == UserRole.driver ? vehicle.trim() : null,
      licenceNumber: role == UserRole.driver
          ? (licence.trim().isEmpty ? null : licence.trim())
          : null,
      vehiclePlate: role == UserRole.driver ? vehiclePlate.trim().toUpperCase() : null,
      operatingZone: role == UserRole.driver ? operatingZone.trim() : null,
    );
    // Documents optional at signup — can be uploaded later in Documents.
    final docs = initialDriverDocs ??
        (role == UserRole.driver ? List<DriverDocument>.from(requiredDriverDocs) : const <DriverDocument>[]);
    final docsComplete =
        role != UserRole.driver || docs.every((d) => d.status == DriverDocStatus.verified);

    _accounts[e] = _LocalAccount(
      password: p,
      user: user,
      documentsComplete: docsComplete,
      driverDocs: role == UserRole.driver ? docs : const [],
    );
    await _activateUser(
      user,
      forceDocsIncomplete: role == UserRole.driver && !docsComplete,
      driverDocs: role == UserRole.driver ? docs : null,
    );
    return null;
  }

  Future<void> uploadDriverDocument(String id) async {
    final i = _driverDocs.indexWhere((d) => d.id == id);
    if (i < 0) return;
    _driverDocs = [
      for (var j = 0; j < _driverDocs.length; j++)
        if (j == i) _driverDocs[j].copyWith(status: DriverDocStatus.pending) else _driverDocs[j],
    ];
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 700));
    _driverDocs = [
      for (var j = 0; j < _driverDocs.length; j++)
        if (j == i) _driverDocs[j].copyWith(status: DriverDocStatus.verified) else _driverDocs[j],
    ];
    final email = _user?.email.toLowerCase();
    if (email != null && _accounts[email] != null) {
      final acc = _accounts[email]!;
      _accounts[email] = _LocalAccount(
        password: acc.password,
        user: acc.user,
        documentsComplete: driverDocumentsComplete,
        driverDocs: List<DriverDocument>.from(_driverDocs),
      );
    }
    notifyListeners();
    await _persistSession();
  }

  Future<void> _activateUser(
    AppUser user, {
    bool forceDocsIncomplete = false,
    bool persist = true,
    List<DriverDocument>? driverDocs,
  }) async {
    _user = user;
    _pendingRole = user.role;
    // Keep an in-progress live ride when switching Passenger ↔ Driver mode.
    if (_activeRide == null) {
      _rideBooked = false;
      _tracking = false;
      _searching = false;
      _driverMatched = false;
      _ridePhase = PassengerRidePhase.idle;
      _driversSeen = 0;
      _activeTrip = null;
      _pendingPassengerJobId = null;
      _availableJobs.clear();
    }
    if (user.role == UserRole.driver) {
      if (_activeRide == null) {
        _online = DriverOnlineStatus.offline;
      }
      final acc = _accounts[user.email.toLowerCase()];
      if (driverDocs != null) {
        _driverDocs = List<DriverDocument>.from(driverDocs);
      } else if (acc != null && acc.driverDocs.isNotEmpty) {
        _driverDocs = List<DriverDocument>.from(acc.driverDocs);
      } else {
        final complete =
            !forceDocsIncomplete && (acc?.documentsComplete ?? false);
        _driverDocs = requiredDriverDocs
            .map(
              (d) => d.copyWith(
                status: complete ? DriverDocStatus.verified : DriverDocStatus.missing,
              ),
            )
            .toList();
      }
    } else {
      _driverDocs = const [];
      if (_activeRide == null) {
        _online = DriverOnlineStatus.offline;
      }
    }
    notifyListeners();
    if (persist) {
      await _persistSession();
    }
  }

  Future<void> logout() async {
    _stopRideTicker();
    _activeRide = null;
    _user = null;
    _pendingRole = UserRole.passenger;
    _online = DriverOnlineStatus.offline;
    _rideBooked = false;
    _tracking = false;
    _ridePhase = PassengerRidePhase.idle;
    _activeTrip = null;
    _pendingPassengerJobId = null;
    _availableJobs.clear();
    _driverDocs = const [];
    notifyListeners();
    await _persistSession();
  }

  /// Soft delete — clears local session/account data for this device.
  Future<void> deleteAccount() async {
    final email = _user?.email.toLowerCase();
    if (email != null) {
      _accounts.remove(email);
    }
    await logout();
  }

  void setPickup(String v) {
    _pickup = v;
    notifyListeners();
  }

  void setDestination(String v) {
    _destination = v;
    notifyListeners();
  }

  void setRideType(RideType t) {
    _rideType = t;
    notifyListeners();
  }

  void setBookMode(BookMode mode) {
    _bookMode = mode;
    if (mode == BookMode.now) _scheduledAt = null;
    notifyListeners();
  }

  void setVehicleCategory(VehicleCategory v) {
    _vehicleCategory = v;
    notifyListeners();
  }

  void setStop(String? value) {
    final v = value?.trim() ?? '';
    _stop = v.isEmpty ? null : v;
    notifyListeners();
  }

  void setScheduledAt(DateTime? when) {
    _scheduledAt = when;
    _bookMode = BookMode.later;
    notifyListeners();
  }

  void useCurrentLocation() {
    _pickup = 'Riverside Park, Glenrothes, Fife';
    notifyListeners();
  }

  String? confirmBooking() {
    if (_pickup.trim().isEmpty) return 'Set a pickup location.';
    if (_destination.trim().isEmpty) return 'Set a destination.';
    if (_bookMode == BookMode.later && _scheduledAt == null) {
      return 'Pick a date & time for Book Later.';
    }
    _rideBooked = true;
    _driverMatched = false;
    _driversSeen = 0;
    if (_bookMode == BookMode.now) {
      _tracking = true;
      _searching = true;
      _selectedDriverId = null;
      _ridePhase = PassengerRidePhase.finding;
      final jobId = 'job-p-${DateTime.now().millisecondsSinceEpoch}';
      _pendingPassengerJobId = jobId;
      final miles = 3.0 + _rng.nextDouble() * 8;
      final job = IncomingRequest(
        id: jobId,
        passengerName: _user?.name ?? 'Passenger',
        pickup: _pickup,
        destination: _destination,
        type: _rideType,
        fare: fareEstimate,
        distance: '${miles.toStringAsFixed(1)} mi',
        eta: '${4 + _rng.nextInt(8)} min',
        passengerPhone: _user?.phone ?? '',
      );
      // Push to driver offer queue (synced in this AppState).
      _availableJobs
        ..clear()
        ..add(job);
      if (_online == DriverOnlineStatus.offline && driverDocumentsComplete) {
        _online = DriverOnlineStatus.online;
      }
      // ignore: unawaited_futures
      _runFindDriver();
    } else {
      _tracking = false;
      _searching = false;
      _driverMatched = true;
      _ridePhase = PassengerRidePhase.idle;
      final when = _scheduledAt!;
      final hh = when.hour.toString().padLeft(2, '0');
      final mm = when.minute.toString().padLeft(2, '0');
      final id = 's-${DateTime.now().millisecondsSinceEpoch}';
      final record = RideRecord(
        id: id,
        pickup: _pickup,
        destination: _destination,
        type: RideType.scheduled,
        status: RideStatus.assigned,
        fare: fareEstimate,
        dateLabel: '${when.day}/${when.month} $hh:$mm',
        driverName: 'Pending assign',
        passengerName: _user?.name ?? 'Passenger',
        distance: fareMilesLabel,
      );
      _extraScheduled.insert(0, record);
      _driverScheduled.insert(0, record);
      _pushAlert('Scheduled ride confirmed for ${record.dateLabel}');
    }
    notifyListeners();
    return null;
  }

  /// Radar while waiting for the assigned driver to accept.
  Future<void> _runFindDriver() async {
    final gen = ++_findGeneration;
    final total = nearbyDrivers.length.clamp(1, 4);
    for (var i = 1; i <= total; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (gen != _findGeneration || !_rideBooked || !_tracking) return;
      if (_activeRide != null) return;
      _driversSeen = i;
      notifyListeners();
    }
    // Stay in finding until a driver accepts — do not auto-assign.
  }

  void cancelScheduledRide(String id) {
    _extraScheduled.removeWhere((r) => r.id == id);
    _driverScheduled.removeWhere((r) => r.id == id);
    _pushAlert('Scheduled ride cancelled');
    notifyListeners();
  }

  /// Finish active trip → rating (driver normally completes; passenger can rate after).
  void finishPassengerTrip() {
    if (_ridePhase != PassengerRidePhase.inProgress && _ridePhase != PassengerRidePhase.rating) {
      if (_activeRide?.stage == LiveRideStage.completed) {
        _ridePhase = PassengerRidePhase.rating;
        notifyListeners();
      }
      return;
    }
    _ridePhase = PassengerRidePhase.rating;
    notifyListeners();
  }

  void setMapView(bool map) {
    _mapView = map;
    notifyListeners();
  }

  void selectDriver(String id) {
    _selectedDriverId = id;
    notifyListeners();
  }

  Future<void> searchRide() async {
    _searching = true;
    _rideBooked = false;
    _tracking = false;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 650));
    _searching = false;
    _mapView = true;
    notifyListeners();
  }

  void bookSelectedDriver() {
    _rideBooked = true;
    _tracking = true;
    notifyListeners();
  }

  void cancelBooking() {
    _findGeneration++;
    if (_pendingPassengerJobId != null) {
      _availableJobs.removeWhere((j) => j.id == _pendingPassengerJobId);
      _pendingPassengerJobId = null;
    }
    if (_activeRide != null &&
        (_activeRide!.stage == LiveRideStage.assigned ||
            _activeRide!.stage == LiveRideStage.arrivedPickup)) {
      _stopRideTicker();
      _activeRide = null;
      _activeTrip = null;
      _online = DriverOnlineStatus.online;
      _seedAvailableJobs();
    }
    _rideBooked = false;
    _tracking = false;
    _searching = false;
    _driverMatched = false;
    _ridePhase = PassengerRidePhase.idle;
    _driversSeen = 0;
    _selectedDriverId = 'd1';
    notifyListeners();
  }

  void completePassengerRide(double rating) {
    _findGeneration++;
    _lastRating = rating;
    _stopRideTicker();
    _activeRide = null;
    _activeTrip = null;
    _pendingPassengerJobId = null;
    _rideBooked = false;
    _tracking = false;
    _searching = false;
    _driverMatched = false;
    _ridePhase = PassengerRidePhase.idle;
    _driversSeen = 0;
    if (_online == DriverOnlineStatus.onTrip) {
      _online = DriverOnlineStatus.online;
      _seedAvailableJobs();
    }
    notifyListeners();
  }

  void _pushAlert(String message) {
    _liveAlerts.insert(0, message);
    _alerts = _liveAlerts.length;
  }

  void _stopRideTicker() {
    _rideTicker?.cancel();
    _rideTicker = null;
    _locationSub?.cancel();
    _locationSub = null;
  }

  /// Live GPS tracking + fallback progress when GPS is unavailable.
  void _startRideTicker() {
    _stopRideTicker();
    // ignore: unawaited_futures
    _startLiveLocation();
    _rideTicker = Timer.periodic(const Duration(milliseconds: 900), (_) {
      final ride = _activeRide;
      if (ride == null) {
        _stopRideTicker();
        return;
      }
      if (ride.stage != LiveRideStage.assigned && ride.stage != LiveRideStage.inProgress) {
        return;
      }
      // Prefer real GPS distance; only animate progress when no fix yet.
      if (ride.driverLat != null) {
        _updateLiveMiles();
        notifyListeners();
        return;
      }
      if (ride.progress >= 0.97) {
        ride.progress = 1.0;
        notifyListeners();
        return;
      }
      ride.progress = (ride.progress + 0.045).clamp(0.0, 1.0);
      notifyListeners();
    });
  }

  Future<void> _startLiveLocation() async {
    final ok = await LocationService.ensurePermission();
    if (!ok || _activeRide == null) return;
    final here = await LocationService.currentLatLng();
    final ride = _activeRide;
    if (ride == null) return;
    if (here != null) {
      ride.driverLat = here.latitude;
      ride.driverLng = here.longitude;
      _updateLiveMiles();
      notifyListeners();
    }
    _locationSub?.cancel();
    _locationSub = LocationService.positionStream().listen((p) {
      final active = _activeRide;
      if (active == null) return;
      active.driverLat = p.latitude;
      active.driverLng = p.longitude;
      _updateLiveMiles();
      notifyListeners();
    });
  }

  void _updateLiveMiles() {
    final ride = _activeRide;
    if (ride?.driverLat == null || ride?.driverLng == null) return;
    final target = ride!.isToDropoff
        ? LatLng(ride.dropLat, ride.dropLng)
        : LatLng(ride.pickupLat, ride.pickupLng);
    final miles = LocationService.milesBetween(
      LatLng(ride.driverLat!, ride.driverLng!),
      target,
    );
    ride.liveRemainingMiles = miles;
    if (miles < 0.25) {
      ride.progress = 0.95;
    } else {
      final total = ride.currentLegMiles.clamp(0.5, 40);
      ride.progress = (1 - (miles / total)).clamp(0.0, 0.94);
    }
  }

  /// Returns an error message if the driver cannot go online.
  String? setOnline(bool value) {
    if (value && !driverDocumentsComplete) {
      return 'Upload all required documents before going online.';
    }
    if (_activeRide != null || _activeTrip != null) {
      return value ? null : 'Finish your active ride before going offline.';
    }
    if (value) {
      _online = DriverOnlineStatus.online;
      _seedAvailableJobs();
    } else {
      _online = DriverOnlineStatus.offline;
      _availableJobs.clear();
    }
    notifyListeners();
    return null;
  }

  void _seedAvailableJobs() {
    // Keep a live passenger booking at the front of the queue.
    if (_pendingPassengerJobId != null) {
      final pending = _availableJobs.where((j) => j.id == _pendingPassengerJobId).toList();
      if (pending.isNotEmpty) {
        _availableJobs
          ..clear()
          ..addAll(pending);
        return;
      }
    }
    // Queue of offers for this driver only — UI shows one at a time.
    _availableJobs
      ..clear()
      ..addAll(_randomJobs(1));
  }

  /// Ensure driver is receiving offers when documents are complete.
  void ensureDriverReceivingOffers() {
    if (!isDriver || !driverDocumentsComplete) return;
    if (_online == DriverOnlineStatus.offline) {
      _online = DriverOnlineStatus.online;
    }
    if (_activeTrip == null && _availableJobs.isEmpty) {
      _seedAvailableJobs();
    }
    notifyListeners();
  }

  List<IncomingRequest> _randomJobs(int count) {
    const pickups = [
      'Riverside Park, Glenrothes',
      'Kingdom Centre, Glenrothes',
      'Leven High Street',
      'Kirkcaldy Bus Station',
      'Dunfermline Town Centre',
      'St Andrews Market Street',
      'Cowdenbeath Cross',
    ];
    const drops = [
      'Victoria Hospital, Kirkcaldy',
      'Edinburgh Airport',
      'Fife College, Glenrothes',
      'Levenmouth Hub',
      'Kirkcaldy Waterfront',
      'Dunfermline Abbey',
      'St Andrews Golf Museum',
    ];
    const names = ['Smith', 'Brooke', 'Reece', 'Aisha', 'Callum', 'Nora', 'Jamie', 'Priya'];
    final types = RideType.values;
    final used = <int>{};
    final jobs = <IncomingRequest>[];
    for (var i = 0; i < count; i++) {
      var pi = _rng.nextInt(pickups.length);
      while (used.contains(pi)) {
        pi = _rng.nextInt(pickups.length);
      }
      used.add(pi);
      final di = _rng.nextInt(drops.length);
      final miles = 2.5 + _rng.nextDouble() * 12;
      final fare = 6.5 + miles * 1.35 + _rng.nextDouble() * 4;
      jobs.add(
        IncomingRequest(
          id: 'job-${DateTime.now().millisecondsSinceEpoch}-$i',
          passengerName: names[_rng.nextInt(names.length)],
          pickup: pickups[pi],
          destination: drops[di],
          type: types[_rng.nextInt(types.length)],
          fare: double.parse(fare.toStringAsFixed(2)),
          distance: '${miles.toStringAsFixed(1)} mi',
          eta: '${3 + _rng.nextInt(10)} min',
          passengerPhone: '+44 77${1000000 + _rng.nextInt(8999999)}',
        ),
      );
    }
    return jobs;
  }

  void acceptJob(String id) {
    if (_activeTrip != null || _activeRide != null) return; // one ride at a time
    final i = _availableJobs.indexWhere((j) => j.id == id);
    if (i < 0) return;
    _activeTrip = _availableJobs.removeAt(i);
    _availableJobs.clear(); // do not keep other offers while on a trip
    _online = DriverOnlineStatus.onTrip;
    final trip = _activeTrip!;
    final pickupMiles = double.tryParse(trip.distance.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 4.0;
    final driverUser = _user;
    final center = MapsConfig.fifeCenter;
    final jitter = (_rng.nextDouble() - 0.5) * 0.04;
    _activeRide = ActiveRide(
      id: trip.id,
      passengerName: trip.passengerName,
      passengerPhone: trip.passengerPhone,
      driverName: driverUser?.name ?? 'Driver',
      vehicle: driverUser?.vehicle ?? 'Toyota Prius',
      plate: 'SF26 TAX',
      driverRating: 4.9,
      pickup: trip.pickup,
      destination: trip.destination,
      type: trip.type,
      fare: trip.fare,
      pickupLegMiles: pickupMiles.clamp(1.5, 12),
      tripLegMiles: (pickupMiles * 1.4).clamp(2.0, 18),
      pickupLat: center.latitude + jitter,
      pickupLng: center.longitude + jitter * 0.6,
      dropLat: center.latitude - 0.05 + jitter * 0.3,
      dropLng: center.longitude - 0.02 + jitter * 0.4,
      stage: LiveRideStage.assigned,
      progress: 0,
    );
    // Sync passenger side immediately.
    _rideBooked = true;
    _tracking = true;
    _searching = false;
    _driverMatched = true;
    _ridePhase = PassengerRidePhase.approaching;
    _selectedDriverId = 'active-driver';
    _pendingPassengerJobId = null;
    _pushAlert(
      'Your driver is on the way. Please be ready. Your driver will arrive shortly.',
    );
    _ensureChatThreadForTrip(trip);
    _startRideTicker();
    notifyListeners();
  }

  void rejectJob(String id) {
    _availableJobs.removeWhere((j) => j.id == id);
    if (_pendingPassengerJobId == id) {
      // Passenger request rejected — keep searching with a new offer seed later.
      _pendingPassengerJobId = null;
    }
    if (_activeTrip == null && _availableJobs.isEmpty && isOnline) {
      _seedAvailableJobs();
    }
    notifyListeners();
  }

  /// Legacy aliases used by older UI.
  void acceptRequest() {
    final offer = offeredJob;
    if (offer == null) return;
    acceptJob(offer.id);
  }

  void rejectRequest() {
    final offer = offeredJob;
    if (offer == null) return;
    rejectJob(offer.id);
  }

  /// Driver arrived at passenger pickup.
  void markArrivedAtPickup() {
    final ride = _activeRide;
    if (ride == null || ride.stage != LiveRideStage.assigned) return;
    ride.stage = LiveRideStage.arrivedPickup;
    ride.progress = 1.0;
    _ridePhase = PassengerRidePhase.arrived;
    _pushAlert('Your driver has arrived. Please meet your driver at the pickup location.');
    _ensureChatStatus('Arrived at pickup — waiting for passenger');
    notifyListeners();
  }

  /// Passenger boarded — start trip to destination.
  void startActiveRide() {
    final ride = _activeRide;
    if (ride == null || ride.stage != LiveRideStage.arrivedPickup) return;
    ride.stage = LiveRideStage.inProgress;
    ride.progress = 0;
    _ridePhase = PassengerRidePhase.inProgress;
    _pushAlert('Your ride has started. Tracking to your destination.');
    _ensureChatStatus('Ride started · en route to destination');
    _startRideTicker();
    notifyListeners();
  }

  /// Drop-off complete.
  void completeActiveRide() {
    final ride = _activeRide;
    final trip = _activeTrip;
    if (ride == null) {
      completeTrip();
      return;
    }
    if (ride.stage != LiveRideStage.inProgress) return;
    _stopRideTicker();
    ride.stage = LiveRideStage.completed;
    ride.progress = 1.0;
    final now = DateTime.now();
    final label =
        'Today ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final record = RideRecord(
      id: ride.id,
      pickup: ride.pickup,
      destination: ride.destination,
      type: ride.type,
      status: RideStatus.completed,
      fare: ride.fare,
      dateLabel: label,
      driverName: ride.driverName,
      passengerName: ride.passengerName,
      distance: '${ride.tripLegMiles.toStringAsFixed(1)} mi',
      rating: 5,
    );
    _completedPassengerTrips.insert(0, record);
    _completedDriverTrips.insert(0, record);
    _ridePhase = PassengerRidePhase.rating;
    _pushAlert('Your ride has been completed. Thank you for riding with FNT.');
    if (trip != null) {
      _ensureChatThreadForTrip(trip, completedNote: true);
    }
    _activeTrip = null;
    _online = DriverOnlineStatus.online;
    _seedAvailableJobs();
    notifyListeners();
  }

  void _ensureChatStatus(String note) {
    final trip = _activeTrip;
    if (trip == null) return;
    final now = DateTime.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final msg = ChatMessage(from: 'You', body: note, time: time, mine: true);
    final i = _chatThreads.indexWhere(
      (t) => t.passengerName == trip.passengerName || t.rideId == trip.id,
    );
    if (i >= 0) {
      final t = _chatThreads[i];
      _chatThreads[i] = t.copyWith(
        lastMessage: note,
        time: time,
        messages: [...t.messages, msg],
      );
    }
  }

  void completeTrip() {
    if (_activeRide != null) {
      completeActiveRide();
      return;
    }
    final done = _activeTrip;
    _activeTrip = null;
    _online = DriverOnlineStatus.online;
    if (done != null) {
      _ensureChatThreadForTrip(done, completedNote: true);
    }
    _seedAvailableJobs();
    notifyListeners();
  }

  void refreshJobs() {
    if (_activeTrip != null) return;
    if (!driverDocumentsComplete) return;
    if (_online == DriverOnlineStatus.offline) {
      _online = DriverOnlineStatus.online;
    }
    _seedAvailableJobs();
    notifyListeners();
  }

  void _ensureChatThreadForTrip(IncomingRequest trip, {bool completedNote = false}) {
    final now = DateTime.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final note = completedNote
        ? 'Trip completed · ${trip.pickup} → ${trip.destination}'
        : 'Ride accepted · heading to pickup';
    final msg = ChatMessage(from: 'You', body: note, time: time, mine: true);
    final i = _chatThreads.indexWhere(
      (t) => t.passengerName == trip.passengerName || t.rideId == trip.id,
    );
    if (i >= 0) {
      final t = _chatThreads[i];
      _chatThreads[i] = t.copyWith(
        lastMessage: note,
        time: time,
        messages: [...t.messages, msg],
        unread: 0,
      );
    } else {
      _chatThreads.insert(
        0,
        ChatThread(
          id: 'c-${trip.id}',
          passengerName: trip.passengerName,
          rideId: trip.id,
          lastMessage: note,
          time: time,
          unread: 0,
          messages: [msg],
        ),
      );
    }
  }

  ChatThread? chatThreadById(String id) {
    try {
      return _chatThreads.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  void markThreadRead(String id) {
    final i = _chatThreads.indexWhere((t) => t.id == id);
    if (i < 0) return;
    _chatThreads[i] = _chatThreads[i].copyWith(unread: 0);
    notifyListeners();
  }

  void sendChatMessage(String threadId, String body) {
    final text = body.trim();
    if (text.isEmpty) return;
    final i = _chatThreads.indexWhere((t) => t.id == threadId);
    if (i < 0) return;
    final now = DateTime.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final msg = ChatMessage(from: 'You', body: text, time: time, mine: true);
    final t = _chatThreads[i];
    final updated = t.copyWith(
      lastMessage: text,
      time: time,
      messages: [...t.messages, msg],
      unread: 0,
    );
    _chatThreads.removeAt(i);
    _chatThreads.insert(0, updated);
    notifyListeners();
  }

  void clearMessages() {
    for (var i = 0; i < _chatThreads.length; i++) {
      _chatThreads[i] = _chatThreads[i].copyWith(unread: 0);
    }
    notifyListeners();
  }

  void clearAlerts() {
    _alerts = 0;
    _liveAlerts.clear();
    notifyListeners();
  }

  void blockClient(String name) {
    _blocked.add(name);
    notifyListeners();
  }

  void unblockClient(String name) {
    _blocked.remove(name);
    notifyListeners();
  }
}

class _LocalAccount {
  final String password;
  final AppUser user;
  final bool documentsComplete;
  final List<DriverDocument> driverDocs;
  _LocalAccount({
    required this.password,
    required this.user,
    this.documentsComplete = false,
    List<DriverDocument>? driverDocs,
  }) : driverDocs = driverDocs ?? const [];
}
