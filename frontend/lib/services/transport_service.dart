import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/transport.dart';
import '../config/api_config.dart';
import 'package:logger/logger.dart';

class TransportService {
  final logger = Logger();

  // Créer un transport
  Future<Transport?> createTransport(Transport transport) async {
    try {
      final url = '${ApiConfig.baseUrl}${ApiConfig.transportEndpoint}';
      logger.i('POST $url');

      final response = await http
          .post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(transport.toJson()),
      )
          .timeout(ApiConfig.connectTimeout);

      logger.i('Status: ${response.statusCode}');
      logger.i('Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // ✅ Extrayez le champ 'data' de la réponse
        final json = jsonDecode(response.body);
        logger.i('✅ Transport créé avec succès');
        return Transport.fromJson(json['data']);
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

  // Récupérer tous les transports
  Future<List<Transport>?> getAllTransports() async {
    try {
      final url = '${ApiConfig.baseUrl}${ApiConfig.transportEndpoint}';
      logger.i('GET $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(ApiConfig.receiveTimeout);

      logger.i('Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // ✅ Extrayez le champ 'data' de la réponse
        final json = jsonDecode(response.body);
        final List<dynamic> data = json['data'];
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

  // Récupérer un transport par ID
  Future<Transport?> getTransportById(int id) async {
    try {
      final url = '${ApiConfig.baseUrl}${ApiConfig.transportEndpoint}/$id';
      logger.i('GET $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(ApiConfig.receiveTimeout);

      logger.i('Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // ✅ Extrayez le champ 'data' de la réponse
        final json = jsonDecode(response.body);
        logger.i('✅ Transport $id récupéré');
        return Transport.fromJson(json['data']);
      } else {
        logger.e('❌ Erreur: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      logger.e('❌ Exception: $e');
      return null;
    }
  }

  // Mettre à jour un transport
  Future<Transport?> updateTransport(int id, Transport transport) async {
    try {
      final url = '${ApiConfig.baseUrl}${ApiConfig.transportEndpoint}/$id';
      logger.i('PUT $url');

      final response = await http
          .put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(transport.toJson()),
      )
          .timeout(ApiConfig.connectTimeout);

      logger.i('Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // ✅ Extrayez le champ 'data' de la réponse
        final json = jsonDecode(response.body);
        logger.i('✅ Transport $id mis à jour');
        return Transport.fromJson(json['data']);
      } else {
        logger.e('❌ Erreur: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      logger.e('❌ Exception: $e');
      return null;
    }
  }

  // Supprimer un transport
  Future<bool> deleteTransport(int id) async {
    try {
      final url = '${ApiConfig.baseUrl}${ApiConfig.transportEndpoint}/$id';
      logger.i('DELETE $url');

      final response = await http.delete(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(ApiConfig.connectTimeout);

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
}