// lib/services/achat_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:sama/config/api_config.dart';
import '../models/achat.dart';
import 'auth_service.dart';
import '../models/logged_user.dart';

class AchatService {
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

  LoggedUser? get logged => LoggedUser.fromSupabase();
  bool get isAdmin => logged?.role == 'admin';

  String get userEndpoint => ApiConfig.achatEndpoint; // "/api/achats"
  String get adminEndpoint => "/api/admin/achats";

  // ── Créer un achat ────────────────────────────────────────────────────────
  Future<Achat?> createAchat(Achat achat) async {
    try {
      final url = '${ApiConfig.baseUrl}$userEndpoint';
      final headers = await _headers();
      logger.i('POST $url');

      final response = await http
          .post(Uri.parse(url),
              headers: headers, body: jsonEncode(achat.toJson()))
          .timeout(ApiConfig.connectTimeout);

      logger.i('Status: ${response.statusCode}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body);
        logger.i('✅ Achat créé');
        return Achat.fromJson(json is Map<String, dynamic> ? json : {});
      }
      logger.e('❌ Erreur: ${response.statusCode} ${response.body}');
      return null;
    } catch (e) {
      logger.e('❌ Exception: $e');
      return null;
    }
  }

  // ── Récupérer tous les achats ──────────────────────────────────────────────
  Future<List<Achat>?> getAllAchats() async {
    try {
      final url = isAdmin
          ? '${ApiConfig.baseUrl}$adminEndpoint/all'
          : '${ApiConfig.baseUrl}$userEndpoint';
      final headers = await _headers();
      logger.i('GET $url');

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(ApiConfig.receiveTimeout);

      logger.i('Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> data =
            decoded is List ? decoded : (decoded['data'] ?? decoded);
        logger.i('✅ Achats récupérés');
        return data.map((a) => Achat.fromJson(a)).toList();
      }
      logger.e('❌ Erreur: ${response.statusCode}');
      return null;
    } catch (e) {
      logger.e('❌ Exception: $e');
      return null;
    }
  }

  // ── Mettre à jour un achat ────────────────────────────────────────────────
  Future<Achat?> updateAchat(Achat achat) async {
    final url = isAdmin
        ? '${ApiConfig.baseUrl}$adminEndpoint/${achat.id}'
        : '${ApiConfig.baseUrl}$userEndpoint/${achat.id}';
    try {
      final headers = await _headers();
      logger.i('PUT $url');

      final response = await http
          .put(Uri.parse(url),
              headers: headers, body: jsonEncode(achat.toJson()))
          .timeout(ApiConfig.connectTimeout);

      logger.i('Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        logger.i('✅ Achat ${achat.id} mis à jour');
        return Achat.fromJson(json is Map<String, dynamic> ? json : {});
      }
      logger.e('❌ Erreur: ${response.statusCode}');
      return null;
    } catch (e) {
      logger.e('❌ Exception: $e');
      return null;
    }
  }

  // ── Supprimer un achat ────────────────────────────────────────────────────
  Future<bool> deleteAchat(int id) async {
    final url = isAdmin
        ? '${ApiConfig.baseUrl}$adminEndpoint/$id'
        : '${ApiConfig.baseUrl}$userEndpoint/$id';
    try {
      final headers = await _headers();
      logger.i('DELETE $url');

      final response = await http
          .delete(Uri.parse(url), headers: headers)
          .timeout(ApiConfig.connectTimeout);

      logger.i('Status: ${response.statusCode}');
      if (response.statusCode == 200 || response.statusCode == 204) {
        logger.i('✅ Achat $id supprimé');
        return true;
      }
      logger.e('❌ Erreur: ${response.statusCode}');
      return false;
    } catch (e) {
      logger.e('❌ Exception: $e');
      return false;
    }
  }

  // ── Archiver ──────────────────────────────────────────────────────────────
  Future<bool> archiveAchat(int id) async {
    if (!isAdmin) return false;
    final url = '${ApiConfig.baseUrl}$adminEndpoint/$id/archive';
    try {
      final headers = await _headers();
      logger.i('PATCH $url [ARCHIVE]');

      final response = await http
          .patch(Uri.parse(url), headers: headers)
          .timeout(ApiConfig.connectTimeout);

      logger.i('Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        logger.i('✅ Achat $id archivé');
        return true;
      }
      logger.e('❌ Erreur archivage: ${response.statusCode}');
      return false;
    } catch (e) {
      logger.e('❌ Exception archivage: $e');
      return false;
    }
  }

