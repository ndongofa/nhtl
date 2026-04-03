import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../models/app_notification.dart';
import 'auth_service.dart';
import 'notification_service.dart';
import 'notification_sound.dart';

class NotificationPollingService extends ChangeNotifier {
  static const Duration _pollInterval = Duration(seconds: 30);

  final _api = NotificationService();
  final _logger = Logger();

  Timer? _timer;
  List<AppNotification> _notifications = [];
  int _previousUnreadCount = 0;

  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void start() {
    _timer?.cancel();
    _poll();
    _timer = Timer.periodic(_pollInterval, (_) => _poll());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> refresh() => _poll();

  Future<void> _poll() async {
    if (!AuthService.isLoggedIn()) {
      if (_notifications.isNotEmpty) {
        _notifications = [];
        _previousUnreadCount = 0;
        notifyListeners();
      }
      return;
    }
    try {
      final data = await _api.getMyNotifications();
      final newUnreadCount = data.where((n) => !n.isRead).length;
      if (newUnreadCount > _previousUnreadCount) {
        await NotificationSound.playAlert();
      }
      _previousUnreadCount = newUnreadCount;
      _notifications = data;
      notifyListeners();
    } catch (e) {
      _logger.w('[NotificationPollingService] poll failed: $e');
    }
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
