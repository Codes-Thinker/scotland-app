import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../services/app_state.dart';
import '../models/models.dart';

/// Passenger | Driver toggle — switches mode in-place (no re-login).
class ModeSwitcher extends StatelessWidget {
  final UserRole current;
  final VoidCallback? beforeNavigate;

  const ModeSwitcher({
    super.key,
    required this.current,
    this.beforeNavigate,
  });

  void _switch(BuildContext context, UserRole target) {
    if (target == current) return;
    beforeNavigate?.call();
    final state = context.read<AppState>();
    state.switchMode(target);
    if (target == UserRole.passenger) {
      context.go('/passenger');
    } else {
      context.go(state.driverDocumentsComplete ? '/driver' : '/driver/documents');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Mode',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: PassengerPalette.muted),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: _Chip(
                  label: 'Passenger',
                  icon: CupertinoIcons.person_fill,
                  selected: current == UserRole.passenger,
                  onTap: () => _switch(context, UserRole.passenger),
                ),
              ),
              Expanded(
                child: _Chip(
                  label: 'Driver',
                  icon: CupertinoIcons.car_detailed,
                  selected: current == UserRole.driver,
                  onTap: () => _switch(context, UserRole.driver),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Switch anytime from the drawer — you stay signed in.',
          style: TextStyle(fontSize: 11, color: PassengerPalette.muted, height: 1.3),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      elevation: selected ? 0.5 : 0,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? PassengerPalette.limeDeep : PassengerPalette.muted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: selected ? PassengerPalette.ink : PassengerPalette.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
