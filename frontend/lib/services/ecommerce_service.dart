// lib/services/ecommerce_service.dart
//
// Client HTTP générique pour les services e-commerce (Maad, Téranga, BestSeller).
// Paramétré par serviceType : 'maad' | 'teranga' | 'bestseller'

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../config/api_config.dart';
import '../models/produit.dart';
import '../models/panier_item.dart';
import '../models/commande_ecommerce.dart';
import 'auth_service.dart';

class EcommerceService {
  final String serviceType; // 'maad' | 'teranga' | 'bestseller'
  final _logger = Logger();

  EcommerceService({required this.serviceType});

  String get _service => serviceType.toLowerCase();

  Future<Map<String, String>> _authHeaders() async {
    final jwt = await AuthService.getJwt();
    if (jwt == null) throw Exception("Non authentifié");
    return {
      'Authorization': 'Bearer $jwt',
      'Content-Type': 'application/json',
    };
  }

  Map<String, String> get _publicHeaders =>
      {'Content-Type': 'application/json'};

  // ── Produits (lecture publique) ───────────────────────────────────────────

  Future<List<Produit>> getProduits() async {
    final url = '${ApiConfig.baseUrl}/api/$_service/produits';
    try {
      _logger.i('GET $url');
      final response = await http
          .get(Uri.parse(url), headers: _publicHeaders)
          .timeout(ApiConfig.receiveTimeout);
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list
            .map((p) => Produit.fromJson(p as Map<String, dynamic>))
            .toList();
      }
      _logger.e('❌ getProduits ${response.statusCode}');
      return [];
    } catch (e) {
      _logger.e('❌ getProduits exception: $e');
      return [];
    }
  }

  Future<Produit?> getProduit(int id) async {
    final url = '${ApiConfig.baseUrl}/api/$_service/produits/$id';
    try {
      final response = await http
          .get(Uri.parse(url), headers: _publicHeaders)
          .timeout(ApiConfig.receiveTimeout);
      if (response.statusCode == 200) {
        return Produit.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      _logger.e('❌ getProduit exception: $e');
      return null;
    }
  }

  // ── Panier (authentifié) ──────────────────────────────────────────────────

  Future<List<PanierItem>> getPanier() async {
    final url = '${ApiConfig.baseUrl}/api/$_service/panier';
    try {
      final headers = await _authHeaders();
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(ApiConfig.receiveTimeout);
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list
            .map((i) => PanierItem.fromJson(i as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      _logger.e('❌ getPanier exception: $e');
      return [];
    }
  }

  Future<PanierItem?> ajouterAuPanier(int produitId, int quantite) async {
    final url = '${ApiConfig.baseUrl}/api/$_service/panier';
    try {
      final headers = await _authHeaders();
      final response = await http
          .post(Uri.parse(url),
              headers: headers,
              body: jsonEncode({'produitId': produitId, 'quantite': quantite}))
          .timeout(ApiConfig.connectTimeout);
      if (response.statusCode == 200) {
        return PanierItem.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      }
      _logger.e('❌ ajouterAuPanier ${response.statusCode}');
      return null;
    } catch (e) {
      _logger.e('❌ ajouterAuPanier exception: $e');
      return null;
    }
  }

  Future<bool> retirerDuPanier(int produitId) async {
    final url = '${ApiConfig.baseUrl}/api/$_service/panier/$produitId';
    try {
      final headers = await _authHeaders();
      final response = await http
          .delete(Uri.parse(url), headers: headers)
          .timeout(ApiConfig.connectTimeout);
      return response.statusCode == 200;
    } catch (e) {
      _logger.e('❌ retirerDuPanier exception: $e');
      return false;
    }
  }

  Future<bool> viderPanier() async {
    final url = '${ApiConfig.baseUrl}/api/$_service/panier';
    try {
      final headers = await _authHeaders();
      final response = await http
          .delete(Uri.parse(url), headers: headers)
          .timeout(ApiConfig.connectTimeout);
      return response.statusCode == 200;
    } catch (e) {
      _logger.e('❌ viderPanier exception: $e');
      return false;
    }
  }

  // ── Commandes (authentifié) ───────────────────────────────────────────────

  Future<CommandeEcommerce?> validerCommande(
      CommandeEcommerce commande) async {
    final url = '${ApiConfig.baseUrl}/api/$_service/commandes';
    try {
      final headers = await _authHeaders();
      final response = await http
          .post(Uri.parse(url),
              headers: headers, body: jsonEncode(commande.toJson()))
          .timeout(ApiConfig.connectTimeout);
      if (response.statusCode == 200) {
        return CommandeEcommerce.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      }
      _logger.e('❌ validerCommande ${response.statusCode}');
      return null;
    } catch (e) {
      _logger.e('❌ validerCommande exception: $e');
      return null;
    }
  }

  Future<List<CommandeEcommerce>> getMesCommandes() async {
    final url = '${ApiConfig.baseUrl}/api/$_service/commandes';
    try {
      final headers = await _authHeaders();
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(ApiConfig.receiveTimeout);
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list
            .map((c) => CommandeEcommerce.fromJson(c as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      _logger.e('❌ getMesCommandes exception: $e');
      return [];
    }
  }

  Future<List<CommandeEcommerce>> getMesArchives() async {
    final url = '${ApiConfig.baseUrl}/api/$_service/commandes/archives';
    try {
      final headers = await _authHeaders();
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(ApiConfig.receiveTimeout);
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list
            .map((c) => CommandeEcommerce.fromJson(c as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      _logger.e('❌ getMesArchives exception: $e');
      return [];
    }
  }

  Future<CommandeEcommerce?> getCommande(int id) async {
    final url = '${ApiConfig.baseUrl}/api/$_service/commandes/$id';
    try {
      final headers = await _authHeaders();
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(ApiConfig.receiveTimeout);
      if (response.statusCode == 200) {
        return CommandeEcommerce.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      _logger.e('❌ getCommande exception: $e');
      return null;
    }
  }

  // ── Admin ──────────────────────────────────────────────────────────────────

  Future<List<Produit>> getProduitsAdmin() async {
    final url =
        '${ApiConfig.baseUrl}/api/admin/$_service/produits';
    try {
      final headers = await _authHeaders();
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(ApiConfig.receiveTimeout);
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list
            .map((p) => Produit.fromJson(p as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      _logger.e('❌ getProduitsAdmin exception: $e');
      return [];
    }
  }

  Future<Produit?> createProduit(Produit produit) async {
    final url = '${ApiConfig.baseUrl}/api/admin/$_service/produits';
    try {
      final headers = await _authHeaders();
      final response = await http
          .post(Uri.parse(url),
              headers: headers, body: jsonEncode(produit.toJson()))
          .timeout(ApiConfig.connectTimeout);
      if (response.statusCode == 200) {
        return Produit.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      _logger.e('❌ createProduit exception: $e');
      return null;
    }
  }

  Future<Produit?> updateProduit(int id, Produit produit) async {
    final url = '${ApiConfig.baseUrl}/api/admin/$_service/produits/$id';
    try {
      final headers = await _authHeaders();
      final response = await http
          .put(Uri.parse(url),
              headers: headers, body: jsonEncode(produit.toJson()))
          .timeout(ApiConfig.connectTimeout);
      if (response.statusCode == 200) {
        return Produit.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      _logger.e('❌ updateProduit exception: $e');
      return null;
    }
  }

  Future<bool> deleteProduit(int id) async {
    final url = '${ApiConfig.baseUrl}/api/admin/$_service/produits/$id';
    try {
      final headers = await _authHeaders();
      final response = await http
          .delete(Uri.parse(url), headers: headers)
          .timeout(ApiConfig.connectTimeout);
      return response.statusCode == 200;
    } catch (e) {
      _logger.e('❌ deleteProduit exception: $e');
      return false;
    }
  }

  Future<Produit?> updateStock(int id, int stock) async {
    final url =
        '${ApiConfig.baseUrl}/api/admin/$_service/produits/$id/stock';
    try {
      final headers = await _authHeaders();
      final response = await http
          .patch(Uri.parse(url),
              headers: headers, body: jsonEncode({'stock': stock}))
          .timeout(ApiConfig.connectTimeout);
      if (response.statusCode == 200) {
        return Produit.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      _logger.e('❌ updateStock exception: $e');
      return null;
    }
  }

  Future<List<CommandeEcommerce>> getCommandesAdmin() async {
    final url = '${ApiConfig.baseUrl}/api/admin/$_service/commandes';
    try {
      final headers = await _authHeaders();
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(ApiConfig.receiveTimeout);
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list
            .map((c) => CommandeEcommerce.fromJson(c as Map<String, dynamic>))
            .toList();
      }
      _logger.e('❌ getCommandesAdmin ${response.statusCode}');
      return [];
    } catch (e) {
      _logger.e('❌ getCommandesAdmin exception: $e');
      return [];
    }
  }

  Future<List<CommandeEcommerce>> getCommandesArchivedAdmin() async {
    final url = '${ApiConfig.baseUrl}/api/admin/$_service/commandes/archives';
    try {
      final headers = await _authHeaders();
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(ApiConfig.receiveTimeout);
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list
            .map((c) => CommandeEcommerce.fromJson(c as Map<String, dynamic>))
            .toList();
      }
      _logger.e('❌ getCommandesArchivedAdmin ${response.statusCode}');
      return [];
    } catch (e) {
      _logger.e('❌ getCommandesArchivedAdmin exception: $e');
      return [];
    }
  }

  Future<bool> updateStatutAdmin(int id, String statut) async {
    final url =
        '${ApiConfig.baseUrl}/api/admin/$_service/commandes/$id/statut';
    try {
      final headers = await _authHeaders();
      final response = await http
          .patch(Uri.parse(url),
              headers: headers, body: jsonEncode({'statut': statut}))
          .timeout(ApiConfig.connectTimeout);
      return response.statusCode == 200;
    } catch (e) {
      _logger.e('❌ updateStatutAdmin exception: $e');
      return false;
    }
  }

  Future<bool> archiverCommandeAdmin(int id) async {
    final url =
        '${ApiConfig.baseUrl}/api/admin/$_service/commandes/$id/archive';
    try {
      final headers = await _authHeaders();
      final response = await http
          .patch(Uri.parse(url), headers: headers)
          .timeout(ApiConfig.connectTimeout);
      return response.statusCode == 200;
    } catch (e) {
      _logger.e('❌ archiverCommandeAdmin exception: $e');
      return false;
    }
  }

  Future<bool> desarchiverCommandeAdmin(int id) async {
    final url =
        '${ApiConfig.baseUrl}/api/admin/$_service/commandes/$id/unarchive';
    try {
      final headers = await _authHeaders();
      final response = await http
          .patch(Uri.parse(url), headers: headers)
          .timeout(ApiConfig.connectTimeout);
      return response.statusCode == 200;
    } catch (e) {
      _logger.e('❌ desarchiverCommandeAdmin exception: $e');
      return false;
    }
  }

  Future<bool> deleteCommandeAdmin(int id) async {
    final url =
        '${ApiConfig.baseUrl}/api/admin/$_service/commandes/$id';
    try {
      final headers = await _authHeaders();
      final response = await http
          .delete(Uri.parse(url), headers: headers)
          .timeout(ApiConfig.connectTimeout);
      return response.statusCode == 200;
    } catch (e) {
      _logger.e('❌ deleteCommandeAdmin exception: $e');
      return false;
    }
  }
}
