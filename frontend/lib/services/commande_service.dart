import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/commande.dart';
import 'package:sama/config/ApiConfig_dev.dart';
import 'package:logger/logger.dart';
import 'auth_service.dart';
import '../models/logged_user.dart';

class CommandeService {
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

  String get userEndpoint => ApiConfig.commandeEndpoint; // "/api/commandes"
  String get adminEndpoint => "/admin/commandes";

  // Créer une commande (toujours user)
  Future<Commande?> createCommande(Commande commande) async {
    try {
      final url = '${ApiConfig.baseUrl}$userEndpoint';
      logger.i('POST $url');
      final headers = await _headers();

      final response = await http
          .post(
            Uri.parse(url),
            headers: headers,
            body: jsonEncode(commande.toJson()),
          )
          .timeout(ApiConfig.connectTimeout);

      logger.i('Status: ${response.statusCode}');
      logger.i('Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body);
        logger.i('✅ Commande créée avec succès');
        return Commande.fromJson(json is Map<String, dynamic> ? json : {});
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

  // Récupérer toutes les commandes de l'utilisateur
  Future<List<Commande>?> getAllCommandes() async {
    try {
      final url = '${ApiConfig.baseUrl}$userEndpoint';
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
        logger.i('✅ Commandes récupérées');
        return data.map((c) => Commande.fromJson(c)).toList();
      } else {
        logger.e('❌ Erreur: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      logger.e('❌ Exception: $e');
      return null;
    }
  }

  // Récupérer toutes les commandes côté admin
  Future<List<Commande>?> getAllCommandesAdmin() async {
    try {
      final url = '${ApiConfig.baseUrl}$adminEndpoint/all';
      final headers = await _headers();

      final response = await http.get(Uri.parse(url), headers: headers);
      logger.i('GET $url ADMIN');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> data =
            decoded is List ? decoded : (decoded['data'] ?? decoded);
        logger.i('✅ Commandes récupérées (admin)');
        return data.map((c) => Commande.fromJson(c)).toList();
      } else {
        logger.e('❌ Erreur admin: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      logger.e('❌ Exception admin: $e');
      return null;
    }
  }

  // 🟢 Récupérer les commandes archivées de l'utilisateur
  Future<List<Commande>?> getCommandesArchivesUser() async {
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
        logger.i('✅ Commandes archivées récupérées (user)');
        return data.map((c) => Commande.fromJson(c)).toList();
      } else {
        logger.e('❌ Erreur archives user: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      logger.e('❌ Exception archives user: $e');
      return null;
    }
  }

  // 🟢 Récupérer toutes les commandes archivées côté admin
  Future<List<Commande>?> getCommandesArchivesAdmin() async {
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
        logger.i('✅ Commandes archivées récupérées (admin)');
        return data.map((c) => Commande.fromJson(c)).toList();
      } else {
        logger.e('❌ Erreur archives admin: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      logger.e('❌ Exception archives admin: $e');
      return null;
    }
  }

  // Récupérer une commande par ID
  Future<Commande?> getCommandeById(int id) async {
    final url = isAdmin
        ? '${ApiConfig.baseUrl}$adminEndpoint/$id'
        : '${ApiConfig.baseUrl}$userEndpoint/$id';
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
        logger.i('✅ Commande $id récupérée');
        return Commande.fromJson(json is Map<String, dynamic> ? json : {});
      } else {
        logger.e('❌ Erreur: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      logger.e('❌ Exception: $e');
      return null;
    }
  }

  // Mettre à jour une commande (user ou admin)
  Future<Commande?> updateCommande(Commande commande) async {
    final id = commande.id;
    if (id == null) return null;
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
            body: jsonEncode(commande.toJson()),
          )
          .timeout(ApiConfig.connectTimeout);

      logger.i('Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        logger.i('✅ Commande $id mise à jour');
        return Commande.fromJson(json is Map<String, dynamic> ? json : {});
      } else {
        logger.e('❌ Erreur: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      logger.e('❌ Exception: $e');
      return null;
    }
  }

  // Supprimer une commande (user ou admin)
  Future<bool> deleteCommande(int id) async {
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
        logger.i('✅ Commande $id supprimée');
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

  // ARCHIVAGE : PATCH admin seulement
  Future<bool> archiveCommandeAdmin(int id) async {
    if (!isAdmin) return false;
    try {
      final url = '${ApiConfig.baseUrl}$adminEndpoint/$id/archive';
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
        logger.i('✅ Commande $id archivée');
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

  // STATUT : PATCH admin seulement
  Future<bool> changeStatutCommandeAdmin(int id, String newStatut) async {
    if (!isAdmin) return false;
    try {
      final url = '${ApiConfig.baseUrl}$adminEndpoint/$id/statut';
      logger.i('PATCH $url [STATUT]');
      final headers = await _headers();

      final response = await http
          .patch(
            Uri.parse(url),
            headers: headers,
            body: jsonEncode({'statut': newStatut}),
          )
          .timeout(ApiConfig.connectTimeout);

      logger.i('Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        logger.i('✅ Commande $id statut modifié');
        return true;
      } else {
        logger.e('❌ Erreur statue: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      logger.e('❌ Exception statut: $e');
      return false;
    }
  }

  // Recherche par statut (user ou admin)
  Future<List<Commande>?> getCommandesByStatut(String statut) async {
    final url = isAdmin
        ? '${ApiConfig.baseUrl}$adminEndpoint/search/statut?statut=$statut'
        : '${ApiConfig.baseUrl}$userEndpoint/search/statut?statut=$statut';
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
        logger.i('✅ Commandes par statut récupérées');
        return data.map((c) => Commande.fromJson(c)).toList();
      } else {
        logger.e('❌ Erreur: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      logger.e('❌ Exception: $e');
      return null;
    }
  }

  // --- AJOUT : désarchiver une commande (admin) ---
  Future<bool> unarchiveCommandeAdmin(int id) async {
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
        logger.i('✅ Commande $id désarchivée');
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

  // --- AJOUT : récupérer dynamiquement la liste des statuts possibles ---
  Future<List<String>?> getStatutsCommandes() async {
    try {
      final url = '${ApiConfig.baseUrl}/api/statuts-commandes';
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
