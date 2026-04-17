// lib/services/ad_api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:sama/config/api_config.dart';
import '../models/ad_model.dart';
import 'auth_service.dart';

class AdApiService {
  final _log = Logger();

  static const _headers = {'Content-Type': 'application/json'};

  Future<Map<String, String>> _authHeaders() async {
    final jwt = await AuthService.getJwt();
    if (jwt == null) throw Exception('Non authentifié');
    return {
      'Authorization': 'Bearer $jwt',
      'Content-Type': 'application/json',
    };
  }

  // ── PUBLIC — carousel ─────────────────────────────────────────────────────
  // Returns null when the request fails (network error, non-200 status), so
  // callers can distinguish "no active ads" (empty list) from "request failed"
  // (null) and avoid overwriting a previously loaded ad list with stale data.
  Future<List<AdModel>?> getPublicAds({String? serviceType}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/ads/public').replace(
      queryParameters: serviceType != null && serviceType.isNotEmpty
          ? {'serviceType': serviceType}
          : null,
    );
    try {
      _log.i('GET $uri [ADS PUBLIC]');
      final res = await http
          .get(uri, headers: _headers)
          .timeout(ApiConfig.receiveTimeout);
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        return list.map((e) => AdModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      _log.e('❌ getPublicAds: ${res.statusCode}');
      return null;
    } catch (e) {
      _log.e('❌ getPublicAds exception: $e');
      return null;
    }
  }

  // ── ADMIN — CRUD ──────────────────────────────────────────────────────────
  Future<List<AdModel>> adminGetAll() async {
    final url = '${ApiConfig.baseUrl}/api/admin/ads';
    try {
      final headers = await _authHeaders();
      final res = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(ApiConfig.receiveTimeout);
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        return list.map((e) => AdModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      _log.e('❌ adminGetAll ads: ${res.statusCode}');
      return [];
    } catch (e) {
      _log.e('❌ adminGetAll ads exception: $e');
      return [];
    }
  }

  Future<AdModel?> adminCreate(AdModel ad) async {
    final url = '${ApiConfig.baseUrl}/api/admin/ads';
    try {
      final headers = await _authHeaders();
      final res = await http
          .post(Uri.parse(url), headers: headers, body: jsonEncode(ad.toJson()))
          .timeout(ApiConfig.connectTimeout);
      if (res.statusCode == 200) return AdModel.fromJson(jsonDecode(res.body));
      _log.e('❌ adminCreate ad: ${res.statusCode} ${res.body}');
      return null;
    } catch (e) {
      _log.e('❌ adminCreate ad exception: $e');
      return null;
    }
  }

  Future<AdModel?> adminUpdate(int id, AdModel ad) async {
    final url = '${ApiConfig.baseUrl}/api/admin/ads/$id';
    try {
      final headers = await _authHeaders();
      final res = await http
          .put(Uri.parse(url), headers: headers, body: jsonEncode(ad.toJson()))
          .timeout(ApiConfig.connectTimeout);
      if (res.statusCode == 200) return AdModel.fromJson(jsonDecode(res.body));
      _log.e('❌ adminUpdate ad: ${res.statusCode}');
      return null;
    } catch (e) {
      _log.e('❌ adminUpdate ad exception: $e');
      return null;
    }
  }

  Future<bool> adminDelete(int id) async {
    final url = '${ApiConfig.baseUrl}/api/admin/ads/$id';
    try {
      final headers = await _authHeaders();
      final res = await http
          .delete(Uri.parse(url), headers: headers)
          .timeout(ApiConfig.connectTimeout);
      return res.statusCode == 200;
    } catch (e) {
      _log.e('❌ adminDelete ad exception: $e');
      return false;
    }
  }

  Future<bool> adminToggle(int id) async {
    final url = '${ApiConfig.baseUrl}/api/admin/ads/$id/toggle';
    try {
      final headers = await _authHeaders();
      final res = await http
          .patch(Uri.parse(url), headers: headers)
          .timeout(ApiConfig.connectTimeout);
      return res.statusCode == 200;
    } catch (e) {
      _log.e('❌ adminToggle ad exception: $e');
      return false;
    }
  }
}
