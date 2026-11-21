import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

class PassengerPaymentsScreen extends StatelessWidget {
  const PassengerPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Payments', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('Choose how you pay for rides', style: TextStyle(color: PassengerPalette.muted)),
          const SizedBox(height: 16),
          _PayTile(icon: Icons.payments_outlined, title: 'Cash', subtitle: 'Pay driver at end of trip', selected: true),
          _PayTile(icon: Icons.credit_card, title: 'Card', subtitle: 'Add card when backend is linked'),
          _PayTile(icon: Icons.account_balance_wallet_outlined, title: 'Wallet', subtitle: 'Coming soon'),
          const SizedBox(height: 20),
          const Text('Recent charges', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _Charge(title: 'Glenrothes → Kirkcaldy', amount: '£12.40', date: 'Yesterday'),
          _Charge(title: 'Leven → St Andrews', amount: '£28.00', date: 'Mon'),
        ],
      ),
    );
  }
}

class _PayTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;

  const _PayTile({required this.icon, required this.title, required this.subtitle, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected ? PassengerPalette.lime.withValues(alpha: 0.2) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: selected ? PassengerPalette.limeDeep : PassengerPalette.border),
      ),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: PassengerPalette.muted)),
              ],
            ),
          ),
          if (selected) const Icon(Icons.check_circle, color: PassengerPalette.limeDeep),
        ],
      ),
    );
  }
}

class _Charge extends StatelessWidget {
  final String title;
  final String amount;
  final String date;

  const _Charge({required this.title, required this.amount, required this.date});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(date),
      trailing: Text(amount, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}
