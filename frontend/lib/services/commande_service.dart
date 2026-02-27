import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/commande.dart';
import '../config/api_config.dart';
import 'package:logger/logger.dart';
import 'auth_service.dart';

class CommandeService {
  final logger = Logger();

  /// Helper pour les headers HTTP avec JWT Supabase
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

  // Créer une commande
  Future<Commande?> createCommande(Commande commande) async {
    try {
      final url = '${ApiConfig.baseUrl}${ApiConfig.commandeEndpoint}';
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
        return Commande.fromJson(json['data']);
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

  // Récupérer toutes les commandes
  Future<List<Commande>?> getAllCommandes() async {
    try {
      final url = '${ApiConfig.baseUrl}${ApiConfig.commandeEndpoint}';
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
        final List<dynamic> data = json['data'];
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

  // Récupérer une commande par ID
  Future<Commande?> getCommandeById(int id) async {
    try {
      final url = '${ApiConfig.baseUrl}${ApiConfig.commandeEndpoint}/$id';
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
        return Commande.fromJson(json['data']);
      } else {
        logger.e('❌ Erreur: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      logger.e('❌ Exception: $e');
      return null;
    }
  }

  // Mettre à jour une commande
  Future<Commande?> updateCommande(int id, Commande commande) async {
    try {
      final url = '${ApiConfig.baseUrl}${ApiConfig.commandeEndpoint}/$id';
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
        return Commande.fromJson(json['data']);
      } else {
        logger.e('❌ Erreur: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      logger.e('❌ Exception: $e');
      return null;
    }
  }

  // Supprimer une commande
  Future<bool> deleteCommande(int id) async {
    try {
      final url = '${ApiConfig.baseUrl}${ApiConfig.commandeEndpoint}/$id';
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

  // Récupérer les commandes par statut
  Future<List<Commande>?> getCommandesByStatut(String statut) async {
    try {
      final url =
          '${ApiConfig.baseUrl}${ApiConfig.commandeEndpoint}/search/statut?statut=$statut';
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
        final List<dynamic> data = json['data'];
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
}
