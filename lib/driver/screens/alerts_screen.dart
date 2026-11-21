import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../services/app_state.dart';
import '../../shared/widgets/confirm_bottom_sheet.dart';

class DriverAlertsScreen extends StatelessWidget {
  const DriverAlertsScreen({super.key});

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
                if (state.alertItems.isNotEmpty)
                  TextButton(
                    onPressed: () async {
                      final ok = await showConfirmBottomSheet(
                        context,
                        title: 'Clear alerts?',
                        message: 'Remove all alert notifications from this list?',
                        cancelLabel: 'Keep',
                        confirmLabel: 'Clear all',
                        onConfirm: () async => state.clearAlerts(),
                      );
                      if (ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Alerts cleared')),
                        );
                      }
                    },
                    child: const Text('Clear'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (state.alertItems.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(
                  child: Text('No alerts', style: TextStyle(color: PassengerPalette.muted)),
                ),
              )
            else
              ...state.alertItems.map(
                (a) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.notification_important, color: AppPalette.warning),
                      const SizedBox(width: 10),
                      Expanded(child: Text(a)),
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
