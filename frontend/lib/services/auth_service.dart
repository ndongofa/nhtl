import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/api_config.dart';

/// Résultat du signup:
/// - signedIn: session créée (pas de confirmation requise ou auto-confirm)
/// - confirmationRequired: signup OK, mais l'utilisateur doit confirmer email/phone
/// - smsDeliveryFailed: compte créé dans Supabase mais l'envoi du SMS a échoué
///   (crédit Twilio épuisé ou panne provider). L'utilisateur peut activer
///   son compte via le bypass OTP (/api/auth/skip-phone-otp).
enum SignupOutcome {
  signedIn,
  confirmationRequired,
  smsDeliveryFailed,
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

  /// Détecte si une erreur Supabase est due à une panne de livraison SMS
  /// (crédit Twilio épuisé, provider indisponible, etc.).
  /// Dans ce cas, le compte Supabase EST créé, seul l'envoi du code a échoué.
  static bool _isSmsDeliveryFailure(String? message) {
    if (message == null) return false;
    final m = message.toLowerCase();
    // SMS-specific failure patterns (exclude "send" alone to avoid false positives
    // like "SMS send successful")
    if (m.contains('sms') &&
        (m.contains('fail') ||
            m.contains('error') ||
            m.contains('deliver') ||
            m.contains('not sent'))) {
      return true;
    }
    if (m.contains('phone message') &&
        (m.contains('fail') || m.contains('error') || m.contains('not sent'))) {
      return true;
    }
    if ((m.contains('twilio') || m.contains('messagebird') || m.contains('vonage')) &&
        (m.contains('fail') ||
            m.contains('error') ||
            m.contains('credit') ||
            m.contains('insufficient') ||
            m.contains('not active') ||
            m.contains('not authorized'))) {
      return true;
    }
    if (m.contains('insufficient') &&
        (m.contains('credit') || m.contains('fund') || m.contains('balance'))) {
      return true;
    }
    // Supabase internal error codes
    if (m.contains('otp_send_failed') ||
        m.contains('phone_provider_disabled') ||
        m.contains('sms_send_failed') ||
        m.contains('error sending confirmation')) {
      return true;
    }
    return false;
  }

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
    if (_isSmsDeliveryFailure(message)) {
      return "Le service SMS est temporairement indisponible. "
          "Votre compte a été créé. Vous pouvez l'activer sans code SMS.";
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

      // Quand Supabase crée le compte mais échoue à envoyer le SMS (ex: crédit
      // Twilio épuisé), on retourne smsDeliveryFailed au lieu de bloquer le
      // signup. Le compte existe dans Supabase ; l'utilisateur pourra activer
      // son compte via le bouton bypass sur l'écran suivant.
      // Guard: only applicable to phone signups – an email signup cannot trigger
      // an SMS delivery failure, and we want to avoid misclassifying unrelated errors.
      if (_looksLikeE164Phone(cleanIdentifier) && _isSmsDeliveryFailure(e.message)) {
        // ignore: avoid_print
        print("[AuthService][signup] SMS delivery failed – returning smsDeliveryFailed outcome");
        return SignupOutcome.smsDeliveryFailed;
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

  /// Envoi d'un code OTP pour confirmer le signup par téléphone.
  /// Le backend tente WhatsApp en premier, puis SMS Twilio en fallback.
  /// À utiliser à la place de [sendPhoneOtp] pour le flux signup.
  static Future<void> sendSignupPhoneOtp(String phoneE164) async {
    final cleanPhone = phoneE164.trim();
    if (!_looksLikeE164Phone(cleanPhone)) {
      throw Exception(
        "Numéro invalide. Utilisez le format international E.164, ex: +221783042838",
      );
    }

    // ignore: avoid_print
    print("[AuthService][sendSignupPhoneOtp] start phone=$cleanPhone");

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/auth/phone-otp/send');
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': cleanPhone}),
      );
      // ignore: avoid_print
      print("[AuthService][sendSignupPhoneOtp] status=${resp.statusCode}");
      if (resp.statusCode != 200) {
        final decoded = jsonDecode(resp.body) as Map<String, dynamic>?;
        final msg = decoded?['error']?.toString() ??
            "Impossible d'envoyer le code. Réessayez ou contactez le support.";
        throw Exception(msg);
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(_friendlyUnknownError(e));
    }
  }

  /// Vérifie le code OTP signup via le backend.
  /// En cas de succès, le backend confirme le téléphone dans Supabase via l'API admin.
  static Future<void> verifySignupPhoneOtp({
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
        "[AuthService][verifySignupPhoneOtp] start phone=$cleanPhone tokenLen=${cleanToken.length}");

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/auth/phone-otp/verify');
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': cleanPhone, 'otp': cleanToken}),
      );
      // ignore: avoid_print
      print("[AuthService][verifySignupPhoneOtp] status=${resp.statusCode}");
      if (resp.statusCode != 200) {
        final decoded = jsonDecode(resp.body) as Map<String, dynamic>?;
        final msg = decoded?['error']?.toString() ??
            "Code invalide ou expiré. Demandez un nouveau code.";
        throw Exception(msg);
      }
    } catch (e) {
      if (e is Exception) rethrow;
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
