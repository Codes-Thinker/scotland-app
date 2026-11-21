import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../services/app_state.dart';
import '../../shared/models/models.dart';

class DriverHistoryScreen extends StatelessWidget {
  const DriverHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final trips = context.watch<AppState>().driverTrips
        .where((t) => t.status == RideStatus.completed)
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
          children: [
            const Text('Ride History', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
            const SizedBox(height: 6),
            const Text('Your completed trips', style: TextStyle(color: PassengerPalette.muted)),
            const SizedBox(height: 16),
            if (trips.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 48),
                child: Center(child: Text('No completed rides yet', style: TextStyle(color: PassengerPalette.muted))),
              )
            else
              ...trips.map((t) => _HistoryCard(trip: t, forDriver: true)),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final RideRecord trip;
  final bool forDriver;

  const _HistoryCard({required this.trip, required this.forDriver});

  @override
  Widget build(BuildContext context) {
    final person = forDriver ? (trip.passengerName ?? 'Passenger') : (trip.driverName ?? 'Driver');
    return Container(
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
              CircleAvatar(
                radius: 18,
                backgroundColor: PassengerPalette.lime.withValues(alpha: 0.4),
                child: Text(
                  person.isNotEmpty ? person[0].toUpperCase() : '?',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(person, style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text(trip.dateLabel, style: const TextStyle(fontSize: 12, color: PassengerPalette.muted)),
                  ],
                ),
              ),
              Text(
                '£${trip.fare.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${trip.pickup}\n→ ${trip.destination}',
            style: const TextStyle(color: PassengerPalette.muted, height: 1.35),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (trip.distance != null) ...[
                const Icon(CupertinoIcons.arrow_left_right, size: 14, color: PassengerPalette.muted),
                const SizedBox(width: 4),
                Text(trip.distance!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
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
    );
  }
}
