import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/auth_theme.dart';
import '../services/app_state.dart';
import '../shared/models/models.dart';
import '../shared/widgets/brand_logo.dart';
import '../shared/widgets/document_image_picker.dart';

class AuthSignupScreen extends StatefulWidget {
  final UserRole role;
  const AuthSignupScreen({super.key, required this.role});

  @override
  State<AuthSignupScreen> createState() => _AuthSignupScreenState();
}

class _AuthSignupScreenState extends State<AuthSignupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _vehicle = TextEditingController();
  final _plate = TextEditingController();
  bool _obscure = true;
  bool _obscure2 = true;
  String? _error;
  bool _loading = false;
  VehicleCategory _vehicleCategory = VehicleCategory.fourSeater;
  String? _operatingZone;
  late List<DriverDocument> _docs;
  String? _uploadingDocId;

  bool get _isPassenger => widget.role == UserRole.passenger;

  @override
  void initState() {
    super.initState();
    _docs = AppState.requiredDriverDocs.map((d) => d.copyWith()).toList();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppState>().selectRole(widget.role);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    _vehicle.dispose();
    _plate.dispose();
    super.dispose();
  }

  String _vehicleLabel(VehicleCategory v) {
    switch (v) {
      case VehicleCategory.fourSeater:
        return '4 Seater';
      case VehicleCategory.sixSeater:
        return '6 Seater (MPV)';
      case VehicleCategory.eightSeater:
        return '8 Seater (Mini Bus)';
      case VehicleCategory.wheelchair:
        return 'Wheelchair Vehicle';
    }
  }

  IconData _vehicleIcon(VehicleCategory v) {
    switch (v) {
      case VehicleCategory.eightSeater:
        return CupertinoIcons.car_fill;
      default:
        return CupertinoIcons.car_detailed;
    }
  }

  Future<void> _uploadDoc(DriverDocument doc) async {
    final path = await pickDocumentImage(context, title: 'Upload ${doc.title}');
    if (!mounted || path == null) return;

    setState(() => _uploadingDocId = doc.id);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    setState(() {
      _docs = [
        for (final d in _docs)
          if (d.id == doc.id) d.copyWith(status: DriverDocStatus.verified) else d,
      ];
      _uploadingDocId = null;
    });
  }

  Future<void> _submit() async {
    final state = context.read<AppState>();
    state.selectRole(widget.role);
    setState(() {
      _loading = true;
      _error = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 400));

    final vehicleValue = _isPassenger
        ? ''
        : '${_vehicle.text.trim()} · ${_vehicleLabel(_vehicleCategory)}';

    final err = await state.signUp(
      name: _name.text,
      email: _email.text,
      phone: _phone.text,
      password: _password.text,
      confirmPassword: _confirm.text,
      vehicle: vehicleValue,
      vehiclePlate: _plate.text,
      operatingZone: _operatingZone ?? '',
      initialDriverDocs: _isPassenger ? null : _docs,
      acceptedTerms: true,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = err;
    });
    if (err == null) {
      final role = widget.role;
      await state.logout();
      if (!mounted) return;
      state.selectRole(role);
      context.go('/auth/signin');
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: Text(
          _isPassenger ? 'Create Account' : 'Driver Sign Up',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
              children: [
                const BrandLogo(size: 64),
                const SizedBox(height: 12),
                Text(
                  _isPassenger ? 'Passenger registration' : 'Driver registration',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AuthTheme.ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isPassenger
                      ? 'Create your account to book rides across Scotland.'
                      : 'Submit your driver application. Documents can be uploaded now or later.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: PassengerPalette.muted, height: 1.4),
                ),
                const SizedBox(height: 22),
                _LabeledField(
                  label: 'Full Name *',
                  child: TextField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: AuthTheme.fieldDecoration(
                      hint: 'John Smith',
                      icon: CupertinoIcons.person,
                    ),
                  ),
                ),
                _LabeledField(
                  label: 'Email Address *',
                  child: TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: AuthTheme.fieldDecoration(
                      hint: 'you@email.com',
                      icon: CupertinoIcons.mail,
                    ),
                  ),
                ),
                _LabeledField(
                  label: 'Phone Number *',
                  child: TextField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: AuthTheme.fieldDecoration(
                      hint: '+44 7xxx xxxxxx',
                      icon: CupertinoIcons.phone,
                    ),
                  ),
                ),
                _LabeledField(
                  label: 'Password *',
                  child: TextField(
                    controller: _password,
                    obscureText: _obscure,
                    decoration: AuthTheme.fieldDecoration(
                      hint: 'Minimum 6 characters',
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
                ),
                _LabeledField(
                  label: 'Confirm Password *',
                  child: TextField(
                    controller: _confirm,
                    obscureText: _obscure2,
                    decoration: AuthTheme.fieldDecoration(
                      hint: 'Repeat password',
                      icon: CupertinoIcons.lock,
                      suffix: IconButton(
                        onPressed: () => setState(() => _obscure2 = !_obscure2),
                        icon: Icon(
                          _obscure2 ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                          color: AuthTheme.muted,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                if (!_isPassenger) ..._driverSections(),
                if (_error != null) ...[
                  Text(_error!, style: const TextStyle(color: AppPalette.danger)),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 8),
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
                        : Text(
                            _isPassenger ? 'Create Account' : 'Submit Driver Application',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    context.read<AppState>().selectRole(widget.role);
                    context.go('/auth/signin');
                  },
                  child: const Text(
                    'Already have an account? Sign In',
                    style: TextStyle(color: AuthTheme.gold, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _driverSections() {
    return [
      const Text('Vehicle Type *', style: AuthTheme.labelStyle),
      const SizedBox(height: 8),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.2,
        children: VehicleCategory.values.map((v) {
          final selected = _vehicleCategory == v;
          return Material(
            color: selected ? AuthTheme.gold.withValues(alpha: 0.16) : AuthTheme.surface,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: () => setState(() => _vehicleCategory = v),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? AuthTheme.gold : AuthTheme.border,
                    width: selected ? 1.6 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _vehicleIcon(v),
                      color: selected ? AuthTheme.ink : AuthTheme.muted,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _vehicleLabel(v),
                        style: const TextStyle(
                          color: AuthTheme.ink,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 14),
      _LabeledField(
        label: 'Vehicle Make and Model *',
        child: TextField(
          controller: _vehicle,
          textCapitalization: TextCapitalization.words,
          decoration: AuthTheme.fieldDecoration(
            hint: 'e.g. Ford Mondeo',
            icon: CupertinoIcons.car_detailed,
          ),
        ),
      ),
      _LabeledField(
        label: 'Vehicle Registration Plate *',
        child: TextField(
          controller: _plate,
          textCapitalization: TextCapitalization.characters,
          decoration: AuthTheme.fieldDecoration(
            hint: 'e.g. AB12 CDE',
            icon: CupertinoIcons.square_list,
          ),
        ),
      ),
      const Text('Operating Zone *', style: AuthTheme.labelStyle),
      const SizedBox(height: 4),
      const Text(
        'Select the zone where you will primarily operate',
        style: TextStyle(color: PassengerPalette.muted, fontSize: 12),
      ),
      const SizedBox(height: 6),
      DropdownButtonFormField<String>(
        // ignore: deprecated_member_use
        value: _operatingZone,
        decoration: AuthTheme.fieldDecoration(
          hint: 'Select your zone...',
          icon: CupertinoIcons.map,
        ),
        items: AppState.operatingZones
            .map((z) => DropdownMenuItem(value: z, child: Text(z)))
            .toList(),
        onChanged: (v) => setState(() => _operatingZone = v),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(CupertinoIcons.info_circle_fill, color: Color(0xFF2563EB), size: 18),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'You can register without uploading documents and provide them later in the Documents section. An administrator can approve your application even when documents are missing. You remain responsible for meeting applicable licensing and legal requirements.',
                style: TextStyle(
                  color: Color(0xFF1E3A8A),
                  fontSize: 12.5,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      const Text(
        'DOCUMENTS YOU CAN PROVIDE LATER',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: PassengerPalette.muted,
        ),
      ),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: AuthTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AuthTheme.border),
        ),
        child: Column(
          children: [
            for (var i = 0; i < _docs.length; i++) ...[
              if (i > 0) const Divider(height: 1, color: AuthTheme.border),
              _DocSignupRow(
                doc: _docs[i],
                uploading: _uploadingDocId == _docs[i].id,
                onUpload: () => _uploadDoc(_docs[i]),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFED7AA)),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(CupertinoIcons.calendar, color: Color(0xFFC2410C), size: 18),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'If you upload your Council Plate Number document, include its expiry date.',
                style: TextStyle(
                  color: Color(0xFF9A3412),
                  fontSize: 12.5,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(CupertinoIcons.shield_lefthalf_fill, color: Color(0xFF2563EB), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              children: [
                const Text(
                  'Learn how FNT uses and protects your information in our ',
                  style: TextStyle(fontSize: 12, color: PassengerPalette.muted, height: 1.35),
                ),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Privacy Policy — fifenearbytaxis.co.uk/privacy')),
                    );
                  },
                  child: const Text(
                    'Privacy Policy',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const Text('.', style: TextStyle(fontSize: 12, color: PassengerPalette.muted)),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
    ];
  }
}

class _DocSignupRow extends StatelessWidget {
  final DriverDocument doc;
  final bool uploading;
  final VoidCallback onUpload;

  const _DocSignupRow({
    required this.doc,
    required this.uploading,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    final done = doc.status == DriverDocStatus.verified;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      child: Row(
        children: [
          Icon(
            done ? CupertinoIcons.checkmark_square_fill : CupertinoIcons.square,
            color: done ? AppPalette.success : AuthTheme.muted,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
                Text(
                  done ? 'Uploaded' : 'Provide later or upload now',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: done ? AppPalette.success : PassengerPalette.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (!done)
            TextButton(
              onPressed: uploading ? null : onUpload,
              child: uploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Upload',
                      style: TextStyle(fontWeight: FontWeight.w800, color: AuthTheme.gold),
                    ),
            )
          else
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(CupertinoIcons.checkmark_circle_fill, color: AppPalette.success, size: 20),
            ),
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AuthTheme.labelStyle),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}
