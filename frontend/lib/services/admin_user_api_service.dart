import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:sama/services/auth_service.dart';
import 'package:sama/config/ApiConfig_dev.dart';

class AdminUserApiService {
  final logger = Logger();

  Future<Map<String, String>> _headers() async {
    final jwt = await AuthService.getJwt();
    if (jwt == null) {
      logger.e('JWT absent: utilisateur non connecté ?');
      throw Exception("Non authentifié");
    }
    return {
      'Authorization': 'Bearer $jwt',
      'Content-Type': 'application/json',
    };
  }

  Future<bool> createUser({
    required String identifier,
    required String password,
    required String prenom,
    required String nom,
    required String role,
  }) async {
    final url = '${ApiConfig.baseUrl}${ApiConfig.adminUserEndpoint}';
    final headers = await _headers();

    final res = await http
        .post(
          Uri.parse(url),
          headers: headers,
          body: jsonEncode({
            'identifier': identifier,
            'password': password,
            'prenom': prenom,
            'nom': nom,
            'role': role,
          }),
        )
        .timeout(ApiConfig.connectTimeout);

    logger.i('POST $url -> ${res.statusCode}');
    if (res.statusCode >= 200 && res.statusCode < 300) return true;

    logger.e('Body: ${res.body}');
    throw Exception(
      res.body.isNotEmpty ? res.body : 'Erreur création utilisateur (admin)',
    );
  }

  Future<bool> updateUser({
    required String supabaseUserId,
    String? email,
    String? phone,
    String? prenom,
    String? nom,
    String? role,
  }) async {
    final url =
        '${ApiConfig.baseUrl}${ApiConfig.adminUserEndpoint}/$supabaseUserId';
    final headers = await _headers();

    final payload = <String, dynamic>{};
    if (email != null) payload['email'] = email;
    if (phone != null) payload['phone'] = phone;
    if (prenom != null) payload['prenom'] = prenom;
    if (nom != null) payload['nom'] = nom;
    if (role != null) payload['role'] = role;

    final res = await http
        .patch(
          Uri.parse(url),
          headers: headers,
          body: jsonEncode(payload),
        )
        .timeout(ApiConfig.connectTimeout);

    logger.i('PATCH $url -> ${res.statusCode}');
    if (res.statusCode >= 200 && res.statusCode < 300) return true;

    logger.e('Body: ${res.body}');
    throw Exception(
      res.body.isNotEmpty
          ? res.body
          : 'Erreur modification utilisateur (admin)',
    );
  }

  Future<bool> deleteUser({required String supabaseUserId}) async {
    final url =
        '${ApiConfig.baseUrl}${ApiConfig.adminUserEndpoint}/$supabaseUserId';
    final headers = await _headers();

    final res = await http
        .delete(Uri.parse(url), headers: headers)
        .timeout(ApiConfig.connectTimeout);

    logger.i('DELETE $url -> ${res.statusCode}');
    if (res.statusCode == 204 ||
        (res.statusCode >= 200 && res.statusCode < 300)) {
      return true;
    }

    logger.e('Body: ${res.body}');
    throw Exception(
      res.body.isNotEmpty ? res.body : 'Erreur suppression utilisateur (admin)',
    );
  }

  Future<bool> resetPassword({
    required String supabaseUserId,
    required String newPassword,
  }) async {
    final url =
        '${ApiConfig.baseUrl}${ApiConfig.adminUserEndpoint}/$supabaseUserId/reset-password';
    final headers = await _headers();

    final res = await http
        .post(
          Uri.parse(url),
          headers: headers,
          body: jsonEncode({'newPassword': newPassword}),
        )
        .timeout(ApiConfig.connectTimeout);

    logger.i('POST $url [reset-password] -> ${res.statusCode}');
    if (res.statusCode >= 200 && res.statusCode < 300) return true;

    logger.e('Body: ${res.body}');
    throw Exception(
      res.body.isNotEmpty ? res.body : 'Erreur reset password (admin)',
    );
  }
}