  // ── Désarchiver (admin uniquement) ────────────────────────────────────────
  Future<bool> unarchiveAchatAdmin(int id) async {
    if (!isAdmin) return false;
    final url = '${ApiConfig.baseUrl}$adminEndpoint/$id/unarchive';
    try {
      final headers = await _headers();
      logger.i('PATCH $url [UNARCHIVE]');

      final response = await http
          .patch(Uri.parse(url), headers: headers)
          .timeout(ApiConfig.connectTimeout);

      logger.i('Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        logger.i('✅ Achat $id désarchivé');
        return true;
      }
      logger.e('❌ Erreur désarchivage: ${response.statusCode}');
      return false;
    } catch (e) {
      logger.e('❌ Exception désarchivage: $e');
      return false;
    }
  }

  // ── Statut ADMINISTRATIF ──────────────────────────────────────────────────
  Future<bool> changeAchatStatut(int id, String newStatut) async {
    if (!isAdmin) return false;
    final url = '${ApiConfig.baseUrl}$adminEndpoint/$id/statut';
    try {
      final headers = await _headers();
      logger.i('PATCH $url [STATUT-ADMIN=$newStatut]');

      final response = await http
          .patch(Uri.parse(url),
              headers: headers, body: jsonEncode({'statut': newStatut}))
          .timeout(ApiConfig.connectTimeout);

      logger.i('Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        logger.i('✅ Statut admin achat $id → $newStatut');
        return true;
      }
      logger.e('❌ Erreur statut admin: ${response.statusCode} ${response.body}');
      return false;
    } catch (e) {
      logger.e('❌ Exception statut admin: $e');
      return false;
    }
  }

  // Alias pour compatibilité avec AchatsArchivesScreen
  Future<bool> changeStatutAchatAdmin(int id, String newStatut) =>
      changeAchatStatut(id, newStatut);

  // ── Récupérer un achat par ID ─────────────────────────────────────────────
  Future<Achat?> getAchatById(int id) async {
    try {
      final jwt = await AuthService.getJwt();
      if (jwt == null) return null;
      final url = '${ApiConfig.baseUrl}/api/achats/$id';
      final response = await http.get(Uri.parse(url), headers: {
        'Authorization': 'Bearer $jwt',
        'Content-Type': 'application/json',
      }).timeout(ApiConfig.receiveTimeout);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return Achat.fromJson(json is Map<String, dynamic> ? json : {});
      }
      logger.e('❌ getAchatById $id : ${response.statusCode}');
      return null;
    } catch (e) {
      logger.e('❌ getAchatById exception: $e');
      return null;
    }
  }

  // ── Admin — récupère un achat par ID ──────────────────────────────────────
  Future<Achat?> getAchatByIdAdmin(int id) async {
    try {
      final jwt = await AuthService.getJwt();
      if (jwt == null) return null;
      final url = '${ApiConfig.baseUrl}/api/admin/achats/$id';
      final response = await http.get(Uri.parse(url), headers: {
        'Authorization': 'Bearer $jwt',
        'Content-Type': 'application/json',
      }).timeout(ApiConfig.receiveTimeout);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return Achat.fromJson(json is Map<String, dynamic> ? json : {});
      }
      logger.e('❌ getAchatByIdAdmin ${response.statusCode}');
      return null;
    } catch (e) {
      logger.e('❌ getAchatByIdAdmin exception: $e');
      return null;
    }
  }

  // ── Archives utilisateur ──────────────────────────────────────────────────
  Future<List<Achat>?> getAchatsArchivesUser() async {
    try {
      final url = '${ApiConfig.baseUrl}$userEndpoint/archives';
      final headers = await _headers();
      logger.i('GET $url [ARCHIVES user]');

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(ApiConfig.receiveTimeout);

      logger.i('Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> data =
            decoded is List ? decoded : (decoded['data'] ?? decoded);
        logger.i('✅ Archives achats user récupérées');
        return data.map((a) => Achat.fromJson(a)).toList();
      }
      logger.e('❌ Erreur archives user: ${response.statusCode}');
      return null;
    } catch (e) {
      logger.e('❌ Exception archives user: $e');
      return null;
    }
  }

  // ── Archives admin ────────────────────────────────────────────────────────
  Future<List<Achat>?> getAchatsArchivesAdmin() async {
    if (!isAdmin) return null;
    try {
      final url = '${ApiConfig.baseUrl}$adminEndpoint/archives';
      final headers = await _headers();
      logger.i('GET $url [ARCHIVES admin]');

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(ApiConfig.receiveTimeout);

      logger.i('Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> data =
            decoded is List ? decoded : (decoded['data'] ?? decoded);
        logger.i('✅ Archives achats admin récupérées');
        return data.map((a) => Achat.fromJson(a)).toList();
      }
      logger.e('❌ Erreur archives admin: ${response.statusCode}');
      return null;
    } catch (e) {
      logger.e('❌ Exception archives admin: $e');
      return null;
    }
  }

  // ── Statuts possibles ─────────────────────────────────────────────────────
  Future<List<String>?> getStatutsAchats() async {
    // Statuts prédéfinis (pas d'endpoint dédié côté backend)
    return const ["EN_ATTENTE", "EN_COURS", "LIVRE", "ANNULE"];
  }
}
