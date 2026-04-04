// lib/providers/app_theme_provider.dart
//
// ✅ Provider thème clair/sombre/auto — clair par défaut
// ✅ Mode auto : suit le thème système (Approche C) avec fallback GPS lever/coucher du soleil (Approche A)
// ✅ Toggle 3 états : Clair → Sombre → Auto → Clair
// ✅ Persistance du choix via SharedPreferences
// ✅ Tous les getters utilisés dans landing, home, transport_tracking
// ✅ Constantes statiques accessibles sans instance

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Les 3 modes de thème disponibles
enum AppThemeMode { light, dark, auto }

class AppThemeProvider extends ChangeNotifier with WidgetsBindingObserver {
  AppThemeMode _mode = AppThemeMode.light;
  bool _systemIsDark = false;
  bool _sunIsDark = false;
  double? _latitude;
  double? _longitude;
  Timer? _autoTimer;

  // ── Mode courant ─────────────────────────────────────────────────────────
  AppThemeMode get mode => _mode;

  // ── isDark calculé selon le mode actif ───────────────────────────────────
  bool get isDark {
    switch (_mode) {
      case AppThemeMode.light:
        return false;
      case AppThemeMode.dark:
        return true;
      case AppThemeMode.auto:
        // GPS dispo → lever/coucher du soleil; sinon → thème système
        return (_latitude != null && _longitude != null)
            ? _sunIsDark
            : _systemIsDark;
    }
  }

  // ── Icône et tooltip pour l'UI ───────────────────────────────────────────
  IconData get themeIcon {
    switch (_mode) {
      case AppThemeMode.light:
        return Icons.wb_sunny_outlined;
      case AppThemeMode.dark:
        return Icons.nightlight_round;
      case AppThemeMode.auto:
        return Icons.brightness_auto;
    }
  }

  String get themeTooltip {
    switch (_mode) {
      case AppThemeMode.light:
        return "Thème clair";
      case AppThemeMode.dark:
        return "Thème sombre";
      case AppThemeMode.auto:
        return "Mode auto";
    }
  }

  // ── Initialisation asynchrone (SharedPreferences + WidgetsBinding) ───────
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final idx = prefs.getInt('theme_mode') ?? 0;
    _mode = AppThemeMode.values[idx.clamp(0, AppThemeMode.values.length - 1)];
    _latitude = prefs.getDouble('theme_lat');
    _longitude = prefs.getDouble('theme_lon');

    WidgetsBinding.instance.addObserver(this);
    _systemIsDark =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark;

