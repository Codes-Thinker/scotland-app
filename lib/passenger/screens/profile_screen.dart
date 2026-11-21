import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../services/app_state.dart';
import '../../shared/widgets/confirm_actions.dart';

class PassengerProfileScreen extends StatelessWidget {
  const PassengerProfileScreen({super.key});

  static const _gold = Color(0xFFC9A227);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.user;
    final initial = (user?.name.isNotEmpty == true) ? user!.name.characters.first.toUpperCase() : 'A';

    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: [
            const Text('My Account', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: _gold.withValues(alpha: 0.25),
                        child: Text(initial, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(color: _gold, shape: BoxShape.circle),
                          child: const Icon(CupertinoIcons.camera_fill, size: 12, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.name ?? 'Guest', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(user?.email ?? '', style: const TextStyle(color: PassengerPalette.muted, fontSize: 13)),
                        Text(user?.phone ?? '', style: const TextStyle(color: PassengerPalette.muted, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Edit profile (mock)')),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: _gold,
                  side: const BorderSide(color: _gold, width: 1.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Edit profile details', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),

            const SizedBox(height: 20),
            const Text('MY PRIORITY DRIVER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: PassengerPalette.muted)),
            const SizedBox(height: 8),
            _DashedCard(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                title: const Text('No Priority Driver Set', style: TextStyle(fontWeight: FontWeight.w800)),
                subtitle: const Text('Priority drivers receive your bookings first when available.'),
                trailing: const Icon(CupertinoIcons.chevron_right, size: 16),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Choose priority driver (mock)')),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),
            const Text('BLOCKED DRIVERS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: PassengerPalette.muted)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: const Icon(CupertinoIcons.hand_raised_fill, color: AppPalette.danger),
                title: const Text('Manage blocked drivers', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                subtitle: const Text('You have no drivers to manage yet.'),
                trailing: const Icon(CupertinoIcons.chevron_right, size: 16),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Blocked drivers (mock)')),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),
            const Text('ACCOUNT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: PassengerPalette.muted)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _AccountTile(
                    icon: CupertinoIcons.clock,
                    title: 'Ride History',
                    onTap: () => context.go('/passenger/trips'),
                  ),
                  const Divider(height: 1, indent: 56),
                  _AccountTile(
                    icon: CupertinoIcons.headphones,
                    title: 'Help & Support',
                    onTap: () => context.go('/passenger/support'),
                  ),
                  const Divider(height: 1, indent: 56),
                  _AccountTile(
                    icon: CupertinoIcons.info_circle,
                    title: 'About Fife Nearby Taxis',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Fife Nearby Taxis · licensed private hire')),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  _AccountTile(
                    icon: CupertinoIcons.doc_text,
                    title: 'Terms & Conditions',
                    onTap: () => context.go('/passenger/support'),
                  ),
                  const Divider(height: 1, indent: 56),
                  _AccountTile(
                    icon: CupertinoIcons.shield,
                    title: 'Privacy Policy',
                    onTap: () => context.go('/passenger/support'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: () => confirmLogout(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppPalette.danger,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: () => confirmDeleteAccount(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppPalette.danger,
                  side: const BorderSide(color: Color(0xFFFECACA)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Delete Account', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Fife Nearby Taxis · v1.0.0',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: PassengerPalette.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _AccountTile({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFC9A227)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      trailing: const Icon(CupertinoIcons.chevron_right, size: 16),
      onTap: onTap,
    );
  }
}

class _DashedCard extends StatelessWidget {
  final Widget child;
  const _DashedCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashPainter(),
      child: child,
    );
  }
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(16));
    final paint = Paint()
      ..color = const Color(0xFFD1D5DB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path()..addRRect(r);
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        final next = (d + 6).clamp(0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(d, next), paint);
        d += 10;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
