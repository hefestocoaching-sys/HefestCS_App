import 'package:flutter/material.dart';
import 'package:hefestocs/constants/colors.dart';

class AppBrand {
  AppBrand._();
  static const String name = 'HCS';
  static const String logoAsset = 'assets/hcs.png';
  static const List<String> phrases = [
    'Tu mejor versión te espera',
    'Disciplina antes que motivación',
    'Nutre tu cuerpo, fortalece tu mente',
  ];
}

class FrameConfig {
  FrameConfig._();
  static const bool applyFrame = false;
  static const bool applyDate = false;
  static const double thicknessTopBottomPx = 50.0;
  static const double thicknessSidesPx = 50.0;
  static const Color frameColor = AppTheme.surface;
  static const double dateBottomMarginPx = 8.0;
  static const TextStyle dateTextStyle = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 18,
    color: AppTheme.textPrimary,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
    shadows: [Shadow(color: Colors.black54, blurRadius: 2, offset: Offset(0, 1))],
  );
  static const String dateIntlFormat = 'd MMM yyyy';
  static const String dateIntlLocale = 'es';
  static const double exportPixelRatio = 2.0;
}
class FirebaseConfig {
  FirebaseConfig._();
  static const String coachId = 'PEGAR_AQUI_COACH_DOC_ID_REAL';
}
