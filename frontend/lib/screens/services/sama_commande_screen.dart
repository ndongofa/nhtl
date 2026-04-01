// lib/screens/services/sama_commande_screen.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../providers/app_theme_provider.dart';
import '../../../services/auth_service.dart';
import '../commandes_list_screen.dart';

class SamaCommandeScreen extends StatelessWidget {
  const SamaCommandeScreen({Key? key}) : super(key: key);

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
      "titre": "Envoyez le lien",
      "desc": "Partagez le lien du produit et la quantité souhaitée."
    },
    {
      "n": "2",
      "titre": "Confirmation & paiement",
      "desc": "Nous confirmons la disponibilité et le coût total."
    },
    {
      "n": "3",
      "titre": "Achat & expédition",
      "desc": "Nous commandons et expédions via nos partenaires GP."
    },
    {
      "n": "4",
      "titre": "Livraison",
      "desc": "Vous récupérez votre colis à destination."
    },
  ];

  Future<void> _wa(String digits) async {
    final uri = Uri.parse(
        "https://wa.me/$digits?text=${Uri.encodeComponent("Bonjour SAMA, je souhaite passer une commande en ligne.")}");
    if (await canLaunchUrl(uri))
      await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // ✅ Navigue vers MesCommandes si déjà connecté,
  //    sinon vers /login avec retour sur CommandesListScreen
  void _handleAccesCommandes(BuildContext context) {
    if (AuthService.isLoggedIn()) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const CommandesListScreen()));
    } else {
      // On pousse /login, puis à la connexion l'utilisateur revient ici
      // et on redirige vers CommandesListScreen
      Navigator.pushNamed(context, '/login').then((_) {
        if (AuthService.isLoggedIn()) {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const CommandesListScreen()));
        }
      });
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
        title: Row(children: [
          const Text("🛒", style: TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          const Text("Sama Commande",
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        ]),
        actions: [
          // ✅ Bouton "Mes commandes" ou "Connexion" selon l'état
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: isLoggedIn
                ? TextButton.icon(
                    icon: const Icon(Icons.receipt_long_outlined,
                        color: Colors.white, size: 16),
                    label: const Text("Mes commandes",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                    onPressed: () => _handleAccesCommandes(context),
                  )
                : TextButton.icon(
                    icon: const Icon(Icons.login_outlined,
                        color: Colors.white, size: 16),
                    label: const Text("Connexion",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                    onPressed: () => _handleAccesCommandes(context),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: AppThemeProvider.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppThemeProvider.green.withValues(alpha: 0.5))),
              child: const Text("● Disponible",
                  style: TextStyle(
                      color: AppThemeProvider.green,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(children: [
          // ── Hero ──────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 64 : 24, vertical: isDesktop ? 56 : 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: t.isDark
                      ? [const Color(0xFF0A1628), const Color(0xFF1A2E45)]
                      : [const Color(0xFFFFB300), const Color(0xFFFF8C00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
            ),
            child: Column(children: [
              const Text("🛒", style: TextStyle(fontSize: 52)),
              const SizedBox(height: 16),
              Text("Commandez depuis n'importe où",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color:
                          t.isDark ? Colors.white : AppThemeProvider.textDark,
                      fontWeight: FontWeight.w900,
                      fontSize: isDesktop ? 36 : 24)),
              const SizedBox(height: 10),
              Text(
                "Nous achetons pour vous sur Amazon, Temu, Shein,\nAliExpress, Alibaba et tout autre site.",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: (t.isDark ? Colors.white : AppThemeProvider.textDark)
                        .withValues(alpha: 0.75),
                    fontSize: 14,
                    height: 1.6),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  // ✅ Bouton principal : "Mes commandes" ou "Connexion"
                  ElevatedButton.icon(
                    icon: Icon(
                        isLoggedIn
                            ? Icons.receipt_long_outlined
                            : Icons.login_outlined,
                        size: 16),
                    label: Text(isLoggedIn ? "Mes commandes" : "Se connecter",
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
                            horizontal: 20, vertical: 13)),
                    onPressed: () => _handleAccesCommandes(context),
                  ),
                  ElevatedButton.icon(
                    icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 16),
                    label: const Text("Commander via WhatsApp",
                        style: TextStyle(fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppThemeProvider.green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 13)),
                    onPressed: () => _wa(_waFrance),
                  ),
                  if (!isLoggedIn)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.person_add_outlined, size: 16),
                      label: const Text("Créer un compte",
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: t.isDark
                              ? Colors.white
                              : AppThemeProvider.textDark,
                          side: BorderSide(
                              color: (t.isDark
                                      ? Colors.white
                                      : AppThemeProvider.textDark)
                                  .withValues(alpha: 0.4)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 13)),
                      onPressed: () => Navigator.pushNamed(context, '/signup'),
                    ),
                ],
              ),
            ]),
          ),

          // ── Plateformes supportées ────────────────────────────────────
          _Section(
            t: t,
            isDesktop: isDesktop,
            title: "Plateformes supportées",
            subtitle: "Nous achetons sur tous ces sites et bien d'autres",
            child: Wrap(
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
                                  .withValues(alpha: 0.25)),
                        ),
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
          ),

          // ── Comment ça marche ─────────────────────────────────────────
          _Section(
            t: t,
            isDesktop: isDesktop,
            title: "Comment ça marche ?",
            subtitle: "Simple, rapide et sécurisé",
            bgColor: t.bgSection,
            child: Column(
              children: _etapes
                  .map((e) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: t.bgCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: t.border),
                        ),
                        child: Row(children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                                color: AppThemeProvider.amber
                                    .withValues(alpha: 0.15),
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
                                const SizedBox(height: 3),
                                Text(e['desc']!,
                                    style: TextStyle(
                                        color: t.textMuted,
                                        fontSize: 13,
                                        height: 1.4)),
                              ])),
                        ]),
                      ))
                  .toList(),
            ),
          ),

          // ── CTA ───────────────────────────────────────────────────────
          _CtaBand(
            t: t,
            isLoggedIn: isLoggedIn,
            onWaFrance: () => _wa(_waFrance),
            onWaDakar: () => _wa(_waDakar),
            onAccesCommandes: () => _handleAccesCommandes(context),
          ),

          const SizedBox(height: 40),
        ]),
      ),
    );
  }
}

