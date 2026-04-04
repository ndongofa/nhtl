// lib/screens/commande_hub_screen.dart
// Page intermédiaire post-login Commande
// Accès : après connexion depuis LandingCommandeScreen

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/sama_account_menu.dart';
import '../providers/app_theme_provider.dart';
import '../services/auth_service.dart';
import 'commande_form_screen.dart';
import 'commandes_list_screen.dart';

class CommandeHubScreen extends StatelessWidget {
  const CommandeHubScreen({Key? key}) : super(key: key);

  static const String _waFrance = "33768913074";
  static const String _waDakar = "221783042838";

  static const List<Map<String, dynamic>> _plateformes = [
    {"emoji": "📦", "name": "Amazon", "color": Color(0xFFFF9900)},
    {"emoji": "🛍️", "name": "Temu", "color": Color(0xFFE53935)},
    {"emoji": "👗", "name": "Shein", "color": Color(0xFF000000)},
    {"emoji": "🏭", "name": "AliExpress", "color": Color(0xFFFF6A00)},
    {"emoji": "🔧", "name": "Alibaba", "color": Color(0xFFFF8C00)},
    {"emoji": "🌐", "name": "Autre site", "color": AppThemeProvider.appBlue},
  ];

  Future<void> _wa(BuildContext context, String digits) async {
    final uri = Uri.parse(
      "https://wa.me/$digits?text=${Uri.encodeComponent("Bonjour SAMA, je souhaite passer une commande en ligne.")}",
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
        title: const Row(
          children: [
            Text("🛒", style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Text(
              "Sama Commande",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: -0.2,
              ),
            ),
          ],
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
                  tooltip: t.themeTooltip,
                  onPressed: () =>
                      context.read<AppThemeProvider>().toggleTheme(),
                  icon: Icon(t.themeIcon),
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
                        Icon(t.themeIcon, size: 18),
                        const SizedBox(width: 10),
                        Text(t.themeTooltip),
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
                            icon: FontAwesomeIcons.bagShopping,
                            color: AppThemeProvider.amber,
                            title: "Nouvelle commande",
                            subtitle: "Commander un article en ligne",
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CommandeFormScreen(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _actionCard(
                            t,
                            icon: Icons.receipt_long_outlined,
                            color: AppThemeProvider.appBlue,
                            title: "Mes commandes",
                            subtitle: "Suivre mes achats en cours",
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CommandesListScreen(),
                              ),
                            ),
                          ),
                        ),
                      ])
                    : Column(children: [
                        _actionCard(
                          t,
                          icon: FontAwesomeIcons.bagShopping,
                          color: AppThemeProvider.amber,
                          title: "Nouvelle commande",
                          subtitle: "Commander un article en ligne",
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CommandeFormScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _actionCard(
                          t,
                          icon: Icons.receipt_long_outlined,
                          color: AppThemeProvider.appBlue,
                          title: "Mes commandes",
                          subtitle: "Suivre mes achats en cours",
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CommandesListScreen(),
                            ),
                          ),
                        ),
                      ]),

                const SizedBox(height: 28),

                _buildTarifs(t),

                const SizedBox(height: 28),

                _buildPlateformes(t),

                const SizedBox(height: 28),

                _buildContact(t, context),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Tarifs ───────────────────────────────────────────────────────────────
  Widget _buildTarifs(AppThemeProvider t) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: t.isDark
                ? [const Color(0xFF1A1200), const Color(0xFF2A1E00)]
                : [const Color(0xFFFFB300), const Color(0xFFFF8C00)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppThemeProvider.amber.withValues(alpha: 0.20),
              blurRadius: 16,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.local_offer_outlined,
                color: Colors.white, size: 16),
            const SizedBox(width: 8),
            const Text(
              "Tarifs Commande en ligne",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "−50% WEB",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
            ),
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
            "+ Frais de service 5% · Paiement à la livraison disponible",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 11,
            ),
          ),
        ]),
      );

  Widget _tarif(String flag, String city, String price) => Expanded(
        child: Column(children: [
          Text(
            "$flag $city",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.80),
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            price,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ]),
      );

  Widget _tarifDiv() => Container(
        width: 1,
        height: 32,
        color: Colors.white.withValues(alpha: 0.20),
        margin: const EdgeInsets.symmetric(horizontal: 4),
      );

  // ── Plateformes ───────────────────────────────────────────────────────────
  Widget _buildPlateformes(AppThemeProvider t) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "PLATEFORMES SUPPORTÉES",
            style: TextStyle(
              color: t.textMuted,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _plateformes
                .map(
                  (p) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: t.bgCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: (p['color'] as Color).withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(p['emoji'] as String,
                          style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 7),
                      Text(
                        p['name'] as String,
                        style: TextStyle(
                          color: t.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ]),
                  ),
                )
                .toList(),
          ),
        ],
      );

  // ── Contact ───────────────────────────────────────────────────────────────
  Widget _buildContact(AppThemeProvider t, BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "BESOIN D'AIDE ?",
            style: TextStyle(
              color: t.textMuted,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _waBtn(t, context, "WhatsApp France", _waFrance)),
            const SizedBox(width: 10),
            Expanded(child: _waBtn(t, context, "WhatsApp Dakar", _waDakar)),
          ]),
        ],
      );

  Widget _waBtn(
    AppThemeProvider t,
    BuildContext context,
    String label,
    String digits,
  ) =>
      GestureDetector(
        onTap: () => _wa(context, digits),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppThemeProvider.green.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppThemeProvider.green.withValues(alpha: 0.25),
            ),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const FaIcon(FontAwesomeIcons.whatsapp,
                color: AppThemeProvider.green, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: t.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ]),
        ),
      );

  // ── Action card ───────────────────────────────────────────────────────────
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
                offset: const Offset(0, 4),
              )
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
              child: icon is IconData
                  ? Icon(icon, color: color, size: 22)
                  : FaIcon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: t.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(color: t.textMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: t.textMuted, size: 22),
          ]),
        ),
      );
}
