import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Light auth styling — matches Passenger / Driver dashboard UI.
class AuthTheme {
  static const gold = Color(0xFFC9A227);
  static const ink = PassengerPalette.ink;
  static const muted = PassengerPalette.muted;
  static const surface = PassengerPalette.surface;
  static const border = PassengerPalette.border;
  static const background = Colors.white;

  static InputDecoration fieldDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
      prefixIcon: Icon(icon, color: muted, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: gold, width: 1.5),
      ),
    );
  }

  static const labelStyle = TextStyle(
    color: muted,
    fontSize: 13,
    fontWeight: FontWeight.w700,
  );

  static ButtonStyle primaryButton() {
    return FilledButton.styleFrom(
      backgroundColor: gold,
      foregroundColor: Colors.black,
      disabledBackgroundColor: gold.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}
