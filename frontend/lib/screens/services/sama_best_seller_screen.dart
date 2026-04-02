// lib/screens/services/sama_best_seller_screen.dart

import 'package:flutter/material.dart';
import 'sama_coming_soon_screen.dart';

class SamaBestSellerScreen extends StatelessWidget {
  const SamaBestSellerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => const SamaComingSoonScreen(
        emoji: '⭐',
        name: 'Sama Best Seller',
        tagline: 'Les articles les plus demandés, à portée de main',
        description: 'Une sélection hebdomadaire des articles les plus '
            'commandés par notre communauté : mode, high-tech, '
            'beauté, maison et bien plus encore à prix compétitifs.',
        accentColor: Color(0xFF7C3AED),
        teaser: [
          'Sélection hebdomadaire des 20 articles les plus populaires',
          'Mode, high-tech, beauté, maison et lifestyle',
          'Prix négociés en volume pour des tarifs avantageux',
          'Commande groupée — livraison optimisée Paris · Dakar · Casa',
        ],
        whatsappMessage:
            "Bonjour SAMA, je suis intéressé par le service Sama Best Seller. Pouvez-vous m'avertir à l'ouverture ?",
      );
}
