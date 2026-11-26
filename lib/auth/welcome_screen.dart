import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../shared/models/models.dart';
import '../shared/widgets/brand_logo.dart';
import '../viewmodels/auth_view_model.dart';

/// Light welcome — select Passenger/Driver, then Sign In.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const _gold = Color(0xFFC9A227);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final selected = auth.pendingRole;
    final h = MediaQuery.sizeOf(context).height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, h < 700 ? 16 : 28, 24, 20),
              child: Column(
                children: [
                  SizedBox(height: h < 700 ? 8 : 20),
                  const BrandLogo(size: 110, showShadow: true),
                  const SizedBox(height: 18),
                  const Text(
                    'Welcome to Scotland',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: PassengerPalette.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Book a Ride Across Scotland',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: PassengerPalette.muted,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: _RoleCard(
                          icon: CupertinoIcons.person_fill,
                          title: 'Passenger',
                          subtitle: 'Book rides',
                          selected: selected == UserRole.passenger,
                          onTap: () => auth.selectRole(UserRole.passenger),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _RoleCard(
                          icon: CupertinoIcons.car_detailed,
                          title: 'Driver',
                          subtitle: 'Drive & earn',
                          selected: selected == UserRole.driver,
                          onTap: () => auth.selectRole(UserRole.driver),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: () {
                        auth.selectRole(selected);
                        context.go('/auth/choice');
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: _gold,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () {
                      auth.selectRole(selected);
                      context.go('/auth/signin');
                    },
                    child: const Text(
                      'Already registered? Sign In',
                      style: TextStyle(
                        color: PassengerPalette.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  static const _gold = Color(0xFFC9A227);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _gold.withValues(alpha: 0.16) : PassengerPalette.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.fromLTRB(14, 20, 14, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? _gold : PassengerPalette.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: selected ? _gold : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: selected ? _gold : PassengerPalette.border),
                ),
                child: Icon(
                  icon,
                  color: selected ? Colors.black : PassengerPalette.muted,
                  size: 26,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: selected ? PassengerPalette.ink : PassengerPalette.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: PassengerPalette.muted,
                ),
              ),
              if (selected) ...[
                const SizedBox(height: 10),
                const Icon(CupertinoIcons.checkmark_circle_fill, color: _gold, size: 20),
              ] else
                const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
