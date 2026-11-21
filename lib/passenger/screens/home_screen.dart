import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../services/app_state.dart';
import '../../services/mock_repository.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/map_placeholder.dart';
import 'location_picker_screen.dart';

/// Passenger Book — Book Now / Later, route map, vehicles, fare (live FNT flow).
class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen> {
  bool _showStop = false;
  static const _gold = Color(0xFFC9A227);

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  String _fmtSchedule(DateTime d) {
    final wd = _weekdays[d.weekday - 1];
    final mo = _months[d.month - 1];
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$wd ${d.day} $mo, $hh:$mm';
  }

  Future<void> _openScheduleSheet(AppState state) async {
    state.setBookMode(BookMode.later);
    final initial = state.scheduledAt ?? DateTime.now().add(const Duration(hours: 2));
    var date = DateTime(initial.year, initial.month, initial.day);
    var time = TimeOfDay(hour: initial.hour, minute: initial.minute);

    final result = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            final bottom = MediaQuery.paddingOf(ctx).bottom;
            return Container(
              margin: const EdgeInsets.only(top: 48),
              padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottom),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Schedule Your Ride',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Payment is due when your ride is complete.',
                    style: TextStyle(color: PassengerPalette.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 18),
                  const Text('Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: PassengerPalette.muted)),
                  const SizedBox(height: 8),
                  Material(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 60)),
                          initialDate: date,
                        );
                        if (picked != null) setModal(() => date = picked);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                        child: Row(
                          children: [
                            const Icon(CupertinoIcons.calendar, color: _gold, size: 18),
                            const SizedBox(width: 10),
                            Text(
                              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                            const Spacer(),
                            const Icon(CupertinoIcons.chevron_right, size: 14, color: PassengerPalette.muted),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Time (24hr)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: PassengerPalette.muted)),
                  const SizedBox(height: 8),
                  Material(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () async {
                        final picked = await showTimePicker(context: ctx, initialTime: time);
                        if (picked != null) setModal(() => time = picked);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                        child: Row(
                          children: [
                            const Icon(CupertinoIcons.clock, color: _gold, size: 18),
                            const SizedBox(width: 10),
                            Text(
                              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                            const Spacer(),
                            const Icon(CupertinoIcons.chevron_right, size: 14, color: PassengerPalette.muted),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
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
                            'Reminders will be sent 1 hour and 15 minutes before your ride to both you and the driver.',
                            style: TextStyle(fontSize: 12, height: 1.35, color: Color(0xFF1E3A5F), fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: PassengerPalette.ink,
                              side: const BorderSide(color: Color(0xFFE5E7EB)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: FilledButton(
                            onPressed: () {
                              Navigator.pop(
                                ctx,
                                DateTime(date.year, date.month, date.day, time.hour, time.minute),
                              );
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: _gold,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('Set Schedule', style: TextStyle(fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result != null && mounted) {
      state.setScheduledAt(result);
    }
  }

  Future<void> _openPlace(LocationPickKind kind) async {
    final state = context.read<AppState>();
    final initial = switch (kind) {
      LocationPickKind.pickup => state.pickup,
      LocationPickKind.dropoff => state.destination,
      LocationPickKind.stop => state.stop,
    };
    final result = await LocationPickerScreen.open(
      context,
      kind: kind,
      initial: (initial == null || initial.isEmpty) ? null : initial,
    );
    if (result == null || !mounted) return;
    switch (kind) {
      case LocationPickKind.pickup:
        state.setPickup(result);
      case LocationPickKind.dropoff:
        state.setDestination(result);
      case LocationPickKind.stop:
        state.setStop(result);
        setState(() => _showStop = true);
    }
  }

  void _confirm(AppState state) {
    final err = state.confirmBooking();
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    if (state.bookMode == BookMode.later) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ride scheduled — see Scheduled tab')),
      );
      context.go('/passenger/scheduled');
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Finding a nearby driver…')),
    );
    context.go('/passenger/tracking');
  }

  IconData _vehicleIcon(VehicleCategory v) {
    switch (v) {
      case VehicleCategory.fourSeater:
        return CupertinoIcons.car_detailed;
      case VehicleCategory.sixSeater:
        return CupertinoIcons.car_fill;
      case VehicleCategory.eightSeater:
        return Icons.airport_shuttle_rounded;
      case VehicleCategory.wheelchair:
        return Icons.accessible_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final name = state.user?.name ?? 'Guest';
    final topPad = MediaQuery.paddingOf(context).top;
    final hasRoute = state.hasBookingRoute;

    return ColoredBox(
      color: const Color(0xFFF2F4F7),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.sizeOf(context).height * 0.42,
            child: _BookMap(hasRoute: hasRoute, drivers: state.nearbyDrivers.length),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(12, topPad + 6, 12, 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.96),
                    Colors.white.withValues(alpha: 0.65),
                    Colors.white.withValues(alpha: 0),
                  ],
                ),
              ),
              child: Row(
                children: [
                  _GlassBtn(
                    icon: CupertinoIcons.line_horizontal_3,
                    onTap: () => Scaffold.of(context).openDrawer(),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(CupertinoIcons.car_detailed, color: _gold, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Fife Nearby Taxis',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: -0.2),
                            ),
                          ],
                        ),
                        Text(
                          'Welcome, $name',
                          style: const TextStyle(fontSize: 12, color: PassengerPalette.muted, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  _GlassBtn(
                    icon: CupertinoIcons.bell,
                    badge: state.passengerAlerts.isNotEmpty ? state.passengerAlerts.length : null,
                    onTap: () => context.go('/passenger/alerts'),
                  ),
                  const SizedBox(width: 8),
                  _SosChip(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('SOS sent to dispatch')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            top: MediaQuery.sizeOf(context).height * 0.34,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 28,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hello, $name',
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Where are you going?',
                                    style: TextStyle(color: PassengerPalette.muted, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5E6B8),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Standard (Mon–Fri)',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _Seg(
                                  label: 'Book Now',
                                  icon: CupertinoIcons.car_detailed,
                                  active: state.bookMode == BookMode.now,
                                  onTap: () => state.setBookMode(BookMode.now),
                                ),
                              ),
                              Expanded(
                                child: _Seg(
                                  label: 'Book Later',
                                  icon: CupertinoIcons.clock,
                                  active: state.bookMode == BookMode.later,
                                  onTap: () => _openScheduleSheet(state),
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (state.bookMode == BookMode.later) ...[
                          const SizedBox(height: 10),
                          Material(
                            color: const Color(0xFFF7F8FA),
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              onTap: () => _openScheduleSheet(state),
                              borderRadius: BorderRadius.circular(14),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                child: Row(
                                  children: [
                                    const Icon(CupertinoIcons.calendar, color: _gold, size: 18),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        state.scheduledAt == null
                                            ? 'Select date & time'
                                            : _fmtSchedule(state.scheduledAt!),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: state.scheduledAt == null
                                              ? PassengerPalette.muted
                                              : PassengerPalette.ink,
                                        ),
                                      ),
                                    ),
                                    const Icon(CupertinoIcons.chevron_right, size: 14, color: PassengerPalette.muted),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 14),

                        // Locations — soft fill, no hard border
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F8FA),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            children: [
                              _LocTap(
                                dot: PassengerPalette.limeDeep,
                                icon: CupertinoIcons.location_circle,
                                label: state.pickup.isEmpty ? 'Set pickup location' : state.pickup,
                                empty: state.pickup.isEmpty,
                                onTap: () => _openPlace(LocationPickKind.pickup),
                              ),
                              const Padding(
                                padding: EdgeInsets.only(left: 28),
                                child: Divider(height: 1, color: Color(0xFFE8EAED)),
                              ),
                              _LocTap(
                                dot: const Color(0xFFE11D48),
                                icon: CupertinoIcons.placemark,
                                label: state.destination.isEmpty ? 'Tap to set destination' : state.destination,
                                empty: state.destination.isEmpty,
                                onTap: () => _openPlace(LocationPickKind.dropoff),
                              ),
                              if (_showStop || (state.stop != null && state.stop!.isNotEmpty)) ...[
                                const Padding(
                                  padding: EdgeInsets.only(left: 28),
                                  child: Divider(height: 1, color: Color(0xFFE8EAED)),
                                ),
                                _LocTap(
                                  dot: _gold,
                                  icon: CupertinoIcons.plus_circle,
                                  label: (state.stop == null || state.stop!.isEmpty) ? 'Add a stop' : state.stop!,
                                  empty: state.stop == null || state.stop!.isEmpty,
                                  onTap: () => _openPlace(LocationPickKind.stop),
                                ),
                              ],
                              Padding(
                                padding: const EdgeInsets.fromLTRB(10, 2, 10, 10),
                                child: Row(
                                  children: [
                                    if (!_showStop && (state.stop == null || state.stop!.isEmpty))
                                      TextButton.icon(
                                        onPressed: () {
                                          setState(() => _showStop = true);
                                          _openPlace(LocationPickKind.stop);
                                        },
                                        icon: const Icon(CupertinoIcons.plus, size: 14),
                                        label: const Text('Add a stop'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: PassengerPalette.ink,
                                          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                                        ),
                                      ),
                                    const Spacer(),
                                    TextButton.icon(
                                      onPressed: state.useCurrentLocation,
                                      icon: const Icon(CupertinoIcons.location_fill, size: 14, color: PassengerPalette.limeDeep),
                                      label: const Text('Use GPS'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: PassengerPalette.limeDeep,
                                        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),
                        const Text('Vehicle Type', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 10),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 1.55,
                          children: VehicleCategory.values.map((v) {
                            final selected = state.vehicleCategory == v;
                            return Material(
                              color: selected ? _gold.withValues(alpha: 0.18) : const Color(0xFFF7F8FA),
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                onTap: () => state.setVehicleCategory(v),
                                borderRadius: BorderRadius.circular(16),
                                child: Stack(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(_vehicleIcon(v), color: selected ? Colors.black : PassengerPalette.muted, size: 22),
                                          const Spacer(),
                                          Text(
                                            MockRepository.vehicleLabel(v),
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 12,
                                              color: selected ? Colors.black : PassengerPalette.ink,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (selected)
                                      const Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Icon(CupertinoIcons.checkmark_circle_fill, size: 18, color: _gold),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        if (hasRoute) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1D26),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Estimated Fare',
                                  style: TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600, fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  state.fareEstimateLabel,
                                  style: const TextStyle(
                                    color: _gold,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Standard (Mon–Fri) · ${state.fareMilesLabel} · ${state.fareMinsLabel}',
                                  style: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Pay cash to the driver at the end of the ride.',
                                  style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 18),
                        if (state.rideBooked && state.bookMode == BookMode.now)
                          Material(
                            color: _gold.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(16),
                            child: ListTile(
                              leading: const Icon(CupertinoIcons.location_north_line_fill, color: _gold),
                              title: Text(
                                state.activeRide?.statusLabel ??
                                    (state.isFindingDriver ? 'Looking for a driver' : 'Live tracking'),
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                              subtitle: Text('${state.pickup} → ${state.destination}', maxLines: 1, overflow: TextOverflow.ellipsis),
                              trailing: const Icon(CupertinoIcons.chevron_right),
                              onTap: () => context.go('/passenger/tracking'),
                            ),
                          )
                        else
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: FilledButton(
                              onPressed: () => _confirm(state),
                              style: FilledButton.styleFrom(
                                backgroundColor: _gold,
                                foregroundColor: Colors.black,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                              ),
                              child: Text(state.bookMode == BookMode.later ? 'Schedule ride' : 'Confirm booking'),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookMap extends StatelessWidget {
  final bool hasRoute;
  final int drivers;

  const _BookMap({required this.hasRoute, required this.drivers});

  @override
  Widget build(BuildContext context) {
    return MapPlaceholder(
      borderRadius: BorderRadius.zero,
      showPreviewChip: true,
      areaLabel: 'Scotland',
      nearbyLabel: hasRoute ? 'Route ready' : '$drivers drivers nearby',
      // null center → fetch device GPS and center the map there.
      zoom: 14.2,
      interactive: true,
      followUser: true,
    );
  }
}

class _GlassBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int? badge;

  const _GlassBtn({required this.icon, required this.onTap, this.badge});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      elevation: 1.5,
      shadowColor: Colors.black26,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, size: 18, color: PassengerPalette.ink),
              if (badge != null && badge! > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: Color(0xFFE11D48), shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SosChip extends StatelessWidget {
  final VoidCallback onTap;
  const _SosChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppPalette.danger,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text('SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
        ),
      ),
    );
  }
}

class _Seg extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _Seg({required this.label, required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFC9A227) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 15, color: active ? Colors.black : PassengerPalette.muted),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: active ? Colors.black : PassengerPalette.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LocTap extends StatelessWidget {
  final Color dot;
  final IconData icon;
  final String label;
  final bool empty;
  final VoidCallback onTap;

  const _LocTap({
    required this.dot,
    required this.icon,
    required this.label,
    required this.empty,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
            const SizedBox(width: 12),
            Icon(icon, size: 18, color: PassengerPalette.muted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: empty ? FontWeight.w500 : FontWeight.w700,
                  fontSize: 14,
                  color: empty ? PassengerPalette.muted : PassengerPalette.ink,
                ),
              ),
            ),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(CupertinoIcons.map, size: 16, color: PassengerPalette.muted),
            ),
          ],
        ),
      ),
    );
  }
}
