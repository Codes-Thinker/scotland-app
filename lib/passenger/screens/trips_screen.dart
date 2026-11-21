import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../services/app_state.dart';
import '../../shared/models/models.dart';

class PassengerTripsScreen extends StatelessWidget {
  const PassengerTripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final trips = context.watch<AppState>().passengerTrips
        .where((t) => t.status == RideStatus.completed)
        .toList();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('History', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('Your completed rides', style: TextStyle(color: PassengerPalette.muted)),
          const SizedBox(height: 16),
          if (trips.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 48),
              child: Center(child: Text('No trips yet', style: TextStyle(color: PassengerPalette.muted))),
            )
          else
            ...trips.map(
              (t) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: PassengerPalette.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: PassengerPalette.lime.withValues(alpha: 0.35),
                          child: Text(
                            (t.driverName ?? 'D').isNotEmpty
                                ? (t.driverName ?? 'D')[0].toUpperCase()
                                : 'D',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.driverName ?? 'Driver',
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                              Text(t.dateLabel, style: const TextStyle(fontSize: 12, color: PassengerPalette.muted)),
                            ],
                          ),
                        ),
                        Text(
                          '£${t.fare.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${t.pickup}\n→ ${t.destination}',
                      style: const TextStyle(color: PassengerPalette.muted, height: 1.35),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (t.distance != null) ...[
                          const Icon(CupertinoIcons.arrow_left_right, size: 14, color: PassengerPalette.muted),
                          const SizedBox(width: 4),
                          Text(t.distance!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 10),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: PassengerPalette.lime.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Completed', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                      ],
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
