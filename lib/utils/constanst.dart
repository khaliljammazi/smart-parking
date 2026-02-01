import 'package:flutter/material.dart';

class AppColor {
  // Primary Colors
  static const Color navy = Color(0xFF064789);
  static const Color orange = Color(0xFFF77F00);
  static const Color forText = Color(0xFF032445);
  static const Color fadeText = Color(0xFF6A91B8);
  static const Color navyPale = Color(0xFFE7EDF4);
  static Color paleOrange = const Color(0xFFFEA559).withOpacity(0.3);
  
  // Dark Mode Colors
  static const Color darkBackground = Color(0xFF0A0E27);
  static const Color darkCard = Color(0xFF1A1F3A);
  static const Color darkSurface = Color(0xFF252B48);
  static const Color darkPrimary = Color(0xFF1E88E5);
  static const Color darkAccent = Color(0xFFFF9800);
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF29B6F6);
  
  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF064789), Color(0xFF0A5FA5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF0A0E27), Color(0xFF1A1F3A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}