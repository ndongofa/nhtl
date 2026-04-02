import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:sama/config/api_config.dart';
import '../models/app_notification.dart';
import '../services/auth_service.dart';

class NotificationService {
  final logger = Logger();

  Future<Map<String, String>> _headers() async {
    final jwt = await AuthService.getJwt();
    if (jwt == null) throw Exception("Non authentifié");
    return {
      'Authorization': 'Bearer $jwt',
      'Content-Type': 'application/json',
    };
  }

  Future<List<AppNotification>> getMyNotifications() async {
    final headers = await _headers();
    final url = '${ApiConfig.baseUrl}/api/notifications';
    logger.i('GET $url');

    final res = await http.get(Uri.parse(url), headers: headers);
    if (res.statusCode != 200) {
      logger.e('❌ get notifications failed: ${res.statusCode} ${res.body}');
      throw Exception("Erreur chargement notifications");
    }

    final decoded = jsonDecode(res.body);
    final List<dynamic> list =
        decoded is List ? decoded : (decoded['data'] ?? []);
    return list
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markRead(int id) async {
    final headers = await _headers();
    final url = '${ApiConfig.baseUrl}/api/notifications/$id/read';
    logger.i('PATCH $url');

    final res = await http.patch(Uri.parse(url), headers: headers);
    if (res.statusCode != 200) {
      logger.e('❌ mark read failed: ${res.statusCode} ${res.body}');
      throw Exception("Erreur: impossible de marquer comme lu");
    }
  }

  /// ✅ Supprimer une notification par ID
  Future<void> deleteNotification(int id) async {
    final headers = await _headers();
    final url = '${ApiConfig.baseUrl}/api/notifications/$id';
    logger.i('DELETE $url');

    final res = await http.delete(Uri.parse(url), headers: headers);
    if (res.statusCode != 200 && res.statusCode != 204) {
      logger.e('❌ delete notification failed: ${res.statusCode} ${res.body}');
      throw Exception("Erreur: impossible de supprimer la notification");
    }
  }

  /// ✅ Supprimer toutes les notifications de l'utilisateur connecté
  Future<void> deleteAllNotifications() async {
    final headers = await _headers();
    final url = '${ApiConfig.baseUrl}/api/notifications';
    logger.i('DELETE $url (all)');

    final res = await http.delete(Uri.parse(url), headers: headers);
    if (res.statusCode != 200 && res.statusCode != 204) {
      logger.e(
          '❌ delete all notifications failed: ${res.statusCode} ${res.body}');
      throw Exception("Erreur: impossible de supprimer les notifications");
    }
  }
}
