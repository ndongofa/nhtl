import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user.dart';
import '../config/api_config.dart';
import 'package:logger/logger.dart';

class UserService {
  final logger = Logger();

  // Ajouter un utilisateur
  Future<User?> addUser(User user) async {
    try {
      final url = '${ApiConfig.baseUrl}/users';
      logger.i('POST $url');

      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(user.toJson()),
          )
          .timeout(ApiConfig.connectTimeout);

      logger.i('Status: ${response.statusCode}');
      logger.i('Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body);
        logger.i('✅ Utilisateur créé avec succès');
        // ✅ ton backend retourne directement l'objet utilisateur
        return User.fromJson(json);
      } else {
        logger.e('❌ Erreur: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      logger.e('❌ Exception: $e');
      return null;
    }
  }

  // Récupérer tous les utilisateurs
  Future<List<User>?> getUsers() async {
    try {
      final url = '${ApiConfig.baseUrl}/users';
      logger.i('GET $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(ApiConfig.receiveTimeout);

      logger.i('Status: ${response.statusCode}');
      logger.i('Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        logger.i('✅ Utilisateurs récupérés');
        return data.map((u) => User.fromJson(u)).toList();
      } else {
        logger.e('❌ Erreur: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      logger.e('❌ Exception: $e');
      return null;
    }
  }

  // Mettre à jour un utilisateur
  Future<User?> updateUser(User user) async {
    try {
      final url = '${ApiConfig.baseUrl}/users/${user.id}';
      logger.i('PUT $url');

      final response = await http
          .put(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(user.toJson()),
          )
          .timeout(ApiConfig.connectTimeout);

      logger.i('Status: ${response.statusCode}');
      logger.i('Body: ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        logger.i('✅ Utilisateur ${user.id} mis à jour');
        return User.fromJson(json);
      } else {
        logger.e('❌ Erreur: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      logger.e('❌ Exception: $e');
      return null;
    }
  }

  // Supprimer un utilisateur
  Future<bool> deleteUser(int id) async {
    try {
      final url = '${ApiConfig.baseUrl}/users/$id';
      logger.i('DELETE $url');

      final response = await http.delete(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(ApiConfig.connectTimeout);

      logger.i('Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        logger.i('✅ Utilisateur $id supprimé');
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
