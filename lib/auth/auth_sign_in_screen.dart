import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/auth_theme.dart';
import '../core/utils/validators.dart';
import '../services/app_state.dart';
import '../shared/models/models.dart';
import '../shared/widgets/brand_logo.dart';
import '../viewmodels/auth_view_model.dart';

class AuthSignInScreen extends StatefulWidget {
  const AuthSignInScreen({super.key});

  @override
  State<AuthSignInScreen> createState() => _AuthSignInScreenState();
}

class _AuthSignInScreenState extends State<AuthSignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = context.read<AuthViewModel>();
    final app = context.read<AppState>();

    final err = await auth.login(email: _email.text, password: _password.text);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }

    final u = auth.user!;
    final role = auth.sessionRole ?? UserRole.passenger;
    await app.syncFromApiAuth(
      id: u.id,
      name: u.name,
      email: u.email,
      phone: u.phone,
      role: role,
      vehicle: u.driver?.vehicleMakeModel,
      vehiclePlate: u.driver?.vehiclePlate,
      operatingZone: u.driver?.operatingZone,
      documentsComplete: role == UserRole.passenger,
    );
    if (!mounted) return;

    if (auth.isPassengerMode) {
      context.go('/passenger');
    } else {
      context.go(app.driverDocumentsComplete ? '/driver' : '/driver/documents');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final role = auth.pendingRole;
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
            child: Form(
              key: _formKey,
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
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
                    decoration: AuthTheme.fieldDecoration(
                      hint: 'you@email.com',
                      icon: CupertinoIcons.mail,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Password', style: AuthTheme.labelStyle),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Enter your password.' : null,
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
                  const SizedBox(height: 22),
                  SizedBox(
                    height: 54,
                    child: FilledButton(
                      onPressed: auth.isLoading ? null : _submit,
                      style: AuthTheme.primaryButton(),
                      child: auth.isLoading
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
                      auth.selectRole(role);
                      context.go(signupPath);
                    },
                    child: const Text(
                      'Need an account? Sign Up',
                      style: TextStyle(color: AuthTheme.gold, fontWeight: FontWeight.w700),
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
