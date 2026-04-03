// lib/screens/services/sama_maad_screen.dart

import 'package:flutter/material.dart';
import '../ecommerce/ecommerce_hub_screen.dart';

class SamaMaadScreen extends StatelessWidget {
  const SamaMaadScreen({Key? key}) : super(key: key);

  static const Color _green = Color(0xFF16A34A);

  @override
  Widget build(BuildContext context) {
    return const EcommerceHubScreen(
      serviceType: 'maad',
      serviceLabel: 'Sama Maad',
      accentColor: _green,
    );
  }
}

