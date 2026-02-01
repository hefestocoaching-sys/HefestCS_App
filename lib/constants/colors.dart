import 'package:flutter/material.dart';

/// Paleta de colores y estilos reutilizables de la aplicación.
class AppTheme {
  AppTheme._();

  static const Color primaryGold = Color(0xFF9a9071);
  static const Color wrapperBackground = Color(0xFF181E2F);
  static const Color navBar = Color(0xFF181E2F);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white;
  static const Color unselectedItemColor = Colors.white;
  static const Color surface = Color(0xFF181E2F);
  static const Color surfaceTransparent = Color(0xC3192031);
  static const Color overlay = Color(0x4D000000);
  static const Color progressIndicatorBackground = Color(0x4D9E9E9E);
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x87000000),
      spreadRadius: 0.5,
      blurRadius: 2.75,
      offset: Offset(6, 8),
    ),
  ];
}