import 'package:flutter/material.dart';
import 'package:sama/screens/admin/admin_user_screen.dart';
import 'package:sama/screens/transport_form_screen.dart';
import 'package:sama/screens/transports_list_screen.dart';

// ✅ NEW: debug token helper
import 'package:sama/debug/debug_token.dart';

import '../services/auth_service.dart';
import '../models/logged_user.dart';
import 'commande_form_screen.dart';
import 'commandes_list_screen.dart';
import 'gp/gp_list_screen.dart';
import 'notifications/notifications_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  void _handleLogout(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await AuthService.logout();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false,
                );
              }
            },
            child: const Text(
              'Déconnecter',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = LoggedUser.fromSupabase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('SAMA Services International'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
            tooltip: 'Notifications',
          ),

          // ✅ NEW: Quick debug button (prints access token in console)
          // Tu peux le laisser seulement en debug (voir note plus bas).
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              printSupabaseTokens();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Token imprimé dans la console (Debug Console / Logcat).',
                  ),
                ),
              );
            },
            tooltip: 'Debug: Print token',
          ),

          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.of(context).pushNamed('/profile');
            },
            tooltip: 'Mon profil',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                'Bienvenue sur SAMA Services International',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Gérez vos transports, commandes et vos demandes en toute simplicité',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              _buildButton(
                context,
                'Nouveau Transport',
                Icons.local_shipping,
                () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TransportFormScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildButton(
                context,
                'Nouvelle Commande',
                Icons.shopping_cart,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CommandeFormScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildButton(
                context,
                'Mes Transports',
                Icons.list,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TransportListScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildButton(
                context,
                'Mes Commandes',
                Icons.receipt,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CommandesListScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),
              if (user.role == 'admin')
                _buildButton(
                  context,
                  'GP (Agents de transport)',
                  Icons.badge_outlined,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const GpListScreen()),
                    );
                  },
                ),
              const SizedBox(height: 12),
              if (user.role == 'admin')
                _buildButton(
                  context,
                  'Gestion des Utilisateurs',
                  Icons.people,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AdminUserScreen()),
                    );
                  },
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
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
