import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../services/app_state.dart';

class PassengerAlertsScreen extends StatelessWidget {
  const PassengerAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final alerts = context.watch<AppState>().passengerAlerts;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
        children: [
          const Text('Alerts', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
          const SizedBox(height: 6),
          const Text('Ride updates & reminders (mock)', style: TextStyle(color: PassengerPalette.muted)),
          const SizedBox(height: 16),
          ...alerts.map(
            (a) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(CupertinoIcons.bell_fill, color: Color(0xFFC9A227), size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(a, style: const TextStyle(fontWeight: FontWeight.w600, height: 1.35))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
