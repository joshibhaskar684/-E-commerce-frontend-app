import 'package:flutter/material.dart';

/// Brand colours sampled from the Quick logo (assets/images/logo.jpg).
class AppColors {
  AppColors._();

  static const brandYellow = Color(0xFFFBBB02);
  static const brandYellowSoft = Color(0xFFFFF4CC);
  static const navy = Color(0xFF17283C);
  static const navySoft = Color(0xFF2B4461);

  static const success = Color(0xFF2E7D32); // ratings, discounts (website #388e3c)
  static const danger = Color(0xFFE53935);
  static const info = Color(0xFF1E6FD9);

  // Light
  static const lightBackground = Color(0xFFF4F5F7);
  static const lightSurface = Colors.white;
  static const lightOutline = Color(0xFFE4E7EC);

  // Dark
  static const darkBackground = Color(0xFF0D1117);
  static const darkSurface = Color(0xFF161B22);
  static const darkSurfaceHigh = Color(0xFF1F2630);
  static const darkOutline = Color(0xFF2A313C);
}
