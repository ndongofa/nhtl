// lib/screens/services/sama_teranga_screen.dart

import 'package:flutter/material.dart';
import 'sama_coming_soon_screen.dart';

class SamaTerangaScreen extends StatelessWidget {
  const SamaTerangaScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => const SamaComingSoonScreen(
        emoji: '🥂',
        name: 'Sama Téranga Apéro',
        tagline: 'L\'apéro sénégalais authentique à Paris',
        description: 'Bissap, Gnamakoudji, Ditax, Bouye, Jus de Baobab, '
            'et toutes les boissons & snacks sénégalais pour sublimer '
            'vos apéros avec la chaleur de la téranga.',
        accentColor: Color(0xFFDC2626),
        teaser: [
          'Bissap, Gnamakoudji, Ditax et jus de fruits exotiques',
          'Snacks & biscuits sénégalais traditionnels',
          'Boxes apéro thématiques à commander pour vos événements',
          'Livraison à Paris et en Île-de-France',
        ],
        whatsappMessage:
            "Bonjour SAMA, je suis intéressé par le service Sama Téranga Apéro. Pouvez-vous m'avertir à l'ouverture ?",
      );
}
