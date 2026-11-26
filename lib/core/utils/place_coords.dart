import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/maps_config.dart';
import '../../services/location_service.dart';

/// Resolve lat/lng for booking when the UI only has an address string.
class PlaceCoords {
  PlaceCoords._();

  static Future<LatLng> resolve(String address, {LatLng? hint}) async {
    if (hint != null) return hint;

    final lower = address.toLowerCase();
    if (lower.contains('current location') || lower.startsWith('current location')) {
      final here = await LocationService.currentLatLng();
      if (here != null) return here;
    }

    // Deterministic offset around Fife so each address is stable for mock/geo-less flows.
    final hash = utf8.encode(address.trim().toLowerCase()).fold<int>(0, (a, b) => a + b);
    final dLat = ((hash % 200) - 100) / 2500.0;
    final dLng = (((hash ~/ 7) % 200) - 100) / 2500.0;
    return LatLng(
      MapsConfig.fifeCenter.latitude + dLat,
      MapsConfig.fifeCenter.longitude + dLng,
    );
  }
}
