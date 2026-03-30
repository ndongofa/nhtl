// lib/screens/services/sama_coming_soon_screen.dart
//
// Widget générique "Bientôt disponible"
// Réutilisé par SamaMaadScreen, SamaTerangaScreen, SamaBestSellerScreen

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../providers/app_theme_provider.dart';

class SamaComingSoonScreen extends StatelessWidget {
  final String emoji;
  final String name;
  final String tagline;
  final String description;
  final Color accentColor;
  final List<String> teaser; // 3-4 points de teaser
  final String whatsappMessage;

  const SamaComingSoonScreen({
    Key? key,
    required this.emoji,
    required this.name,
    required this.tagline,
    required this.description,
    required this.accentColor,
    required this.teaser,
    required this.whatsappMessage,
  }) : super(key: key);

  static const String _waFrance = "33768913074";
  static const String _waDakar = "221783042838";

  Future<void> _wa(String digits, BuildContext context) async {
    final uri = Uri.parse(
        "https://wa.me/$digits?text=${Uri.encodeComponent(whatsappMessage)}");
    if (await canLaunchUrl(uri))
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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
        title: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text(name,
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        ]),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: accentColor.withValues(alpha: 0.5))),
              child: Text("Bientôt disponible",
                  style: TextStyle(
                      color: accentColor,
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
                horizontal: isDesktop ? 64 : 24, vertical: isDesktop ? 64 : 48),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: t.isDark
                      ? [
                          const Color(0xFF0A1628),
                          Color.lerp(
                              const Color(0xFF0A1628), accentColor, 0.15)!
                        ]
                      : [
                          accentColor,
                          Color.lerp(accentColor, Colors.black, 0.2)!
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
            ),
            child: Column(children: [
              // Emoji grand
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle),
                child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 48))),
              ),
              const SizedBox(height: 20),
              // Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.4))),
                child: const Text("🚀  Bientôt disponible",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
              ),
              const SizedBox(height: 16),
              Text(name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: isDesktop ? 40 : 28)),
              const SizedBox(height: 8),
              Text(tagline,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w600,
                      fontSize: 16)),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Text(description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 14,
                        height: 1.65)),
              ),
            ]),
          ),

          // ── Ce qui arrive ─────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 64 : 20, vertical: 36),
            child: Center(
                child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(children: [
                Text("Au programme",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: isDesktop ? 24 : 20)),
                const SizedBox(height: 6),
                Text("Voici ce que vous pourrez bientôt commander",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: t.textMuted, fontSize: 13)),
                const SizedBox(height: 24),
                ...teaser
                    .map((item) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: t.bgCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: accentColor.withValues(alpha: 0.2)),
                          ),
                          child: Row(children: [
                            Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                    color: accentColor,
                                    shape: BoxShape.circle)),
                            const SizedBox(width: 14),
                            Expanded(
                                child: Text(item,
                                    style: TextStyle(
                                        color: t.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14))),
                          ]),
                        ))
                    .toList(),
              ]),
            )),
          ),

          // ── Inscription anticipée ─────────────────────────────────────
          Container(
            color: t.bgSection,
            padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 64 : 20, vertical: 36),
            child: Center(
                child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(children: [
                Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle),
                    child: Icon(Icons.notifications_outlined,
                        color: accentColor, size: 28)),
                const SizedBox(height: 16),
                Text("Soyez averti à l'ouverture",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 20)),
                const SizedBox(height: 8),
                Text(
                  "Envoyez-nous un message WhatsApp pour être parmi les premiers informés du lancement.",
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: t.textMuted, fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 24),
                Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 16),
                        label: const Text("Je veux être averti — France",
                            style: TextStyle(fontWeight: FontWeight.w800)),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppThemeProvider.green,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 12)),
                        onPressed: () => _wa(_waFrance, context),
                      ),
                      ElevatedButton.icon(
                        icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 16),
                        label: const Text("Je veux être averti — Dakar",
                            style: TextStyle(fontWeight: FontWeight.w800)),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppThemeProvider.green,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 12)),
                        onPressed: () => _wa(_waDakar, context),
                      ),
                    ]),
              ]),
            )),
          ),

          const SizedBox(height: 40),
        ]),
      ),
    );
  }
}
