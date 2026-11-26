import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../shared/models/models.dart';

class ApiPlace {
  final String address;
  final double lat;
  final double lng;

  const ApiPlace({required this.address, required this.lat, required this.lng});

  Map<String, dynamic> toJson() => {
        'address': address,
        'lat': lat,
        'lng': lng,
      };

  factory ApiPlace.fromJson(Map<String, dynamic> json) => ApiPlace(
        address: '${json['address'] ?? ''}',
        lat: (json['lat'] as num?)?.toDouble() ?? 0,
        lng: (json['lng'] as num?)?.toDouble() ?? 0,
      );

  LatLng get latLng => LatLng(lat, lng);
}

class RideEstimate {
  final String rideType;
  final String bookingMode;
  final int distanceM;
  final int fareEstimatePence;
  final String currency;

  const RideEstimate({
    required this.rideType,
    required this.bookingMode,
    required this.distanceM,
    required this.fareEstimatePence,
    required this.currency,
  });

  double get farePounds => fareEstimatePence / 100.0;
  double get distanceMiles => distanceM / 1609.344;

  factory RideEstimate.fromJson(Map<String, dynamic> json) => RideEstimate(
        rideType: '${json['rideType']}',
        bookingMode: '${json['bookingMode']}',
        distanceM: (json['distanceM'] as num?)?.toInt() ?? 0,
        fareEstimatePence: (json['fareEstimatePence'] as num?)?.toInt() ?? 0,
        currency: '${json['currency'] ?? 'GBP'}',
      );
}

class ApiRide {
  final String id;
  final String status;
  final String rideType;
  final String bookingMode;
  final String vehicleCategory;
  final ApiPlace pickup;
  final ApiPlace drop;
  final DateTime? scheduledAt;
  final int? distanceM;
  final int fareEstimatePence;
  final int? fareFinalPence;
  final DateTime requestedAt;
  final String passengerId;
  final String passengerName;
  final String? passengerPhone;
  final String? driverId;
  final String? driverName;
  final String? driverPhone;
  final String? cancelReason;

  const ApiRide({
    required this.id,
    required this.status,
    required this.rideType,
    required this.bookingMode,
    required this.vehicleCategory,
    required this.pickup,
    required this.drop,
    this.scheduledAt,
    this.distanceM,
    required this.fareEstimatePence,
    this.fareFinalPence,
    required this.requestedAt,
    required this.passengerId,
    required this.passengerName,
    this.passengerPhone,
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.cancelReason,
  });

  double get farePounds => (fareFinalPence ?? fareEstimatePence) / 100.0;

  bool get isActive =>
      status == 'requested' ||
      status == 'assigned' ||
      status == 'arrived' ||
      status == 'in_progress';

  factory ApiRide.fromJson(Map<String, dynamic> json) {
    final passenger = json['passenger'] as Map<String, dynamic>? ?? {};
    final driver = json['driver'] as Map<String, dynamic>?;
    return ApiRide(
      id: '${json['id']}',
      status: '${json['status']}',
      rideType: '${json['rideType']}',
      bookingMode: '${json['bookingMode']}',
      vehicleCategory: '${json['vehicleCategory']}',
      pickup: ApiPlace.fromJson(Map<String, dynamic>.from(json['pickup'] as Map)),
      drop: ApiPlace.fromJson(Map<String, dynamic>.from(json['drop'] as Map)),
      scheduledAt: json['scheduledAt'] != null ? DateTime.tryParse('${json['scheduledAt']}') : null,
      distanceM: (json['distanceM'] as num?)?.toInt(),
      fareEstimatePence: (json['fareEstimatePence'] as num?)?.toInt() ?? 0,
      fareFinalPence: (json['fareFinalPence'] as num?)?.toInt(),
      requestedAt: DateTime.tryParse('${json['requestedAt']}') ?? DateTime.now().toUtc(),
      passengerId: '${passenger['id'] ?? ''}',
      passengerName: '${passenger['name'] ?? 'Passenger'}',
      passengerPhone: passenger['phone'] as String?,
      driverId: driver?['id'] as String?,
      driverName: driver?['name'] as String?,
      driverPhone: driver?['phone'] as String?,
      cancelReason: json['cancelReason'] as String?,
    );
  }
}

class ApiRideOffer {
  final String offerId;
  final String rideId;
  final String rideType;
  final ApiPlace pickup;
  final ApiPlace drop;
  final int fareEstimatePence;
  final int? distanceToPickupM;
  final DateTime expiresAt;

  const ApiRideOffer({
    required this.offerId,
    required this.rideId,
    required this.rideType,
    required this.pickup,
    required this.drop,
    required this.fareEstimatePence,
    this.distanceToPickupM,
    required this.expiresAt,
  });

  double get farePounds => fareEstimatePence / 100.0;

  factory ApiRideOffer.fromJson(Map<String, dynamic> json) => ApiRideOffer(
        offerId: '${json['offerId']}',
        rideId: '${json['rideId']}',
        rideType: '${json['rideType']}',
        pickup: ApiPlace.fromJson(Map<String, dynamic>.from(json['pickup'] as Map)),
        drop: ApiPlace.fromJson(Map<String, dynamic>.from(json['drop'] as Map)),
        fareEstimatePence: (json['fareEstimatePence'] as num?)?.toInt() ?? 0,
        distanceToPickupM: (json['distanceToPickupM'] as num?)?.toInt(),
        expiresAt: DateTime.tryParse('${json['expiresAt']}') ?? DateTime.now().toUtc(),
      );
}

class RideWire {
  RideWire._();

  static String rideType(RideType t) {
    switch (t) {
      case RideType.emergency:
        return 'emergency';
      case RideType.roadside:
        return 'roadside';
      case RideType.scheduled:
      case RideType.standard:
        return 'standard';
    }
  }

  static String bookingMode(BookMode m) => m == BookMode.later ? 'later' : 'now';

  static String vehicleCategory(VehicleCategory v) {
    switch (v) {
      case VehicleCategory.fourSeater:
        return 'four_seater';
      case VehicleCategory.sixSeater:
        return 'six_seater';
      case VehicleCategory.eightSeater:
        return 'eight_seater';
      case VehicleCategory.wheelchair:
        return 'wheelchair';
    }
  }

  static RideType parseRideType(String v) {
    switch (v) {
      case 'emergency':
        return RideType.emergency;
      case 'roadside':
        return RideType.roadside;
      default:
        return RideType.standard;
    }
  }

  static LiveRideStage? liveStage(String status) {
    switch (status) {
      case 'assigned':
        return LiveRideStage.assigned;
      case 'arrived':
        return LiveRideStage.arrivedPickup;
      case 'in_progress':
        return LiveRideStage.inProgress;
      case 'completed':
        return LiveRideStage.completed;
      default:
        return null;
    }
  }

  static PassengerRidePhase passengerPhase(String status) {
    switch (status) {
      case 'requested':
        return PassengerRidePhase.finding;
      case 'assigned':
        return PassengerRidePhase.approaching;
      case 'arrived':
        return PassengerRidePhase.arrived;
      case 'in_progress':
        return PassengerRidePhase.inProgress;
      case 'completed':
        return PassengerRidePhase.rating;
      default:
        return PassengerRidePhase.idle;
    }
  }
}
