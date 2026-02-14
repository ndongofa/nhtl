import 'package:flutter/material.dart';
import 'transport_form_screen.dart';
import 'commande_form_screen.dart';
import 'transports_list_screen.dart';
import 'commandes_list_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NHTL'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                'Bienvenue sur NHTL',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Gérez vos transports et commandes',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              _buildButton(
                context,
                'Nouveau Transport',
                Icons.local_shipping,
                const TransportFormScreen(),
              ),
              const SizedBox(height: 12),
              _buildButton(
                context,
                'Nouvelle Commande',
                Icons.shopping_cart,
                const CommandeFormScreen(),
              ),
              const SizedBox(height: 12),
              _buildButton(
                context,
                'Mes Transports',
                Icons.list,
                const TransportsListScreen(),
              ),
              const SizedBox(height: 12),
              _buildButton(
                context,
                'Mes Commandes',
                Icons.receipt,
                const CommandesListScreen(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(
    BuildContext context,
    String label,
    IconData icon,
    Widget screen,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screen),
          );
        },
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
