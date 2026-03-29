// lib/services/commande_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:sama/config/api_config.dart';
import '../models/commande.dart';
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
  String get adminEndpoint => "/api/admin/commandes";

  // ── Créer une commande ────────────────────────────────────────────────────
  Future<Commande?> createCommande(Commande commande) async {
    try {
      final url = '${ApiConfig.baseUrl}$userEndpoint';
      final headers = await _headers();
      logger.i('POST $url');

      final response = await http
          .post(Uri.parse(url),
              headers: headers, body: jsonEncode(commande.toJson()))
          .timeout(ApiConfig.connectTimeout);

      logger.i('Status: ${response.statusCode}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body);
        logger.i('✅ Commande créée');
        return Commande.fromJson(json is Map<String, dynamic> ? json : {});
      }
      logger.e('❌ Erreur: ${response.statusCode} ${response.body}');
      return null;
    } catch (e) {
      logger.e('❌ Exception: $e');
      return null;
    }
  }

  // ── Récupérer toutes les commandes ────────────────────────────────────────
  Future<List<Commande>?> getAllCommandes() async {
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
        logger.i('✅ Commandes récupérées');
        return data.map((c) => Commande.fromJson(c)).toList();
      }
      logger.e('❌ Erreur: ${response.statusCode}');
      return null;
    } catch (e) {
      logger.e('❌ Exception: $e');
      return null;
    }
  }

  // ── Mettre à jour une commande ────────────────────────────────────────────
  Future<Commande?> updateCommande(Commande commande) async {
    final url = isAdmin
        ? '${ApiConfig.baseUrl}$adminEndpoint/${commande.id}'
        : '${ApiConfig.baseUrl}$userEndpoint/${commande.id}';
    try {
      final headers = await _headers();
      logger.i('PUT $url');

      final response = await http
          .put(Uri.parse(url),
              headers: headers, body: jsonEncode(commande.toJson()))
          .timeout(ApiConfig.connectTimeout);

      logger.i('Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        logger.i('✅ Commande ${commande.id} mise à jour');
        return Commande.fromJson(json is Map<String, dynamic> ? json : {});
      }
      logger.e('❌ Erreur: ${response.statusCode}');
      return null;
    } catch (e) {
      logger.e('❌ Exception: $e');
      return null;
    }
  }

  // ── Supprimer une commande ────────────────────────────────────────────────
  Future<bool> deleteCommande(int id) async {
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
        logger.i('✅ Commande $id supprimée');
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
  Future<bool> archiveCommande(int id) async {
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
        logger.i('✅ Commande $id archivée');
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
  Future<bool> unarchiveCommandeAdmin(int id) async {
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
        logger.i('✅ Commande $id désarchivée');
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
  Future<bool> changeCommandeStatut(int id, String newStatut) async {
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
        logger.i('✅ Statut admin commande $id → $newStatut');
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

  // Alias pour compatibilité avec CommandesArchivesScreen
  Future<bool> changeStatutCommandeAdmin(int id, String newStatut) =>
      changeCommandeStatut(id, newStatut);

  // ── Statut LOGISTIQUE — avec notifications ────────────────────────────────
  // Valeurs : EN_ATTENTE, COMMANDE_CONFIRMEE, EN_TRANSIT, EN_DOUANE,
  //           ARRIVE, PRET_LIVRAISON, LIVRE
  Future<bool> updateStatutSuivi(int id, String newStatus) async {
    if (!isAdmin) {
      logger.w('⛔ updateStatutSuivi commande: accès refusé (non admin)');
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
        logger.i('✅ StatutSuivi commande $id → $newStatus');
        return true;
      }
      logger.e('❌ Erreur statutSuivi: ${response.statusCode} ${response.body}');
      return false;
    } catch (e) {
      logger.e('❌ Exception updateStatutSuivi: $e');
      return false;
    }
  }

  // ── Archives utilisateur ──────────────────────────────────────────────────
  Future<List<Commande>?> getCommandesArchivesUser() async {
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
        logger.i('✅ Archives commandes user récupérées');
        return data.map((c) => Commande.fromJson(c)).toList();
      }
      logger.e('❌ Erreur archives user: ${response.statusCode}');
      return null;
    } catch (e) {
      logger.e('❌ Exception archives user: $e');
      return null;
    }
  }

  // ── Archives admin ────────────────────────────────────────────────────────
  Future<List<Commande>?> getCommandesArchivesAdmin() async {
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
        logger.i('✅ Archives commandes admin récupérées');
        return data.map((c) => Commande.fromJson(c)).toList();
      }
      logger.e('❌ Erreur archives admin: ${response.statusCode}');
      return null;
    } catch (e) {
      logger.e('❌ Exception archives admin: $e');
      return null;
    }
  }

  // ── Statuts possibles ─────────────────────────────────────────────────────
  Future<List<String>?> getStatutsCommandes() async {
    try {
      final url = '${ApiConfig.baseUrl}/api/statuts-commandes';
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
        logger.i('✅ Statuts commandes récupérés');
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
