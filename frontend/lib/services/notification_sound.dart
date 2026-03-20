import 'package:flutter/foundation.dart';

import 'notification_sound_stub.dart'
    if (dart.library.html) 'notification_sound_web.dart';

class NotificationSound {
  NotificationSound._();

  static Future<void> playAlert() async {
    try {
      if (kIsWeb) {
        playNotificationSound();
      }
    } catch (e) {
      print('[NotificationSound] error: $e');
    }
  }
}
