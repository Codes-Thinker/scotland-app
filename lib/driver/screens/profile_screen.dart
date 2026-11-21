import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../services/app_state.dart';
import '../../shared/widgets/confirm_actions.dart';

class DriverProfileScreen extends StatelessWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.user;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
        children: [
          const Text(
            'Profile',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.4),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: PassengerPalette.lime.withValues(alpha: 0.35),
                child: Text(
                  user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'D',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: PassengerPalette.ink),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? '',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.2),
                    ),
                    Text(user?.email ?? '', style: const TextStyle(color: PassengerPalette.muted)),
                    const SizedBox(height: 4),
                    const Text('Rating ★ 4.8', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _Tile(
            icon: CupertinoIcons.folder,
            title: 'Documents',
            subtitle: state.driverDocumentsComplete
                ? 'All verified'
                : '${state.driverDocumentsMissing} required — tap to upload',
            onTap: () => context.go('/driver/documents'),
          ),
          _Tile(
            icon: CupertinoIcons.bell,
            title: 'Alerts',
            subtitle: state.alerts > 0 ? '${state.alerts} new' : 'No new alerts',
            onTap: () => context.go('/driver/alerts'),
          ),
          _Tile(
            icon: CupertinoIcons.money_dollar_circle,
            title: 'Earnings summary',
            subtitle: 'Today & week totals',
            onTap: () => context.go('/driver/earnings'),
          ),
          _Tile(
            icon: CupertinoIcons.phone_fill,
            title: 'Call dispatch',
            subtitle: 'Support line',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Calling dispatch…')),
              );
            },
          ),
          const SizedBox(height: 8),
          _Tile(
            icon: CupertinoIcons.square_arrow_right,
            title: 'Sign out',
            subtitle: null,
            danger: true,
            onTap: () => confirmLogout(context),
          ),
          _Tile(
            icon: CupertinoIcons.trash,
            title: 'Delete account',
            subtitle: 'Remove this account from this device',
            danger: true,
            onTap: () => confirmDeleteAccount(context),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool danger;

  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppPalette.danger : PassengerPalette.ink;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: color)),
                      if (subtitle != null)
                        Text(subtitle!, style: const TextStyle(fontSize: 12, color: PassengerPalette.muted)),
                    ],
                  ),
                ),
                Icon(CupertinoIcons.chevron_right, size: 16, color: PassengerPalette.muted.withValues(alpha: 0.7)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
