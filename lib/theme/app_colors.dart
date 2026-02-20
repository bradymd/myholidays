import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  // Primary palette — pinky purple GenZ vibes
  static const primary = Color(0xFFAB47BC);
  static const primaryDark = Color(0xFF6A1B9A);
  static const primaryLight = Color(0xFFCE93D8);
  static const accent = Color(0xFFFF80AB);
  static const accentDark = Color(0xFFF50057);

  // Extra vibrant accents — KPop palette
  static const mint = Color(0xFF00E5CC);
  static const lilac = Color(0xFFD1B3FF);
  static const peach = Color(0xFFFFB5A7);
  static const skyBlue = Color(0xFF89CFF0);
  static const lemon = Color(0xFFFFF176);

  // Status colours
  static const success = Color(0xFF2E7D32);
  static const warning = Color(0xFFF57F17);
  static const danger = Color(0xFFD32F2F);

  // Neutrals
  static const textPrimary = Color(0xFF2D1B4E);
  static const textSecondary = Color(0xFF6B5B7B);
  static const textMuted = Color(0xFF9B8DAD);
  static const surface = Color(0xFFFFFBFE);
  static const background = Color(0xFFF0E6F6);
  static const cardShadow = Color(0x30AB47BC);

  // Pastels — softer and cuter
  static const softPurple = Color(0xFFF3E5F5);
  static const softPink = Color(0xFFFCE4EC);
  static const softOrange = Color(0xFFFFF3E0);
  static const softRed = Color(0xFFFFEBEE);
  static const softGreen = Color(0xFFE8F5E9);
  static const softMint = Color(0xFFE0F7F4);
  static const softLilac = Color(0xFFEDE7F6);
  static const softSky = Color(0xFFE3F2FD);

  // Holiday icon helpers
  static const holidayIconKeys = [
    'flight',
    'beach',
    'driving',
    'camping',
    'sporty',
    'relaxation',
    'sightseeing',
    'mountain',
  ];

  static String holidayIconAsset(String icon) {
    final key = holidayIconKeys.contains(icon) ? icon : 'flight';
    return 'assets/icons/$key.png';
  }

  static String holidayIconLabel(String icon) {
    return switch (icon) {
      'flight' => 'Flight',
      'beach' => 'Beach',
      'driving' => 'Road Trip',
      'camping' => 'Camping',
      'sporty' => 'Sports',
      'relaxation' => 'Relaxation',
      'sightseeing' => 'Sightseeing',
      'mountain' => 'Mountain',
      _ => 'Flight',
    };
  }

  static Color holidayColour(String hex) {
    if (hex.isEmpty) return AppColors.primary;
    final value = int.tryParse(hex, radix: 16);
    if (value == null) return AppColors.primary;
    return Color(value);
  }
}
