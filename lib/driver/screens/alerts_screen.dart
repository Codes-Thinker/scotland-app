import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../shared/widgets/confirm_bottom_sheet.dart';
import '../../viewmodels/alerts_view_model.dart';

class DriverAlertsScreen extends StatefulWidget {
  const DriverAlertsScreen({super.key});

  @override
  State<DriverAlertsScreen> createState() => _DriverAlertsScreenState();
}

class _DriverAlertsScreenState extends State<DriverAlertsScreen> {
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/driver/profile');
                    }
                  },
                  icon: const Icon(Icons.arrow_back),
                ),
                const Expanded(
                  child: Text('Alerts', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                ),
                if (alerts.isNotEmpty)
                  TextButton(
                    onPressed: () async {
                      final ok = await showConfirmBottomSheet(
                        context,
                        title: 'Mark all read?',
                        message: 'Clear unread badges on all alerts?',
                        cancelLabel: 'Keep',
                        confirmLabel: 'Mark read',
                        onConfirm: () async => vm.markAllRead(),
                      );
                      if (ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Alerts marked read')),
                        );
                      }
                    },
                    child: const Text('Clear'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (alerts.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: Text(
                    vm.error ?? 'No alerts',
                    style: const TextStyle(color: PassengerPalette.muted),
                  ),
                ),
              )
            else
              ...alerts.map(
                (a) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: a.isUnread ? const Color(0xFFFFF8E7) : const Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.notification_important,
                        color: a.isUnread ? AppPalette.warning : PassengerPalette.muted,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                            if (a.body.trim().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(a.body),
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
      ),
    );
  }
}
