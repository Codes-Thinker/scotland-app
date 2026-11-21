import 'package:flutter/material.dart';

import '../shared/models/models.dart';

class MockRepository {
  static const nearbyDrivers = [
    NearbyDriver(
      id: 'd1',
      name: 'Wadza Makore',
      vehicle: 'Toyota Prius',
      plate: 'SF26 TAX',
      distanceKm: 1.2,
      rating: 4.9,
      eta: '4 min',
      fareEstimate: 8.40,
      mapOffset: Offset(0.58, 0.55),
    ),
    NearbyDriver(
      id: 'd2',
      name: 'Eugene Dhliwayo',
      vehicle: 'Skoda Octavia',
      plate: 'KY12 CAB',
      distanceKm: 1.5,
      rating: 4.7,
      eta: '6 min',
      fareEstimate: 9.10,
      mapOffset: Offset(0.30, 0.40),
    ),
    NearbyDriver(
      id: 'd3',
      name: 'Glenrothes Driver',
      vehicle: 'Ford Focus',
      plate: 'FK26 RDE',
      distanceKm: 2.1,
      rating: 4.6,
      eta: '8 min',
      fareEstimate: 10.50,
      mapOffset: Offset(0.70, 0.32),
    ),
    NearbyDriver(
      id: 'd4',
      name: 'Coastal Fleet',
      vehicle: 'VW Passat',
      plate: 'CO24 FLT',
      distanceKm: 2.4,
      rating: 4.5,
      eta: '9 min',
      fareEstimate: 11.20,
      mapOffset: Offset(0.42, 0.72),
    ),
  ];

  static const passengerTrips = [
    RideRecord(
      id: 'r1',
      pickup: 'Glenrothes',
      destination: 'Kirkcaldy',
      type: RideType.standard,
      status: RideStatus.completed,
      fare: 12.40,
      dateLabel: 'Yesterday',
      driverName: 'Wadza Makore',
      rating: 5,
    ),
    RideRecord(
      id: 'r2',
      pickup: 'Leven',
      destination: 'St Andrews',
      type: RideType.scheduled,
      status: RideStatus.completed,
      fare: 28.00,
      dateLabel: 'Mon',
      driverName: 'Coastal Fleet',
      rating: 4,
    ),
    RideRecord(
      id: 'r3',
      pickup: 'Home',
      destination: 'Airport',
      type: RideType.emergency,
      status: RideStatus.completed,
      fare: 48.00,
      dateLabel: 'Sun',
      driverName: 'Wadza Makore',
      rating: 5,
    ),
  ];

  static const driverTrips = [
    RideRecord(
      id: 'dr1',
      pickup: 'Kingdom Centre',
      destination: 'Glenrothes',
      type: RideType.standard,
      status: RideStatus.completed,
      fare: 9.80,
      dateLabel: 'Today',
      driverName: null,
      rating: 5,
    ),
    RideRecord(
      id: 'dr2',
      pickup: 'Kirkcaldy',
      destination: 'Leven',
      type: RideType.standard,
      status: RideStatus.completed,
      fare: 14.20,
      dateLabel: 'Yesterday',
      driverName: null,
      rating: 4,
    ),
  ];

  static const clientNames = [
    'Ayaz Aslam',
    'Sarah Mitchell',
    'James Wilson',
    'Emma Fraser',
  ];

  static const messages = [
    ChatMessage(from: 'Dispatch', body: 'New job in Glenrothes area', time: '09:12'),
    ChatMessage(from: 'You', body: 'On my way', time: '09:13', mine: true),
    ChatMessage(from: 'Passenger', body: 'I am outside the station', time: '09:18'),
  ];

  /// Existing ride-linked chats for driver Inbox (WhatsApp-style list).
  static final chatThreads = <ChatThread>[
    ChatThread(
      id: 'c-smith',
      passengerName: 'Smith',
      rideId: 'r1',
      lastMessage: 'I am outside the station',
      time: '09:18',
      unread: 1,
      messages: [
        ChatMessage(from: 'Smith', body: 'Hi, I booked a ride to Kirkcaldy', time: '09:10'),
        ChatMessage(from: 'You', body: 'On my way — 4 min', time: '09:13', mine: true),
        ChatMessage(from: 'Smith', body: 'I am outside the station', time: '09:18'),
      ],
    ),
    ChatThread(
      id: 'c-brooke',
      passengerName: 'Brooke',
      rideId: 'r2',
      lastMessage: 'Thanks for the ride',
      time: 'Yesterday',
      unread: 0,
      messages: [
        ChatMessage(from: 'Brooke', body: 'Pickup is the blue door', time: '18:02'),
        ChatMessage(from: 'You', body: 'Got it, see you soon', time: '18:03', mine: true),
        ChatMessage(from: 'Brooke', body: 'Thanks for the ride', time: '18:40'),
      ],
    ),
    ChatThread(
      id: 'c-dispatch',
      passengerName: 'Dispatch',
      lastMessage: 'Peak demand expected this evening',
      time: 'Mon',
      unread: 1,
      messages: [
        ChatMessage(from: 'Dispatch', body: 'New job in Glenrothes area', time: '09:12'),
        ChatMessage(from: 'You', body: 'Standing by', time: '09:13', mine: true),
        ChatMessage(from: 'Dispatch', body: 'Peak demand expected this evening', time: 'Mon'),
      ],
    ),
  ];

  static const driverAlerts = [
    'Documents due for renewal in 14 days',
    'Peak demand expected this evening',
    'New retained client: Ayaz Aslam',
  ];

  static String rideTypeLabel(RideType t) {
    switch (t) {
      case RideType.standard:
        return 'Standard';
      case RideType.emergency:
        return 'Emergency';
      case RideType.scheduled:
        return 'Scheduled';
      case RideType.roadside:
        return 'Roadside';
    }
  }

