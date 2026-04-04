// lib/screens/services/sama_best_seller_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/panier_provider.dart';
import '../ecommerce/catalogue_screen.dart';

class SamaBestSellerScreen extends StatelessWidget {
  const SamaBestSellerScreen({Key? key}) : super(key: key);

  static const Color _purple = Color(0xFF7C3AED);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PanierProvider(serviceType: 'bestseller'),
      child: const CatalogueScreen(
        serviceType: 'bestseller',
        serviceLabel: 'Sama Best Seller',
        serviceEmoji: '⭐',
        accentColor: _purple,
      ),
    );
  }
}

