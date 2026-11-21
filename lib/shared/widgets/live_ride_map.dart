import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/app_colors.dart';
import '../../services/directions_service.dart';
import '../models/models.dart';

/// Real Google Map for an [ActiveRide] — pickup / drop pins + live driver + route.
class LiveRideMap extends StatefulWidget {
  final ActiveRide ride;
  final bool showDestination;

  const LiveRideMap({
    super.key,
    required this.ride,
    this.showDestination = true,
  });

  @override
  State<LiveRideMap> createState() => _LiveRideMapState();
}

class _LiveRideMapState extends State<LiveRideMap> {
  GoogleMapController? _controller;
  List<LatLng> _route = const [];
  String? _routeKey;

  LatLng get _pickup => LatLng(widget.ride.pickupLat, widget.ride.pickupLng);
  LatLng get _drop => LatLng(widget.ride.dropLat, widget.ride.dropLng);

  LatLng get _driver {
    final r = widget.ride;
    if (r.driverLat != null && r.driverLng != null) {
      return LatLng(r.driverLat!, r.driverLng!);
    }
    // Fallback along leg until GPS arrives.
    final end = r.isToDropoff ? _drop : _pickup;
    final start = r.isToDropoff ? _pickup : LatLng(_pickup.latitude - 0.02, _pickup.longitude - 0.015);
    return LatLng(
      start.latitude + (end.latitude - start.latitude) * r.progress,
      start.longitude + (end.longitude - start.longitude) * r.progress,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  @override
  void didUpdateWidget(covariant LiveRideMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final stageChanged = oldWidget.ride.stage != widget.ride.stage;
    if (stageChanged) _loadRoute();
    _followDriver();
  }

  Future<void> _loadRoute() async {
    final toDrop = widget.ride.stage == LiveRideStage.inProgress ||
        widget.ride.stage == LiveRideStage.completed;
    final origin = toDrop ? _pickup : _driver;
    final dest = toDrop ? _drop : _pickup;
    final key = '${widget.ride.stage.name}:${origin.latitude.toStringAsFixed(4)}:${dest.latitude.toStringAsFixed(4)}';
    if (key == _routeKey && _route.isNotEmpty) return;
    _routeKey = key;
    final points = await DirectionsService.route(origin, dest);
    if (!mounted) return;
    setState(() => _route = points);
    _fitBounds();
  }

  Future<void> _followDriver() async {
    final c = _controller;
    if (c == null) return;
    await c.animateCamera(CameraUpdate.newLatLng(_driver));
  }

  Future<void> _fitBounds() async {
    final c = _controller;
    if (c == null) return;
    final pts = <LatLng>[_driver, _pickup];
    if (widget.showDestination || widget.ride.isToDropoff) pts.add(_drop);
    if (_route.isNotEmpty) pts.addAll(_route);
    double minLat = pts.first.latitude, maxLat = pts.first.latitude;
    double minLng = pts.first.longitude, maxLng = pts.first.longitude;
    for (final p in pts) {
      minLat = minLat < p.latitude ? minLat : p.latitude;
      maxLat = maxLat > p.latitude ? maxLat : p.latitude;
      minLng = minLng < p.longitude ? minLng : p.longitude;
      maxLng = maxLng > p.longitude ? maxLng : p.longitude;
    }
    await c.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat - 0.004, minLng - 0.004),
          northeast: LatLng(maxLat + 0.004, maxLng + 0.004),
        ),
        56,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final toDrop = widget.ride.stage == LiveRideStage.inProgress ||
        widget.ride.stage == LiveRideStage.completed;
    final showDrop = widget.showDestination || toDrop;

    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('pickup'),
        position: _pickup,
        infoWindow: InfoWindow(title: 'Pickup', snippet: widget.ride.pickup),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      Marker(
        markerId: const MarkerId('driver'),
        position: _driver,
        infoWindow: InfoWindow(title: widget.ride.driverName, snippet: widget.ride.vehicle),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        rotation: 0,
      ),
      if (showDrop)
        Marker(
          markerId: const MarkerId('drop'),
          position: _drop,
          infoWindow: InfoWindow(title: 'Destination', snippet: widget.ride.destination),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
    };

    final polylines = <Polyline>{
      if (_route.length >= 2)
        Polyline(
          polylineId: const PolylineId('route'),
          points: _route,
          color: const Color(0xFFC9A227),
          width: 5,
        ),
    };

    return Stack(
      fit: StackFit.expand,
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: _driver, zoom: 14),
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          compassEnabled: false,
          mapToolbarEnabled: false,
          zoomControlsEnabled: false,
          markers: markers,
          polylines: polylines,
          onMapCreated: (c) {
            _controller = c;
            _fitBounds();
            _loadRoute();
          },
        ),
        Positioned(
          left: 12,
          bottom: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              toDrop ? 'To destination' : (widget.ride.stage == LiveRideStage.arrivedPickup ? 'At pickup' : 'To pickup'),
              style: const TextStyle(
                color: PassengerPalette.muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
