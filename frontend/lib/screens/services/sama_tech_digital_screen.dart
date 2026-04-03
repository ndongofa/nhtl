// lib/screens/services/sama_tech_digital_screen.dart
//
// Landing dédiée au service Sama Tech Digital
// Création de sites web & solutions digitales sur mesure

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../providers/app_theme_provider.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/sama_account_menu.dart';

class SamaTechDigitalScreen extends StatelessWidget {
  const SamaTechDigitalScreen({Key? key}) : super(key: key);

  static const Color _cyan = Color(0xFF0EA5E9);
  static const Color _cyanDark = Color(0xFF0284C7);

  static const String _waFrance = "33768913074";
  static const String _waDakar = "221783042838";
  static const String _email = "tech@ngom-holding.com";

  static const List<Map<String, String>> _services = [
    {
      "emoji": "🌐",
      "type": "Création de sites web",
      "desc": "Sites vitrines, portfolios, landing pages modernes et responsives"
    },
    {
      "emoji": "🛒",
      "type": "E-commerce",
      "desc": "Boutiques en ligne complètes avec paiement et gestion des commandes"
    },
    {
      "emoji": "📱",
      "type": "Applications mobiles",
      "desc": "Applications iOS & Android sur mesure pour votre activité"
    },
    {
      "emoji": "🎨",
      "type": "Design UI/UX",
      "desc": "Interfaces soignées, identité visuelle et expérience utilisateur optimale"
    },
    {
      "emoji": "📊",
      "type": "Marketing digital",
      "desc": "Référencement SEO, réseaux sociaux, campagnes publicitaires en ligne"
    },
    {
      "emoji": "🔧",
      "type": "Maintenance & Support",
      "desc": "Suivi technique, mises à jour et assistance continue de vos projets"
    },
  ];

