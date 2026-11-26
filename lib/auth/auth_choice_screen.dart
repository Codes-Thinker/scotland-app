import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/auth_theme.dart';
import '../shared/models/models.dart';
import '../shared/widgets/brand_logo.dart';
import '../viewmodels/auth_view_model.dart';

class AuthChoiceScreen extends StatelessWidget {
  const AuthChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final role = auth.pendingRole;
    final isDriver = role == UserRole.driver;
    final roleLabel = isDriver ? 'Driver' : 'Passenger';
    final signupPath = isDriver ? '/auth/signup/driver' : '/auth/signup/passenger';

    return Scaffold(
      backgroundColor: AuthTheme.background,
      appBar: AppBar(
        backgroundColor: AuthTheme.background,
        foregroundColor: AuthTheme.ink,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => context.go('/auth/welcome'),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
              child: Column(
                children: [
                  const BrandLogo(size: 88, showShadow: true),
                  const SizedBox(height: 18),
                  Text(
                    roleLabel,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AuthTheme.ink,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isDriver
                        ? 'Sign in to your driver account or create a new application.'
                        : 'Sign in to book rides or create a new passenger account.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: PassengerPalette.muted,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: () {
                        auth.selectRole(role);
                        context.go('/auth/signin');
                      },
                      style: AuthTheme.primaryButton(),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton(
                      onPressed: () {
                        auth.selectRole(role);
                        context.go(signupPath);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AuthTheme.ink,
                        side: const BorderSide(color: AuthTheme.gold, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
