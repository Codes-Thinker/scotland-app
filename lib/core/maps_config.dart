import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Google Maps Platform configuration (Fife Nearby Taxis).
class MapsConfig {
  /// Maps SDK + Directions API key.
  static const apiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  /// Default camera — Glenrothes / central Fife.
  static const fifeCenter = LatLng(56.1955, -3.1565);
  static const defaultZoom = 13.2;

  static const CameraPosition initialCamera = CameraPosition(
    target: fifeCenter,
    zoom: defaultZoom,
  );
}