  Future<void> _wa(String digits) async {
    final uri = Uri.parse(
        "https://wa.me/$digits?text=${Uri.encodeComponent("Bonjour SAMA Tech Digital, je souhaite un devis pour mon projet digital.")}");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openEmail() async {
    final uri = Uri.parse(
        "mailto:$_email?subject=${Uri.encodeComponent("Projet digital - Sama Tech Digital")}&body=${Uri.encodeComponent("Bonjour,\n\nJe souhaite vous contacter concernant un projet digital.\n\nCordialement,")}");
    if (await canLaunchUrl(uri)) await launchUrl(uri);
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
        title: const Row(children: [
          Text("💻", style: TextStyle(fontSize: 20)),
          SizedBox(width: 8),
          Text("Sama Tech Digital",
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        ]),
        actions: [
          IconButton(
            tooltip: "Mon espace",
            icon: const Icon(Icons.dashboard_outlined),
            onPressed: () => SamaAccountMenu.open(context),
          ),
          if (isLoggedIn)
            IconButton(
              tooltip: "Déconnexion",
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await AuthService.logout();
                if (!context.mounted) return;
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/', (_) => false);
              },
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: _cyan.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _cyan.withValues(alpha: 0.5))),
              child: const Text("● Disponible",
                  style: TextStyle(
                      color: _cyan,
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
                      ? [const Color(0xFF0A1628), const Color(0xFF03233F)]
                      : [_cyan, _cyanDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
            ),
            child: Column(children: [
              const Text("💻", style: TextStyle(fontSize: 52)),
              const SizedBox(height: 16),
              Text("Votre présence digitale\nà un niveau supérieur",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: isDesktop ? 36 : 24,
                      height: 1.2)),
              const SizedBox(height: 10),
              Text(
                "Sites web, applications mobiles, e-commerce et marketing digital.\nNos experts vous accompagnent de la conception à la mise en ligne.",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                    height: 1.6),
              ),
              const SizedBox(height: 24),
              Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.rocket_launch_outlined, size: 16),
                      label: const Text("Demander un devis",
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _cyan,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 13)),
                      onPressed: () => _wa(_waFrance),
                    ),
                    ElevatedButton.icon(
                      icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 16),
                      label: const Text("Via WhatsApp",
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.4)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 13)),
                      onPressed: () => _wa(_waFrance),
                    ),
                  ]),
            ]),
          ),

          // ── Nos services ──────────────────────────────────────────────
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 64 : 20, vertical: 36),
            child: Center(
                child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(children: [
                Text("Nos services digitaux",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: isDesktop ? 26 : 20)),
                const SizedBox(height: 6),
                Text(
                    "Des solutions adaptées à chaque besoin, pour entreprises et particuliers",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: t.textMuted, fontSize: 13)),
                const SizedBox(height: 28),
                isDesktop ? _gridDesktop(t) : _gridMobile(t),
              ]),
            )),
          ),

          // ── Comment ça marche ─────────────────────────────────────────
          Container(
            color: t.bgSection,
            padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 64 : 20, vertical: 36),
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
                const SizedBox(height: 24),
                ...[
                  (
                    "1",
                    "Décrivez votre projet",
                    "Contactez-nous par WhatsApp ou email avec une description de votre besoin digital."
                  ),
                  (
                    "2",
                    "Analyse & devis",
                    "Nous analysons votre projet et vous envoyons un devis détaillé sous 24h."
                  ),
                  (
                    "3",
                    "Conception & développement",
                    "Notre équipe conçoit et développe votre solution sur mesure."
                  ),
                  (
                    "4",
                    "Livraison & suivi",
                    "Votre projet est livré clé en main avec une formation et un support continu."
                  ),
                ]
                    .map((e) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: t.bgCard,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: t.border)),
                          child: Row(children: [
                            Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                    color: _cyan.withValues(alpha: 0.15),
                                    shape: BoxShape.circle),
                                child: Center(
                                    child: Text(e.$1,
                                        style: const TextStyle(
                                            color: _cyan,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 16)))),
                            const SizedBox(width: 14),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(e.$2,
                                      style: TextStyle(
                                          color: t.textPrimary,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14)),
                                  const SizedBox(height: 3),
                                  Text(e.$3,
                                      style: TextStyle(
                                          color: t.textMuted,
                                          fontSize: 13,
                                          height: 1.4)),
                                ])),
                          ]),
                        ))
                    .toList(),
              ]),
            )),
          ),

          // ── Pourquoi nous choisir ─────────────────────────────────────
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 64 : 20, vertical: 36),
            child: Center(
                child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(children: [
                Text("Pourquoi choisir Sama Tech Digital ?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: isDesktop ? 26 : 20)),
                const SizedBox(height: 24),
                isDesktop
                    ? _avantagesDesktop(t)
                    : _avantagesMobile(t),
              ]),
            )),
          ),

          // ── CTA ───────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [Color(0xFF0A1628), Color(0xFF03233F)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight)),
            child: Column(children: [
              const Text("Prêt à lancer votre projet ?",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 22)),
              const SizedBox(height: 8),
              Text("Notre équipe vous répond rapidement",
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14)),
              const SizedBox(height: 20),
              Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.rocket_launch_outlined, size: 16),
                      label: const Text("Demander un devis",
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _cyan,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 12)),
                      onPressed: () => _wa(_waFrance),
                    ),
                    _waBtn("WhatsApp France", () => _wa(_waFrance)),
                    _waBtn("WhatsApp Dakar", () => _wa(_waDakar)),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.email_outlined, size: 16),
                      label: const Text("Envoyer un email",
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.15),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.3)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 12)),
                      onPressed: _openEmail,
                    ),
                  ]),
            ]),
          ),

          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _gridDesktop(AppThemeProvider t) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
              child: Column(
                  children: _services
                      .sublist(0, 3)
                      .map((e) => _serviceCard(t, e))
                      .toList())),
          const SizedBox(width: 16),
          Expanded(
              child: Column(
                  children: _services
                      .sublist(3, 6)
                      .map((e) => _serviceCard(t, e))
                      .toList())),
        ],
      );

  Widget _gridMobile(AppThemeProvider t) =>
      Column(children: _services.map((e) => _serviceCard(t, e)).toList());

  Widget _serviceCard(AppThemeProvider t, Map<String, String> e) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: t.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _cyan.withValues(alpha: 0.2))),
        child: Row(children: [
          Text(e['emoji']!, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(e['type']!,
                    style: TextStyle(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                Text(e['desc']!,
                    style: TextStyle(
                        color: t.textMuted, fontSize: 12, height: 1.4)),
              ])),
        ]),
      );

  static const List<Map<String, String>> _avantages = [
    {
      "emoji": "⚡",
      "title": "Livraison rapide",
      "desc": "Projets livrés dans les délais convenus"
    },
    {
      "emoji": "🔒",
      "title": "Qualité garantie",
      "desc": "Code propre, sécurisé et facilement maintenable"
    },
    {
      "emoji": "🌍",
      "title": "Expertise locale",
      "desc": "Une équipe qui comprend les marchés africains et européens"
    },
    {
      "emoji": "💬",
      "title": "Suivi personnalisé",
      "desc": "Un interlocuteur dédié du début jusqu'à la livraison"
    },
  ];

  Widget _avantagesDesktop(AppThemeProvider t) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _avantages
            .map((a) => Expanded(child: _avantageCard(t, a)))
            .toList(),
      );

  Widget _avantagesMobile(AppThemeProvider t) => Column(
        children: _avantages.map((a) => _avantageCard(t, a)).toList(),
      );

  Widget _avantageCard(AppThemeProvider t, Map<String, String> a) => Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: t.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _cyan.withValues(alpha: 0.18))),
        child: Column(children: [
          Text(a['emoji']!, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 10),
          Text(a['title']!,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: t.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 14)),
          const SizedBox(height: 6),
          Text(a['desc']!,
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: t.textMuted, fontSize: 12, height: 1.4)),
        ]),
      );

  Widget _waBtn(String label, VoidCallback onTap) => ElevatedButton.icon(
        icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 16),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        style: ElevatedButton.styleFrom(
            backgroundColor: AppThemeProvider.green,
            foregroundColor: Colors.white,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
        onPressed: onTap,
      );
}
