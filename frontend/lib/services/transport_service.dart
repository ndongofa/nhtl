// lib/services/transport_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:sama/config/api_config.dart';
import '../models/transport.dart';
import 'auth_service.dart';
import '../models/logged_user.dart';

class TransportService {
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

  String get userEndpoint => ApiConfig.transportEndpoint; // "/api/transports"
  // ✅ URL admin corrigée — correspond à TransportAdminController
  String get adminEndpoint => "/api/admin/transports";

  // ── Créer un transport ────────────────────────────────────────────────────
  Future<Transport?> createTransport(Transport transport) async {
    try {
      final url = '${ApiConfig.baseUrl}$userEndpoint';
      final headers = await _headers();
      logger.i('POST $url');

      final response = await http
          .post(Uri.parse(url),
              headers: headers, body: jsonEncode(transport.toJson()))
          .timeout(ApiConfig.connectTimeout);

      logger.i('Status: ${response.statusCode}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body);
        logger.i('✅ Transport créé');
        return Transport.fromJson(json is Map<String, dynamic> ? json : {});
      }
      logger.e('❌ Erreur: ${response.statusCode} ${response.body}');
      return null;
    } catch (e) {
      logger.e('❌ Exception: $e');
      return null;
    }
  }

  // ── Récupérer tous les transports ─────────────────────────────────────────
  Future<List<Transport>?> getAllTransports() async {
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
        logger.i('✅ Transports récupérés');
        return data.map((t) => Transport.fromJson(t)).toList();
      }
      logger.e('❌ Erreur: ${response.statusCode}');
      return null;
    } catch (e) {
      logger.e('❌ Exception: $e');
      return null;
    }
  }

  Future<List<Transport>?> getAllTransportsForUser(String userId) async {
    try {
      final url = '${ApiConfig.baseUrl}$userEndpoint';
      final headers = await _headers();
      logger.i('GET $url [USER]');

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(ApiConfig.receiveTimeout);

      logger.i('Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> data =
            decoded is List ? decoded : (decoded['data'] ?? decoded);
        logger.i('✅ Transports récupérés (user)');
        return data.map((t) => Transport.fromJson(t)).toList();
      }
      logger.e('❌ Erreur: ${response.statusCode}');
      return null;
    } catch (e) {
      logger.e('❌ Exception: $e');
      return null;
    }
  }

  Future<Transport?> getTransportById(int id) async {
    final url = '${ApiConfig.baseUrl}$userEndpoint/$id';
    try {
      final headers = await _headers();
      logger.i('GET $url');

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(ApiConfig.receiveTimeout);

      logger.i('Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        logger.i('✅ Transport $id récupéré');
        return Transport.fromJson(json is Map<String, dynamic> ? json : {});
      }
      logger.e('❌ Erreur: ${response.statusCode}');
      return null;
    } catch (e) {
      logger.e('❌ Exception: $e');
      return null;
    }
  }

  // ✅ Admin — récupère un transport par ID via l'endpoint admin
  // (inclut tous les champs : photoColisUrl, deposePosteAt, etc.)
  Future<Transport?> getTransportByIdAdmin(int id) async {
    final url = '${ApiConfig.baseUrl}$adminEndpoint/$id';
    try {
      final headers = await _headers();
      logger.i('GET [ADMIN] $url');
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(ApiConfig.receiveTimeout);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        logger.i('✅ Transport admin $id récupéré');
        return Transport.fromJson(json is Map<String, dynamic> ? json : {});
      }
      logger.e('❌ getTransportByIdAdmin ${response.statusCode}');
      return null;
    } catch (e) {
      logger.e('❌ getTransportByIdAdmin exception: $e');
      return null;
    }
  }

  Future<Transport?> updateTransport(int id, Transport transport) async {
    final url = isAdmin
        ? '${ApiConfig.baseUrl}$adminEndpoint/$id'
        : '${ApiConfig.baseUrl}$userEndpoint/$id';
    try {
      final headers = await _headers();
      logger.i('PUT $url');

      final response = await http
          .put(Uri.parse(url),
              headers: headers, body: jsonEncode(transport.toJson()))
          .timeout(ApiConfig.connectTimeout);

      logger.i('Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        logger.i('✅ Transport $id mis à jour');
        return Transport.fromJson(json is Map<String, dynamic> ? json : {});
      }
      logger.e('❌ Erreur: ${response.statusCode}');
      return null;
    } catch (e) {
      logger.e('❌ Exception: $e');
      return null;
    }
  }

  Future<bool> deleteTransport(int id) async {
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
        logger.i('✅ Transport $id supprimé');
        return true;
      }
      logger.e('❌ Erreur: ${response.statusCode}');
      return false;
    } catch (e) {
      logger.e('❌ Exception: $e');
      return false;
    }
  }

  // ── Archivage ─────────────────────────────────────────────────────────────
  Future<bool> archiveTransport(int id) async {
    final url = isAdmin
        ? '${ApiConfig.baseUrl}$adminEndpoint/$id/archive'
        : '${ApiConfig.baseUrl}$userEndpoint/$id/archive';
    try {
      final headers = await _headers();
      logger.i('PATCH $url [ARCHIVE]');

      final response = await http
          .patch(Uri.parse(url), headers: headers)
          .timeout(ApiConfig.connectTimeout);

      logger.i('Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        logger.i('✅ Transport $id archivé');
        return true;
      }
      logger.e('❌ Erreur archivage: ${response.statusCode}');
      return false;
    } catch (e) {
      logger.e('❌ Exception archivage: $e');
      return false;
    }
  }

  Future<bool> unarchiveTransportAdmin(int id) async {
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
        logger.i('✅ Transport $id désarchivé');
        return true;
      }
      logger.e('❌ Erreur désarchivage: ${response.statusCode}');
      return false;
    } catch (e) {
      logger.e('❌ Exception désarchivage: $e');
      return false;
    }
  }

  // ── Statut ADMINISTRATIF — sans notifications ─────────────────────────────
  // Correspond à PATCH /api/admin/transports/{id}/statut (TransportAdminController)
  Future<bool> changeTransportStatut(int id, String newStatut) async {
    if (!isAdmin) return false;
    // ✅ URL corrigée : /api/admin/transports/{id}/statut
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
        logger.i('✅ Statut admin → $newStatut pour transport $id');
        return true;
      }
      logger
          .e('❌ Erreur statut admin: ${response.statusCode} ${response.body}');
      return false;
    } catch (e) {
      logger.e('❌ Exception statut admin: $e');
      return false;
    }
  }

  // ── Statut LOGISTIQUE — avec notifications ────────────────────────────────
  // Correspond à PATCH /api/admin/transports/{id}/status (TransportStatusController)
  Future<bool> updateStatutSuivi(int id, String newStatus) async {
    if (!isAdmin) {
      logger.w('⛔ updateStatutSuivi: accès refusé (non admin)');
      return false;
    }
    final url = '${ApiConfig.baseUrl}$adminEndpoint/$id/status';
    try {
      final headers = await _headers();
      logger.i('PATCH $url [STATUT-SUIVI=$newStatus]');

      final response = await http
          .patch(Uri.parse(url),
              headers: headers, body: jsonEncode({'status': newStatus}))
          .timeout(ApiConfig.connectTimeout);

      logger.i('Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        logger.i('✅ StatutSuivi → $newStatus pour transport $id');
        return true;
      }
      logger.e('❌ Erreur statutSuivi: ${response.statusCode} ${response.body}');
      return false;
    } catch (e) {
      logger.e('❌ Exception updateStatutSuivi: $e');
      return false;
    }
  }

  // ── Recherche par statut ──────────────────────────────────────────────────
  Future<List<Transport>?> getTransportsByStatut(String statut) async {
    final encoded = Uri.encodeQueryComponent(statut);
    final url = isAdmin
        ? '${ApiConfig.baseUrl}$adminEndpoint/search/statut?statut=$encoded'
        : '${ApiConfig.baseUrl}$userEndpoint/search/statut?statut=$encoded';
    try {
      final headers = await _headers();
      logger.i('GET $url');

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(ApiConfig.receiveTimeout);

      logger.i('Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List<dynamic> data = json is List ? json : (json['data'] ?? json);
        logger.i('✅ Transports par statut récupérés');
        return data.map((t) => Transport.fromJson(t)).toList();
      }
      logger.e('❌ Erreur: ${response.statusCode}');
      return null;
    } catch (e) {
      logger.e('❌ Exception: $e');
      return null;
    }
  }

  // ── Archives ──────────────────────────────────────────────────────────────
  Future<List<Transport>?> getTransportsArchivesUser() async {
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
        logger.i('✅ Archives user récupérées');
        return data.map((t) => Transport.fromJson(t)).toList();
      }
      logger.e('❌ Erreur archives user: ${response.statusCode}');
      return null;
    } catch (e) {
      logger.e('❌ Exception archives user: $e');
      return null;
    }
  }

  Future<List<Transport>?> getTransportsArchivesAdmin() async {
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
        logger.i('✅ Archives admin récupérées');
        return data.map((t) => Transport.fromJson(t)).toList();
      }
      logger.e('❌ Erreur archives admin: ${response.statusCode}');
      return null;
    } catch (e) {
      logger.e('❌ Exception archives admin: $e');
      return null;
    }
  }

  // ── Statuts possibles ─────────────────────────────────────────────────────
  Future<List<String>?> getStatutsTransports() async {
    try {
      final url = '${ApiConfig.baseUrl}/api/statuts-transports';
      final headers = await _headers();
      logger.i('GET $url [STATUTS]');

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(ApiConfig.receiveTimeout);

      logger.i('Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> data =
            decoded is List ? decoded : (decoded['data'] ?? decoded);
        logger.i('✅ Statuts récupérés');
        return data.map((s) => s.toString()).toList();
      }
      logger.e('❌ Erreur statuts: ${response.statusCode}');
      return null;
    } catch (e) {
      logger.e('❌ Exception statuts: $e');
      return null;
    }
  }
}
