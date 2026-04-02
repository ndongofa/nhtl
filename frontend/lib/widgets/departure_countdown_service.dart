// lib/services/departure_countdown_service.dart
// Service partagé : compte à rebours automatique qui passe au départ suivant
// quand le délai est écoulé. Utilisé par landing_screen et home_screen.
//
// Usage :
//   final svc = DepartureCountdownService();
//   svc.start(() => setState(() {}));
//   // Lire : svc.currentDeparture, svc.remaining, svc.currentIndex
//   // Disposer : svc.dispose()

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
  // ── Liste complète des départs par ordre chronologique ──────────────────────
  static final List<Departure> allDepartures = [
    Departure(
      date: '23 mars 2026',
      dateTime: DateTime(2026, 3, 23, 8, 0),
      route: 'Dakar → Paris',
      flag: '🇸🇳🇫🇷',
    ),
    Departure(
      date: '23 mars 2026',
      dateTime: DateTime(2026, 3, 23, 14, 0),
      route: 'Dakar → Casablanca',
      flag: '🇸🇳🇲🇦',
    ),
    Departure(
      date: '25 mars 2026',
      dateTime: DateTime(2026, 3, 25, 10, 0),
      route: 'Casablanca → Paris',
      flag: '🇲🇦🇫🇷',
    ),
    Departure(
      date: '28 avril 2026',
      dateTime: DateTime(2026, 4, 28, 9, 0),
      route: 'Paris → Casablanca',
      flag: '🇫🇷🇲🇦',
    ),
    Departure(
      date: '29 avril 2026',
      dateTime: DateTime(2026, 4, 29, 11, 0),
      route: 'Casablanca → Dakar',
      flag: '🇲🇦🇸🇳',
    ),
  ];

  int _currentIndex = 0;
  Duration _remaining = Duration.zero;
  Timer? _timer;

  // ── Accesseurs ───────────────────────────────────────────────────────────────
  int get currentIndex => _currentIndex;
  Duration get remaining => _remaining;
  Departure get currentDeparture => allDepartures[_currentIndex];
  bool get isExpired => _remaining == Duration.zero;

  // ── Démarre le service ───────────────────────────────────────────────────────
  void start(void Function() onTick) {
    // Trouver le prochain départ à venir
    _currentIndex = _findNextDeparture();
    _updateRemaining();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();

      // ✅ Départ écoulé → passe automatiquement au suivant
      if (_remaining == Duration.zero) {
        _goToNextDeparture();
      }

      onTick();
    });

    // Premier tick immédiat
    onTick();
  }

  // ── Trouve l'index du prochain départ à venir ────────────────────────────────
  int _findNextDeparture() {
    final now = DateTime.now();
    for (int i = 0; i < allDepartures.length; i++) {
      if (allDepartures[i].dateTime.isAfter(now)) return i;
    }
    // Tous passés → on reste sur le dernier
    return allDepartures.length - 1;
  }

  // ── Met à jour le temps restant ──────────────────────────────────────────────
  void _updateRemaining() {
    final now = DateTime.now();
    final diff = allDepartures[_currentIndex].dateTime.difference(now);
    _remaining = diff.isNegative ? Duration.zero : diff;
  }

  // ── Passe au départ suivant ──────────────────────────────────────────────────
  void _goToNextDeparture() {
    if (_currentIndex < allDepartures.length - 1) {
      _currentIndex++;
      _updateRemaining();
    }
    // Si dernier départ → reste à 00:00:00:00
  }

  // ── Helpers formatage ─────────────────────────────────────────────────────────
  String get days => _remaining.inDays.toString().padLeft(2, '0');
  String get hours => (_remaining.inHours % 24).toString().padLeft(2, '0');
  String get minutes => (_remaining.inMinutes % 60).toString().padLeft(2, '0');
  String get seconds => (_remaining.inSeconds % 60).toString().padLeft(2, '0');

  // ── Dispose ──────────────────────────────────────────────────────────────────
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
