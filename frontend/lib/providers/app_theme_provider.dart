// lib/providers/app_theme_provider.dart
//
// ✅ Provider thème clair/sombre — clair par défaut
// ✅ Toggle animé (soleil/lune) dans top bar
// ✅ Tous les getters utilisés dans landing, home, transport_tracking
// ✅ Constantes statiques accessibles sans instance

import 'package:flutter/material.dart';

class AppThemeProvider extends ChangeNotifier {
  // ── Thème clair par défaut (reset à chaque ouverture) ───────────────────
  bool _isDark = false;
  bool get isDark => _isDark;

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }

  // ── Couleurs statiques (accessibles sans instance) ───────────────────────
  static const Color appBlue = Color(0xFF2296F3);
  static const Color blueBright = Color(0xFF42AAFE);
  static const Color blueMid = Color(0xFF1A7ED4);
  static const Color amber = Color(0xFFFFB300);
  static const Color amberDeep = Color(0xFFFF8F00);
  static const Color amberBright = Color(0xFFFFCA28);
  static const Color amberLight = Color(0xFFFFF3CD);
  static const Color teal = Color(0xFF00D4C8);
  static const Color green = Color(0xFF22C55E);
  static const Color textDark = Color(0xFF0F2040);

  // ── Backgrounds ───────────────────────────────────────────────────────────

  /// Fond principal de la page
  Color get bg => _isDark ? const Color(0xFF0D1117) : const Color(0xFFF4F8FF);

  /// Fond des cartes / containers
  Color get bgCard => _isDark ? const Color(0xFF161B22) : Colors.white;

  /// Fond des sections alternées (légèrement différent de bg)
  Color get bgSection =>
      _isDark ? const Color(0xFF13191F) : const Color(0xFFEEF4FF);

  /// Section claire (tarifs, pricing)
  Color get sectionLight =>
      _isDark ? const Color(0xFF0F1419) : const Color(0xFFF0F7FF);

  /// Section claire alternative (contact)
  Color get sectionLightAlt =>
      _isDark ? const Color(0xFF111620) : const Color(0xFFF5F0FF);

  // ── Top bar ───────────────────────────────────────────────────────────────

  /// Fond de la top bar — toujours coloré (bleu nuit sombre / bleu app clair)
  Color get topBarBg => _isDark ? const Color(0xFF0A1628) : appBlue;

  // ── Texte ─────────────────────────────────────────────────────────────────

  Color get textPrimary =>
      _isDark ? const Color(0xFFE6EDF3) : const Color(0xFF0F2040);

  Color get textMuted =>
      _isDark ? const Color(0xFF8B949E) : const Color(0xFF6B7A99);

  // ── Bordures ──────────────────────────────────────────────────────────────

  Color get border =>
      _isDark ? const Color(0xFF30363D) : const Color(0xFFDDE3EF);

  /// Bordure plus visible (focus, cartes actives)
  Color get borderBright =>
      _isDark ? const Color(0xFF3D4752) : const Color(0xFFC5D0E8);

  // ── Hero gradient (landing) ───────────────────────────────────────────────

  /// 3 couleurs pour le gradient animé du hero
  List<Color> get heroGradient => _isDark
      ? [
          const Color(0xFF0A1628),
          const Color(0xFF0D3060),
          const Color(0xFF0A2040),
        ]
      : [
          appBlue,
          blueMid,
          const Color(0xFF0E5DA8),
        ];
}
