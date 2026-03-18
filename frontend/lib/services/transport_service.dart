import 'package:http/http.dart' as http;
import 'package:sama/config/api_config.dart';
import 'dart:convert';
import '../models/transport.dart';
import 'package:logger/logger.dart';
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
  String get adminEndpoint => "/admin/transports";

  // Créer un transport (toujours user)
  Future<Transport?> createTransport(Transport transport) async {
    try {
      final url = '${ApiConfig.baseUrl}$userEndpoint';
      logger.i('POST $url');
      final headers = await _headers();

      final response = await http
          .post(
            Uri.parse(url),
            headers: headers,
            body: jsonEncode(transport.toJson()),
          )
          .timeout(ApiConfig.connectTimeout);

      logger.i('Status: ${response.statusCode}');
      logger.i('Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body);
        logger.i('✅ Transport créé avec succès');
        return Transport.fromJson(json is Map<String, dynamic> ? json : {});
      } else {
        logger.e('❌ Erreur: ${response.statusCode}');
        logger.e('Body: ${response.body}');
        return null;
      }
    } catch (e) {
      logger.e('❌ Exception: $e');
      return null;
    }
  }

  // Récupérer tous les transports de l'utilisateur/admin
  Future<List<Transport>?> getAllTransports() async {
    try {
      final url = isAdmin
          ? '${ApiConfig.baseUrl}$adminEndpoint/all'
          : '${ApiConfig.baseUrl}$userEndpoint';
      logger.i('GET $url');
      final headers = await _headers();

      final response = await http
          .get(
            Uri.parse(url),
            headers: headers,
          )
          .timeout(ApiConfig.receiveTimeout);

      logger.i('Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> data =
            decoded is List ? decoded : (decoded['data'] ?? decoded);
        logger.i('✅ Transports récupérés');
        return data.map((t) => Transport.fromJson(t)).toList();
      } else {
        logger.e('❌ Erreur: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      logger.e('❌ Exception: $e');
      return null;
    }
  }

  // Récupérer tous les transports pour un userId spécifique
  //
  // NOTE: ton backend /api/transports ignore ce param (il renvoie les transports du principal).
  // On garde quand même la méthode pour compat, mais tu peux juste appeler getAllTransports() côté user.
  Future<List<Transport>?> getAllTransportsForUser(String userId) async {
    try {
      final url = '${ApiConfig.baseUrl}$userEndpoint?userId=$userId';
      logger.i('GET $url [USER SPECIFIC]');
      final headers = await _headers();

      final response = await http
          .get(
            Uri.parse(url),
            headers: headers,
          )
          .timeout(ApiConfig.receiveTimeout);

      logger.i('Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> data =
            decoded is List ? decoded : (decoded['data'] ?? decoded);
        logger.i('✅ Transports récupérés (par utilisateur)');
        return data.map((t) => Transport.fromJson(t)).toList();
      } else {
        logger.e('❌ Erreur: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      logger.e('❌ Exception: $e');
      return null;
    }
  }

  // Récupérer un transport par ID
  //
  // NOTE: backend actuel n'a pas de GET /admin/transports/{id}
  // donc en admin ça fera 404. On garde l'accès via endpoint user.
  Future<Transport?> getTransportById(int id) async {
    final url = '${ApiConfig.baseUrl}$userEndpoint/$id';
    try {
      logger.i('GET $url');
      final headers = await _headers();

      final response = await http
          .get(
            Uri.parse(url),
            headers: headers,
          )
          .timeout(ApiConfig.receiveTimeout);

      logger.i('Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        logger.i('✅ Transport $id récupéré');
        return Transport.fromJson(json is Map<String, dynamic> ? json : {});
      } else {
        logger.e('❌ Erreur: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      logger.e('❌ Exception: $e');
      return null;
    }
  }

  // Mettre à jour un transport (user ou admin)
  Future<Transport?> updateTransport(int id, Transport transport) async {
    final url = isAdmin
        ? '${ApiConfig.baseUrl}$adminEndpoint/$id'
        : '${ApiConfig.baseUrl}$userEndpoint/$id';
    try {
      logger.i('PUT $url');
      final headers = await _headers();

      final response = await http
          .put(
            Uri.parse(url),
            headers: headers,
            body: jsonEncode(transport.toJson()),
          )
          .timeout(ApiConfig.connectTimeout);

      logger.i('Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        logger.i('✅ Transport $id mis à jour');
        return Transport.fromJson(json is Map<String, dynamic> ? json : {});
      } else {
        logger.e('❌ Erreur: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      logger.e('❌ Exception: $e');
      return null;
    }
  }

  // Supprimer un transport (user ou admin)
  Future<bool> deleteTransport(int id) async {
    final url = isAdmin
        ? '${ApiConfig.baseUrl}$adminEndpoint/$id'
        : '${ApiConfig.baseUrl}$userEndpoint/$id';
    try {
      logger.i('DELETE $url');
      final headers = await _headers();

      final response = await http
          .delete(
            Uri.parse(url),
            headers: headers,
          )
          .timeout(ApiConfig.connectTimeout);

      logger.i('Status: ${response.statusCode}');
      if (response.statusCode == 200 || response.statusCode == 204) {
        logger.i('✅ Transport $id supprimé');
        return true;
      } else {
        logger.e('❌ Erreur: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      logger.e('❌ Exception: $e');
      return false;
    }
  }

  // --- ARCHIVAGE : pour admin ET user ---

  /// Archive un transport.
  Future<bool> archiveTransport(int id) async {
    final url = isAdmin
        ? '${ApiConfig.baseUrl}$adminEndpoint/$id/archive'
        : '${ApiConfig.baseUrl}$userEndpoint/$id/archive';
    try {
      logger.i('PATCH $url [ARCHIVE]');
      final headers = await _headers();
      final response = await http
          .patch(
            Uri.parse(url),
            headers: headers,
          )
          .timeout(ApiConfig.connectTimeout);
      logger.i('Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        logger.i('✅ Transport $id archivé');
        return true;
      } else {
        logger.e('❌ Erreur archivage: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      logger.e('❌ Exception archivage: $e');
      return false;
    }
  }

  /// Désarchive un transport (admin uniquement)
  Future<bool> unarchiveTransportAdmin(int id) async {
    if (!isAdmin) return false;
    try {
      final url = '${ApiConfig.baseUrl}$adminEndpoint/$id/unarchive';
      logger.i('PATCH $url [UNARCHIVE]');
      final headers = await _headers();

      final response = await http
          .patch(
            Uri.parse(url),
            headers: headers,
          )
          .timeout(ApiConfig.connectTimeout);

      logger.i('Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        logger.i('✅ Transport $id désarchivé');
        return true;
      } else {
        logger.e('❌ Erreur désarchivage: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      logger.e('❌ Exception désarchivage: $e');
      return false;
    }
  }

  // --- CHANGEMENT DE STATUT : pour admin ET user ---

  /// Change le statut d'un transport.
  Future<bool> changeTransportStatut(int id, String newStatut) async {
    final url = isAdmin
        ? '${ApiConfig.baseUrl}$adminEndpoint/$id/statut'
        : '${ApiConfig.baseUrl}$userEndpoint/$id/statut';
    try {
      logger.i('PATCH $url [STATUT]');
      final headers = await _headers();
      final body = jsonEncode({'statut': newStatut});

      final response = await http
          .patch(
            Uri.parse(url),
            headers: headers,
            body: body,
          )
          .timeout(ApiConfig.connectTimeout);

      logger.i('Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        logger.i('✅ Statut changé en $newStatut pour transport $id');
        return true;
      } else {
        logger.e('❌ Erreur statut: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      logger.e('❌ Exception statut: $e');
      return false;
    }
  }

  // Recherche par statut (user ou admin)
  Future<List<Transport>?> getTransportsByStatut(String statut) async {
    final encoded = Uri.encodeQueryComponent(statut);

    final url = isAdmin
        ? '${ApiConfig.baseUrl}$adminEndpoint/search/statut?statut=$encoded'
        : '${ApiConfig.baseUrl}$userEndpoint/search/statut?statut=$encoded';
    try {
      logger.i('GET $url');
      final headers = await _headers();

      final response = await http
          .get(
            Uri.parse(url),
            headers: headers,
          )
          .timeout(ApiConfig.receiveTimeout);

      logger.i('Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List<dynamic> data = json is List ? json : (json['data'] ?? json);
        logger.i('✅ Transports par statut récupérés');
        return data.map((t) => Transport.fromJson(t)).toList();
      } else {
        logger.e('❌ Erreur: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      logger.e('❌ Exception: $e');
      return null;
    }
  }

  // Archives utilisateur
  Future<List<Transport>?> getTransportsArchivesUser() async {
    try {
      final url = '${ApiConfig.baseUrl}$userEndpoint/archives';
      logger.i('GET $url [ARCHIVES user]');
      final headers = await _headers();

      final response = await http
          .get(
            Uri.parse(url),
            headers: headers,
          )
          .timeout(ApiConfig.receiveTimeout);

      logger.i('Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> data =
            decoded is List ? decoded : (decoded['data'] ?? decoded);
        logger.i('✅ Transports archivés récupérés (user)');
        return data.map((t) => Transport.fromJson(t)).toList();
      } else {
        logger.e('❌ Erreur archives user: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      logger.e('❌ Exception archives user: $e');
      return null;
    }
  }

  // Archives admin
  Future<List<Transport>?> getTransportsArchivesAdmin() async {
    if (!isAdmin) return null;
    try {
      final url = '${ApiConfig.baseUrl}$adminEndpoint/archives';
      final headers = await _headers();

      final response = await http.get(Uri.parse(url), headers: headers);
      logger.i('GET $url [ARCHIVES admin]');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> data =
            decoded is List ? decoded : (decoded['data'] ?? decoded);
        logger.i('✅ Transports archivés récupérés (admin)');
        return data.map((t) => Transport.fromJson(t)).toList();
      } else {
        logger.e('❌ Erreur archives admin: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      logger.e('❌ Exception archives admin: $e');
      return null;
    }
  }

  // --- Option : récupérer dynamiquement la liste des statuts possibles ---
  Future<List<String>?> getStatutsTransports() async {
    try {
      final url = '${ApiConfig.baseUrl}/api/statuts-transports';
      logger.i('GET $url [STATUTS]');
      final headers = await _headers();
      final response = await http.get(Uri.parse(url), headers: headers);
      logger.i('Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> data =
            decoded is List ? decoded : (decoded['data'] ?? decoded);
        logger.i('✅ Statuts récupérés');
        return data.map((s) => s.toString()).toList();
      } else {
        logger.e('❌ Erreur statuts: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      logger.e('❌ Exception statuts: $e');
      return null;
    }
  }
}
