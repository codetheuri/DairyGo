import 'package:flutter/material.dart';

/// AppColors defines the Material 3 color palette for the Dairy Sacco Platform.
/// 
/// Senior Architect Note:
/// We use tailored HSL / Hex brand tokens instead of default Material colors:
/// - Primary Green: Represents agriculture, growth, and trust.
/// - Surface Slate: Clean, high-contrast dark backgrounds and text.
/// - Secondary / Accent Mint: Subtle badge backgrounds and containers.
abstract class AppColors {
  // Brand Primary
  static const Color primary = Color(0xFF0A5C36);
  static const Color primaryLight = Color(0xFF2E8B57);
  static const Color primaryDark = Color(0xFF053B21);

  // Secondary & Accents
  static const Color secondary = Color(0xFF007A78);
  static const Color accentMint = Color(0xFFE8F5E9);
  static const Color accentAmber = Color(0xFFF57C00);

  // Backgrounds & Surfaces
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color cardBorder = Color(0xFFE2E8F0);

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);

  // Status & Feedback Colors
  static const Color success = Color(0xFF16A34A);
  static const Color successContainer = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFD97706);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFDC2626);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF0284C7);
  static const Color infoContainer = Color(0xFFE0F2FE);
}
