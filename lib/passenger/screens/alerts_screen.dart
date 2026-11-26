import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../viewmodels/alerts_view_model.dart';

class PassengerAlertsScreen extends StatefulWidget {
  const PassengerAlertsScreen({super.key});

  @override
  State<PassengerAlertsScreen> createState() => _PassengerAlertsScreenState();
}

class _PassengerAlertsScreenState extends State<PassengerAlertsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AlertsViewModel>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AlertsViewModel>();
    final alerts = vm.alerts;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Alerts', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
              ),
              if (vm.unreadCount > 0)
                TextButton(
                  onPressed: () => vm.markAllRead(),
                  child: const Text('Mark read'),
                ),
              IconButton(
                onPressed: vm.isLoading ? null : () => vm.refresh(),
                icon: vm.isLoading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text('Ride updates from your account', style: TextStyle(color: PassengerPalette.muted)),
          const SizedBox(height: 16),
          if (alerts.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Center(
                child: Text(
                  vm.error ?? 'No alerts yet',
                  style: const TextStyle(color: PassengerPalette.muted, fontWeight: FontWeight.w600),
                ),
              ),
            )
          else
            ...alerts.map(
              (a) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: a.isUnread ? const Color(0xFFFFF8E7) : const Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      CupertinoIcons.bell_fill,
                      color: a.isUnread ? const Color(0xFFC9A227) : PassengerPalette.muted,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.title, style: const TextStyle(fontWeight: FontWeight.w700, height: 1.3)),
                          if (a.body.trim().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(a.body, style: const TextStyle(fontWeight: FontWeight.w500, height: 1.35)),
                          ],
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
