// lib/services/departure_countdown_service.dart
//
// ✅ Charge les départs depuis l'API (plus hardcodés)
// ✅ Fallback silencieux si l'API est indisponible
// ✅ 3-4 prochains départs s'alternent (toutes les 5s)
// ✅ Groupement par jour + swipe manuel inter-jours
// ✅ Ticker filtré départs à venir uniquement

import 'dart:async';
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

class DepartureCountdownService {
  final _api = DepartureApiService();

  List<Departure> _loaded = [];

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

  List<List<Departure>> _groups = [];
  int _groupIndex = 0;
  int _inGroupIndex = 0;
  Duration _remaining = Duration.zero;
  Timer? _countdownTimer;
  Timer? _autoSwitchTimer;

  List<Departure> get sameDayGroup {
    if (_groups.isEmpty || _groupIndex >= _groups.length) return [];
    return _groups[_groupIndex];
  }

  int get sameDayCount => sameDayGroup.length;
  int get inGroupIndex => _inGroupIndex;
  int get groupIndex => _groupIndex; // ✅ index du groupe actif
  int get groupCount => _groups.length; // ✅ total groupes (jours distincts)
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

  Future<void> loadDepartures() async {
    try {
      final models = await _api.getPublicNext();
      if (models.isNotEmpty) {
        _loaded = models.map((m) => Departure.fromModel(m)).toList();
      }
    } catch (_) {}
  }

  void start(void Function() onTick) {
    loadDepartures().then((_) {
      _buildGroups();
      _updateRemaining();
      onTick();
    });

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

    // ✅ Alternance auto 5s — même jour ET inter-groupes (3-4 prochains)
    _autoSwitchTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (sameDayCount > 1) {
        _inGroupIndex = (_inGroupIndex + 1) % sameDayCount;
        onTick();
      } else if (_groups.length > 1) {
        _groupIndex = (_groupIndex + 1) % _groups.length;
        _inGroupIndex = 0;
        _updateRemaining();
        onTick();
      }
    });

    onTick();
  }

  Future<void> reload(void Function() onTick) async {
    await loadDepartures();
    _groupIndex = 0;
    _inGroupIndex = 0;
    _buildGroups();
    _updateRemaining();
    onTick();
  }

  void nextSameDay(void Function() onTick) {
    if (sameDayCount > 1) {
      _inGroupIndex = (_inGroupIndex + 1) % sameDayCount;
    } else if (_groups.length > 1) {
      _groupIndex = (_groupIndex + 1) % _groups.length;
      _inGroupIndex = 0;
      _updateRemaining();
    }
    onTick();
  }

  void prevSameDay(void Function() onTick) {
    if (sameDayCount > 1) {
      _inGroupIndex = (_inGroupIndex - 1 + sameDayCount) % sameDayCount;
    } else if (_groups.length > 1) {
      _groupIndex = (_groupIndex - 1 + _groups.length) % _groups.length;
      _inGroupIndex = 0;
      _updateRemaining();
    }
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
