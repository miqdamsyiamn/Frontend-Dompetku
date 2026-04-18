import 'package:flutter/material.dart';


class AppTheme {

  static const Color primary = Color(0xFF059669);


  static const Color background = Color(0xFFF8FAFC);

  static const Color surface = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF064E3B);


  static const Color textSecondary = Color(0xFF64748B);


  static const Color success = Color(0xFF16A34A);


  static const Color danger = Color(0xFFE11D48);


  static const Color border = Color(0xFFE2E8F0);


  static const Color buttonText = Color(0xFFFFFFFF);


  static const List<Color> gradient = [
    Color(0xFF059669), // Emerald Deep
    Color(0xFF10B981), // Emerald 500
  ];


  static Color getPrimaryColor() => primary;
  static Color getBackgroundColor() => background;
  static Color getCardColor() => surface;
  static Color getSurfaceColor() => surface;
  static Color getTextColor() => textPrimary;
  static Color getSecondaryTextColor() => textSecondary;
  static Color getBorderColor() => border;
  static Color getButtonTextColor() => buttonText;
  static Color getInputBackgroundColor() => surface;
  static Color getSuccessColor() => success;
  static Color getDangerColor() => danger;
  static List<Color> getGradient() => gradient;
}
