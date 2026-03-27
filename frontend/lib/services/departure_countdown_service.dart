// lib/services/departure_countdown_service.dart
//
// ✅ Compte à rebours vers le prochain départ à venir
// ✅ Groupement par jour — alternance auto 5s entre départs du même jour
// ✅ Swipe manuel nextSameDay() / prevSameDay()
// ✅ Ticker : uniquement les départs à venir (passés filtrés)
// ✅ Passage auto au groupe suivant quand tous écoulés

import 'dart:async';

class Departure {
  final String date;
  final DateTime dateTime;
  final String route;
  final String flag;

  const Departure({
    required this.date,
    required this.dateTime,
    required this.route,
    required this.flag,
  });
}

class DepartureCountdownService {
  static final List<Departure> allDepartures = [
    Departure(
        date: '23 mars 2026',
        dateTime: DateTime(2026, 3, 23, 8, 0),
        route: 'Dakar → Paris',
        flag: '🇸🇳🇫🇷'),
    Departure(
        date: '23 mars 2026',
        dateTime: DateTime(2026, 3, 23, 14, 0),
        route: 'Dakar → Casablanca',
        flag: '🇸🇳🇲🇦'),
    Departure(
        date: '25 mars 2026',
        dateTime: DateTime(2026, 3, 25, 10, 0),
        route: 'Casablanca → Paris',
        flag: '🇲🇦🇫🇷'),
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

  // ✅ Uniquement les départs à venir — pour le ruban ticker
  static List<Departure> get upcomingDepartures {
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

  // ── Accesseurs ────────────────────────────────────────────────────────────
  List<Departure> get sameDayGroup {
    if (_groups.isEmpty || _groupIndex >= _groups.length) return [];
    return _groups[_groupIndex];
  }

  int get sameDayCount => sameDayGroup.length;
  int get inGroupIndex => _inGroupIndex;
  bool get isExpired => _remaining == Duration.zero && _groups.isEmpty;
  Duration get remaining => _remaining;

  Departure get currentDeparture {
    if (_groups.isEmpty) return allDepartures.last;
    final g = _groups[_groupIndex];
    return g[_inGroupIndex.clamp(0, g.length - 1)];
  }

  String get days => _remaining.inDays.toString().padLeft(2, '0');
  String get hours => (_remaining.inHours % 24).toString().padLeft(2, '0');
  String get minutes => (_remaining.inMinutes % 60).toString().padLeft(2, '0');
  String get seconds => (_remaining.inSeconds % 60).toString().padLeft(2, '0');

  // ── Démarrage ─────────────────────────────────────────────────────────────
  void start(void Function() onTick) {
    _buildGroups();
    _updateRemaining();

    // Tick 1s — mise à jour + passage auto au groupe suivant
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
      onTick();
    });

    // ✅ Alternance auto 5s entre départs du même jour
    _autoSwitchTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (sameDayCount > 1) {
        _inGroupIndex = (_inGroupIndex + 1) % sameDayCount;
        onTick();
      }
    });

    onTick();
  }

  // ✅ Swipe manuel suivant (même jour)
  void nextSameDay(void Function() onTick) {
    if (sameDayCount <= 1) return;
    _inGroupIndex = (_inGroupIndex + 1) % sameDayCount;
    onTick();
  }

  // ✅ Swipe manuel précédent (même jour)
  void prevSameDay(void Function() onTick) {
    if (sameDayCount <= 1) return;
    _inGroupIndex = (_inGroupIndex - 1 + sameDayCount) % sameDayCount;
    onTick();
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

  void dispose() {
    _countdownTimer?.cancel();
    _autoSwitchTimer?.cancel();
  }
}
