// lib/screens/achat_hub_screen.dart
// Page intermédiaire post-login Achat
// Accès : après connexion depuis SamaAchatScreen

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/sama_account_menu.dart';
import '../providers/app_theme_provider.dart';
import '../services/auth_service.dart';
import 'achat_form_screen.dart';
import 'achats_list_screen.dart';

class AchatHubScreen extends StatelessWidget {
  const AchatHubScreen({Key? key}) : super(key: key);

  static const String _waFrance = "33768913074";
  static const String _waDakar = "221783042838";

  static const List<Map<String, dynamic>> _categories = [
    {"emoji": "🧵", "name": "Tissus & Wax", "color": Color(0xFF00BCD4)},
    {"emoji": "💎", "name": "Bijoux", "color": Color(0xFFFFB300)},
    {"emoji": "🌶️", "name": "Épices", "color": Color(0xFFE53935)},
    {"emoji": "🏺", "name": "Artisanat", "color": Color(0xFF8D6E63)},
    {"emoji": "💊", "name": "Santé", "color": Color(0xFF4CAF50)},
    {"emoji": "📱", "name": "High-Tech", "color": Color(0xFF2296F3)},
  ];

  Future<void> _wa(BuildContext context, String digits) async {
    final uri = Uri.parse(
      "https://wa.me/$digits?text=${Uri.encodeComponent("Bonjour SAMA, je souhaite un achat sur mesure.")}",
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    final salut = hour < 12
        ? "Bonjour"
        : hour < 18
            ? "Bon après-midi"
            : "Bonsoir";
    final meta = AuthService.userMetadata;
    final user = AuthService.currentUser;
    String prenom = meta?['prenom']?.toString().trim() ?? '';
    if (prenom.isEmpty) {
      final full = user?.email?.split('@').first ?? '';
      prenom = full.isNotEmpty
          ? full[0].toUpperCase() + full.substring(1).toLowerCase()
          : '';
    } else {
      prenom = prenom[0].toUpperCase() + prenom.substring(1).toLowerCase();
    }
    return "$salut${prenom.isNotEmpty ? ', $prenom' : ''} 👋";
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppThemeProvider>();
    final w = MediaQuery.of(context).size.width;
    final isDesktop = w >= 900;

    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.topBarBg,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 360;
            return Row(children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.20)),
                ),
                child: const Center(
                  child: Text("🏪",
                      style: TextStyle(fontSize: 18, height: 1.0)),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "Sama Achat",
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: -0.2),
                ),
              ),
              const SizedBox(width: 10),
              if (isWide)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppThemeProvider.green.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color:
                            AppThemeProvider.green.withValues(alpha: 0.45)),
                  ),
                  child: const Text("● Disponible",
                      style: TextStyle(
                          color: AppThemeProvider.green,
                          fontSize: 11,
                          fontWeight: FontWeight.w800)),
                ),
            ]);
          },
        ),
        actions: isDesktop
            ? [
                IconButton(
                  tooltip: "Mon espace",
                  icon: const Icon(Icons.dashboard_outlined),
                  onPressed: () => SamaAccountMenu.open(context),
                  splashRadius: 20,
                ),
                IconButton(
                  tooltip: "Profil",
                  icon: const Icon(Icons.person_outline),
                  onPressed: () => Navigator.pushNamed(context, '/profile'),
                  splashRadius: 20,
                ),
                IconButton(
                  tooltip:
                      t.isDark ? "Thème clair" : "Thème sombre",
                  onPressed: () =>
                      context.read<AppThemeProvider>().toggleTheme(),
                  icon: Icon(t.isDark
                      ? Icons.wb_sunny_outlined
                      : Icons.nightlight_round),
                  splashRadius: 20,
                ),
                IconButton(
                  tooltip: "Déconnexion",
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    await AuthService.logout();
                    if (!context.mounted) return;
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil('/', (_) => false);
                  },
                  splashRadius: 20,
                ),
              ]
            : [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  tooltip: "Menu",
                  onSelected: (value) async {
                    switch (value) {
                      case 'account':
                        SamaAccountMenu.open(context);
                        break;
                      case 'profile':
                        Navigator.pushNamed(context, '/profile');
                        break;
                      case 'theme':
                        context.read<AppThemeProvider>().toggleTheme();
                        break;
                      case 'logout':
                        await AuthService.logout();
                        if (!context.mounted) return;
                        Navigator.of(context)
                            .pushNamedAndRemoveUntil('/', (_) => false);
                        break;
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem<String>(
                      value: 'account',
                      child: Row(children: [
                        Icon(Icons.dashboard_outlined, size: 18),
                        SizedBox(width: 10),
                        Text("Mon espace"),
                      ]),
                    ),
                    const PopupMenuItem<String>(
                      value: 'profile',
                      child: Row(children: [
                        Icon(Icons.person_outline, size: 18),
                        SizedBox(width: 10),
                        Text("Profil"),
                      ]),
                    ),
                    PopupMenuItem<String>(
                      value: 'theme',
                      child: Row(children: [
                        Icon(
                          t.isDark
                              ? Icons.wb_sunny_outlined
                              : Icons.nightlight_round,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(t.isDark
                            ? "Thème clair"
                            : "Thème sombre"),
                      ]),
                    ),
                    const PopupMenuItem<String>(
                      value: 'logout',
                      child: Row(children: [
                        Icon(Icons.logout, size: 18, color: Colors.red),
                        SizedBox(width: 10),
                        Text("Déconnexion",
                            style: TextStyle(color: Colors.red)),
                      ]),
                    ),
                  ],
                ),
              ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 40 : 16,
          vertical: 24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(),
                  style: TextStyle(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Que souhaitez-vous faire ?",
                  style: TextStyle(color: t.textMuted, fontSize: 14),
                ),
                const SizedBox(height: 24),

                // ── Actions principales ────────────────────────────────────
                isDesktop
                    ? Row(children: [
                        Expanded(
                          child: _actionCard(
                            t,
                            icon: Icons.add_shopping_cart_outlined,
                            color: AppThemeProvider.teal,
                            title: "Nouvelle demande",
                            subtitle: "Acheter un article sur mesure",
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AchatFormScreen()),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _actionCard(
                            t,
                            icon: Icons.receipt_long_outlined,
                            color: AppThemeProvider.appBlue,
                            title: "Mes achats",
                            subtitle: "Suivre mes demandes en cours",
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AchatsListScreen()),
                            ),
                          ),
                        ),
                      ])
                    : Column(children: [
                        _actionCard(
                          t,
                          icon: Icons.add_shopping_cart_outlined,
                          color: AppThemeProvider.teal,
                          title: "Nouvelle demande",
                          subtitle: "Acheter un article sur mesure",
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AchatFormScreen()),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _actionCard(
                          t,
                          icon: Icons.receipt_long_outlined,
                          color: AppThemeProvider.appBlue,
                          title: "Mes achats",
                          subtitle: "Suivre mes demandes en cours",
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AchatsListScreen()),
                          ),
                        ),
                      ]),

                const SizedBox(height: 28),

                // ── Tarifs ────────────────────────────────────────────────
                _buildTarifs(t),

                const SizedBox(height: 28),

                // ── Catégories ────────────────────────────────────────────
                _buildCategories(t),

                const SizedBox(height: 28),

                // ── Contact ───────────────────────────────────────────────
                _buildContact(t, context),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTarifs(AppThemeProvider t) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: t.isDark
                ? [const Color(0xFF001A1A), const Color(0xFF002A2A)]
                : [const Color(0xFF00BCD4), const Color(0xFF0097A7)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppThemeProvider.teal.withValues(alpha: 0.20),
              blurRadius: 16,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.local_offer_outlined, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text("Tarifs Achat sur Mesure",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14)),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            _tarif("🇫🇷", "Vers Paris", "10€/kg"),
            _tarifDiv(),
            _tarif("🇲🇦", "Vers Casablanca", "65DH/kg"),
            _tarifDiv(),
            _tarif("🇸🇳", "Vers Dakar", "6500 FCFA"),
          ]),
          const SizedBox(height: 12),
          Text(
            "+ Frais de service 5% · Devis envoyé avant achat",
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65), fontSize: 11),
          ),
        ]),
      );

  Widget _tarif(String flag, String city, String price) => Expanded(
        child: Column(children: [
          Text("$flag $city",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.80),
                  fontWeight: FontWeight.w600,
                  fontSize: 11)),
          const SizedBox(height: 4),
          Text(price,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14)),
        ]),
      );

  Widget _tarifDiv() => Container(
        width: 1,
        height: 32,
        color: Colors.white.withValues(alpha: 0.20),
        margin: const EdgeInsets.symmetric(horizontal: 4),
      );

  Widget _buildCategories(AppThemeProvider t) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("CE QU'ON PEUT ACHETER POUR VOUS",
              style: TextStyle(
                  color: t.textMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _categories
                .map((c) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: t.bgCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: (c['color'] as Color)
                                .withValues(alpha: 0.25)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(c['emoji'] as String,
                            style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 7),
                        Text(c['name'] as String,
                            style: TextStyle(
                                color: t.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                      ]),
                    ))
                .toList(),
          ),
        ],
      );

  Widget _buildContact(AppThemeProvider t, BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("BESOIN D'AIDE ?",
              style: TextStyle(
                  color: t.textMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: _waBtn(t, context, "WhatsApp France", _waFrance)),
            const SizedBox(width: 10),
            Expanded(
                child: _waBtn(t, context, "WhatsApp Dakar", _waDakar)),
          ]),
        ],
      );

  Widget _waBtn(AppThemeProvider t, BuildContext context, String label,
          String digits) =>
      GestureDetector(
        onTap: () => _wa(context, digits),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppThemeProvider.green.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppThemeProvider.green.withValues(alpha: 0.25)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const FaIcon(FontAwesomeIcons.whatsapp,
                color: AppThemeProvider.green, size: 16),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ]),
        ),
      );

  Widget _actionCard(
    AppThemeProvider t, {
    required dynamic icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: t.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.22)),
            boxShadow: [
              BoxShadow(
                  color: color.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon as IconData, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: t.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 15)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: TextStyle(
                          color: t.textMuted, fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: t.textMuted, size: 22),
          ]),
        ),
      );
}
