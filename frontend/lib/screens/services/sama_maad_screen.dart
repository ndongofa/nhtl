// lib/screens/services/sama_maad_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ecommerce/catalogue_screen.dart';
import '../../providers/panier_provider.dart';

class SamaMaadScreen extends StatelessWidget {
  const SamaMaadScreen({Key? key}) : super(key: key);

  static const Color _green = Color(0xFF16A34A);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PanierProvider(serviceType: 'maad'),
      child: const CatalogueScreen(
        serviceType: 'maad',
        serviceLabel: 'Sama Maad',
        serviceEmoji: '🌿',
        accentColor: _green,
      ),
    );
  }
}

