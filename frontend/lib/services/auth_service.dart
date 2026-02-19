import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_client.dart';
import '../models/auth/login_request.dart';
import '../models/auth/login_response.dart';
import '../models/auth/signup_request.dart';
import '../models/auth/signup_response.dart';

class AuthService {
  // LOGIN
  static Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await ApiClient.post(
        '/auth/login',
        request.toJson(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final loginResponse = LoginResponse.fromJson(data);

        // Sauvegarder le token
        await ApiClient.saveToken(loginResponse.accessToken);

        return loginResponse;
      } else {
        throw Exception('Erreur login: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  // SIGNUP
  static Future<SignupResponse> signup(SignupRequest request) async {
    try {
      final response = await ApiClient.post(
        '/auth/signup',
        request.toJson(),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SignupResponse.fromJson(data);
      } else {
        throw Exception('Erreur signup: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  // SEND RESET OTP (Forgot Password) - Email OU Téléphone
  static Future<void> sendResetOtp(String identifier) async {
    try {
      final response = await ApiClient.post(
        '/auth/forgot-password',
        {'identifier': identifier}, // Email OU Téléphone
      );

      if (response.statusCode != 200) {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  // VERIFY OTP - Email OU Téléphone
  static Future<bool> verifyOtp(String identifier, String otp) async {
    try {
      final response = await ApiClient.post(
        '/auth/verify-otp',
        {
          'identifier': identifier, // Email OU Téléphone
          'otp': otp
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('OTP invalide');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  // RESET PASSWORD - Email OU Téléphone
  static Future<void> resetPassword(
    String identifier, // Email OU Téléphone
    String otp,
    String newPassword,
  ) async {
    try {
      final response = await ApiClient.post(
        '/auth/reset-password',
        {
          'identifier': identifier, // Email OU Téléphone
          'otp': otp,
          'newPassword': newPassword,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  // LOGOUT
  static Future<void> logout() async {
    await ApiClient.deleteToken();
  }

  // CHECK IF LOGGED IN
  static Future<bool> isLoggedIn() async {
    final token = await ApiClient.getToken();
    return token != null && token.isNotEmpty;
  }
}
