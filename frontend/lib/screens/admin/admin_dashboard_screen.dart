// lib/screens/admin/admin_dashboard_screen.dart

import 'package:flutter/material.dart';

import '../../models/logged_user.dart';
import '../../services/auth_service.dart';
import '../admin_ecommerce/admin_produit_list_screen.dart';
import '../gp/gp_list_screen.dart';
import 'admin_departures_screen.dart';
import 'admin_user_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  static const Color _bg = Color(0xFF0D1B2E);
  static const Color _bgSection = Color(0xFF112236);
  static const Color _bgCard = Color(0xFF1A2E45);
  static const Color _appBlue = Color(0xFF2296F3);
  static const Color _amber = Color(0xFFFFB300);
  static const Color _teal = Color(0xFF00D4C8);
  static const Color _textPrimary = Color(0xFFF0F6FF);
  static const Color _textMuted = Color(0xFF7A94B0);
  static const Color _border = Color(0xFF1E3A55);

  void _navigate(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _logout(BuildContext context) async {
    await AuthService.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final logged = LoggedUser.fromSupabase();

    if (logged.role != 'admin') {
      return Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bgSection,
          title: const Text('Sécurité',
              style: TextStyle(
                  color: _textPrimary, fontWeight: FontWeight.w800)),
        ),
        body: const Center(
          child: Text('Accès refusé.',
              style: TextStyle(color: _textPrimary, fontSize: 16)),
        ),
      );
    }

    final w = MediaQuery.of(context).size.width;
    final isDesktop = w >= 700;
    final crossCount = isDesktop ? 3 : 2;

    final items = <_DashCard>[
      _DashCard(
        icon: Icons.people_outline,
        label: 'Utilisateurs',
        sub: 'Gérer les comptes',
        color: _appBlue,
        onTap: () => _navigate(context, const AdminUserScreen()),
      ),
      _DashCard(
        icon: Icons.support_agent_outlined,
        label: 'GPs',
        sub: 'Agents de groupage',
        color: _teal,
        onTap: () => _navigate(context, const GpListScreen()),
      ),
      _DashCard(
        icon: Icons.flight_takeoff_outlined,
        label: 'Départs',
        sub: 'Planifier les départs GP',
        color: _amber,
        onTap: () => _navigate(context, const AdminDeparturesScreen()),
      ),
      _DashCard(
        icon: Icons.eco_outlined,
        label: 'Produits Maad',
        sub: 'Catalogue Sama Maad',
        color: const Color(0xFF16A34A),
        onTap: () => _navigate(
          context,
          const AdminProduitListScreen(
              serviceType: 'maad', serviceLabel: 'Sama Maad'),
        ),
      ),
      _DashCard(
        icon: Icons.wine_bar_outlined,
        label: 'Produits Téranga',
        sub: 'Catalogue Téranga Apéro',
        color: const Color(0xFFDC2626),
        onTap: () => _navigate(
          context,
          const AdminProduitListScreen(
              serviceType: 'teranga', serviceLabel: 'Sama Téranga Apéro'),
        ),
      ),
      _DashCard(
        icon: Icons.star_outline,
        label: 'Produits Best Seller',
        sub: 'Catalogue Best Seller',
        color: const Color(0xFF7C3AED),
        onTap: () => _navigate(
          context,
          const AdminProduitListScreen(
              serviceType: 'bestseller', serviceLabel: 'Sama Best Seller'),
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bgSection,
        elevation: 0,
        iconTheme: const IconThemeData(color: _textPrimary),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tableau de bord Admin',
              style: TextStyle(
                  color: _textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16),
            ),
            if (logged.fullName != null || logged.email.isNotEmpty)
              Text(
                logged.fullName ?? logged.email,
                style:
                    const TextStyle(color: _textMuted, fontSize: 11),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: _textPrimary),
            tooltip: 'Profil',
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: _textPrimary),
            tooltip: 'Déconnexion',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(isDesktop ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'FONCTIONNALITÉS ADMIN',
              style: const TextStyle(
                color: _textMuted,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossCount,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: isDesktop ? 1.6 : 1.3,
                ),
                itemCount: items.length,
                itemBuilder: (_, i) => _AdminTile(card: items[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Data ──────────────────────────────────────────────────────────────────────

class _DashCard {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  final VoidCallback onTap;

  const _DashCard({
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
    required this.onTap,
  });
}

// ── Tile ──────────────────────────────────────────────────────────────────────

class _AdminTile extends StatelessWidget {
  final _DashCard card;
  static const Color _bg = Color(0xFF0D1B2E);
  static const Color _bgCard = Color(0xFF1A2E45);
  static const Color _border = Color(0xFF1E3A55);
  static const Color _textPrimary = Color(0xFFF0F6FF);
  static const Color _textMuted = Color(0xFF7A94B0);

  const _AdminTile({required this.card});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: card.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: card.color.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: card.color.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: card.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(card.icon, color: card.color, size: 22),
            ),
            const Spacer(),
            Text(
              card.label,
              style: const TextStyle(
                color: _textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              card.sub,
              style: const TextStyle(color: _textMuted, fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
