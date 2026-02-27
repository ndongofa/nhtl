import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user.dart';
import '../config/api_config.dart';
import 'package:logger/logger.dart';
import 'auth_service.dart';

class UserService {
  final Logger logger = Logger();

  /// Headers HTTP incluant le JWT pour l'authentification.
  Future<Map<String, String>> _headers() async {
    final jwt = await AuthService
        .getJwt(); // ✅ ASYNC : token Supabase récupéré à chaque appel
    return {
      if (jwt != null) 'Authorization': 'Bearer $jwt',
      'Content-Type': 'application/json',
    };
  }

  /// Création d'un utilisateur par un admin (POST /admin/users)
  Future<bool> createUserParAdmin({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final url = '${ApiConfig.baseUrl}/admin/users';
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
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      logger.e('Erreur création user admin: $e');
      return false;
    }
  }

  /// Ajouter un utilisateur standard (POST /api/users)
  Future<User?> addUser(User user) async {
    try {
      final url = '${ApiConfig.baseUrl}${ApiConfig.userEndpoint}';
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
      logger.e('Exception addUser: $e');
      return null;
    }
  }

  /// Récupérer tous les utilisateurs (GET /api/users)
  Future<List<User>?> getUsers() async {
    try {
      final url = '${ApiConfig.baseUrl}${ApiConfig.userEndpoint}';
      final headers = await _headers();

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<dynamic> jsonList = [];
        if (decoded is List) {
          jsonList = decoded;
        } else if (decoded is Map && decoded.containsKey('data')) {
          jsonList = decoded['data'];
        }
        return jsonList.map((u) => User.fromJson(u)).toList();
      } else {
        logger.e('Erreur getUsers: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      logger.e('Exception getUsers: $e');
      return null;
    }
  }

  /// Mettre à jour un utilisateur (PUT /api/users/{id})
  Future<User?> updateUser(User user) async {
    try {
      if (user.id == null) throw Exception('ID utilisateur requis pour update');
      final url = '${ApiConfig.baseUrl}${ApiConfig.userEndpoint}/${user.id}';
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
      logger.e('Exception updateUser: $e');
      return null;
    }
  }

  /// Supprimer un utilisateur (DELETE /api/users/{id})
  Future<bool> deleteUser(int id) async {
    try {
      final url = '${ApiConfig.baseUrl}${ApiConfig.userEndpoint}/$id';
      final headers = await _headers();

      final response = await http.delete(
        Uri.parse(url),
        headers: headers,
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      logger.e('Exception deleteUser: $e');
      return false;
    }
  }
}
