// lib/screens/services/sama_best_seller_screen.dart

import 'package:flutter/material.dart';
import '../ecommerce/ecommerce_hub_screen.dart';

class SamaBestSellerScreen extends StatelessWidget {
  const SamaBestSellerScreen({Key? key}) : super(key: key);

  static const Color _purple = Color(0xFF7C3AED);

  @override
  Widget build(BuildContext context) {
    return const EcommerceHubScreen(
      serviceType: 'bestseller',
      serviceLabel: 'Sama Best Seller',
      accentColor: _purple,
    );
  }
}

