// lib/screens/services/sama_maillot_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/panier_provider.dart';
import '../ecommerce/catalogue_screen.dart';

class SamaMaillotScreen extends StatelessWidget {
  const SamaMaillotScreen({Key? key}) : super(key: key);

  static const Color _green = Color(0xFF009A44); // vert du drapeau sénégalais

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PanierProvider(serviceType: 'maillot'),
      child: const CatalogueScreen(
        serviceType: 'maillot',
        serviceLabel: 'Sama Maillot',
        serviceEmoji: '🇸🇳',
        accentColor: _green,
      ),
    );
  }
}
