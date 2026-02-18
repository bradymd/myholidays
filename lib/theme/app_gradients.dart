import 'package:flutter/material.dart';
import 'package:my_holidays/theme/app_colors.dart';

class AppGradients {
  const AppGradients._();

  // Pink -> purple -> deep purple — vibrant KPop gradient
  static const header = LinearGradient(
    colors: [
      Color(0xFFFF80AB),
      AppColors.primary,
      Color(0xFF7B1FA2),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const primaryGradient = LinearGradient(
    colors: [AppColors.primary, AppColors.primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const successCard = LinearGradient(
    colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const warningCard = LinearGradient(
    colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const dangerCard = LinearGradient(
    colors: [Color(0xFFFFEBEE), Color(0xFFFFCDD2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
