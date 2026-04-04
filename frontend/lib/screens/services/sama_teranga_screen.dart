// lib/screens/services/sama_teranga_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/panier_provider.dart';
import '../ecommerce/catalogue_screen.dart';

class SamaTerangaScreen extends StatelessWidget {
  const SamaTerangaScreen({Key? key}) : super(key: key);

  static const Color _red = Color(0xFFDC2626);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PanierProvider(serviceType: 'teranga'),
      child: const CatalogueScreen(
        serviceType: 'teranga',
        serviceLabel: 'Sama Téranga Apéro',
        serviceEmoji: '🥂',
        accentColor: _red,
      ),
    );
  }
}

