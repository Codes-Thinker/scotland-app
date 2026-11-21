import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../core/maps_config.dart';

class DirectionsService {
  /// Returns a driving route polyline between [origin] and [destination].
  static Future<List<LatLng>> route(LatLng origin, LatLng destination) async {
    if (MapsConfig.apiKey.isEmpty) return [origin, destination];

    final uri = Uri.https('maps.googleapis.com', '/maps/api/directions/json', {
      'origin': '${origin.latitude},${origin.longitude}',
      'destination': '${destination.latitude},${destination.longitude}',
      'mode': 'driving',
      'key': MapsConfig.apiKey,
    });
    try {
      final res = await http.get(uri);
      if (res.statusCode != 200) return [origin, destination];
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['status'] != 'OK') return [origin, destination];
      final routes = data['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return [origin, destination];
      final overview = routes.first['overview_polyline']?['points'] as String?;
      if (overview == null || overview.isEmpty) return [origin, destination];
      return decodePolyline(overview);
    } catch (_) {
      return [origin, destination];
    }
  }

  static List<LatLng> decodePolyline(String encoded) {
    final points = <LatLng>[];
    var index = 0;
    final len = encoded.length;
    var lat = 0;
    var lng = 0;

    while (index < len) {
      int b;
      var shift = 0;
      var result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }
}
