import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_holidays/theme/app_colors.dart';

class AppTextStyles {
  const AppTextStyles._();

  static TextStyle get heading => GoogleFonts.nunitoSans(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      );

  static TextStyle get subheading => GoogleFonts.nunitoSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get body => GoogleFonts.nunitoSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyBold => GoogleFonts.nunitoSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get caption => GoogleFonts.nunitoSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  static TextStyle get buttonText => GoogleFonts.nunitoSans(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      );

  static TextStyle get label => GoogleFonts.nunitoSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      );
}
