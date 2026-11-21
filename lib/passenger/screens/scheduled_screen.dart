import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../services/app_state.dart';
import '../../services/mock_repository.dart';
import '../../shared/widgets/confirm_actions.dart';

class PassengerScheduledScreen extends StatelessWidget {
  const PassengerScheduledScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final rides = state.scheduledRides;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
        children: [
          const Text('Scheduled', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
          const SizedBox(height: 6),
          const Text('Upcoming booked rides', style: TextStyle(color: PassengerPalette.muted)),
          const SizedBox(height: 16),
          if (rides.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: Text('No scheduled rides', style: TextStyle(color: PassengerPalette.muted))),
            )
          else
            ...rides.map(
              (t) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(CupertinoIcons.calendar, size: 18, color: Color(0xFFC9A227)),
                        const SizedBox(width: 8),
                        Text(t.dateLabel, style: const TextStyle(fontWeight: FontWeight.w800)),
                        const Spacer(),
                        Text('£${t.fare.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w800)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('${t.pickup}\n→ ${t.destination}', style: const TextStyle(color: PassengerPalette.muted, height: 1.35)),
                    const SizedBox(height: 6),
                    Text(
                      '${MockRepository.rideTypeLabel(t.type)} · ${t.driverName ?? 'Driver TBD'}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => confirmCancelScheduledRide(context, t.id),
                        style: TextButton.styleFrom(foregroundColor: const Color(0xFFB91C1C)),
                        child: const Text('Cancel'),
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
