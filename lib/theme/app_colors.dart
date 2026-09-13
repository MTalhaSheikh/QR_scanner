import 'package:flutter/material.dart';

/// Central color palette for ScanCraft.
///
/// The app uses a deep indigo/violet brand color paired with a fresh
/// aqua accent — this gives scanning (camera-heavy, dark UI) and
/// generation (light, card-heavy UI) screens a consistent identity.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF5B5FEF); // Indigo violet
  static const Color primaryDark = Color(0xFF3E41B8);
  static const Color primaryLight = Color(0xFF8B8FFF);

  static const Color accent = Color(0xFF14E0C4); // Aqua/teal
  static const Color accentSoft = Color(0xFFB6FBF1);

  static const Color coral = Color(0xFFFF6B6B);
  static const Color amber = Color(0xFFFFB020);
  static const Color success = Color(0xFF2ECC71);

  // Neutral / surfaces
  static const Color darkBg = Color(0xFF0E0E1B);
  static const Color darkSurface = Color(0xFF17172B);
  static const Color darkCard = Color(0xFF1F1F38);

  static const Color lightBg = Color(0xFFF6F7FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);

  static const Color textPrimaryDark = Color(0xFFF3F3FB);
  static const Color textSecondaryDark = Color(0xFFA9A9C7);

  static const Color textPrimaryLight = Color(0xFF1B1B2E);
  static const Color textSecondaryLight = Color(0xFF6E6E8E);

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6A5CFF), Color(0xFF14E0C4)],
  );

  static const LinearGradient scanGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0E0E1B), Color(0xFF1B1B3A)],
  );

  static const LinearGradient coralGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6B6B), Color(0xFFFF9472)],
  );

  /// Per-content-type accent colors used across result & history screens.
  static const Map<String, Color> typeColors = {
    'url': Color(0xFF5B5FEF),
    'wifi': Color(0xFF14E0C4),
    'contact': Color(0xFFFF6B6B),
    'email': Color(0xFFFFB020),
    'phone': Color(0xFF2ECC71),
    'sms': Color(0xFF8B8FFF),
    'text': Color(0xFF6E6E8E),
    'barcode': Color(0xFFFF9472),
  };
}
