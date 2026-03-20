import 'package:flutter/material.dart';

/// Provider de thème global — sombre par défaut, reset à chaque ouverture.
/// À placer dans lib/providers/app_theme_provider.dart
/// Envelopper le MaterialApp avec ChangeNotifierProvider<AppThemeProvider>
class AppThemeProvider extends ChangeNotifier {
  // ✅ Clair par défaut
  bool _isDark = false;

  bool get isDark => _isDark;
  bool get isLight => !_isDark;

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }

  // ── Palette sombre ────────────────────────────────────────────────────────
  static const Color darkBg = Color(0xFF0D1B2E);
  static const Color darkBgSection = Color(0xFF112236);
  static const Color darkBgCard = Color(0xFF1A2E45);
  static const Color darkBorder = Color(0xFF1E3A55);
  static const Color darkBorderBright = Color(0xFF2A5070);
  static const Color darkTextPrimary = Color(0xFFF0F6FF);
  static const Color darkTextSecond = Color(0xFFB0C4DE);
  static const Color darkTextMuted = Color(0xFF7A94B0);

  // ── Palette claire ────────────────────────────────────────────────────────
  static const Color lightBg = Color(0xFFF4F8FF);
  static const Color lightBgSection = Color(0xFFEEF5FF);
  static const Color lightBgCard = Colors.white;
  static const Color lightBorder = Color(0xFFDDE3EF);
  static const Color lightBorderBright = Color(0xFFBDD4EE);
  static const Color lightTextPrimary = Color(0xFF0F2040);
  static const Color lightTextSecond = Color(0xFF3A5A8A);
  static const Color lightTextMuted = Color(0xFF6B7A99);

  // ── Couleurs communes ─────────────────────────────────────────────────────
  static const Color appBlue = Color(0xFF2296F3);
  static const Color blueBright = Color(0xFF42AAFE);
  static const Color blueMid = Color(0xFF1A7ED4);
  static const Color amber = Color(0xFFFFB300);
  static const Color amberLight = Color(0xFFFFF3D0);
  static const Color teal = Color(0xFF00D4C8);
  static const Color green = Color(0xFF22C55E);
  static const Color textDark = Color(0xFF0F2040);
  static const Color textDarkMuted = Color(0xFF4A6A8A);

  // ── Getters dynamiques (utilisent isDark) ─────────────────────────────────
  Color get bg => _isDark ? darkBg : lightBg;
  Color get bgSection => _isDark ? darkBgSection : lightBgSection;
  Color get bgCard => _isDark ? darkBgCard : lightBgCard;
  Color get border => _isDark ? darkBorder : lightBorder;
  Color get borderBright => _isDark ? darkBorderBright : lightBorderBright;
  Color get textPrimary => _isDark ? darkTextPrimary : lightTextPrimary;
  Color get textSecond => _isDark ? darkTextSecond : lightTextSecond;
  Color get textMuted => _isDark ? darkTextMuted : lightTextMuted;

  // Sections alternées
  Color get sectionLight => _isDark ? darkBgSection : const Color(0xFFF0F6FF);
  Color get sectionLightAlt => _isDark ? darkBg : const Color(0xFFE8F4FE);

  // Hero gradient
  List<Color> get heroGradient => _isDark
      ? [
          const Color(0xFF0A1628),
          const Color(0xFF0D3060),
          const Color(0xFF1565C0)
        ]
      : [appBlue, blueMid, const Color(0xFF0A3070)];

  // Top bar bg
  Color get topBarBg => _isDark ? darkBg : appBlue;
  // Top bar text/icons
  Color get topBarText => Colors.white;
  // Outline button border
  Color get outlineBorder =>
      _isDark ? darkBorderBright : Colors.white.withValues(alpha: 0.5);
}
