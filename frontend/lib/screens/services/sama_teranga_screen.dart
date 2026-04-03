// lib/screens/services/sama_teranga_screen.dart

import 'package:flutter/material.dart';
import '../ecommerce/ecommerce_hub_screen.dart';

class SamaTerangaScreen extends StatelessWidget {
  const SamaTerangaScreen({Key? key}) : super(key: key);

  static const Color _red = Color(0xFFDC2626);

  @override
  Widget build(BuildContext context) {
    return const EcommerceHubScreen(
      serviceType: 'teranga',
      serviceLabel: 'Sama Téranga Apéro',
      accentColor: _red,
    );
  }
}

