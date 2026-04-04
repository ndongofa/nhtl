// lib/screens/landing_commande_screen.dart
// Landing publique Commande — accessible via ServicesHub et /commande

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/sama_account_menu.dart';
import '../providers/app_theme_provider.dart';
import '../services/auth_service.dart';
import 'auth/login_screen.dart';
import 'commande_hub_screen.dart';

class LandingCommandeScreen extends StatelessWidget {
  const LandingCommandeScreen({Key? key}) : super(key: key);

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

  static const List<Map<String, String>> _etapes = [
    {
      "n": "1",
      "titre": "Envoyez le lien produit",
      "desc":
          "Partagez l'URL du produit, la taille, la couleur et la quantité souhaitée."
    },
    {
      "n": "2",
      "titre": "Confirmation du devis",
      "desc":
          "Nous vous confirmeons le prix total (produit + frais de service) avant achat."
    },
    {
      "n": "3",
      "titre": "Achat & expédition",
      "desc":
          "Nous commandons à votre place et expédions via nos partenaires logistiques."
    },
    {
      "n": "4",
      "titre": "Livraison à domicile",
      "desc":
          "Vous recevez votre colis à l'adresse indiquée dans les délais convenus."
    },
  ];

  static const List<Map<String, String>> _avantages = [
    {
      "icon": "🛡️",
      "titre": "Achat sécurisé",
      "desc": "Nous vérifions la fiabilité du vendeur avant de commander."
    },
    {
      "icon": "💸",
      "titre": "Meilleurs prix",
      "desc":
          "Accès aux promotions et ventes flash inaccessibles depuis l'Afrique."
    },
    {
      "icon": "📦",
      "titre": "Tout type d'article",
      "desc": "Vêtements, électronique, beauté, maison et bien plus."
    },
    {
      "icon": "📱",
      "titre": "Suivi en temps réel",
      "desc": "Notifications WhatsApp et SMS à chaque étape de votre commande."
    },
  ];

