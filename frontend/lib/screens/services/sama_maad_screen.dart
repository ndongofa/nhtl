// lib/screens/services/sama_maad_screen.dart

import 'package:flutter/material.dart';
import 'sama_coming_soon_screen.dart';

class SamaMaadScreen extends StatelessWidget {
  const SamaMaadScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => const SamaComingSoonScreen(
        emoji: '🌿',
        name: 'Sama Maad',
        tagline: 'Le meilleur du Maad sénégalais, livré en France',
        description: 'Nous sélectionnons les meilleures variétés de Maad '
            'directement auprès de producteurs sénégalais, '
            'pour vous les livrer frais à Paris et partout en France.',
        accentColor: Color(0xFF16A34A),
        teaser: [
          'Maad frais sélectionné à la source au Sénégal',
          'Livraison express par avion pour garantir la fraîcheur',
          'Commandes à la caisse, au kg ou en box découverte',
          'Disponible à Paris et livraison en France metropolitaine',
        ],
        whatsappMessage:
            "Bonjour SAMA, je suis intéressé par le service Sama Maad. Pouvez-vous m'avertir à l'ouverture ?",
      );
}
