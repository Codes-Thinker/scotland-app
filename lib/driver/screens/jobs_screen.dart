import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../services/app_state.dart';
import '../../services/mock_repository.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/map_placeholder.dart';

/// Driver home — one offered ride at a time, then active trip until complete.
class DriverJobsScreen extends StatefulWidget {
  const DriverJobsScreen({super.key});

  @override
  State<DriverJobsScreen> createState() => _DriverJobsScreenState();
}

class _DriverJobsScreenState extends State<DriverJobsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppState>().ensureDriverReceivingOffers();
    });
  }

  String _hello() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final name = state.user?.name ?? 'Driver';
    final offer = state.offeredJob;
    final trip = state.activeTrip;

    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  icon: const Icon(CupertinoIcons.line_horizontal_3, size: 24, color: PassengerPalette.ink),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_hello()},',
                        style: const TextStyle(
                          fontSize: 15,
                          color: PassengerPalette.muted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: PassengerPalette.lime.withValues(alpha: 0.35),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'D',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: PassengerPalette.ink),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Material(
              color: const Color(0xFFF7FBE8),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: () => context.go('/driver/earnings'),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.money_dollar_circle_fill, color: PassengerPalette.limeDeep, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Today £${state.todayEarnings.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                      ),
                      Text(
                        'Week £${state.weekEarnings.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: PassengerPalette.muted,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(CupertinoIcons.chevron_right, size: 14, color: PassengerPalette.muted),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            if (!state.driverDocumentsComplete) ...[
              Material(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () => context.go('/driver/documents'),
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.doc_text_fill, color: Color(0xFFC2410C)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${state.driverDocumentsMissing} required document${state.driverDocumentsMissing == 1 ? '' : 's'} still needed',
                            style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF9A3412)),
                          ),
                        ),
                        const Icon(CupertinoIcons.chevron_right, size: 16, color: Color(0xFF9A3412)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],

            Text(
              !state.driverDocumentsComplete
                  ? 'Upload documents to receive ride offers.'
                  : trip != null
                      ? 'Active trip — manage until complete.'
                      : offer != null
                          ? 'New ride offered to you — accept or reject.'
                          : 'Waiting for your next assigned ride…',
              style: const TextStyle(
                fontSize: 15,
                height: 1.35,
                color: PassengerPalette.muted,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _ActionChip(
                    icon: CupertinoIcons.phone_fill,
                    label: 'Dispatch',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Calling dispatch…')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionChip(
                    icon: CupertinoIcons.refresh,
                    label: 'Refresh',
                    onTap: () {
                      if (!state.driverDocumentsComplete) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Complete documents first')),
                        );
                        context.go('/driver/documents');
                        return;
                      }
                      if (trip != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Finish your current trip first')),
                        );
                        return;
                      }
                      state.refreshJobs();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                _SosButton(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('SOS sent to dispatch')),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            if (!state.driverDocumentsComplete)
              const _EmptyCard(
                icon: CupertinoIcons.doc_text,
                title: 'Documents required',
                body: 'Verify your licence and vehicle docs to start receiving offers.',
              )
            else if (trip != null)
              _ActiveTripCard(
                trip: trip,
                onComplete: () => context.go('/driver/tracking'),
                onChat: () {
                  final threads = state.chatThreads.where((t) => t.passengerName == trip.passengerName);
                  if (threads.isNotEmpty) {
                    context.push('/driver/chat/${threads.first.id}');
                  } else {
                    context.go('/driver/messages');
                  }
                },
              )
            else if (offer != null)
              _OfferCard(
                job: offer,
                onAccept: () {
                  state.acceptJob(offer.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Accepted · ${offer.passengerName} — navigating to pickup')),
                  );
                  context.go('/driver/tracking');
                },
                onReject: () {
                  state.rejectJob(offer.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Rejected — waiting for next offer')),
                  );
                },
              )
            else
              const _EmptyCard(
                icon: CupertinoIcons.sparkles,
                title: 'No offer right now',
                body: 'When dispatch assigns a ride to you, it will appear here. Pull Refresh to check.',
              ),

            const SizedBox(height: 22),
            const Text(
              'Your area',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: -0.2),
            ),
            const SizedBox(height: 10),
            const SizedBox(height: 200, child: MapPlaceholder()),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF3F4F6),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: PassengerPalette.limeDeep, size: 20),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SosButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SosButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppPalette.danger,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: const SizedBox(
          width: 64,
          height: 64,
          child: Center(
            child: Text('SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _EmptyCard({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: PassengerPalette.muted),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(color: PassengerPalette.muted, height: 1.35, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final IncomingRequest job;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _OfferCard({
    required this.job,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBE8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PassengerPalette.limeDeep.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: PassengerPalette.limeDeep,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'OFFERED TO YOU',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11),
                ),
              ),
              const Spacer(),
              Text(
                '£${job.fare.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: PassengerPalette.limeDeep),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(job.passengerName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          const SizedBox(height: 8),
          Text(
            '${job.pickup}\n→ ${job.destination}',
            style: const TextStyle(color: PassengerPalette.muted, height: 1.4, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Text(
            '${MockRepository.rideTypeLabel(job.type)} · ${job.distance} · ETA ${job.eta}',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppPalette.danger,
                      side: const BorderSide(color: Color(0xFFFECACA)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: onAccept,
                    style: FilledButton.styleFrom(
                      backgroundColor: PassengerPalette.limeDeep,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActiveTripCard extends StatelessWidget {
  final IncomingRequest trip;
  final VoidCallback onComplete;
  final VoidCallback onChat;

  const _ActiveTripCard({
    required this.trip,
    required this.onComplete,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBE8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PassengerPalette.limeDeep.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: PassengerPalette.limeDeep,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'IN PROGRESS',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11),
                ),
              ),
              const Spacer(),
              Text(
                '£${trip.fare.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w800, color: PassengerPalette.limeDeep, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(trip.passengerName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          if (trip.passengerPhone.isNotEmpty)
            Text(trip.passengerPhone, style: const TextStyle(color: PassengerPalette.muted, fontSize: 13)),
          const SizedBox(height: 10),
          Text(
            '${trip.pickup}\n→ ${trip.destination}',
            style: const TextStyle(color: PassengerPalette.muted, height: 1.4),
          ),
          const SizedBox(height: 8),
          Text(
            '${MockRepository.rideTypeLabel(trip.type)} · ${trip.distance} · ETA ${trip.eta}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: onChat,
                    icon: const Icon(CupertinoIcons.chat_bubble_fill, size: 16),
                    label: const Text('Chat'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: PassengerPalette.ink,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: onComplete,
                    style: FilledButton.styleFrom(
                      backgroundColor: PassengerPalette.limeDeep,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Track ride', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
