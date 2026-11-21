import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/app_colors.dart';
import '../../core/maps_config.dart';
import '../../services/location_service.dart';
import '../../services/mock_repository.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/map_placeholder.dart';

enum LocationPickKind { pickup, dropoff, stop }

enum _SearchMode { address, postcode, map }

/// Full-screen location picker — Address / Postcode / Map (mock), no focus border.
class LocationPickerScreen extends StatefulWidget {
  final LocationPickKind kind;
  final String? initial;

  const LocationPickerScreen({
    super.key,
    required this.kind,
    this.initial,
  });

  static Future<String?> open(
    BuildContext context, {
    required LocationPickKind kind,
    String? initial,
  }) {
    return Navigator.of(context, rootNavigator: true).push<String>(
      PageRouteBuilder(
        opaque: true,
        barrierDismissible: false,
        pageBuilder: (context, animation, secondaryAnimation) =>
            LocationPickerScreen(kind: kind, initial: initial),
        transitionsBuilder: (context, anim, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late final TextEditingController _search;
  late final FocusNode _focus;
  _SearchMode _mode = _SearchMode.address;
  List<PlaceSuggestion> _results = const [];
  PlaceSuggestion? _selected;
  LatLng _mapPin = MapsConfig.fifeCenter;
  String? _mapLabel;

  static const _gold = Color(0xFFC9A227);

  String get _header {
    switch (widget.kind) {
      case LocationPickKind.pickup:
        return 'Set Pickup Location';
      case LocationPickKind.dropoff:
        return 'Set Destination';
      case LocationPickKind.stop:
        return 'Add a Stop';
    }
  }

  Color get _accent {
    switch (widget.kind) {
      case LocationPickKind.pickup:
        return PassengerPalette.limeDeep;
      case LocationPickKind.dropoff:
        return const Color(0xFFE11D48);
      case LocationPickKind.stop:
        return _gold;
    }
  }

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: widget.initial ?? '');
    _focus = FocusNode();
    if (_search.text.trim().length >= 3) {
      _results = MockRepository.searchPlaces(_search.text);
    }
    if (widget.initial != null && widget.initial!.isNotEmpty) {
      _mapLabel = widget.initial;
      for (final p in MockRepository.places) {
        if (widget.initial!.contains(p.title) || p.fullAddress == widget.initial) {
          _selected = p;
          _mapPin = LatLng(
            MapsConfig.fifeCenter.latitude + (0.5 - p.mapOffset.dy) * 0.06,
            MapsConfig.fifeCenter.longitude + (p.mapOffset.dx - 0.5) * 0.08,
          );
          break;
        }
      }
    } else {
      // Center pin on real GPS when opening the map picker.
      // ignore: unawaited_futures
      _seedFromGps();
    }
  }

  Future<void> _seedFromGps() async {
    final here = await LocationService.currentLatLng();
    if (!mounted || here == null) return;
    setState(() {
      _mapPin = here;
      _mapLabel =
          'Current location · ${here.latitude.toStringAsFixed(5)}, ${here.longitude.toStringAsFixed(5)}';
    });
  }

  @override
  void dispose() {
    _search.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _runSearch(String q) {
    setState(() {
      _results = MockRepository.searchPlaces(
        q,
        postcodeOnly: _mode == _SearchMode.postcode,
      );
      if (_selected != null && !_results.any((r) => r.title == _selected!.title)) {
        _selected = null;
      }
    });
  }

  void _select(PlaceSuggestion p) {
    HapticFeedback.selectionClick();
    setState(() {
      _selected = p;
      _mapPin = LatLng(
        MapsConfig.fifeCenter.latitude + (0.5 - p.mapOffset.dy) * 0.06,
        MapsConfig.fifeCenter.longitude + (p.mapOffset.dx - 0.5) * 0.08,
      );
      _mapLabel = p.fullAddress;
      _search.text = _mode == _SearchMode.postcode ? p.postcode : p.fullAddress;
      _search.selection = TextSelection.collapsed(offset: _search.text.length);
    });
    _focus.unfocus();
  }

  void _pickRecent(PlaceSuggestion p) {
    _select(p);
    setState(() {
      _results = [p];
    });
  }

  void _confirm() {
    final value = _selected?.fullAddress ??
        _mapLabel ??
        (_search.text.trim().length >= 3 ? _search.text.trim() : null);
    if (value == null || value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a matching result or place the pin on the map')),
      );
      return;
    }
    Navigator.of(context).pop(value);
  }

  Future<void> _useGps() async {
    setState(() => _mode = _SearchMode.map);
    final here = await LocationService.currentLatLng();
    if (!mounted) return;
    if (here == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission needed for GPS')),
      );
      return;
    }
    setState(() {
      _mapPin = here;
      _selected = null;
      _mapLabel =
          'Current location · ${here.latitude.toStringAsFixed(5)}, ${here.longitude.toStringAsFixed(5)}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final canConfirm = _selected != null ||
        (_mapLabel != null && _mapLabel!.isNotEmpty) ||
        (_mode == _SearchMode.map && _mapLabel != null);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Text(
                        _header,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(CupertinoIcons.xmark, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Address / Postcode / Map
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _ModeTab(
                        label: 'Address',
                        icon: CupertinoIcons.pencil,
                        active: _mode == _SearchMode.address,
                        onTap: () => setState(() {
                          _mode = _SearchMode.address;
                          _runSearch(_search.text);
                        }),
                      ),
                    ),
                    Expanded(
                      child: _ModeTab(
                        label: 'Postcode',
                        icon: CupertinoIcons.number,
                        active: _mode == _SearchMode.postcode,
                        onTap: () => setState(() {
                          _mode = _SearchMode.postcode;
                          _runSearch(_search.text);
                        }),
                      ),
                    ),
                    Expanded(
                      child: _ModeTab(
                        label: 'Map',
                        icon: CupertinoIcons.map,
                        active: _mode == _SearchMode.map,
                        onTap: () => setState(() => _mode = _SearchMode.map),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Recent chips
            SizedBox(
              height: 40,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: MockRepository.recentPlaces.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final p = MockRepository.recentPlaces[i];
                  final selected = _selected?.title == p.title;
                  return Material(
                    color: selected ? _gold.withValues(alpha: 0.22) : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      onTap: () => _pickRecent(p),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.placemark_fill, size: 14, color: _gold),
                            const SizedBox(width: 6),
                            Text(
                              p.recentChip,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            Expanded(
              child: _mode == _SearchMode.map
                  ? _buildMap()
                  : _buildSearchBody(),
            ),

            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + bottom),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: canConfirm ? _confirm : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: _gold,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: const Color(0xFFE5E7EB),
                    disabledForegroundColor: PassengerPalette.muted,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  child: const Text('Confirm Location'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBody() {
    final hint = _mode == _SearchMode.postcode
        ? 'Postcode (e.g. KY7 5NA)'
        : 'Place, address or postcode (3+ characters)';
    final label = _mode == _SearchMode.postcode
        ? 'Search by postcode'
        : 'Search by place, address or postcode';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: PassengerPalette.muted),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                Icon(
                  _mode == _SearchMode.postcode ? CupertinoIcons.number_square : CupertinoIcons.search,
                  size: 18,
                  color: PassengerPalette.muted,
                ),
                Expanded(
                  child: CupertinoTextField(
                    controller: _search,
                    focusNode: _focus,
                    autofocus: true,
                    onChanged: _runSearch,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: PassengerPalette.ink,
                    ),
                    placeholder: hint,
                    placeholderStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                      color: Color(0xFF9CA3AF),
                    ),
                    cursorColor: _gold,
                    decoration: const BoxDecoration(),
                  ),
                ),
                if (_search.text.isNotEmpty)
                  IconButton(
                    onPressed: () {
                      _search.clear();
                      _runSearch('');
                      setState(() {
                        _selected = null;
                        _mapLabel = null;
                      });
                    },
                    icon: const Icon(CupertinoIcons.clear_circled_solid, size: 18, color: Color(0xFF9CA3AF)),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(CupertinoIcons.info_circle_fill, size: 18, color: Color(0xFF2563EB)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Type at least 3 characters, then choose a matching result to fill its location.',
                    style: TextStyle(fontSize: 12, height: 1.35, color: Color(0xFF1E3A5F), fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.kind == LocationPickKind.pickup) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Material(
              color: PassengerPalette.limeDeep.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: _useGps,
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.location_fill, color: PassengerPalette.limeDeep, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Use current GPS location',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                      Icon(CupertinoIcons.chevron_right, size: 14, color: PassengerPalette.muted),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Expanded(
          child: _search.text.trim().length < 3
              ? const Center(
                  child: Text(
                    'Start typing to search…',
                    style: TextStyle(color: PassengerPalette.muted, fontWeight: FontWeight.w600),
                  ),
                )
              : _results.isEmpty
                  ? const Center(
                      child: Text(
                        'No matches — try another address or postcode',
                        style: TextStyle(color: PassengerPalette.muted, fontWeight: FontWeight.w600),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                      itemCount: _results.length,
                      separatorBuilder: (_, _) => const Divider(height: 1, indent: 64),
                      itemBuilder: (context, i) {
                        final p = _results[i];
                        final selected = _selected?.title == p.title;
                        return ListTile(
                          onTap: () => _select(p),
                          selected: selected,
                          selectedTileColor: _gold.withValues(alpha: 0.12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          leading: CircleAvatar(
                            backgroundColor: _accent.withValues(alpha: 0.12),
                            child: Icon(CupertinoIcons.placemark_fill, color: _accent, size: 18),
                          ),
                          title: Text(p.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(
                            '${p.subtitle}${p.postcode.isNotEmpty ? ' · ${p.postcode}' : ''}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: selected
                              ? Icon(CupertinoIcons.checkmark_circle_fill, color: _accent)
                              : null,
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildMap() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            MapPlaceholder(
              borderRadius: BorderRadius.zero,
              showPreviewChip: false,
              areaLabel: 'Tap map to set pin',
              center: _mapPin,
              zoom: 14.2,
              interactive: true,
              followUser: false,
              markers: {
                Marker(
                  markerId: const MarkerId('pick'),
                  position: _mapPin,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                ),
              },
              onTap: (latLng) {
                setState(() {
                  _mapPin = latLng;
                  _selected = null;
                  _mapLabel =
                      'Pinned · ${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)}';
                });
              },
            ),
            if (_mapLabel != null)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12),
                    ],
                  ),
                  child: Text(
                    _mapLabel!,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? const Color(0xFFC9A227) : Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: active ? Colors.black : PassengerPalette.muted),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: active ? Colors.black : PassengerPalette.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
