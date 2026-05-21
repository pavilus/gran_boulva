import 'package:flutter/material.dart';

class AppColors {
  // Background layers
  static const Color bg0 = Color(0xFF050014);
  static const Color bg1 = Color(0xFF10102A);
  static const Color bg2 = Color(0xFF220060);
  static const Color card = Color(0xFF10052E);
  static const Color cardLight = Color(0xFF2A0070);

  // Secondary / icon button background
  static const Color secondary = Color(0xFF1E1E3A);

  // Input / search field background
  static const Color inputBg = Color(0xFF1A1A32);

  // Brand
  static const Color purple = Color(0xFF4F158F);
  static const Color purpleLight = Color(0xFF7B3FBE);
  static const Color primary = purpleLight;
  static const Color purpleDim = Color(0xFF2A1440);
  static const Color pink = Color(0xFFD90C82);
  static const Color pinkLight = Color(0xFFFF4DAE);

  // Extra brand colours
  static const Color orange = Color(0xFFF97316);
  static const Color green = Color(0xFF22C55E);
  static const Color blue = Color(0xFF3B82F6);

  // Gradient stops
  static const Color gradPurple = Color(0xFF4F158F);
  static const Color gradPink = Color(0xFFD90C82);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFCCCCDD);
  static const Color textMuted = Color(0xFF8888AA);
  static const Color textDim = Color(0xFF7C5DB8);

  // Status
  static const Color success = Color(0xFF00D68F);
  static const Color warning = Color(0xFFEAB308);
  static const Color error = Color(0xFFFF3D71);

  // Borders
  static const Color border = Color(0xFF2A2A4A);
  static const Color borderDim = Color(0xFF1E1E36);

  // VS badge
  static const Color vs = Color(0xFF050014);

  static LinearGradient get primaryGradient => const LinearGradient(
        colors: [gradPurple, gradPink],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );

  static LinearGradient get bgGradient => const LinearGradient(
        colors: [bg0, bg0],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

  static LinearGradient get optionAGradient => const LinearGradient(
        colors: [gradPurple, gradPink],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );

  static LinearGradient get optionBGradient => const LinearGradient(
        colors: [gradPurple, gradPink],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );
}
