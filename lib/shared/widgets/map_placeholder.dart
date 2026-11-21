import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/app_colors.dart';
import '../../core/maps_config.dart';
import '../../services/location_service.dart';

/// Real Google Map preview — centers on device GPS when [center] is null.
class MapPlaceholder extends StatefulWidget {
  final Widget? overlay;
  final List<Widget> pins;
  final BorderRadius? borderRadius;
  final bool showPreviewChip;
  final String areaLabel;
  final String? nearbyLabel;
  final LatLng? center;
  final double zoom;
  final Set<Marker>? markers;
  final bool interactive;
  final bool followUser;
  final ValueChanged<LatLng>? onTap;

  const MapPlaceholder({
    super.key,
    this.overlay,
    this.pins = const [],
    this.borderRadius,
    this.showPreviewChip = true,
    this.areaLabel = 'Scotland',
    this.nearbyLabel,
    this.center,
    this.zoom = MapsConfig.defaultZoom,
    this.markers,
    this.interactive = false,
    this.followUser = true,
    this.onTap,
  });

  @override
  State<MapPlaceholder> createState() => _MapPlaceholderState();
}

class _MapPlaceholderState extends State<MapPlaceholder> {
  GoogleMapController? _controller;
  LatLng _center = MapsConfig.fifeCenter;
  bool _ready = false;
  bool _hasGps = false;
  String _label = 'Scotland';

  @override
  void initState() {
    super.initState();
    _center = widget.center ?? MapsConfig.fifeCenter;
    _label = widget.areaLabel;
    _bootstrap();
  }

  @override
  void didUpdateWidget(covariant MapPlaceholder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.center != null && widget.center != oldWidget.center) {
      _center = widget.center!;
      _controller?.animateCamera(CameraUpdate.newLatLngZoom(_center, widget.zoom));
    }
    if (widget.areaLabel != oldWidget.areaLabel && !_hasGps) {
      _label = widget.areaLabel;
    }
  }

  Future<void> _bootstrap() async {
    if (widget.center != null) {
      if (mounted) setState(() => _ready = true);
      // Still request permission so the blue "my location" dot works.
      await LocationService.ensurePermission();
      return;
    }

    final here = await LocationService.currentLatLng();
    if (!mounted) return;
    setState(() {
      if (here != null) {
        _center = here;
        _hasGps = true;
        _label = 'Current location';
      }
      _ready = true;
    });
    if (here != null && widget.followUser) {
      await _controller?.animateCamera(
        CameraUpdate.newLatLngZoom(here, widget.zoom),
      );
    }
  }

  Future<void> _goToMe() async {
    final here = await LocationService.currentLatLng();
    if (!mounted || here == null) return;
    setState(() {
      _center = here;
      _hasGps = true;
      _label = 'Current location';
    });
    await _controller?.animateCamera(
      CameraUpdate.newLatLngZoom(here, widget.zoom),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(20);
    return ClipRRect(
      borderRadius: radius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (!_ready)
            const ColoredBox(
              color: Color(0xFFE4EDF5),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            GoogleMap(
              initialCameraPosition: CameraPosition(target: _center, zoom: widget.zoom),
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              compassEnabled: false,
              mapToolbarEnabled: false,
              zoomControlsEnabled: false,
              markers: widget.markers ?? {},
              scrollGesturesEnabled: widget.interactive,
              zoomGesturesEnabled: widget.interactive,
              tiltGesturesEnabled: false,
              rotateGesturesEnabled: false,
              onTap: widget.onTap,
              onMapCreated: (c) async {
                _controller = c;
                if (_hasGps && widget.followUser) {
                  await c.animateCamera(
                    CameraUpdate.newLatLngZoom(_center, widget.zoom),
                  );
                }
              },
            ),
          ...widget.pins,
          if (widget.showPreviewChip)
            const Positioned(
              top: 12,
              right: 12,
              child: _GlassChip(label: 'Live map'),
            ),
          Positioned(
            top: widget.showPreviewChip ? 52 : 12,
            right: 12,
            child: Material(
              color: Colors.white.withValues(alpha: 0.95),
              shape: const CircleBorder(),
              elevation: 2,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _goToMe,
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(CupertinoIcons.location_fill, size: 18, color: Color(0xFFC9A227)),
                ),
              ),
            ),
          ),
          if (widget.nearbyLabel != null)
            Positioned(
              left: 12,
              bottom: 12,
              child: _NearbyBadge(label: widget.nearbyLabel!),
            ),
          Positioned(
            left: 12,
            bottom: widget.nearbyLabel != null ? 48 : 12,
            child: _GlassChip(label: _label),
          ),
          if (widget.overlay != null)
            Positioned(left: 12, right: 12, bottom: 12, child: widget.overlay!),
        ],
      ),
    );
  }
}

class _GlassChip extends StatelessWidget {
  final String label;
  const _GlassChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8)],
      ),
      child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

class _NearbyBadge extends StatelessWidget {
  final String label;
  const _NearbyBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: PassengerPalette.limeDeep,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(CupertinoIcons.car_detailed, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }
}
