import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

class BrandLogo extends StatelessWidget {
  final double size;
  final bool showShadow;

  const BrandLogo({super.key, this.size = 72, this.showShadow = false});

  static const assetPath = 'assets/images/new-logo.jpeg';

  @override
  Widget build(BuildContext context) {
    final image = ClipOval(
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: size,
          height: size,
          color: AppPalette.primarySoft,
          alignment: Alignment.center,
          child: Icon(Icons.local_taxi, size: size * 0.4, color: AppPalette.primary),
        ),
      ),
    );

    if (!showShadow) return Center(child: image);

    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: image,
      ),
    );
  }
}
