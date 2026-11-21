import 'package:flutter/material.dart';

enum UserRole { passenger, driver }

enum RideType { standard, emergency, scheduled, roadside }

enum VehicleCategory { fourSeater, sixSeater, eightSeater, wheelchair }

enum BookMode { now, later }

/// Passenger UI stages during an active / pending booking.
enum PassengerRidePhase { idle, finding, approaching, arrived, inProgress, rating }

/// Shared live-ride stages for Driver + Passenger (Uber-style).
enum LiveRideStage { assigned, arrivedPickup, inProgress, completed }

enum RideStatus { searching, assigned, enRoute, arrived, inProgress, completed, cancelled }

/// One synchronized live trip visible to the assigned driver & passenger.
class ActiveRide {
  final String id;
  final String passengerName;
  final String passengerPhone;
  final String driverName;
  final String vehicle;
  final String plate;
  final double driverRating;
  final String pickup;
  final String destination;
  final RideType type;
  final double fare;
  final double pickupLegMiles;
  final double tripLegMiles;
  /// Pickup / drop coordinates (Fife area defaults if not geocoded).
  double pickupLat;
  double pickupLng;
  double dropLat;
  double dropLng;
  /// Live driver GPS (updated from device when available).
  double? driverLat;
  double? driverLng;
  LiveRideStage stage;

  /// 0..1 progress along the *current* leg (to pickup, or to destination).
  double progress;

  /// Live remaining miles from GPS when available; else progress estimate.
  double? liveRemainingMiles;

  ActiveRide({
    required this.id,
    required this.passengerName,
    required this.passengerPhone,
    required this.driverName,
    required this.vehicle,
    required this.plate,
    required this.driverRating,
    required this.pickup,
    required this.destination,
    required this.type,
    required this.fare,
    required this.pickupLegMiles,
    required this.tripLegMiles,
    this.pickupLat = 56.1955,
    this.pickupLng = -3.1565,
    this.dropLat = 56.1165,
    this.dropLng = -3.1590,
    this.driverLat,
    this.driverLng,
    this.stage = LiveRideStage.assigned,
    this.progress = 0,
    this.liveRemainingMiles,
  });

  bool get isToPickup => stage == LiveRideStage.assigned;
  bool get isToDropoff => stage == LiveRideStage.inProgress;

  double get currentLegMiles => isToDropoff ? tripLegMiles : pickupLegMiles;

  double get remainingMiles {
    if (liveRemainingMiles != null) {
      return double.parse(liveRemainingMiles!.clamp(0.1, 99).toStringAsFixed(1));
    }
    final left = currentLegMiles * (1 - progress.clamp(0.0, 1.0));
    return double.parse(left.toStringAsFixed(1));
  }

  int get etaMinutes {
    // ~2.2 min per mile urban estimate
    final m = (remainingMiles * 2.2).ceil();
    return m < 1 ? 1 : m;
  }

  String get statusLabel {
    switch (stage) {
      case LiveRideStage.assigned:
        return 'Driver on the way';
      case LiveRideStage.arrivedPickup:
        return 'Driver has arrived';
      case LiveRideStage.inProgress:
        return 'Ride in progress';
      case LiveRideStage.completed:
        return 'Completed';
    }
  }

  String get passengerBanner {
    switch (stage) {
      case LiveRideStage.assigned:
        return 'Your driver is on the way. Please be ready. Your driver will arrive shortly.';
      case LiveRideStage.arrivedPickup:
        return 'Your driver has arrived. Please meet your driver at the pickup location.';
      case LiveRideStage.inProgress:
        return 'Your ride is in progress. Tracking to your destination.';
      case LiveRideStage.completed:
        return 'Your ride has been completed. Thank you for riding with FNT.';
    }
  }
}

enum DriverOnlineStatus { offline, online, onTrip }

enum DriverDocStatus { missing, pending, verified }

enum PlaceKind { recent, popular, saved, airport, transit }

class PlaceSuggestion {
  final String title;
  final String subtitle;
  final String postcode;
  final PlaceKind kind;
  final Offset mapOffset;

  const PlaceSuggestion({
    required this.title,
    required this.subtitle,
    required this.postcode,
    required this.kind,
    required this.mapOffset,
  });

  String get fullAddress => '$title, $subtitle';

  String get recentChip => postcode.isEmpty ? title : '$title, $postcode';
}

class DriverDocument {
  final String id;
  final String title;
  final String hint;
  final DriverDocStatus status;

  const DriverDocument({
    required this.id,
    required this.title,
    required this.hint,
    required this.status,
  });

  DriverDocument copyWith({DriverDocStatus? status}) => DriverDocument(
        id: id,
        title: title,
        hint: hint,
        status: status ?? this.status,
      );
}

class AppUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String? vehicle;
  final String? licenceNumber;
  final String? vehiclePlate;
  final String? operatingZone;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.vehicle,
    this.licenceNumber,
    this.vehiclePlate,
    this.operatingZone,
  });
}

class NearbyDriver {
  final String id;
  final String name;
  final String vehicle;
  final String plate;
  final double distanceKm;
  final double rating;
  final String eta;
  final double fareEstimate;
  final Offset mapOffset;

  const NearbyDriver({
    required this.id,
    required this.name,
    required this.vehicle,
    required this.plate,
    required this.distanceKm,
    required this.rating,
    required this.eta,
    required this.fareEstimate,
    required this.mapOffset,
  });
}

class RideRecord {
  final String id;
  final String pickup;
  final String destination;
  final RideType type;
  final RideStatus status;
  final double fare;
  final String dateLabel;
  final String? driverName;
  final String? passengerName;
  final String? distance;
  final double? rating;

  const RideRecord({
    required this.id,
    required this.pickup,
    required this.destination,
    required this.type,
    required this.status,
    required this.fare,
    required this.dateLabel,
    this.driverName,
    this.passengerName,
    this.distance,
    this.rating,
  });
}

class IncomingRequest {
  final String id;
  final String passengerName;
  final String pickup;
  final String destination;
  final RideType type;
  final double fare;
  final String distance;
  final String eta;
  final String passengerPhone;

  const IncomingRequest({
    required this.id,
    required this.passengerName,
    required this.pickup,
    required this.destination,
    required this.type,
    required this.fare,
    required this.distance,
    this.eta = '5 min',
    this.passengerPhone = '',
  });
}

class ChatMessage {
  final String from;
  final String body;
  final String time;
  final bool mine;

  const ChatMessage({
    required this.from,
    required this.body,
    required this.time,
    this.mine = false,
  });
}

/// One WhatsApp-style conversation (per passenger / ride thread).
class ChatThread {
  final String id;
  final String passengerName;
  final String? rideId;
  final String lastMessage;
  final String time;
  final int unread;
  final List<ChatMessage> messages;

  const ChatThread({
    required this.id,
    required this.passengerName,
    required this.lastMessage,
    required this.time,
    this.rideId,
    this.unread = 0,
    this.messages = const [],
  });

  ChatThread copyWith({
    String? lastMessage,
    String? time,
    int? unread,
    List<ChatMessage>? messages,
  }) =>
      ChatThread(
        id: id,
        passengerName: passengerName,
        rideId: rideId,
        lastMessage: lastMessage ?? this.lastMessage,
        time: time ?? this.time,
        unread: unread ?? this.unread,
        messages: messages ?? this.messages,
      );
}
