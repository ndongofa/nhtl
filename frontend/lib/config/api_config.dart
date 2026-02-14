
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:logger/logger.dart';

class ApiConfig {
  static final logger = Logger();

  // URL de base selon la plateforme
  static String get baseUrl {
    if (kIsWeb) {
      logger.i('🌐 Plateforme Web détectée');
      return 'http://localhost:8080/api';
    } else if (Platform.isAndroid) {
      logger.i('🤖 Plateforme Android détectée');
      return 'http://10.0.2.2:8080/api';
    } else if (Platform.isIOS) {
      logger.i('🍎 Plateforme iOS détectée');
      return 'http://localhost:8080/api';
    } else if (Platform.isWindows) {
      logger.i('💻 Plateforme Windows détectée');
      return 'http://localhost:8080/api';
    } else {
      return 'http://localhost:8080/api';
    }
  }

  static const String transportEndpoint = '/transports';
  static const String commandeEndpoint = '/commandes';
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}