  Future<void> _wa(String digits) async {
    final uri = Uri.parse(
      "https://wa.me/$digits?text=${Uri.encodeComponent("Bonjour SAMA, je souhaite passer une commande en ligne.")}",
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _handleCTA(BuildContext context) {
    if (AuthService.isLoggedIn()) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CommandeHubScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LoginScreen(redirectTo: const CommandeHubScreen()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppThemeProvider>();
    final w = MediaQuery.of(context).size.width;
    final isDesktop = w >= 900;
    final isLoggedIn = AuthService.isLoggedIn();

    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.topBarBg,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: const Padding(
          padding: EdgeInsets.only(left: 12),
          child: Row(
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
        ),
        actions: isDesktop
            ? [
                TextButton.icon(
                  icon: const Icon(Icons.dashboard_outlined,
                      color: Colors.white, size: 16),
                  label: const Text(
                    "Mon espace",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  onPressed: () => SamaAccountMenu.open(context),
                ),
                if (isLoggedIn)
                  IconButton(
                    tooltip: "Déconnexion",
                    onPressed: () async {
                      await AuthService.logout();
                      if (!context.mounted) return;
                      Navigator.of(context)
                          .pushNamedAndRemoveUntil('/', (_) => false);
                    },
                    icon: const Icon(Icons.logout, color: Colors.white),
                  ),
                IconButton(
                  tooltip: t.themeTooltip,
                  onPressed: () =>
                      context.read<AppThemeProvider>().toggleTheme(),
                  icon: Icon(
                    t.themeIcon,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
              ]
            : [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  tooltip: "Menu",
                  onSelected: (value) async {
                    if (value == 'account') SamaAccountMenu.open(context);
                    if (value == 'theme')
                      context.read<AppThemeProvider>().toggleTheme();
                    if (value == 'logout') {
                      await AuthService.logout();
                      if (!context.mounted) return;
                      Navigator.of(context)
                          .pushNamedAndRemoveUntil('/', (_) => false);
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
                    PopupMenuItem<String>(
                      value: 'theme',
                      child: Row(children: [
                        Icon(t.themeIcon, size: 18),
                        const SizedBox(width: 10),
                        Text(t.themeTooltip),
                      ]),
                    ),
                    if (isLoggedIn)
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
        child: Column(children: [
          _buildHero(t, isDesktop, isLoggedIn, context),
          _buildPlateformes(t, isDesktop),
          _buildEtapes(t, isDesktop, context),
          _buildAvantages(t, isDesktop, context),
          _buildTarifs(t, isDesktop),
          _buildCtaFinal(t, isDesktop, isLoggedIn, context),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  // --- le reste inchangé (tes méthodes existantes) ---
  Widget _buildHero(AppThemeProvider t, bool isDesktop, bool isLoggedIn,
          BuildContext context) =>
      Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 64 : 24, vertical: isDesktop ? 64 : 48),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: t.isDark
                  ? [const Color(0xFF0A1628), const Color(0xFF1A2E45)]
                  : [const Color(0xFFFFB300), const Color(0xFFFF6F00)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
        ),
        child: Column(children: [
          const FaIcon(FontAwesomeIcons.bagShopping,
              color: Colors.white, size: 48),
          const SizedBox(height: 20),
          Text("Commandez depuis\nn'importe où dans le monde",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: t.isDark ? Colors.white : AppThemeProvider.textDark,
                  fontWeight: FontWeight.w900,
                  fontSize: isDesktop ? 38 : 26,
                  height: 1.2)),
          const SizedBox(height: 12),
          Text("Amazon, Temu, Shein, AliExpress et bien d'autres",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: (t.isDark ? Colors.white : AppThemeProvider.textDark)
                      .withValues(alpha: 0.70),
                  fontSize: 15)),
          const SizedBox(height: 28),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: Icon(
                    isLoggedIn
                        ? Icons.add_shopping_cart_outlined
                        : Icons.login_outlined,
                    size: 16),
                label: Text(isLoggedIn ? "Passer une commande" : "Se connecter",
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: t.isDark
                        ? AppThemeProvider.appBlue
                        : AppThemeProvider.textDark,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 14)),
                onPressed: () => _handleCTA(context),
              ),
              ElevatedButton.icon(
                icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 16),
                label: const Text("Contacter via WhatsApp",
                    style: TextStyle(fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppThemeProvider.green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 14)),
                onPressed: () => _wa(_waFrance),
              ),
              if (!isLoggedIn)
                OutlinedButton.icon(
                  icon: const Icon(Icons.person_add_outlined, size: 16),
                  label: const Text("Créer un compte",
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                      foregroundColor:
                          t.isDark ? Colors.white : AppThemeProvider.textDark,
                      side: BorderSide(
                          color: (t.isDark
                                  ? Colors.white
                                  : AppThemeProvider.textDark)
                              .withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 14)),
                  onPressed: () => Navigator.pushNamed(context, '/signup'),
                ),
            ],
          ),
        ]),
      );

  Widget _buildPlateformes(AppThemeProvider t, bool isDesktop) => Container(
        color: t.bgSection,
        padding:
            EdgeInsets.symmetric(horizontal: isDesktop ? 64 : 20, vertical: 36),
        child: Center(
            child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(children: [
            Text("Plateformes supportées",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: isDesktop ? 26 : 20)),
            const SizedBox(height: 6),
            Text("Nous achetons sur tous ces sites et bien d'autres",
                textAlign: TextAlign.center,
                style: TextStyle(color: t.textMuted, fontSize: 14)),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: _plateformes
                  .map((p) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                            color: t.bgCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: (p['color'] as Color)
                                    .withValues(alpha: 0.25))),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(p['emoji'] as String,
                              style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Text(p['name'] as String,
                              style: TextStyle(
                                  color: t.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
                        ]),
                      ))
                  .toList(),
            ),
          ]),
        )),
      );

  Widget _buildEtapes(
          AppThemeProvider t, bool isDesktop, BuildContext context) =>
      Container(
        padding:
            EdgeInsets.symmetric(horizontal: isDesktop ? 64 : 20, vertical: 36),
        child: Center(
            child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(children: [
            Text("Comment ça marche ?",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: isDesktop ? 26 : 20)),
            const SizedBox(height: 6),
            Text("4 étapes simples pour recevoir votre commande",
                textAlign: TextAlign.center,
                style: TextStyle(color: t.textMuted, fontSize: 14)),
            const SizedBox(height: 24),
            ..._etapes.map((e) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                      color: t.bgCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: t.border)),
                  child: Row(children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                          color: AppThemeProvider.amber.withValues(alpha: 0.15),
                          shape: BoxShape.circle),
                      child: Center(
                          child: Text(e['n']!,
                              style: const TextStyle(
                                  color: AppThemeProvider.amber,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16))),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(e['titre']!,
                              style: TextStyle(
                                  color: t.textPrimary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(e['desc']!,
                              style: TextStyle(
                                  color: t.textMuted,
                                  fontSize: 13,
                                  height: 1.4)),
                        ])),
                  ]),
                )),
          ]),
        )),
      );

  Widget _buildAvantages(
          AppThemeProvider t, bool isDesktop, BuildContext context) =>
      Container(
        color: t.bgSection,
        padding:
            EdgeInsets.symmetric(horizontal: isDesktop ? 64 : 20, vertical: 36),
        child: Center(
            child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(children: [
            Text("Pourquoi choisir SAMA ?",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: isDesktop ? 26 : 20)),
            const SizedBox(height: 24),
            ...(_avantages.map((a) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                      color: t.bgCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: t.border)),
                  child: Row(children: [
                    Text(a['icon']!, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 14),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(a['titre']!,
                              style: TextStyle(
                                  color: t.textPrimary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(a['desc']!,
                              style: TextStyle(
                                  color: t.textMuted,
                                  fontSize: 13,
                                  height: 1.4)),
                        ])),
                  ]),
                ))),
          ]),
        )),
      );

  Widget _buildTarifs(AppThemeProvider t, bool isDesktop) => Container(
        padding:
            EdgeInsets.symmetric(horizontal: isDesktop ? 64 : 20, vertical: 36),
        child: Center(
            child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(children: [
            Text("Nos tarifs d'expédition",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: isDesktop ? 26 : 20)),
            const SizedBox(height: 6),
            Text("+ Frais de service 5% sur le montant de la commande",
                textAlign: TextAlign.center,
                style: TextStyle(color: t.textMuted, fontSize: 14)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: t.isDark
                          ? [const Color(0xFF1A1200), const Color(0xFF2A1E00)]
                          : [const Color(0xFFFFB300), const Color(0xFFFF6F00)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: AppThemeProvider.amber.withValues(alpha: 0.20),
                        blurRadius: 16,
                        offset: const Offset(0, 6))
                  ]),
              child: Column(children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _tarifCard("🇫🇷", "Vers Paris", "10€", "/kg"),
                      _tarifCard("🇲🇦", "Vers Casablanca", "65 DH", "/kg"),
                      _tarifCard("🇸🇳", "Vers Dakar", "6 500", "FCFA/kg"),
                    ]),
              ]),
            ),
          ]),
        )),
      );

  Widget _tarifCard(String flag, String city, String price, String unit) =>
      Column(children: [
        Text(flag, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 6),
        Text(city,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.80),
                fontWeight: FontWeight.w600,
                fontSize: 11)),
        const SizedBox(height: 4),
        Text(price,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 22)),
        Text(unit,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65), fontSize: 11)),
      ]);

  Widget _buildCtaFinal(AppThemeProvider t, bool isDesktop, bool isLoggedIn,
          BuildContext context) =>
      Container(
        padding:
            EdgeInsets.symmetric(horizontal: isDesktop ? 64 : 20, vertical: 40),
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [Color(0xFF0A1628), Color(0xFF0D3060)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight)),
        child: Column(children: [
          Text(
              isLoggedIn
                  ? "Accédez à votre espace Commande"
                  : "Prêt à commander ?",
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 22)),
          const SizedBox(height: 8),
          Text(
            isLoggedIn
                ? "Passez une nouvelle commande ou suivez vos achats en cours."
                : "Créez un compte gratuit et passez votre première commande dès aujourd'hui.",
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: Icon(
                isLoggedIn ? Icons.add_shopping_cart_outlined : Icons.login_outlined,
                size: 16),
            label: Text(isLoggedIn ? "Passer une commande" : "Se connecter",
                style: const TextStyle(fontWeight: FontWeight.w800)),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppThemeProvider.amber,
                foregroundColor: AppThemeProvider.textDark,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 13)),
            onPressed: () => _handleCTA(context),
          ),
        ]),
      );
}
