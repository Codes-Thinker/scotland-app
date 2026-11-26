import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../services/app_state.dart';
import '../shared/widgets/brand_logo.dart';
import '../viewmodels/auth_view_model.dart';

/// Full-bleed map splash — car drives & rotates on open map (no card / no GIF).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;
  late final Animation<double> _fadeIn;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 3600));
    _progress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.04, 0.9, curve: Curves.easeInOutCubic),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.18, curve: Curves.easeOut));

    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) _goNext();
    });
  }

  Future<void> _goNext() async {
    if (_navigated || !mounted) return;
    _navigated = true;
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;
    final auth = context.read<AuthViewModel>();
    final state = context.read<AppState>();
    if (auth.isLoggedIn) {
      if (auth.isPassengerMode) {
        context.go('/passenger');
      } else {
        context.go(state.driverDocumentsComplete ? '/driver' : '/driver/documents');
      }
      return;
    }
    context.go('/auth/welcome');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EEF5),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // Open full-screen map (no container / card)
              CustomPaint(
                painter: _SplashMapPainter(progress: _progress.value),
                child: const SizedBox.expand(),
              ),
              // Light edges only — center stays clear for the car
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.82 * _fadeIn.value),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.88 * _fadeIn.value),
                      ],
                      stops: const [0, 0.18, 0.72, 1],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Opacity(
                  opacity: _fadeIn.value.clamp(0.0, 1.0),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                    child: Column(
                      children: [
                        const BrandLogo(size: 56),
                        const SizedBox(height: 10),
                        const Text(
                          'Scotland',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            color: AppPalette.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _etaLabel(_progress.value),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppPalette.muted,
                          ),
                        ),
                        const Spacer(),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: _progress.value.clamp(0.04, 1),
                            minHeight: 3,
                            backgroundColor: Colors.black.withValues(alpha: 0.08),
                            color: PassengerPalette.limeDeep,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _etaLabel(double t) {
    if (t < 0.12) return 'Finding best route…';
    if (t < 0.88) return 'Glenrothes → Kirkcaldy · taxi on the road';
    return 'Ready';
  }
}

class _SplashMapPainter extends CustomPainter {
  final double progress;

  _SplashMapPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(size.width, size.height),
        const [Color(0xFFE8EEF5), Color(0xFFC8D6E4)],
      );
    canvas.drawRect(Offset.zero & size, bg);

    _drawBlocks(canvas, size);
    _drawSecondaryRoads(canvas, size);

    final route = _routePath(size);
    final metrics = route.computeMetrics().first;
    final len = metrics.length;
    final t = progress.clamp(0.0, 1.0);
    final drawn = metrics.extractPath(0, len * t);

    // Full faint route
    canvas.drawPath(
      route,
      Paint()
        ..color = const Color(0xFF94A3B8)
        ..strokeWidth = 5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Travelled glow + line
    canvas.drawPath(
      drawn,
      Paint()
        ..color = PassengerPalette.lime.withValues(alpha: 0.45)
        ..strokeWidth = 18
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawPath(
      drawn,
      Paint()
        ..color = PassengerPalette.limeDeep
        ..strokeWidth = 7
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    final start = metrics.getTangentForOffset(0)!.position;
    final end = metrics.getTangentForOffset(len)!.position;
    _drawPin(canvas, start, const Color(0xFF16A34A), filled: true);
    _drawPin(canvas, end, AppPalette.primary, filled: t > 0.9);

    // Car follows path direction (rotates with road turns)
    final tangent = metrics.getTangentForOffset(len * t);
    if (tangent != null) {
      // Art faces +X (nose forward). PathMetric.angle = atan2(dy, dx) — matches canvas.rotate.
      _drawCar(canvas, tangent.position, tangent.angle);
    }
  }

  /// Open route across the middle of the full screen.
  Path _routePath(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.08, h * 0.72)
      ..quadraticBezierTo(w * 0.22, h * 0.62, w * 0.34, h * 0.55)
      ..quadraticBezierTo(w * 0.48, h * 0.46, w * 0.55, h * 0.50)
      ..quadraticBezierTo(w * 0.68, h * 0.56, w * 0.78, h * 0.42)
      ..quadraticBezierTo(w * 0.88, h * 0.30, w * 0.92, h * 0.28);
  }

  void _drawBlocks(Canvas canvas, Size size) {
    final fill = Paint()..color = const Color(0xFFDCE5EE);
    final stroke = Paint()
      ..color = const Color(0xFFC5D0DB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final rng = math.Random(11);
    for (var i = 0; i < 22; i++) {
      final x = rng.nextDouble() * size.width * 0.9;
      final y = rng.nextDouble() * size.height * 0.9;
      final ww = 42 + rng.nextDouble() * 72;
      final hh = 32 + rng.nextDouble() * 56;
      final r = RRect.fromRectAndRadius(Rect.fromLTWH(x, y, ww, hh), const Radius.circular(6));
      canvas.drawRRect(r, fill);
      canvas.drawRRect(r, stroke);
    }
  }

  void _drawSecondaryRoads(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFB7C3CF)
      ..strokeWidth = 2.8
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, size.height * 0.48), Offset(size.width, size.height * 0.58), paint);
    canvas.drawLine(Offset(size.width * 0.2, 0), Offset(size.width * 0.52, size.height), paint);
    canvas.drawLine(Offset(0, size.height * 0.22), Offset(size.width, size.height * 0.18), paint);
    canvas.drawLine(Offset(0, size.height * 0.82), Offset(size.width * 0.75, size.height * 0.9), paint);
  }

  void _drawPin(Canvas canvas, Offset c, Color color, {required bool filled}) {
    canvas.drawCircle(
      c,
      filled ? 10 : 11,
      Paint()
        ..color = color
        ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    if (filled) {
      canvas.drawCircle(c, 4, Paint()..color = Colors.white);
    }
  }

  /// Top-down taxi facing +X (nose = front). [angle] aligns +X with road direction.
  void _drawCar(Canvas canvas, Offset center, double angle) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    // Soft road glow
    canvas.drawCircle(
      Offset.zero,
      26,
      Paint()..color = PassengerPalette.lime.withValues(alpha: 0.22),
    );

    // Ground shadow (slightly behind / under)
    canvas.drawOval(
      const Rect.fromLTWH(-18, 2, 36, 14),
      Paint()..color = Colors.black.withValues(alpha: 0.18),
    );

    final body = Paint()..color = const Color(0xFF1F2937);
    final lime = Paint()..color = PassengerPalette.limeDeep;
    final glass = Paint()..color = const Color(0xFF7DD3FC);
    final darkGlass = Paint()..color = const Color(0xFF38BDF8).withValues(alpha: 0.85);
    final wheel = Paint()..color = const Color(0xFF0F172A);
    final wheelHub = Paint()..color = const Color(0xFF94A3B8);
    final white = Paint()..color = Colors.white.withValues(alpha: 0.9);

    // --- Wheels first (sit under body) — left / right of travel ---
    void tire(Offset c) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: c, width: 10, height: 7), const Radius.circular(2)),
        wheel,
      );
      canvas.drawCircle(c, 2.2, wheelHub);
    }

    tire(const Offset(-11, -13)); // rear left
    tire(const Offset(-11, 13)); // rear right
    tire(const Offset(10, -13)); // front left
    tire(const Offset(10, 13)); // front right

    // --- Main body: tapered nose (front +X), wider cabin, rounded boot ---
    final hull = Path()
      ..moveTo(-20, -10) // rear left
      ..lineTo(-20, 10) // rear right
      ..quadraticBezierTo(-8, 12, 4, 11) // right flank
      ..quadraticBezierTo(14, 10, 20, 6) // toward nose right
      ..quadraticBezierTo(24, 0, 20, -6) // pointed nose
      ..quadraticBezierTo(14, -10, 4, -11) // toward left
      ..quadraticBezierTo(-8, -12, -20, -10)
      ..close();
    canvas.drawPath(hull, body);

    // Lime taxi stripe down the centre (reads as real cab)
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-16, -2.2, 32, 4.4), const Radius.circular(2)),
      lime,
    );

    // Rear boot / window
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-18, -7, 8, 14), const Radius.circular(2.5)),
      darkGlass,
    );

    // Cabin roof
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-8, -8, 14, 16), const Radius.circular(3)),
      Paint()..color = const Color(0xFF111827),
    );

    // Windshield (front glass — clearly the nose side)
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(6, -7, 9, 14), const Radius.circular(2.5)),
      glass,
    );

    // Roof taxi sign
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-3, -3.5, 8, 7), const Radius.circular(1.5)),
      lime,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-1.5, -2, 5, 4), const Radius.circular(1)),
      white,
    );

    // Headlights at the front (+X)
    canvas.drawCircle(const Offset(19, -5), 2.2, Paint()..color = const Color(0xFFFEF08A));
    canvas.drawCircle(const Offset(19, 5), 2.2, Paint()..color = const Color(0xFFFEF08A));

    // Tail lights at the rear (−X)
    canvas.drawCircle(const Offset(-19, -6), 1.8, Paint()..color = const Color(0xFFF87171));
    canvas.drawCircle(const Offset(-19, 6), 1.8, Paint()..color = const Color(0xFFF87171));

    // Side mirrors
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(4, -14, 5, 3), const Radius.circular(1)),
      body,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(4, 11, 5, 3), const Radius.circular(1)),
      body,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SplashMapPainter oldDelegate) => oldDelegate.progress != progress;
}
