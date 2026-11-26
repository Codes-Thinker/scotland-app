import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../services/app_state.dart';
import '../shared/widgets/brand_logo.dart';
import '../viewmodels/auth_view_model.dart';

/// Simple, clean splash — logo + name with smooth fade / scale.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _enter;
  late final AnimationController _pulse;
  late final AnimationController _hold;

  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _tagFade;
  late final Animation<double> _bar;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _hold = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));

    _logoFade = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
    );
    _logoScale = Tween<double>(begin: 0.82, end: 1).animate(
      CurvedAnimation(
        parent: _enter,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
      ),
    );
    _titleFade = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.28, 0.72, curve: Curves.easeOutCubic),
    );
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.28), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _enter,
        curve: const Interval(0.28, 0.72, curve: Curves.easeOutCubic),
      ),
    );
    _tagFade = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.48, 0.9, curve: Curves.easeOut),
    );
    _bar = CurvedAnimation(
      parent: _hold,
      curve: Curves.easeInOutCubic,
    );

    _enter.forward();
    _enter.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pulse.repeat(reverse: true);
        _hold.forward();
      }
    });
    _hold.addStatusListener((status) {
      if (status == AnimationStatus.completed) _goNext();
    });
  }

  Future<void> _goNext() async {
    if (_navigated || !mounted) return;
    _navigated = true;
    await Future<void>.delayed(const Duration(milliseconds: 180));
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
    _enter.dispose();
    _pulse.dispose();
    _hold.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFF7F8FA),
              Color(0xFFEEF2F7),
            ],
            stops: [0, 0.55, 1],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: Listenable.merge([_enter, _pulse, _hold]),
            builder: (context, _) {
              final breath = 1 + (_pulse.value * 0.03);
              return Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
                child: Column(
                  children: [
                    const Spacer(flex: 3),
                    Opacity(
                      opacity: _logoFade.value.clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: _logoScale.value * breath,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFC9A227).withValues(alpha: 0.18),
                                blurRadius: 28,
                                offset: const Offset(0, 10),
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const BrandLogo(size: 108),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SlideTransition(
                      position: _titleSlide,
                      child: FadeTransition(
                        opacity: _titleFade,
                        child: const Text(
                          'Scotland',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                            color: AppPalette.ink,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    FadeTransition(
                      opacity: _tagFade,
                      child: Text(
                        'Fife Nearby Taxis',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                          color: PassengerPalette.muted.withValues(alpha: 0.95),
                        ),
                      ),
                    ),
                    const Spacer(flex: 4),
                    FadeTransition(
                      opacity: _tagFade,
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: SizedBox(
                              height: 3,
                              width: 96,
                              child: LinearProgressIndicator(
                                value: (0.08 + _bar.value * 0.92).clamp(0.08, 1),
                                backgroundColor: Colors.black.withValues(alpha: 0.06),
                                color: const Color(0xFFC9A227),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Getting ready…',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: PassengerPalette.muted.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
