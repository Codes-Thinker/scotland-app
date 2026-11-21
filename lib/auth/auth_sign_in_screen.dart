import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/auth_theme.dart';
import '../services/app_state.dart';
import '../shared/models/models.dart';
import '../shared/widgets/brand_logo.dart';

/// Role-aware Sign In (Passenger or Driver from welcome selection).
class AuthSignInScreen extends StatefulWidget {
  const AuthSignInScreen({super.key});

  @override
  State<AuthSignInScreen> createState() => _AuthSignInScreenState();
}

class _AuthSignInScreenState extends State<AuthSignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final state = context.read<AppState>();
    final role = state.pendingRole ?? UserRole.passenger;
    state.selectRole(role);

    setState(() {
      _loading = true;
      _error = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 350));

    final err = await state.signIn(
      email: _email.text,
      password: _password.text,
    );

    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = err;
    });

    if (err == null) {
      if (state.isPassenger) {
        context.go('/passenger');
      } else {
        context.go(state.driverDocumentsComplete ? '/driver' : '/driver/documents');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AppState>().pendingRole ?? UserRole.passenger;
    final roleLabel = role == UserRole.passenger ? 'Passenger' : 'Driver';
    final signupPath =
        role == UserRole.driver ? '/auth/signup/driver' : '/auth/signup/passenger';

    return Scaffold(
      backgroundColor: AuthTheme.background,
      appBar: AppBar(
        backgroundColor: AuthTheme.background,
        foregroundColor: AuthTheme.ink,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => context.go('/auth/choice'),
        ),
        title: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
              children: [
                const BrandLogo(size: 72),
                const SizedBox(height: 12),
                Text(
                  'Sign In as $roleLabel',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AuthTheme.ink,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Enter your email and password',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: PassengerPalette.muted),
                ),
                const SizedBox(height: 22),
                const Text('Email Address', style: AuthTheme.labelStyle),
                const SizedBox(height: 6),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: AuthTheme.fieldDecoration(
                    hint: 'you@email.com',
                    icon: CupertinoIcons.mail,
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Password', style: AuthTheme.labelStyle),
                const SizedBox(height: 6),
                TextField(
                  controller: _password,
                  obscureText: _obscure,
                  decoration: AuthTheme.fieldDecoration(
                    hint: 'Enter password',
                    icon: CupertinoIcons.lock,
                    suffix: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                        color: AuthTheme.muted,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppPalette.danger)),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  height: 54,
                  child: FilledButton(
                    onPressed: _loading ? null : _submit,
                    style: AuthTheme.primaryButton(),
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.black),
                          )
                        : const Text('Sign In', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    context.read<AppState>().selectRole(role);
                    context.go(signupPath);
                  },
                  child: Text(
                    'Need an account? Sign Up',
                    style: const TextStyle(color: AuthTheme.gold, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
