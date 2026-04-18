import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Résultat du signup:
/// - signedIn: session créée (pas de confirmation requise ou auto-confirm)
/// - confirmationRequired: signup OK, mais l'utilisateur doit confirmer email/phone
enum SignupOutcome {
  signedIn,
  confirmationRequired,
}

class AuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static bool _looksLikeEmail(String v) => v.contains('@');

  /// Très simple validation E.164: + puis chiffres 8..15
  static bool _looksLikeE164Phone(String v) =>
      RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(v);

  static bool _is429(dynamic statusCode) =>
      statusCode == 429 || statusCode?.toString() == '429';

  static const String _webviewBlockedMsg =
      "Connexion bloquée par votre navigateur.\n\n"
      "⚠️ Si vous êtes dans l'application Facebook ou Instagram, "
      "ouvrez ce lien dans votre navigateur (Chrome, Safari) et réessayez.";

  static bool _looksLikeNetworkBlock(String s) =>
      s.contains('xmlhttprequest') ||
      s.contains('cors') ||
      s.contains('failed to fetch') ||
      s.contains('network error');

  /// Traduit un message d'erreur Supabase en message lisible en français.
  static String _friendlyAuthMessage(String? message) {
    if (message == null || message.isEmpty) {
      return "Une erreur s'est produite. Veuillez réessayer.";
    }
    final m = message.toLowerCase();
    if (m.contains('invalid login credentials') ||
        m.contains('invalid credentials') ||
        m.contains('wrong password') ||
        m.contains('invalid email or password')) {
      return "Email/téléphone ou mot de passe incorrect.";
    }
    if (m.contains('user already registered') ||
        m.contains('already been registered') ||
        m.contains('already exists') ||
        m.contains('user_already_exists')) {
      return "Un compte existe déjà avec cet email ou ce numéro de téléphone.";
    }
    if (m.contains('email not confirmed')) {
      return "Votre email n'a pas encore été confirmé. Vérifiez votre boîte mail et cliquez sur le lien de confirmation.";
    }
    if (m.contains('phone not confirmed')) {
      return "Votre numéro de téléphone n'a pas encore été vérifié.";
    }
    if (m.contains('token has expired') ||
        m.contains('token expired') ||
        m.contains('otp expired') ||
        m.contains('otp has expired') ||
        m.contains('verification token expired')) {
      return "Code expiré. Veuillez en demander un nouveau.";
    }
    if (m.contains('invalid otp') ||
        m.contains('invalid token') ||
        m.contains('otp_invalid') ||
        m.contains('token_not_found') ||
        m.contains('incorrect code')) {
      return "Code incorrect. Vérifiez le code reçu par SMS et réessayez.";
    }
    if (m.contains('user not found') || m.contains('no user found')) {
      return "Aucun compte trouvé avec ces identifiants.";
    }
    if (m.contains('rate limit') || m.contains('too many requests')) {
      return "Trop de tentatives. Veuillez patienter quelques minutes avant de réessayer.";
    }
    if (m.contains('network') ||
        m.contains('connection refused') ||
        m.contains('socket') ||
        _looksLikeNetworkBlock(m)) {
      return _webviewBlockedMsg;
    }
    if (m.contains('weak password') || m.contains('password should be')) {
      return "Le mot de passe doit contenir au moins 8 caractères.";
    }
    if (m.contains('signup is disabled') ||
        m.contains('signups not allowed')) {
      return "Les inscriptions sont temporairement désactivées. Contactez le support.";
    }
    if (m.contains('invalid email address') ||
        m.contains('email must be valid') ||
        m.contains('email address is invalid') ||
        m.contains('valid email address is required')) {
      return "Adresse email invalide.";
    }
    if (m.contains('phone') && m.contains('invalid')) {
      return "Numéro de téléphone invalide.";
    }
    return "Une erreur s'est produite : $message";
  }

  /// Traduit une erreur inconnue (non-AuthException) en message lisible en français.
  static String _friendlyUnknownError(dynamic error) {
    final s = error.toString().toLowerCase();
    if (_looksLikeNetworkBlock(s)) {
      return _webviewBlockedMsg;
    }
    if (s.contains('socketexception') ||
        s.contains('connection refused') ||
        s.contains('no address associated') ||
        s.contains('network is unreachable')) {
      return "Impossible de se connecter. Vérifiez votre connexion internet et réessayez.";
    }
    if (s.contains('timeoutexception') || s.contains('timed out')) {
      return "La connexion a pris trop de temps. Vérifiez votre connexion et réessayez.";
    }
    // Return clean message without the "Exception:" prefix
    return error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  }

  /// Signup avec metadata (prenom/nom/role).
  /// `identifier` = email OU téléphone E.164 (ex: +221783042838)
  static Future<SignupOutcome> signupWithMetadata({
    required String identifier,
    required String password,
    required String prenom,
    required String nom,
    required String role,
  }) async {
    final cleanIdentifier = identifier.trim();
    final cleanPrenom = prenom.trim();
    final cleanNom = nom.trim();

    if (cleanIdentifier.isEmpty) {
      throw Exception(
          "Veuillez renseigner un email ou un numéro de téléphone.");
    }
    if (cleanPrenom.isEmpty) {
      throw Exception("Veuillez renseigner votre prénom.");
    }
    if (cleanNom.isEmpty) {
      throw Exception("Veuillez renseigner votre nom.");
    }
    if (password.length < 8) {
      throw Exception("Le mot de passe doit contenir au moins 8 caractères.");
    }

    // IMPORTANT (Flutter Web + path routing):
    final redirectTo = kIsWeb ? '${Uri.base.origin}/auth/callback' : null;

    // ignore: avoid_print
    print("[AuthService][signup] start identifier=$cleanIdentifier role=$role "
        "prenomLen=${cleanPrenom.length} nomLen=${cleanNom.length} "
        "isWeb=$kIsWeb origin=${kIsWeb ? Uri.base.origin : 'n/a'}");

    try {
      final data = <String, dynamic>{
        'prenom': cleanPrenom,
        'nom': cleanNom,
        'role': role,
      };

      AuthResponse res;

      if (_looksLikeEmail(cleanIdentifier)) {
        final email = cleanIdentifier.toLowerCase();
        res = await _supabase.auth.signUp(
          email: email,
          password: password,
          emailRedirectTo: redirectTo,
          data: data,
        );
      } else {
        if (!_looksLikeE164Phone(cleanIdentifier)) {
          throw Exception(
            "Numéro invalide. Utilisez le format international E.164, ex: +221783042838",
          );
        }
        // Supabase envoie automatiquement un OTP SMS ici — ne pas appeler
        // sendPhoneOtp() ensuite, ce serait un double envoi → 429.
        // Phone must be in full E.164 format (with "+") for Twilio OTP delivery.
        res = await _supabase.auth.signUp(
          phone: cleanIdentifier,
          password: password,
          data: data,
        );
      }

      // ignore: avoid_print
      print("[AuthService][signup] signUp() done userId=${res.user?.id} "
          "email=${res.user?.email} phone=${res.user?.phone} "
          "session=${res.session != null}");

      if (res.session == null) {
        return SignupOutcome.confirmationRequired;
      }
      return SignupOutcome.signedIn;
    } on AuthException catch (e) {
      // ignore: avoid_print
      print(
          "[AuthService][signup] AuthException status=${e.statusCode} message=${e.message}");

      if (_is429(e.statusCode)) {
        throw Exception(
          "Trop de tentatives d'inscription pour le moment. "
          "Veuillez patienter quelques minutes puis réessayer.\n\n"
          "Si le problème persiste, contactez tech@ngom-holding.com.",
        );
      }

      throw Exception(_friendlyAuthMessage(e.message));
    } catch (e) {
      // ignore: avoid_print
      print("[AuthService][signup] Unknown error: $e");
      throw Exception(_friendlyUnknownError(e));
    }
  }

  /// Envoi d'un code OTP par SMS via Supabase.
  /// À utiliser UNIQUEMENT pour le renvoi manuel (bouton "Renvoyer le code").
  /// Ne pas appeler après signUp() — Supabase envoie déjà l'OTP automatiquement.
  static Future<void> sendPhoneOtp(String phoneE164) async {
    final cleanPhone = phoneE164.trim();

    if (!_looksLikeE164Phone(cleanPhone)) {
      throw Exception(
        "Numéro invalide. Utilisez le format international E.164, ex: +221783042838",
      );
    }

    // ignore: avoid_print
    print("[AuthService][sendPhoneOtp] start phone=$cleanPhone");

    try {
      // Phone must be in full E.164 format (with "+") for Twilio OTP delivery.
      await _supabase.auth.signInWithOtp(
        phone: cleanPhone,
      );
      // ignore: avoid_print
      print("[AuthService][sendPhoneOtp] OK");
    } on AuthException catch (e) {
      // ignore: avoid_print
      print(
          "[AuthService][sendPhoneOtp] AuthException status=${e.statusCode} message=${e.message}");

      if (_is429(e.statusCode)) {
        throw Exception(
          "Un code SMS a déjà été envoyé récemment. "
          "Veuillez patienter quelques secondes avant de redemander un code.",
        );
      }

      throw Exception(_friendlyAuthMessage(e.message));
    } catch (e) {
      // ignore: avoid_print
      print("[AuthService][sendPhoneOtp] Unknown error: $e");
      throw Exception(_friendlyUnknownError(e));
    }
  }

  /// Vérifie un code OTP SMS via Supabase (nécessite Phone provider configuré)
  static Future<void> verifyPhoneOtp({
    required String phoneE164,
    required String token,
  }) async {
    final cleanPhone = phoneE164.trim();
    final cleanToken = token.trim();

    if (!_looksLikeE164Phone(cleanPhone)) {
      throw Exception("Numéro invalide (E.164).");
    }
    if (cleanToken.length < 4) {
      throw Exception("Code invalide.");
    }

    // ignore: avoid_print
    print(
        "[AuthService][verifyPhoneOtp] start phone=$cleanPhone tokenLen=${cleanToken.length}");

    try {
      // Phone must be in full E.164 format (with "+") for Twilio OTP delivery.
      await _supabase.auth.verifyOTP(
        type: OtpType.sms,
        phone: cleanPhone,
        token: cleanToken,
      );
      // ignore: avoid_print
      print("[AuthService][verifyPhoneOtp] OK");
    } on AuthException catch (e) {
      // ignore: avoid_print
      print(
          "[AuthService][verifyPhoneOtp] AuthException status=${e.statusCode} message=${e.message}");

      if (_is429(e.statusCode)) {
        throw Exception(
          "Trop de tentatives de vérification. Veuillez patienter avant de réessayer.",
        );
      }

      throw Exception(_friendlyAuthMessage(e.message));
    } catch (e) {
      // ignore: avoid_print
      print("[AuthService][verifyPhoneOtp] Unknown error: $e");
      throw Exception(_friendlyUnknownError(e));
    }
  }

  /// Login avec email OU téléphone + password
  static Future<void> login(String identifier, String password) async {
    final cleanIdentifier = identifier.trim();

    if (cleanIdentifier.isEmpty) {
      throw Exception(
          "Veuillez renseigner un email ou un numéro de téléphone.");
    }

    // ignore: avoid_print
    print("[AuthService][login] start identifier=$cleanIdentifier");

    try {
      AuthResponse res;

      if (_looksLikeEmail(cleanIdentifier)) {
        res = await _supabase.auth.signInWithPassword(
          email: cleanIdentifier.toLowerCase(),
          password: password,
        );
      } else {
        if (!_looksLikeE164Phone(cleanIdentifier)) {
          throw Exception(
            "Numéro invalide. Utilisez le format international E.164, ex: +221783042838",
          );
        }
        res = await _supabase.auth.signInWithPassword(
          phone: cleanIdentifier,
          password: password,
        );
      }

      // ignore: avoid_print
      print(
          "[AuthService][login] done userId=${res.user?.id} session=${res.session != null}");

      if (res.user == null || res.session == null) {
        throw Exception('Connexion échouée. Vérifiez vos identifiants.');
      }
    } on AuthException catch (e) {
      // ignore: avoid_print
      print(
          "[AuthService][login] AuthException status=${e.statusCode} message=${e.message}");
      if (_is429(e.statusCode)) {
        throw Exception(
          "Trop de tentatives de connexion. Veuillez patienter quelques minutes puis réessayer.",
        );
      }
      throw Exception(_friendlyAuthMessage(e.message));
    } catch (e) {
      // ignore: avoid_print
      print("[AuthService][login] Unknown error: $e");
      throw Exception(_friendlyUnknownError(e));
    }
  }

  static Future<void> resetPasswordForEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (!_looksLikeEmail(cleanEmail)) {
      throw Exception("Veuillez entrer une adresse e-mail valide.");
    }

    // ignore: avoid_print
    print("[AuthService][resetPassword] start email=$cleanEmail isWeb=$kIsWeb");

    try {
      await _supabase.auth.resetPasswordForEmail(
        cleanEmail,
        redirectTo: kIsWeb ? '${Uri.base.origin}/reset-password' : null,
      );
      // ignore: avoid_print
      print("[AuthService][resetPassword] OK");
    } on AuthException catch (e) {
      // ignore: avoid_print
      print(
          "[AuthService][resetPassword] AuthException status=${e.statusCode} message=${e.message}");

      if (_is429(e.statusCode)) {
        throw Exception(
          "Trop de demandes de réinitialisation pour le moment. "
          "Veuillez patienter quelques minutes puis réessayer.",
        );
      }

      throw Exception(_friendlyAuthMessage(e.message));
    } catch (e) {
      // ignore: avoid_print
      print("[AuthService][resetPassword] Unknown error: $e");
      throw Exception(_friendlyUnknownError(e));
    }
  }

  static Future<void> logout() async {
    // ignore: avoid_print
    print("[AuthService][logout] start");
    await _supabase.auth.signOut();
    // ignore: avoid_print
    print("[AuthService][logout] done");
  }

  /// Compat: certains services appellent `await AuthService.getJwt()`
  static Future<String?> getJwt() async {
    final token = _supabase.auth.currentSession?.accessToken;
    // ignore: avoid_print
    print("[AuthService][getJwt] token=${token == null ? 'null' : 'present'}");
    return token;
  }

  /// JWT courant (access token) si l'utilisateur est connecté
  static String? get jwt => _supabase.auth.currentSession?.accessToken;

  static bool isLoggedIn() => _supabase.auth.currentSession != null;

  static String? get userId => _supabase.auth.currentUser?.id;
  static User? get currentUser => _supabase.auth.currentUser;

  static Map<String, dynamic>? get userMetadata =>
      _supabase.auth.currentUser?.userMetadata;

  static String getCurrentRole() =>
      _supabase.auth.currentUser?.userMetadata?['role']?.toString() ?? 'user';
}
