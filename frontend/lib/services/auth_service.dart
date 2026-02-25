import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // SIGN UP avec role=user par défaut
  static Future<void> signupWithMetadata({
    required String email,
    required String password,
    required String fullName,
    String? username,
    String? phone,
    String? role, // 'user' si non précisé
  }) async {
    final res = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'role': role ?? 'user',
        if (username != null) 'username': username,
        if (phone != null) 'phone': phone,
      },
    );
    if (res.user == null) {
      throw Exception('Erreur lors de l\'inscription');
    }
  }

  static Future<void> login(String email, String password) async {
    final res = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (res.user == null || res.session == null) {
      throw Exception('Connexion échouée. Vérifiez vos identifiants.');
    }
  }

  static Future<void> resetPasswordForEmail(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  static Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  static Future<bool> isLoggedIn() async =>
      _supabase.auth.currentSession != null;

  static Future<String?> getJwt() async {
    final session = _supabase.auth.currentSession;
    return session?.accessToken;
  }

  static String? get jwt => _supabase.auth.currentSession?.accessToken;

  static String? get userId => _supabase.auth.currentUser?.id;

  static User? get currentUser => _supabase.auth.currentUser;

  static Map<String, dynamic>? get userMetadata =>
      _supabase.auth.currentUser?.userMetadata;

  static String getCurrentRole() =>
      _supabase.auth.currentUser?.userMetadata?['role']?.toString() ?? 'user';
}
