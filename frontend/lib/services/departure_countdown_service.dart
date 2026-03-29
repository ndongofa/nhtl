// lib/services/departure_countdown_service.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'departure_api_service.dart';
import '../models/departure_model.dart';

class Departure {
  final String date;
  final DateTime dateTime;
  final String route;
  final String flag;
  final int? id;

  const Departure({
    required this.date,
    required this.dateTime,
    required this.route,
    required this.flag,
    this.id,
  });

  factory Departure.fromModel(DepartureModel m) => Departure(
        date: m.dateLabel,
        dateTime: m.departureDateTime,
        route: m.route,
        flag: m.flagEmoji,
        id: m.id,
      );
}

// ✅ ChangeNotifier — les écrans se rebuildent automatiquement
class DepartureCountdownService extends ChangeNotifier {
  final _api = DepartureApiService();

  List<Departure> _loaded = [];

  // Fallback si l'API est indisponible
  static final List<Departure> _fallback = [
    Departure(
        date: '28 avril 2026',
        dateTime: DateTime(2026, 4, 28, 9, 0),
        route: 'Paris → Casablanca',
        flag: '🇫🇷🇲🇦'),
    Departure(
        date: '29 avril 2026',
        dateTime: DateTime(2026, 4, 29, 11, 0),
        route: 'Casablanca → Dakar',
        flag: '🇲🇦🇸🇳'),
  ];

  List<Departure> get allDepartures => _loaded.isNotEmpty ? _loaded : _fallback;

  List<Departure> get upcomingDepartures {
    final now = DateTime.now();
    return allDepartures.where((d) => d.dateTime.isAfter(now)).toList();
  }

  // ── État interne ──────────────────────────────────────────────────────────
  List<List<Departure>> _groups = [];
  int _groupIndex = 0;
  int _inGroupIndex = 0;
  Duration _remaining = Duration.zero;
  Timer? _countdownTimer;
  Timer? _autoSwitchTimer;
  Timer? _refreshTimer; // ✅ rechargement API toutes les 5 minutes

  // ── Accesseurs ────────────────────────────────────────────────────────────
  List<Departure> get sameDayGroup {
    if (_groups.isEmpty || _groupIndex >= _groups.length) return [];
    return _groups[_groupIndex];
  }

  int get sameDayCount => sameDayGroup.length;
  int get inGroupIndex => _inGroupIndex;
  int get groupIndex => _groupIndex;
  int get groupCount => _groups.length;
  bool get isExpired => _remaining == Duration.zero && _groups.isEmpty;
  Duration get remaining => _remaining;

  Departure get currentDeparture {
    if (_groups.isEmpty) {
      final up = upcomingDepartures;
      return up.isNotEmpty ? up.first : _fallback.last;
    }
    final g = _groups[_groupIndex];
    return g[_inGroupIndex.clamp(0, g.length - 1)];
  }

  String get days => _remaining.inDays.toString().padLeft(2, '0');
  String get hours => (_remaining.inHours % 24).toString().padLeft(2, '0');
  String get minutes => (_remaining.inMinutes % 60).toString().padLeft(2, '0');
  String get seconds => (_remaining.inSeconds % 60).toString().padLeft(2, '0');

  // ── Chargement API ────────────────────────────────────────────────────────
  Future<void> loadDepartures() async {
    try {
      final models = await _api.getPublicNext();
      if (models.isNotEmpty) {
        _loaded = models.map((m) => Departure.fromModel(m)).toList();
        _buildGroups();
        _updateRemaining();
        notifyListeners(); // ✅ notifie les widgets après chaque chargement
      }
    } catch (_) {}
  }

  // ── Démarrage ─────────────────────────────────────────────────────────────
  void start() {
    // Charge immédiatement
    loadDepartures();

    // Tick 1s — compte à rebours
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
      if (_remaining == Duration.zero && _groups.isNotEmpty) {
        _groups[_groupIndex]
            .removeWhere((d) => !d.dateTime.isAfter(DateTime.now()));
        if (_groups[_groupIndex].isEmpty) {
          _groups.removeAt(_groupIndex);
          if (_groupIndex >= _groups.length && _groupIndex > 0) _groupIndex--;
          _inGroupIndex = 0;
        }
        _buildGroups();
        _updateRemaining();
      }
      notifyListeners();
    });

    // Alternance auto 5s entre départs
    _autoSwitchTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (sameDayCount > 1) {
        _inGroupIndex = (_inGroupIndex + 1) % sameDayCount;
        notifyListeners();
      } else if (_groups.length > 1) {
        _groupIndex = (_groupIndex + 1) % _groups.length;
        _inGroupIndex = 0;
        _updateRemaining();
        notifyListeners();
      }
    });

    // ✅ Rechargement API toutes les 5 minutes — capte les nouveaux départs publiés
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      loadDepartures();
    });
  }

  // ✅ Rechargement manuel — appelé après publication admin
  Future<void> reload() async {
    await loadDepartures();
    _groupIndex = 0;
    _inGroupIndex = 0;
    _buildGroups();
    _updateRemaining();
    notifyListeners();
  }

  void nextSameDay() {
    if (sameDayCount > 1) {
      _inGroupIndex = (_inGroupIndex + 1) % sameDayCount;
    } else if (_groups.length > 1) {
      _groupIndex = (_groupIndex + 1) % _groups.length;
      _inGroupIndex = 0;
      _updateRemaining();
    }
    notifyListeners();
  }

  void prevSameDay() {
    if (sameDayCount > 1) {
      _inGroupIndex = (_inGroupIndex - 1 + sameDayCount) % sameDayCount;
    } else if (_groups.length > 1) {
      _groupIndex = (_groupIndex - 1 + _groups.length) % _groups.length;
      _inGroupIndex = 0;
      _updateRemaining();
    }
    notifyListeners();
  }

  void _buildGroups() {
    final now = DateTime.now();
    final upcoming =
        allDepartures.where((d) => d.dateTime.isAfter(now)).toList();
    _groups = [];
    String? lastDate;
    for (final dep in upcoming) {
      if (dep.date != lastDate) {
        _groups.add([dep]);
        lastDate = dep.date;
      } else {
        _groups.last.add(dep);
      }
    }
    if (_groups.isNotEmpty && _groupIndex >= _groups.length) _groupIndex = 0;
    if (sameDayCount > 0 && _inGroupIndex >= sameDayCount) _inGroupIndex = 0;
  }

  void _updateRemaining() {
    if (_groups.isEmpty) {
      _remaining = Duration.zero;
      return;
    }
    final target = _groups[_groupIndex].first.dateTime;
    final diff = target.difference(DateTime.now());
    _remaining = diff.isNegative ? Duration.zero : diff;
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _autoSwitchTimer?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }
}
