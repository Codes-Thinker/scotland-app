import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../viewmodels/earnings_view_model.dart';

class DriverEarningsScreen extends StatefulWidget {
  const DriverEarningsScreen({super.key});

  @override
  State<DriverEarningsScreen> createState() => _DriverEarningsScreenState();
}

class _DriverEarningsScreenState extends State<DriverEarningsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EarningsViewModel>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EarningsViewModel>();
    final avg = vm.completedTrips == 0 ? 0.0 : vm.weekPounds / vm.completedTrips;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => vm.refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Earnings',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.4),
                    ),
                  ),
                  if (vm.isLoading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Gross fares from completed trips',
                style: TextStyle(color: PassengerPalette.muted),
              ),
              if (vm.error != null) ...[
                const SizedBox(height: 8),
                Text(vm.error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _Big(
                      title: 'Today',
                      value: '£${vm.todayPounds.toStringAsFixed(2)}',
                      color: AppPalette.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Big(
                      title: 'This week',
                      value: '£${vm.weekPounds.toStringAsFixed(2)}',
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
                    _Row(label: 'Completed trips', value: '${vm.completedTrips}'),
                    const Divider(height: 20),
                    _Row(label: 'Avg. fare', value: '£${avg.toStringAsFixed(2)}'),
                    const Divider(height: 20),
                    const _Row(label: 'Tips (payments mock)', value: '—'),
                    const Divider(height: 20),
                    const _Row(label: 'Platform fee (payments mock)', value: '—'),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text('Daily breakdown', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
              const SizedBox(height: 10),
              if (vm.days.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Text(
                    'No completed trips in this range yet',
                    style: TextStyle(color: PassengerPalette.muted, fontWeight: FontWeight.w600),
                  ),
                )
              else
                ...vm.days.reversed.map(
                  (d) => Container(
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
                              Text(d.day, style: const TextStyle(fontWeight: FontWeight.w700)),
                              Text(
                                '${d.trips} trip${d.trips == 1 ? '' : 's'}',
                                style: const TextStyle(fontSize: 12, color: PassengerPalette.muted),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '£${d.grossPounds.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
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
