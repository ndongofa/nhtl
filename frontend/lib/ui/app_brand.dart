import 'package:flutter/material.dart';

class AppBrand {
  static const String appName = 'Sama Services International';
  static const String supportEmail = 'tech@ngom-holding.com';

  // Couleur principale (modifiable plus tard)
  static const int primaryColorValue = 0xFF1976D2;

  /// Taille de police responsive pour le nom de l'application,
  /// proportionnelle à la largeur de l'écran (min 12, max 16).
  static double appNameFontSize(BuildContext context) =>
      (MediaQuery.sizeOf(context).width * 0.035).clamp(12.0, 16.0);
}
