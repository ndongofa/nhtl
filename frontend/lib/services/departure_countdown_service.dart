// lib/services/departure_countdown_service.dart
// Compte à rebours partagé landing + home.
// Passe automatiquement au départ suivant quand le délai est écoulé.

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

  static List<Departure> get upcomingDepartures {
    final now = DateTime.now();
    return allDepartures.where((d) => d.dateTime.isAfter(now)).toList();
  }

  int _currentIndex = 0;
  Duration _remaining = Duration.zero;
  Timer? _timer;

  int get currentIndex => _currentIndex;
  Duration get remaining => _remaining;
  Departure get currentDeparture => allDepartures[_currentIndex];
  bool get isExpired => _remaining == Duration.zero;
  bool get hasMore => _currentIndex < allDepartures.length - 1;

  String get days => _remaining.inDays.toString().padLeft(2, '0');
  String get hours => (_remaining.inHours % 24).toString().padLeft(2, '0');
  String get minutes => (_remaining.inMinutes % 60).toString().padLeft(2, '0');
  String get seconds => (_remaining.inSeconds % 60).toString().padLeft(2, '0');

  void start(void Function() onTick) {
    _currentIndex = _findNext();
    _update();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _update();
      // ✅ Départ écoulé → passe automatiquement au suivant
      if (_remaining == Duration.zero && hasMore) {
        _currentIndex++;
        _update();
      }
      onTick();
    });
    onTick();
  }

  int _findNext() {
    final now = DateTime.now();
    for (int i = 0; i < allDepartures.length; i++) {
      if (allDepartures[i].dateTime.isAfter(now)) return i;
    }
    return allDepartures.length - 1;
  }

  void _update() {
    final diff =
        allDepartures[_currentIndex].dateTime.difference(DateTime.now());
    _remaining = diff.isNegative ? Duration.zero : diff;
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
