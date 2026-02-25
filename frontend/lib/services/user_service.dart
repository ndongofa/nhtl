import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user.dart';
import '../config/api_config.dart';
import 'package:logger/logger.dart';
import 'auth_service.dart';

class UserService {
  final logger = Logger();

  Future<Map<String, String>> _headers() async {
    final jwt = await AuthService.getJwt();
    return {
      'Authorization': 'Bearer $jwt',
      'Content-Type': 'application/json',
    };
  }

  /// Création par admin (role choisi) - Correction du endpoint sans /api
  Future<bool> createUserParAdmin({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final url = '${ApiConfig.baseUrl}/admin/users'; // <-- CORRECTION ici !
    final body = {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
    };
    try {
      final headers = await _headers();
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        logger.e(
          'Erreur création user admin: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      logger.e("Erreur création user admin : $e");
      return false;
    }
  }

  // CRUD REST classique
  Future<User?> addUser(User user) async {
    try {
      final url = '${ApiConfig.baseUrl}/api/users';
      final headers = await _headers();
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(user.toJson()),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return User.fromJson(jsonDecode(response.body));
      } else {
        logger.e('Erreur addUser: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      logger.e("Exception addUser: $e");
      return null;
    }
  }

  Future<List<User>?> getUsers() async {
    try {
      final url = '${ApiConfig.baseUrl}/api/users';
      final headers = await _headers();
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final body = response.body;
        final decoded = jsonDecode(body);
        // Supporte [{"id"...}, ...] (spring) ou {"data":[user,...]} (autre API)
        final List<dynamic> jsonList =
            decoded is List ? decoded : (decoded['data'] ?? []);
        return jsonList.map((u) => User.fromJson(u)).toList();
      } else {
        logger.e('Erreur getUsers: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      logger.e("Exception getUsers: $e");
      return null;
    }
  }

  Future<User?> updateUser(User user) async {
    try {
      final url = '${ApiConfig.baseUrl}/api/users/${user.id}';
      final headers = await _headers();
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(user.toJson()),
      );
      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      } else {
        logger
            .e('Erreur updateUser: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      logger.e("Exception updateUser: $e");
      return null;
    }
  }

  Future<bool> deleteUser(int id) async {
    try {
      final url = '${ApiConfig.baseUrl}/api/users/$id';
      final headers = await _headers();
      final response = await http.delete(Uri.parse(url), headers: headers);
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        logger
            .e('Erreur deleteUser: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      logger.e("Exception deleteUser: $e");
      return false;
    }
  }
}
