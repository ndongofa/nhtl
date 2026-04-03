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

// ✅ ChangeNotifier — les écrans se rebuildent automatiquement via context.watch
class DepartureCountdownService extends ChangeNotifier {
  final _api = DepartureApiService();

  // ── Deux listes distinctes ────────────────────────────────────────────────
  // _nextLoaded  : 3-4 prochains publiés → compte à rebours + ticker
  // _allLoaded   : TOUS les publiés (passés + à venir) → section "Tous les départs"
  List<Departure> _nextLoaded = [];
  List<Departure> _allLoaded = [];

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
    Departure(
        date: '15 mai 2026',
        dateTime: DateTime(2026, 5, 15, 10, 0),
        route: 'Dakar → Paris',
        flag: '🇸🇳🇫🇷'),
    Departure(
        date: '20 mai 2026',
        dateTime: DateTime(2026, 5, 20, 14, 0),
        route: 'Paris → Dakar',
        flag: '🇫🇷🇸🇳'),
  ];

  // ✅ allDepartures — utilisé pour la section "Tous les départs" (passés inclus)
  List<Departure> get allDepartures =>
      _allLoaded.isNotEmpty ? _allLoaded : _fallback;

  // ✅ upcomingDepartures — utilisé pour le ticker (départs à venir uniquement)
  List<Departure> get upcomingDepartures {
    final now = DateTime.now();
    return allDepartures.where((d) => d.dateTime.isAfter(now)).toList();
  }

  // ── État interne du compte à rebours ─────────────────────────────────────
  // _groups : groupes des prochains départs (1 groupe = 1 jour)
  List<List<Departure>> _groups = [];
  int _groupIndex = 0;
  int _inGroupIndex = 0;
  Duration _remaining = Duration.zero;
  Timer? _countdownTimer;
  Timer? _autoSwitchTimer;
  Timer? _refreshTimer;

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
      // Fallback : premier à venir dans allDepartures
      final up = upcomingDepartures;
      return up.isNotEmpty ? up.first : _fallback.first;
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
      // Appel 1 : 3-4 prochains → pour le compte à rebours
      final nextModels = await _api.getPublicNext();
      if (nextModels.isNotEmpty) {
        _nextLoaded = nextModels.map(Departure.fromModel).toList();
      }

      // Appel 2 : TOUS les publiés → pour la section "Tous les départs"
      final allModels = await _api.getAllPublic();
      if (allModels.isNotEmpty) {
        _allLoaded = allModels.map(Departure.fromModel).toList();
      }

      // Reconstruire les groupes depuis _nextLoaded (prochains seulement)
      _buildGroups();
      _updateRemaining();
      notifyListeners();
    } catch (e) {
      debugPrint('[DepartureCountdownService] loadDepartures error: $e');
    }
  }

  // ── Démarrage ─────────────────────────────────────────────────────────────
  void start() {
    loadDepartures();

    // Tick 1s — compte à rebours
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
      // Retirer les départs expirés du groupe courant (indépendant de _remaining)
      if (_groups.isNotEmpty &&
          !_groups[_groupIndex].first.dateTime.isAfter(DateTime.now())) {
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

    // ✅ Alternance auto toutes les 5s entre les prochains départs
    // Parcourt TOUS les départs dans l'ordre : d'abord les départs du même jour,
    // puis passe au jour suivant — fonctionne dans tous les cas.
    _autoSwitchTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_groups.isEmpty) return;
      final totalDepartures =
          _groups.fold<int>(0, (sum, g) => sum + g.length);
      if (totalDepartures <= 1) return; // Un seul départ : rien à cycler

      // Avancer dans le groupe courant, ou passer au groupe suivant
      _inGroupIndex++;
      if (_inGroupIndex >= sameDayCount) {
        _inGroupIndex = 0;
        _groupIndex = (_groupIndex + 1) % _groups.length;
      }
      _updateRemaining();
      notifyListeners();
    });

    // Rechargement API toutes les 5 minutes
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      loadDepartures();
    });
  }

  // ✅ Rechargement manuel — à appeler depuis AdminDeparturesScreen après publication
  Future<void> reload() async {
    await loadDepartures();
    _groupIndex = 0;
    _inGroupIndex = 0;
    _buildGroups();
    _updateRemaining();
    notifyListeners();
  }

  void nextSameDay() {
    if (_groups.isEmpty) return;
    if (sameDayCount > 1) {
      _inGroupIndex = (_inGroupIndex + 1) % sameDayCount;
    } else if (_groups.length > 1) {
      _groupIndex = (_groupIndex + 1) % _groups.length;
      _inGroupIndex = 0;
    }
    _updateRemaining();
    notifyListeners();
  }

  void prevSameDay() {
    if (_groups.isEmpty) return;
    if (sameDayCount > 1) {
      _inGroupIndex = (_inGroupIndex - 1 + sameDayCount) % sameDayCount;
    } else if (_groups.length > 1) {
      _groupIndex = (_groupIndex - 1 + _groups.length) % _groups.length;
      _inGroupIndex = 0;
    }
    _updateRemaining();
    notifyListeners();
  }

  // ── Helpers internes ──────────────────────────────────────────────────────

  void _buildGroups() {
    final now = DateTime.now();

    // ✅ Les groupes se construisent depuis _nextLoaded (prochains) ou fallback
    // — PAS depuis allDepartures qui inclut les passés
    final source = _nextLoaded.isNotEmpty ? _nextLoaded : _fallback;
    final upcoming = source.where((d) => d.dateTime.isAfter(now)).toList();

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

    // Garder les indices valides
    if (_groups.isNotEmpty && _groupIndex >= _groups.length) _groupIndex = 0;
    if (sameDayCount > 0 && _inGroupIndex >= sameDayCount) _inGroupIndex = 0;
  }

  void _updateRemaining() {
    if (_groups.isEmpty) {
      _remaining = Duration.zero;
      return;
    }
    // Compte à rebours vers le départ ACTUELLEMENT affiché
    final target = currentDeparture.dateTime;
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
