import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../models/gp_agent.dart';
import '../services/auth_service.dart';
import 'package:sama/config/ApiConfig_dev.dart';

class GpService {
  final logger = Logger();

  Future<Map<String, String>> _headers() async {
    final jwt = await AuthService.getJwt();
    if (jwt == null) {
      throw Exception("Non authentifié");
    }
    return {
      'Authorization': 'Bearer $jwt',
      'Content-Type': 'application/json',
    };
  }

  String get _gpUrl => '${ApiConfig.baseUrl}/admin/gp';

  Future<List<GpAgent>> getAll() async {
    final headers = await _headers();
    final url = _gpUrl;
    logger.i('GET $url');

    final res = await http.get(Uri.parse(url), headers: headers);
    if (res.statusCode != 200) {
      logger.e('❌ getAll GP failed: ${res.statusCode} ${res.body}');
      throw Exception("Erreur chargement GP");
    }
    final decoded = jsonDecode(res.body);
    final List<dynamic> list =
        decoded is List ? decoded : (decoded['data'] ?? []);
    return list
        .map((e) => GpAgent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<GpAgent>> getActive() async {
    final headers = await _headers();
    final url = '$_gpUrl/active';
    logger.i('GET $url');

    final res = await http.get(Uri.parse(url), headers: headers);
    if (res.statusCode != 200) {
      logger.e('❌ getActive GP failed: ${res.statusCode} ${res.body}');
      throw Exception("Erreur chargement GP actifs");
    }
    final decoded = jsonDecode(res.body);
    final List<dynamic> list =
        decoded is List ? decoded : (decoded['data'] ?? []);
    return list
        .map((e) => GpAgent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<GpAgent> create({
    required String prenom,
    required String nom,
    String? phoneNumber,
    String? email,
    bool isActive = true,
  }) async {
    final headers = await _headers();
    final url = _gpUrl;

    final body = jsonEncode({
      'prenom': prenom,
      'nom': nom,
      'phoneNumber': phoneNumber,
      'email': email,
      'isActive': isActive,
    });

    logger.i('POST $url');
    final res = await http.post(Uri.parse(url), headers: headers, body: body);

    if (res.statusCode != 200 && res.statusCode != 201) {
      logger.e('❌ create GP failed: ${res.statusCode} ${res.body}');
      throw Exception("Erreur création GP");
    }

    return GpAgent.fromJson(jsonDecode(res.body));
  }

  Future<GpAgent> update({
    required int id,
    required String prenom,
    required String nom,
    String? phoneNumber,
    String? email,
    required bool isActive,
  }) async {
    final headers = await _headers();
    final url = '$_gpUrl/$id';

    final body = jsonEncode({
      'id': id,
      'prenom': prenom,
      'nom': nom,
      'phoneNumber': phoneNumber,
      'email': email,
      'isActive': isActive,
    });

    logger.i('PUT $url');
    final res = await http.put(Uri.parse(url), headers: headers, body: body);

    if (res.statusCode != 200) {
      logger.e('❌ update GP failed: ${res.statusCode} ${res.body}');
      throw Exception("Erreur modification GP");
    }

    return GpAgent.fromJson(jsonDecode(res.body));
  }

  Future<void> delete(int id) async {
    final headers = await _headers();
    final url = '$_gpUrl/$id';
    logger.i('DELETE $url');

    final res = await http.delete(Uri.parse(url), headers: headers);
    if (res.statusCode != 200) {
      logger.e('❌ delete GP failed: ${res.statusCode} ${res.body}');
      throw Exception("Erreur suppression GP");
    }
  }

  // --- Assignation GP ---

  Future<void> assignGpToTransport({
    required int transportId,
    required int gpId,
    String? newStatut, // si null, on met EN_COURS
  }) async {
    final headers = await _headers();
    final url = '${ApiConfig.baseUrl}/admin/transports/$transportId/assign-gp';
    final body = jsonEncode({
      'gpId': gpId,
      'newStatut': newStatut ?? 'EN_COURS',
    });

    logger.i('PATCH $url');
    final res = await http.patch(Uri.parse(url), headers: headers, body: body);
    if (res.statusCode != 200) {
      logger.e('❌ assign GP transport failed: ${res.statusCode} ${res.body}');
      throw Exception("Erreur assignation GP au transport");
    }
  }

  Future<void> assignGpToCommande({
    required int commandeId,
    required int gpId,
    String? newStatut, // si null, on met EN_TRAITEMENT
  }) async {
    final headers = await _headers();
    final url = '${ApiConfig.baseUrl}/admin/commandes/$commandeId/assign-gp';
    final body = jsonEncode({
      'gpId': gpId,
      'newStatut': newStatut ?? 'EN_TRAITEMENT',
    });

    logger.i('PATCH $url');
    final res = await http.patch(Uri.parse(url), headers: headers, body: body);
    if (res.statusCode != 200) {
      logger.e('❌ assign GP commande failed: ${res.statusCode} ${res.body}');
      throw Exception("Erreur assignation GP à la commande");
    }
  }
}
