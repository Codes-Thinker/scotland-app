import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../services/app_state.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/live_ride_map.dart';
import '../../viewmodels/chat_view_model.dart';
import '../../viewmodels/ride_view_model.dart';

/// Driver post-accept lifecycle: on the way → arrived → start → navigate → complete.
class DriverTrackingScreen extends StatelessWidget {
  const DriverTrackingScreen({super.key});

  static const _gold = Color(0xFFC9A227);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final ride = state.activeRide;
    final top = MediaQuery.paddingOf(context).top;

    if (ride == null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('No active ride', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => context.go('/driver'),
                  child: const Text('Back to Jobs'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final toPickup = ride.stage == LiveRideStage.assigned;
    final arrived = ride.stage == LiveRideStage.arrivedPickup;
    final inProgress = ride.stage == LiveRideStage.inProgress;
    final done = ride.stage == LiveRideStage.completed;
    final nearPickup = toPickup && ride.progress >= 0.75;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.go('/driver');
      },
      child: Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                LiveRideMap(ride: ride, showDestination: inProgress || done),
                Positioned(
                  top: top + 8,
                  left: 12,
                  right: 12,
                  child: Row(
                    children: [
                      _GlassIcon(
                        icon: CupertinoIcons.back,
                        onTap: () => context.go('/driver'),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.94),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: Text(
                            ride.statusLabel,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _GlassIcon(
                        icon: CupertinoIcons.chat_bubble_2,
                        onTap: () {
                          context.read<ChatViewModel>().ensureThreadShell(
                            ride.id,
                            peerName: ride.passengerName,
                          );
                          context.push('/driver/chat/${ride.id}');
                        },
                      ),
                    ],
                  ),
                ),
                if (!done)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Row(
                      children: [
                        _StatChip(
                          label: 'Distance',
                          value: '${ride.remainingMiles} mi',
                        ),
                        const SizedBox(width: 10),
                        _StatChip(
                          label: 'ETA',
                          value: '${ride.etaMinutes} min',
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: PassengerPalette.lime.withValues(alpha: 0.4),
                        child: Text(
                          ride.passengerName.isNotEmpty ? ride.passengerName[0].toUpperCase() : 'P',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ride.passengerName,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              arrived
                                  ? 'Waiting at pickup'
                                  : inProgress
                                      ? 'Passenger on board'
                                      : done
                                          ? 'Trip completed'
                                          : 'Heading to passenger',
                              style: const TextStyle(color: PassengerPalette.muted, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      if (ride.passengerPhone.isNotEmpty)
                        IconButton.filledTonal(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Calling ${ride.passengerPhone}…')),
                            );
                          },
                          icon: const Icon(CupertinoIcons.phone_fill),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _AddressRow(
                    icon: CupertinoIcons.location_solid,
                    color: PassengerPalette.limeDeep,
                    title: 'Pickup',
                    subtitle: ride.pickup,
                  ),
                  const SizedBox(height: 10),
                  _AddressRow(
                    icon: CupertinoIcons.flag_fill,
                    color: const Color(0xFFE11D48),
                    title: 'Destination',
                    subtitle: ride.destination,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '£${ride.fare.toStringAsFixed(2)} · ${ride.tripLegMiles.toStringAsFixed(1)} mi trip',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: PassengerPalette.muted),
                  ),
                  const SizedBox(height: 18),
                  if (toPickup) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton(
                        onPressed: nearPickup
                            ? () async {
                                final err = await context.read<RideViewModel>().markArrived();
                                if (!context.mounted) return;
                                if (err != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                                  return;
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Passenger notified — you have arrived'),
                                  ),
                                );
                              }
                            : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: _gold,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFFE5E7EB),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          nearPickup ? 'Arrived at Pickup' : 'Approaching pickup…',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                      ),
                    ),
                    if (!nearPickup)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Button unlocks when you are near the pickup location.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: PassengerPalette.muted),
                        ),
                      ),
                  ] else if (arrived) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Waiting for passenger. Use chat or call if needed.',
                        style: TextStyle(fontWeight: FontWeight.w600, height: 1.35),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton(
                        onPressed: () async {
                          final err = await context.read<RideViewModel>().startTrip();
                          if (!context.mounted) return;
                          if (err != null) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Ride started — navigate to destination')),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: PassengerPalette.limeDeep,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text(
                          'Start Ride',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                      ),
                    ),
                  ] else if (inProgress) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton(
                        onPressed: ride.progress >= 0.75
                            ? () async {
                                final err = await context.read<RideViewModel>().completeTrip();
                                if (!context.mounted) return;
                                if (err != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                                  return;
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Ride completed — saved to history')),
                                );
                                context.go('/driver/history');
                              }
                            : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: PassengerPalette.ink,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFFE5E7EB),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          ride.progress >= 0.75 ? 'Complete Ride' : 'En route to destination…',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                      ),
                    ),
                  ] else if (done) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton(
                        onPressed: () {
                          state.completePassengerRide(5);
                          context.go('/driver');
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: _gold,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text(
                          'Done — back to Jobs',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
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
      elevation: 2,
      shadowColor: Colors.black26,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 44, height: 44, child: Icon(icon, size: 20, color: PassengerPalette.ink)),
      ),
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
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10)],
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

class _AddressRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _AddressRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: PassengerPalette.muted)),
              Text(subtitle, style: const TextStyle(fontWeight: FontWeight.w600, height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }
}
