import 'package:flutter/material.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bienvenue sur NHTL')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Plateforme de gestion NHTL',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                'Découvrez nos services de gestion de transport et de commandes.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                child: const Text("Se connecter"),
                onPressed: () => Navigator.pushNamed(context, '/login'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                child: const Text("Créer un compte"),
                onPressed: () => Navigator.pushNamed(context, '/signup'),
              ),
              const SizedBox(height: 24),
              // Boutons d’accès open à des pages publiques
              ElevatedButton.icon(
                icon: const Icon(Icons.info),
                label: const Text('Nos informations (public)'),
                onPressed: () {
                  // Naviguer vers une autre page publique, créer si besoin
                  // Navigator.pushNamed(context, '/infos');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
