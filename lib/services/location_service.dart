import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Device GPS helpers for live ride tracking and map centering.
class LocationService {
  static Future<bool> ensurePermission() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      // Prompt user to turn on device location (Android settings sheet).
      await Geolocator.openLocationSettings();
      final again = await Geolocator.isLocationServiceEnabled();
      if (!again) return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }
    return true;
  }

  static LocationSettings _settings({Duration? timeLimit}) {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 8,
        forceLocationManager: false,
        timeLimit: timeLimit,
      );
    }
    return LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 8,
      timeLimit: timeLimit,
    );
  }

  static Future<LatLng?> currentLatLng() async {
    final ok = await ensurePermission();
    if (!ok) return null;

    // Fast path — last known fix (important on Android cold start).
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        // Refresh in background; return last immediately for map centering.
        // ignore: unawaited_futures
        Geolocator.getCurrentPosition(locationSettings: _settings(timeLimit: const Duration(seconds: 12)));
        return LatLng(last.latitude, last.longitude);
      }
    } catch (_) {}

    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: _settings(timeLimit: const Duration(seconds: 12)),
      );
      return LatLng(p.latitude, p.longitude);
    } catch (_) {
      return null;
    }
  }

  static Stream<Position> positionStream() {
    return Geolocator.getPositionStream(locationSettings: _settings());
  }

  static double milesBetween(LatLng a, LatLng b) {
    final m = Geolocator.distanceBetween(a.latitude, a.longitude, b.latitude, b.longitude);
    return m / 1609.344;
  }
}
