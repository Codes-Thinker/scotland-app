import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../services/app_state.dart';

class DriverScheduledScreen extends StatelessWidget {
  const DriverScheduledScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rides = context.watch<AppState>().driverScheduledRides;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
          children: [
            const Text('Scheduled Rides', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
            const SizedBox(height: 6),
            const Text('Upcoming bookings assigned to you', style: TextStyle(color: PassengerPalette.muted)),
            const SizedBox(height: 16),
            if (rides.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(
                  child: Text(
                    'No scheduled rides yet.\nPassenger Book Later trips appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: PassengerPalette.muted, height: 1.4),
                  ),
                ),
              )
            else
              ...rides.map(
                (t) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
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
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: PassengerPalette.lime.withValues(alpha: 0.4),
                            child: Text(
                              (t.passengerName ?? 'P').isNotEmpty
                                  ? (t.passengerName ?? 'P')[0].toUpperCase()
                                  : 'P',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            t.passengerName ?? 'Passenger',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${t.pickup}\n→ ${t.destination}',
                        style: const TextStyle(color: PassengerPalette.muted, height: 1.35),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Reminder: be online 15 minutes before pickup.',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFC2410C)),
                      ),
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