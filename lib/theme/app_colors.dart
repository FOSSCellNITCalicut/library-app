import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Brand ──
  // Unified from original custom hex values:
  //   0xFF6A1B9A (primary), 0xFF624F9A (button purple), 0xFF6C4EB4 (splash)
  static const Color primary = Color(0xFF6A1B9A);

  // ── Surface / Background ──
  // Unified from purple.shade50 (0xFFF3E5F5), purple.shade100 (0xFFE1BEE7),
  // deepPurple.shade50 (0xFFEDE7F6), and the auth-screen bg (0xFFF1EAF9)
  static const Color surfaceLight = Color(0xFFF3E5F5);
  static const Color canvasColor = Color(0xFFF9F9F9);

  // ── Purple Accents ──
  static const Color purple = Color(0xFF9C27B0); // was Colors.purple
  // Unified from purple.shade300 (0xFFBA68C8) & shade400 (0xFFAB47BC)
  static const Color purpleAccent = Color(0xFFBA68C8);
  static const Color purpleDark = Color(0xFF8E24AA); // was purple.shade600

  // ── Text ──
  static const Color textPrimary = Color(0xDD000000);   // ≈ black87
  static const Color textSecondary = Color(0x8A000000);  // ≈ black54
  static const Color textHint = Color(0x42000000);       // ≈ black26
  static const Color textDisabled = Color(0x1F000000);   // ≈ black12
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Greys ──
  // Unified from grey.shade200/300/400
  static const Color greyBorder = Color(0xFFE0E0E0);
  static const Color greyDim = Color(0xFF9E9E9E);        // shade500
  static const Color greyText = Color(0xFF757575);       // shade600
  static const Color greyDark = Color(0xFF616161);       // shade700

  // ── Status ──
  static const Color available = Color(0xFF4CAF50);
  static const Color availableSurface = Color(0xFFE8F5E9); // green.shade50
  static const Color unavailable = Color(0xFFF44336);
  static const Color unavailableSurface = Color(0xFFFFEBEE); // red.shade50

  // ── Utilities ──
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);
}

extension ThemeContext on BuildContext {
  ColorScheme get cs => Theme.of(this).colorScheme;
}
