import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../services/app_state.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/confirm_actions.dart';
import '../../shared/widgets/live_ride_map.dart';
import '../../viewmodels/chat_view_model.dart';
import '../../viewmodels/ride_view_model.dart';

/// Finding → Driver approaching → Arrived → In progress → Rate.
class PassengerTrackingScreen extends StatefulWidget {
  const PassengerTrackingScreen({super.key});

  @override
  State<PassengerTrackingScreen> createState() => _PassengerTrackingScreenState();
}

class _PassengerTrackingScreenState extends State<PassengerTrackingScreen>
    with TickerProviderStateMixin {
  double _rating = 5;
  late final AnimationController _radar;

  @override
  void initState() {
    super.initState();
    _radar = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat();
  }

  @override
  void dispose() {
    _radar.dispose();
    super.dispose();
  }

  String _statusLabel(PassengerRidePhase phase, ActiveRide? ride) {
    if (ride != null) return ride.statusLabel;
    switch (phase) {
      case PassengerRidePhase.finding:
        return 'Finding driver';
      case PassengerRidePhase.approaching:
        return 'Driver on the way';
      case PassengerRidePhase.arrived:
        return 'Driver has arrived';
      case PassengerRidePhase.inProgress:
        return 'Ride in progress';
      case PassengerRidePhase.rating:
        return 'Trip complete';
      case PassengerRidePhase.idle:
        return 'Live tracking';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final phase = state.ridePhase;
    final ride = state.activeRide;
    final finding = phase == PassengerRidePhase.finding;
    final showLiveMap = phase == PassengerRidePhase.approaching ||
        phase == PassengerRidePhase.arrived ||
        phase == PassengerRidePhase.inProgress;
    final d = state.selectedDriver;
    final top = MediaQuery.paddingOf(context).top;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // Leave tracking without cancelling — home shows live-ride banner.
        context.go('/passenger');
      },
      child: Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: Column(
        children: [
          Expanded(
            flex: finding ? 6 : 5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (ride != null && showLiveMap)
                  LiveRideMap(
                    ride: ride,
                    showDestination: phase == PassengerRidePhase.inProgress || phase == PassengerRidePhase.rating,
                  )
                else
                  _FindingMap(
                    drivers: state.nearbyDrivers,
                    driversSeen: state.driversSeen,
                    radar: _radar,
                  ),
                Positioned(
                  top: top + 8,
                  left: 12,
                  right: 12,
                  child: Row(
                    children: [
                      _GlassIcon(
                        icon: CupertinoIcons.back,
                        onTap: () => context.go('/passenger'),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.94),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            _statusLabel(phase, ride),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                        ),
                      ),
                      if (ride != null && showLiveMap) ...[
                        const SizedBox(width: 10),
                        _GlassIcon(
                          icon: CupertinoIcons.chat_bubble_2,
                          onTap: () {
                            context.read<ChatViewModel>().ensureThreadShell(
                              ride.id,
                              peerName: ride.driverName,
                            );
                            context.push('/passenger/chat/${ride.id}');
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                if (ride != null && showLiveMap)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Row(
                      children: [
                        _StatChip(label: 'Distance', value: '${ride.remainingMiles} mi'),
                        const SizedBox(width: 10),
                        _StatChip(label: 'ETA', value: '${ride.etaMinutes} min'),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: finding ? 4 : 5,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: switch (phase) {
                PassengerRidePhase.finding => _FindingSheet(state: state),
                PassengerRidePhase.approaching ||
                PassengerRidePhase.arrived ||
                PassengerRidePhase.inProgress =>
                  _LiveSheet(state: state, ride: ride, driver: d),
                PassengerRidePhase.rating => _RatingSheet(
                    rating: _rating,
                    onChanged: (v) => setState(() => _rating = v),
                    onSubmit: () async {
                      await context.read<RideViewModel>().rateActiveRide(_rating);
                      if (!context.mounted) return;
                      context.go('/passenger/trips');
                    },
                    fare: ride?.fare ?? state.fareEstimate,
                  ),
                PassengerRidePhase.idle => Center(
                    child: TextButton(
                      onPressed: () => context.go('/passenger'),
                      child: const Text('Back to book'),
                    ),
                  ),
              },
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _FindingSheet extends StatelessWidget {
  final AppState state;
  const _FindingSheet({required this.state});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Looking for a nearby driver…', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
          const SizedBox(height: 8),
          Text(
            'Scanning ${state.driversSeen} driver${state.driversSeen == 1 ? '' : 's'} in your area. You’ll be notified when a driver accepts.',
            style: const TextStyle(color: PassengerPalette.muted, height: 1.4),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () async {
                final ok = await confirmCancelRide(context);
                if (ok && context.mounted) context.go('/passenger');
              },
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Cancel request', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveSheet extends StatelessWidget {
  final AppState state;
  final ActiveRide? ride;
  final NearbyDriver? driver;

  const _LiveSheet({required this.state, required this.ride, required this.driver});

  @override
  Widget build(BuildContext context) {
    final name = ride?.driverName ?? driver?.name ?? 'Driver';
    final vehicle = ride?.vehicle ?? driver?.vehicle ?? 'Vehicle';
    final plate = ride?.plate ?? driver?.plate ?? '';
    final rating = ride?.driverRating ?? driver?.rating ?? 4.8;
    final banner = ride?.passengerBanner ?? 'Your driver is on the way.';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Text(banner, style: const TextStyle(fontWeight: FontWeight.w600, height: 1.4)),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: PassengerPalette.lime.withValues(alpha: 0.4),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'D',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 24),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
                  const SizedBox(height: 2),
                  Text(
                    '$vehicle · $plate',
                    style: const TextStyle(color: PassengerPalette.muted, fontWeight: FontWeight.w500),
                  ),
                  Row(
                    children: [
                      const Icon(CupertinoIcons.star_fill, size: 14, color: Color(0xFFC9A227)),
                      const SizedBox(width: 4),
                      Text(rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (ride != null) ...[
          _Addr(icon: CupertinoIcons.location_solid, color: PassengerPalette.limeDeep, label: ride!.pickup),
          const SizedBox(height: 8),
          _Addr(icon: CupertinoIcons.flag_fill, color: const Color(0xFFE11D48), label: ride!.destination),
          const SizedBox(height: 12),
          Text(
            '£${ride!.fare.toStringAsFixed(2)} estimated fare',
            style: const TextStyle(fontWeight: FontWeight.w700, color: PassengerPalette.muted),
          ),
        ],
        if (state.ridePhase == PassengerRidePhase.finding || state.ridePhase == PassengerRidePhase.approaching) ...[
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () async {
              final ok = await confirmCancelRide(context);
              if (ok && context.mounted) context.go('/passenger');
            },
            child: const Text('Cancel ride'),
          ),
        ],
      ],
    );
  }
}

class _RatingSheet extends StatelessWidget {
  final double rating;
  final ValueChanged<double> onChanged;
  final VoidCallback onSubmit;
  final double fare;

  const _RatingSheet({
    required this.rating,
    required this.onChanged,
    required this.onSubmit,
    required this.fare,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('How was your ride?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
          const SizedBox(height: 6),
          Text('Fare £${fare.toStringAsFixed(2)}', style: const TextStyle(color: PassengerPalette.muted)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final star = i + 1;
              return IconButton(
                onPressed: () => onChanged(star.toDouble()),
                icon: Icon(
                  star <= rating ? CupertinoIcons.star_fill : CupertinoIcons.star,
                  color: const Color(0xFFC9A227),
                  size: 36,
                ),
              );
            }),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              onPressed: onSubmit,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC9A227),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Submit & view history', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Addr extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  const _Addr({required this.icon, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: PassengerPalette.muted, fontWeight: FontWeight.w600)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
      ),
    );
  }
}

class _GlassIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.94),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 44, height: 44, child: Icon(icon, size: 20)),
      ),
    );
  }
}

class _FindingMap extends StatelessWidget {
  final List<NearbyDriver> drivers;
  final int driversSeen;
  final AnimationController radar;

  const _FindingMap({
    required this.drivers,
    required this.driversSeen,
    required this.radar,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE4EDF5), Color(0xFFD0DCE8), Color(0xFFC5D4E2)],
        ),
      ),
      child: AnimatedBuilder(
        animation: radar,
        builder: (context, _) {
          return CustomPaint(
            painter: _RadarPainter(
              progress: radar.value,
              offsets: drivers.take(driversSeen.clamp(0, drivers.length)).map((d) => d.mapOffset).toList(),
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final double progress;
  final List<Offset> offsets;

  _RadarPainter({required this.progress, required this.offsets});

  @override
  void paint(Canvas canvas, Size size) {
    if (!size.isFinite || size.isEmpty) return;
    final center = Offset(size.width * 0.5, size.height * 0.55);
    for (var i = 1; i <= 3; i++) {
      final r = 40.0 * i + progress * 50;
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..color = const Color(0xFFC9A227).withValues(alpha: (0.35 - progress * 0.2).clamp(0.05, 0.35))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    canvas.drawCircle(center, 10, Paint()..color = PassengerPalette.limeDeep);
    for (final o in offsets) {
      final p = Offset(size.width * o.dx, size.height * o.dy);
      canvas.drawCircle(p, 7, Paint()..color = const Color(0xFF111827));
      canvas.drawCircle(p, 3, Paint()..color = const Color(0xFFC9A227));
    }
    final sweep = progress * math.pi * 2;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 90),
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..color = const Color(0xFFC9A227).withValues(alpha: 0.25)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) => old.progress != progress || old.offsets.length != offsets.length;
}
