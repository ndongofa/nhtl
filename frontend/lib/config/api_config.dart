import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:logger/logger.dart';

class ApiConfig {
  static final logger = Logger();

  /// Retourne l'URL de base selon la plateforme
  static String get baseUrl {
    if (kIsWeb) {
      logger.i('🌐 Plateforme Web détectée');
      return 'https://nhtl-production-46e3.up.railway.app/api';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        logger.i('🤖 Plateforme Android détectée');
        return 'https://nhtl-production-46e3.up.railway.app/api';
      case TargetPlatform.iOS:
        logger.i('🍎 Plateforme iOS détectée');
        return 'https://nhtl-production-46e3.up.railway.app/api';
      case TargetPlatform.windows:
        logger.i('💻 Plateforme Windows détectée');
        return 'https://nhtl-production-46e3.up.railway.app/api';
      case TargetPlatform.macOS:
        logger.i('🍏 Plateforme macOS détectée');
        return 'https://nhtl-production-46e3.up.railway.app/api';
      case TargetPlatform.linux:
        logger.i('🐧 Plateforme Linux détectée');
        return 'https://nhtl-production-46e3.up.railway.app/api';
      default:
        logger.i('📦 Plateforme inconnue');
        return 'https://nhtl-production-46e3.up.railway.app/api';
    }
  }

  /// Endpoints spécifiques
  static const String transportEndpoint = '/transports';
  static const String commandeEndpoint = '/commandes';

  /// Timeout
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