  static String vehicleLabel(VehicleCategory v) {
    switch (v) {
      case VehicleCategory.fourSeater:
        return '4 Seater';
      case VehicleCategory.sixSeater:
        return '6 Seater (MPV)';
      case VehicleCategory.eightSeater:
        return '8 Seater (Mini Bus)';
      case VehicleCategory.wheelchair:
        return 'Wheelchair Vehicle';
    }
  }

  static const scheduledRides = [
    RideRecord(
      id: 's1',
      pickup: 'Glenrothes Town Centre',
      destination: 'Edinburgh Airport',
      type: RideType.scheduled,
      status: RideStatus.assigned,
      fare: 65.00,
      dateLabel: 'Tomorrow 06:30',
      driverName: 'Pending assign',
    ),
    RideRecord(
      id: 's2',
      pickup: 'Home',
      destination: 'Victoria Hospital',
      type: RideType.scheduled,
      status: RideStatus.assigned,
      fare: 14.00,
      dateLabel: 'Fri 09:00',
      driverName: 'Wadza Makore',
    ),
  ];

  static const passengerAlerts = [
    'Driver is 4 min away from your pickup',
    'Scheduled ride reminder: tomorrow 06:30 to Edinburgh Airport',
    'Promo: weekday Standard rates apply Mon–Fri',
  ];

  static const supportTopics = [
    ('Lost item', 'Report something left in a vehicle'),
    ('Fare dispute', 'Question about a completed trip fare'),
    ('Safety concern', 'Speak with dispatch about a ride'),
    ('Account help', 'Email, phone or payment questions'),
  ];

  /// Mock places for pickup / drop search (Fife-focused).
  static const places = [
    PlaceSuggestion(
      title: 'Glenrothes Centre',
      subtitle: 'North Street, Glenrothes, Fife',
      postcode: 'KY7',
      kind: PlaceKind.recent,
      mapOffset: Offset(0.52, 0.46),
    ),
    PlaceSuggestion(
      title: 'Kirkcaldy Station',
      subtitle: 'Station Road, Kirkcaldy',
      postcode: 'KY1',
      kind: PlaceKind.recent,
      mapOffset: Offset(0.58, 0.64),
    ),
    PlaceSuggestion(
      title: 'Victoria Hospital',
      subtitle: 'Hayfield Road, Kirkcaldy',
      postcode: 'KY2',
      kind: PlaceKind.recent,
      mapOffset: Offset(0.62, 0.58),
    ),
    PlaceSuggestion(
      title: 'Riverside Park',
      subtitle: 'Glenrothes, Fife KY7',
      postcode: 'KY7 6NR',
      kind: PlaceKind.popular,
      mapOffset: Offset(0.48, 0.52),
    ),
    PlaceSuggestion(
      title: 'Kingdom Centre',
      subtitle: 'North Street, Glenrothes',
      postcode: 'KY7 5NA',
      kind: PlaceKind.popular,
      mapOffset: Offset(0.55, 0.42),
    ),
    PlaceSuggestion(
      title: 'Edinburgh Airport',
      subtitle: 'Edinburgh EH12 9DN',
      postcode: 'EH12 9DN',
      kind: PlaceKind.airport,
      mapOffset: Offset(0.72, 0.28),
    ),
    PlaceSuggestion(
      title: 'St Andrews Bus Station',
      subtitle: 'City Road, St Andrews',
      postcode: 'KY16',
      kind: PlaceKind.transit,
      mapOffset: Offset(0.78, 0.36),
    ),
    PlaceSuggestion(
      title: 'Leven High Street',
      subtitle: 'Leven, Fife',
      postcode: 'KY8',
      kind: PlaceKind.popular,
      mapOffset: Offset(0.40, 0.70),
    ),
    PlaceSuggestion(
      title: 'Fife College',
      subtitle: 'Stenton Road, Glenrothes',
      postcode: 'KY6',
      kind: PlaceKind.popular,
      mapOffset: Offset(0.44, 0.46),
    ),
    PlaceSuggestion(
      title: 'Home',
      subtitle: 'Saved place · Glenrothes',
      postcode: 'KY7',
      kind: PlaceKind.saved,
      mapOffset: Offset(0.50, 0.50),
    ),
    PlaceSuggestion(
      title: 'Work',
      subtitle: 'Saved place · Glenrothes',
      postcode: 'KY7',
      kind: PlaceKind.saved,
      mapOffset: Offset(0.53, 0.48),
    ),
    PlaceSuggestion(
      title: 'Dunfermline Town',
      subtitle: 'Dunfermline, Fife',
      postcode: 'KY12',
      kind: PlaceKind.popular,
      mapOffset: Offset(0.35, 0.55),
    ),
  ];

  static List<PlaceSuggestion> get recentPlaces =>
      places.where((p) => p.kind == PlaceKind.recent).take(3).toList();

  static List<PlaceSuggestion> searchPlaces(String query, {bool postcodeOnly = false}) {
    final q = query.trim().toLowerCase().replaceAll(' ', '');
    if (q.length < 3) return const [];
    return places.where((p) {
      final pc = p.postcode.toLowerCase().replaceAll(' ', '');
      final title = p.title.toLowerCase();
      final sub = p.subtitle.toLowerCase();
      if (postcodeOnly) {
        return pc.contains(q) || q.contains(pc) || p.postcode.toLowerCase().contains(query.trim().toLowerCase());
      }
      return title.contains(query.trim().toLowerCase()) ||
          sub.contains(query.trim().toLowerCase()) ||
          pc.contains(q);
    }).toList();
  }
}
