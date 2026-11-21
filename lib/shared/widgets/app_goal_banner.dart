import 'package:flutter/material.dart';

/// Compact goal strip for passenger / driver homes — sits above scroll content.
class AppGoalBanner extends StatelessWidget {
  final String title;
  final String goal;
  final IconData icon;
  final Color accent;
  final Color? background;
  final List<Widget>? trailing;

  const AppGoalBanner({
    super.key,
    required this.title,
    required this.goal,
    required this.icon,
    required this.accent,
    this.background,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: background ?? Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 22, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8E8E93),
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  goal,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    letterSpacing: -0.2,
                    color: Color(0xFF1C1C1E),
                  ),
                ),
              ],
            ),
          ),
          ...?trailing,
        ],
      ),
    );
  }
}

/// Layout: fixed goal banner on top, scrollable body underneath.
class GoalStackScaffold extends StatelessWidget {
  final Widget banner;
  final Widget child;
  final Color? backgroundColor;

  const GoalStackScaffold({
    super.key,
    required this.banner,
    required this.child,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor ?? Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          banner,
          Expanded(child: child),
        ],
      ),
    );
  }
}
