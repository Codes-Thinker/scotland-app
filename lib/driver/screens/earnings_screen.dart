import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../services/app_state.dart';
import '../../services/mock_repository.dart';

class DriverEarningsScreen extends StatelessWidget {
  const DriverEarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
          children: [
            const Text(
              'Earnings',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.4),
            ),
            const SizedBox(height: 6),
            const Text('Overview of your completed trips', style: TextStyle(color: PassengerPalette.muted)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _Big(
                    title: 'Today',
                    value: '£${state.todayEarnings.toStringAsFixed(2)}',
                    color: AppPalette.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Big(
                    title: 'This week',
                    value: '£${state.weekEarnings.toStringAsFixed(2)}',
                    color: AppPalette.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _Row(label: 'Completed trips', value: '${state.completedDriverTrips}'),
                  const Divider(height: 20),
                  _Row(
                    label: 'Avg. fare',
                    value: state.completedDriverTrips == 0
                        ? '£0.00'
                        : '£${(state.weekEarnings / state.completedDriverTrips).toStringAsFixed(2)}',
                  ),
                  const Divider(height: 20),
                  const _Row(label: 'Tips (mock)', value: '£6.50'),
                  const Divider(height: 20),
                  const _Row(label: 'Platform fee (mock)', value: '-£4.20'),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text('Trip breakdown', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 10),
            ...state.driverTrips.map(
              (t) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${t.pickup} → ${t.destination}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${t.dateLabel} · ${MockRepository.rideTypeLabel(t.type)} · ${t.status.name}',
                            style: const TextStyle(fontSize: 12, color: PassengerPalette.muted),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '£${t.fare.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
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

class _Big extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  const _Big({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: PassengerPalette.muted)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}
