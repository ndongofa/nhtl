// lib/services/departure_api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:sama/config/api_config.dart';
import '../models/departure_model.dart';
import 'auth_service.dart';

class DepartureApiService {
  final _log = Logger();

  Future<Map<String, String>> _authHeaders() async {
    final jwt = await AuthService.getJwt();
    if (jwt == null) throw Exception('Non authentifié');
    return {
      'Authorization': 'Bearer $jwt',
      'Content-Type': 'application/json',
    };
  }

  static const _headers = {'Content-Type': 'application/json'};

  // ── PUBLIC — landing + home (pas de JWT requis) ───────────────────────────

  // 3-4 prochains publiés pour le compte à rebours
  Future<List<DepartureModel>> getPublicNext() async {
    final url = '${ApiConfig.baseUrl}/api/departures/public';
    try {
      _log.i('GET $url [PUBLIC NEXT]');
      final res = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(ApiConfig.receiveTimeout);
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        return list.map((e) => DepartureModel.fromJson(e)).toList();
      }
      _log.e('❌ getPublicNext: ${res.statusCode}');
      return [];
    } catch (e) {
      _log.e('❌ getPublicNext exception: $e');
      return [];
    }
  }

  // Tous les publiés — section "Tous les départs"
  Future<List<DepartureModel>> getAllPublic() async {
    final url = '${ApiConfig.baseUrl}/api/departures/public/all';
    try {
      _log.i('GET $url [PUBLIC ALL]');
      final res = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(ApiConfig.receiveTimeout);
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        return list.map((e) => DepartureModel.fromJson(e)).toList();
      }
      _log.e('❌ getAllPublic: ${res.statusCode}');
      return [];
    } catch (e) {
      _log.e('❌ getAllPublic exception: $e');
      return [];
    }
  }

  // ── ADMIN — CRUD complet ──────────────────────────────────────────────────

  Future<List<DepartureModel>> adminGetAll() async {
    final url = '${ApiConfig.baseUrl}/api/admin/departures';
    try {
      _log.i('GET $url [ADMIN ALL]');
      final headers = await _authHeaders();
      final res = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(ApiConfig.receiveTimeout);
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        return list.map((e) => DepartureModel.fromJson(e)).toList();
      }
      _log.e('❌ adminGetAll: ${res.statusCode}');
      return [];
    } catch (e) {
      _log.e('❌ adminGetAll exception: $e');
      return [];
    }
  }

  Future<DepartureModel?> adminCreate(DepartureModel departure) async {
    final url = '${ApiConfig.baseUrl}/api/admin/departures';
    try {
      _log.i('POST $url [ADMIN CREATE]');
      final headers = await _authHeaders();
      final res = await http
          .post(Uri.parse(url),
              headers: headers, body: jsonEncode(departure.toJson()))
          .timeout(ApiConfig.connectTimeout);
      if (res.statusCode == 200) {
        _log.i('✅ Départ créé');
        return DepartureModel.fromJson(jsonDecode(res.body));
      }
      _log.e('❌ adminCreate: ${res.statusCode} ${res.body}');
      return null;
    } catch (e) {
      _log.e('❌ adminCreate exception: $e');
      return null;
    }
  }

  Future<DepartureModel?> adminUpdate(int id, DepartureModel departure) async {
    final url = '${ApiConfig.baseUrl}/api/admin/departures/$id';
    try {
      _log.i('PUT $url [ADMIN UPDATE]');
      final headers = await _authHeaders();
      final res = await http
          .put(Uri.parse(url),
              headers: headers, body: jsonEncode(departure.toJson()))
          .timeout(ApiConfig.connectTimeout);
      if (res.statusCode == 200) {
        _log.i('✅ Départ $id mis à jour');
        return DepartureModel.fromJson(jsonDecode(res.body));
      }
      _log.e('❌ adminUpdate: ${res.statusCode} ${res.body}');
      return null;
    } catch (e) {
      _log.e('❌ adminUpdate exception: $e');
      return null;
    }
  }

  Future<bool> adminDelete(int id) async {
    final url = '${ApiConfig.baseUrl}/api/admin/departures/$id';
    try {
      _log.i('DELETE $url [ADMIN DELETE]');
      final headers = await _authHeaders();
      final res = await http
          .delete(Uri.parse(url), headers: headers)
          .timeout(ApiConfig.connectTimeout);
      if (res.statusCode == 200) {
        _log.i('✅ Départ $id supprimé');
        return true;
      }
      _log.e('❌ adminDelete: ${res.statusCode}');
      return false;
    } catch (e) {
      _log.e('❌ adminDelete exception: $e');
      return false;
    }
  }

  // Publier, archiver, repasser en brouillon
  Future<bool> adminChangeStatus(int id, String status) async {
    final url = '${ApiConfig.baseUrl}/api/admin/departures/$id/status';
    try {
      _log.i('PATCH $url [STATUS=$status]');
      final headers = await _authHeaders();
      final res = await http
          .patch(Uri.parse(url),
              headers: headers, body: jsonEncode({'status': status}))
          .timeout(ApiConfig.connectTimeout);
      if (res.statusCode == 200) {
        _log.i('✅ Statut départ $id → $status');
        return true;
      }
      _log.e('❌ adminChangeStatus: ${res.statusCode} ${res.body}');
      return false;
    } catch (e) {
      _log.e('❌ adminChangeStatus exception: $e');
      return false;
    }
  }
}