    if (_mode == AppThemeMode.auto) {
      _startAutoMode();
    }
    notifyListeners();
  }

  // ── Changer de mode ───────────────────────────────────────────────────────
  void setMode(AppThemeMode newMode) {
    _mode = newMode;
    _persistMode();
    if (newMode == AppThemeMode.auto) {
      _startAutoMode();
    } else {
      _stopAutoMode();
    }
    notifyListeners();
  }

  /// Cycle : Clair → Sombre → Auto → Clair
  void toggleTheme() {
    switch (_mode) {
      case AppThemeMode.light:
        setMode(AppThemeMode.dark);
        break;
      case AppThemeMode.dark:
        setMode(AppThemeMode.auto);
        break;
      case AppThemeMode.auto:
        setMode(AppThemeMode.light);
        break;
    }
  }

  // ── WidgetsBindingObserver : suit la luminosité du système ───────────────
  @override
  void didChangePlatformBrightness() {
    final bright =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final nowDark = bright == Brightness.dark;
    if (_systemIsDark != nowDark) {
      _systemIsDark = nowDark;
      if (_mode == AppThemeMode.auto) notifyListeners();
    }
  }

  // ── Mode auto : timer + GPS ───────────────────────────────────────────────
  void _startAutoMode() {
    _checkAutoTheme();
    _autoTimer?.cancel();
    _autoTimer =
        Timer.periodic(const Duration(minutes: 1), (_) => _checkAutoTheme());
    _refreshLocation();
  }

  void _stopAutoMode() {
    _autoTimer?.cancel();
    _autoTimer = null;
  }

  Future<void> _checkAutoTheme() async {
    if (_latitude == null || _longitude == null) return;
    final now = DateTime.now().toUtc();
    final times = _computeSunriseSunset(_latitude!, _longitude!, now);
    if (times == null) return;
    final (sunrise, sunset) = times;
    final wasDark = _sunIsDark;
    _sunIsDark = now.isBefore(sunrise) || now.isAfter(sunset);
    if (wasDark != _sunIsDark && _mode == AppThemeMode.auto) {
      notifyListeners();
    }
  }

  Future<void> _refreshLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.low),
      ).timeout(const Duration(seconds: 10));
      _latitude = pos.latitude;
      _longitude = pos.longitude;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('theme_lat', _latitude!);
      await prefs.setDouble('theme_lon', _longitude!);
      await _checkAutoTheme();
    } catch (_) {
      // Pas de GPS : le mode auto utilise le thème système
    }
  }

  Future<void> _persistMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', _mode.index);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoTimer?.cancel();
    super.dispose();
  }

  // ── Calcul lever/coucher du soleil (algorithme NOAA simplifié) ───────────
  /// Retourne (sunrise UTC, sunset UTC) ou null (nuit polaire / soleil de minuit)
  (DateTime, DateTime)? _computeSunriseSunset(
      double lat, double lon, DateTime utcDate) {
    final jd = _julianDate(utcDate.year, utcDate.month, utcDate.day);

    // Midi solaire approché (jours juliens)
    final noonApprox = jd + 0.0009 - lon / 360.0;

    // Anomalie moyenne (degrés)
    final M = (357.5291 + 0.98560028 * (noonApprox - 2451545.0)) % 360.0;
    final Mrad = M * pi / 180.0;

    // Équation du centre
    final C = 1.9148 * sin(Mrad) +
        0.0200 * sin(2 * Mrad) +
        0.0003 * sin(3 * Mrad);

    // Longitude écliptique
    final lambda = (M + C + 180.0 + 102.9372) % 360.0;
    final lambdaRad = lambda * pi / 180.0;

    // Transit solaire
    final Jtransit =
        noonApprox + 0.0053 * sin(Mrad) - 0.0069 * sin(2 * lambdaRad);

    // Déclinaison du Soleil
    final sinDec = sin(lambdaRad) * sin(23.4397 * pi / 180.0);
    final cosDec = cos(asin(sinDec));

    // Angle horaire (élévation -0.8333° = coucher apparent)
    final latRad = lat * pi / 180.0;
    final cosH = (sin(-0.8333 * pi / 180.0) - sin(latRad) * sinDec) /
        (cos(latRad) * cosDec);

    if (cosH > 1 || cosH < -1) return null; // nuit polaire ou soleil minuit

    final H = acos(cosH) * 180.0 / pi;
    return (
      _julianToDateTime(Jtransit - H / 360.0),
      _julianToDateTime(Jtransit + H / 360.0),
    );
  }

  double _julianDate(int year, int month, int day) {
    final a = (14 - month) ~/ 12;
    final y = year + 4800 - a;
    final m = month + 12 * a - 3;
    return (day + (153 * m + 2) ~/ 5 + 365 * y + y ~/ 4 - y ~/ 100 +
            y ~/ 400 -
            32045)
        .toDouble();
  }

  DateTime _julianToDateTime(double jd) {
    final jdInt = jd.floor();
    final frac = jd - jdInt;
    var l = jdInt + 68569;
    final n = (4 * l) ~/ 146097;
    l = l - (146097 * n + 3) ~/ 4;
    final i = (4000 * (l + 1)) ~/ 1461001;
    l = l - (1461 * i) ~/ 4 + 31;
    final j = (80 * l) ~/ 2447;
    final day = l - (2447 * j) ~/ 80;
    l = j ~/ 11;
    final month = j + 2 - 12 * l;
    final year = 100 * (n - 49) + i + l;
    final totalSec = (frac * 86400).round();
    return DateTime.utc(year, month, day, totalSec ~/ 3600,
        (totalSec % 3600) ~/ 60, totalSec % 60);
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
  Color get bg => isDark ? const Color(0xFF0D1117) : const Color(0xFFF4F8FF);

  /// Fond des cartes / containers
  Color get bgCard => isDark ? const Color(0xFF161B22) : Colors.white;

  /// Fond des sections alternées (légèrement différent de bg)
  Color get bgSection =>
      isDark ? const Color(0xFF13191F) : const Color(0xFFEEF4FF);

  /// Section claire (tarifs, pricing)
  Color get sectionLight =>
      isDark ? const Color(0xFF0F1419) : const Color(0xFFF0F7FF);

  /// Section claire alternative (contact)
  Color get sectionLightAlt =>
      isDark ? const Color(0xFF111620) : const Color(0xFFF5F0FF);

  // ── Top bar ───────────────────────────────────────────────────────────────

  /// Fond de la top bar — toujours coloré (bleu nuit sombre / bleu app clair)
  Color get topBarBg => isDark ? const Color(0xFF0A1628) : appBlue;

  // ── Texte ─────────────────────────────────────────────────────────────────

  Color get textPrimary =>
      isDark ? const Color(0xFFE6EDF3) : const Color(0xFF0F2040);

  Color get textMuted =>
      isDark ? const Color(0xFF8B949E) : const Color(0xFF6B7A99);

  // ── Bordures ──────────────────────────────────────────────────────────────

  Color get border =>
      isDark ? const Color(0xFF30363D) : const Color(0xFFDDE3EF);

  /// Bordure plus visible (focus, cartes actives)
  Color get borderBright =>
      isDark ? const Color(0xFF3D4752) : const Color(0xFFC5D0E8);

  // ── Hero gradient (landing) ───────────────────────────────────────────────

  /// 3 couleurs pour le gradient animé du hero
  List<Color> get heroGradient => isDark
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