// ── Widgets partagés ─────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final AppThemeProvider t;
  final bool isDesktop;
  final String title;
  final String subtitle;
  final Widget child;
  final Color? bgColor;
  const _Section({
    required this.t,
    required this.isDesktop,
    required this.title,
    required this.subtitle,
    required this.child,
    this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bgColor,
      padding:
          EdgeInsets.symmetric(horizontal: isDesktop ? 64 : 20, vertical: 36),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(children: [
            Text(title,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: isDesktop ? 26 : 20)),
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: t.textMuted, fontSize: 14)),
            const SizedBox(height: 24),
            child,
          ]),
        ),
      ),
    );
  }
}

class _CtaBand extends StatelessWidget {
  final AppThemeProvider t;
  final bool isLoggedIn;
  final VoidCallback onWaFrance;
  final VoidCallback onWaDakar;
  final VoidCallback onAccesCommandes;

  const _CtaBand({
    required this.t,
    required this.isLoggedIn,
    required this.onWaFrance,
    required this.onWaDakar,
    required this.onAccesCommandes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [Color(0xFF0A1628), Color(0xFF0D3060)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight)),
      child: Column(children: [
        Text(
          isLoggedIn ? "Accédez à vos commandes" : "Prêt à commander ?",
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22),
        ),
        const SizedBox(height: 8),
        Text(
          isLoggedIn
              ? "Suivez vos commandes en temps réel depuis votre espace."
              : "Connectez-vous pour passer commande ou contactez-nous par WhatsApp.",
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            // ✅ Bouton principal adapté selon l'état de connexion
            ElevatedButton.icon(
              icon: Icon(
                  isLoggedIn
                      ? Icons.receipt_long_outlined
                      : Icons.login_outlined,
                  size: 16),
              label: Text(isLoggedIn ? "Mes commandes" : "Se connecter",
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppThemeProvider.appBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
              onPressed: onAccesCommandes,
            ),
            ElevatedButton.icon(
              icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 16),
              label: const Text("WhatsApp France",
                  style: TextStyle(fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppThemeProvider.green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
              onPressed: onWaFrance,
            ),
            ElevatedButton.icon(
              icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 16),
              label: const Text("WhatsApp Dakar",
                  style: TextStyle(fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppThemeProvider.green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
              onPressed: onWaDakar,
            ),
          ],
        ),
      ]),
    );
  }
}
