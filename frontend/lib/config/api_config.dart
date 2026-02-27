import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:logger/logger.dart';

// REMARQUE : Cette config sert uniquement aux appels "backend" (Spring Boot).
// Les appels Supabase (auth, BDD directes) s’utilisent via SupabaseClient dans Flutter.

class ApiConfig {
  static final logger = Logger();

  /// Retourne l'URL de base selon la plateforme (SANS /api à la fin !!)
  static String get baseUrl {
    final url = 'https://nhtl-production-5e78.up.railway.app';
    if (kIsWeb) {
      logger.i('🌐 Plateforme Web détectée');
      return url;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        logger.i('🤖 Plateforme Android détectée');
        return url;
      case TargetPlatform.iOS:
        logger.i('🍎 Plateforme iOS détectée');
        return url;
      case TargetPlatform.windows:
        logger.i('💻 Plateforme Windows détectée');
        return url;
      case TargetPlatform.macOS:
        logger.i('🍏 Plateforme macOS détectée');
        return url;
      case TargetPlatform.linux:
        logger.i('🐧 Plateforme Linux détectée');
        return url;
      default:
        logger.i('📦 Plateforme inconnue');
        return url;
    }
  }

  /// Endpoints spécifiques (iels commencent par "/")
  static const String transportEndpoint = '/api/transports';
  static const String commandeEndpoint = '/api/commandes';
  static const String userEndpoint = '/api/users';

  /// Timeout
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
