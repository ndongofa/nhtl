import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:logger/logger.dart';

class ApiConfig {
  static final logger = Logger();

  static const bool useLocal = true;
  static const int localPort = 8080;

  static const String railwayUrl =
      'https://nhtl-production-5e78.up.railway.app';

  static String get localUrl {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:$localPort';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return 'http://localhost:$localPort';
      default:
        return 'http://localhost:$localPort';
    }
  }

  static String get baseUrl {
    if (useLocal) {
      logger.i('🔁 Mode LOCAL activé');
      return localUrl;
    } else {
      logger.i('🌐 Mode Railway/Prod activé');
      return railwayUrl;
    }
  }

  static const String transportEndpoint = '/api/transports';
  static const String commandeEndpoint = '/api/commandes';
  static const String userEndpoint = '/api/users';

  static const String adminUserEndpoint = '/api/admin/users';

  static const String adminCommandeEndpoint = '/admin/commandes/all';
  static const String adminTransportEndpoint = '/admin/transports/all';

  static const String commandeStatutSearchEndpoint =
      '/api/commandes/search/statut';
  static const String transportStatutSearchEndpoint =
      '/api/transports/search/statut';

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
