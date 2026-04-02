// lib/screens/admin/admin_dashboard_screen.dart

import 'package:flutter/material.dart';

import '../../models/logged_user.dart';
import '../../services/auth_service.dart';
import '../achats_archives_screen.dart';
import '../achats_list_screen.dart';
import '../admin_ecommerce/admin_produit_list_screen.dart';
import '../commandes_archives_screen.dart';
import '../commandes_list_screen.dart';
import '../gp/gp_list_screen.dart';
import '../notifications/notifications_screen.dart';
import '../transports_archives_screen.dart';
import '../transports_list_screen.dart';
import 'admin_departures_screen.dart';
import 'admin_user_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  // ── Palette (identique aux autres écrans admin) ───────────────────────────
  static const Color _bg = Color(0xFF0D1B2E);
  static const Color _bgSection = Color(0xFF112236);
  static const Color _appBlue = Color(0xFF2296F3);
  static const Color _amber = Color(0xFFFFB300);
  static const Color _teal = Color(0xFF00D4C8);
  static const Color _green = Color(0xFF22C55E);
  static const Color _textPrimary = Color(0xFFF0F6FF);
  static const Color _textMuted = Color(0xFF7A94B0);

  void _go(BuildContext context, Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

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
    final pad = isDesktop ? 24.0 : 16.0;

    // ── Sections ─────────────────────────────────────────────────────────────
    final sections = <_Section>[
      _Section(
        label: 'OPÉRATIONS',
        cards: [
          _DashCard(
            icon: Icons.local_shipping_outlined,
            label: 'Transports',
            sub: 'Gérer tous les transports',
            color: _appBlue,
            onTap: () => _go(context, const TransportListScreen()),
          ),
          _DashCard(
            icon: Icons.shopping_bag_outlined,
            label: 'Commandes',
            sub: 'Gérer toutes les commandes',
            color: _amber,
            onTap: () => _go(context, const CommandesListScreen()),
          ),
          _DashCard(
            icon: Icons.storefront_outlined,
            label: 'Achats',
            sub: 'Gérer tous les achats',
            color: _teal,
            onTap: () => _go(context, const AchatsListScreen()),
          ),
        ],
      ),
      _Section(
        label: 'ARCHIVES',
        cards: [
          _DashCard(
            icon: Icons.inventory_2_outlined,
            label: 'Archives Transports',
            sub: 'Transports archivés',
            color: const Color(0xFF6366F1),
            onTap: () =>
                _go(context, const TransportArchivesScreen(isAdmin: true)),
          ),
          _DashCard(
            icon: Icons.archive_outlined,
            label: 'Archives Commandes',
            sub: 'Commandes archivées',
            color: const Color(0xFFD97706),
            onTap: () =>
                _go(context, const CommandesArchivesScreen(isAdmin: true)),
          ),
          _DashCard(
            icon: Icons.folder_zip_outlined,
            label: 'Archives Achats',
            sub: 'Achats archivés',
            color: const Color(0xFF0D9488),
            onTap: () =>
                _go(context, const AchatsArchivesScreen(isAdmin: true)),
          ),
        ],
      ),
      _Section(
        label: 'CONFIGURATION',
        cards: [
          _DashCard(
            icon: Icons.people_outline,
            label: 'Utilisateurs',
            sub: 'Gérer les comptes',
            color: _appBlue,
            onTap: () => _go(context, const AdminUserScreen()),
          ),
          _DashCard(
            icon: Icons.support_agent_outlined,
            label: 'GPs',
            sub: 'Agents de groupage',
            color: _teal,
            onTap: () => _go(context, const GpListScreen()),
          ),
          _DashCard(
            icon: Icons.flight_takeoff_outlined,
            label: 'Départs',
            sub: 'Planifier les départs GP',
            color: _amber,
            onTap: () => _go(context, const AdminDeparturesScreen()),
          ),
          _DashCard(
            icon: Icons.notifications_outlined,
            label: 'Notifications',
            sub: 'Historique des notifications',
            color: _green,
            onTap: () => _go(context, const NotificationsScreen()),
          ),
        ],
      ),
      _Section(
        label: 'E-COMMERCE',
        cards: [
          _DashCard(
            icon: Icons.eco_outlined,
            label: 'Produits Maad',
            sub: 'Catalogue Sama Maad',
            color: const Color(0xFF16A34A),
            onTap: () => _go(
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
            onTap: () => _go(
              context,
              const AdminProduitListScreen(
                  serviceType: 'teranga',
                  serviceLabel: 'Sama Téranga Apéro'),
            ),
          ),
          _DashCard(
            icon: Icons.star_outline,
            label: 'Produits Best Seller',
            sub: 'Catalogue Best Seller',
            color: const Color(0xFF7C3AED),
            onTap: () => _go(
              context,
              const AdminProduitListScreen(
                  serviceType: 'bestseller',
                  serviceLabel: 'Sama Best Seller'),
            ),
          ),
        ],
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
                style: const TextStyle(color: _textMuted, fontSize: 11),
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
      body: SingleChildScrollView(
        padding: EdgeInsets.all(pad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final section in sections) ...[
              _SectionHeader(label: section.label),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: isDesktop ? 1.65 : 1.2,
                children: section.cards
                    .map((c) => _AdminTile(card: c))
                    .toList(),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Data ──────────────────────────────────────────────────────────────────────

class _Section {
  final String label;
  final List<_DashCard> cards;
  const _Section({required this.label, required this.cards});
}

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

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  static const Color _textMuted = Color(0xFF7A94B0);
  static const Color _border = Color(0xFF1E3A55);

  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(
        label,
        style: const TextStyle(
          color: _textMuted,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 1.4,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(child: Divider(color: _border, thickness: 1)),
    ]);
  }
}

// ── Tile ──────────────────────────────────────────────────────────────────────

class _AdminTile extends StatelessWidget {
  final _DashCard card;
  static const Color _bgCard = Color(0xFF1A2E45);
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
              color: card.color.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: card.color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(card.icon, color: card.color, size: 20),
            ),
            const Spacer(),
            Text(
              card.label,
              style: const TextStyle(
                color: _textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
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
