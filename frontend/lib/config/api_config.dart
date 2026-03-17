import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:logger/logger.dart';

class ApiConfig {
  static final logger = Logger();

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

  static const String transportEndpoint = '/api/transports';
  static const String commandeEndpoint = '/api/commandes';
  static const String userEndpoint = '/api/users';

  // admin users (nouveau controller Spring)
  static const String adminUserEndpoint = '/api/admin/users';

  // admin commandes/transports (AdminController existant)
  static const String adminCommandeEndpoint = '/admin/commandes/all';
  static const String adminTransportEndpoint = '/admin/transports/all';

  static const String commandeStatutSearchEndpoint =
      '/api/commandes/search/statut';
  static const String transportStatutSearchEndpoint =
      '/api/transports/search/statut';

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
