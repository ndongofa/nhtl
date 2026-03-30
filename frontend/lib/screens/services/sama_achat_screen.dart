// lib/screens/services/sama_achat_screen.dart
//
// Landing dédiée au service Sama Achat
// Achats sur mesure : marchés, boutiques spécialisées

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../providers/app_theme_provider.dart';

class SamaAchatScreen extends StatelessWidget {
  const SamaAchatScreen({Key? key}) : super(key: key);

  static const String _waFrance = "33768913074";
  static const String _waDakar = "221783042838";

  static const List<Map<String, String>> _exemples = [
    {
      "emoji": "🧵",
      "type": "Tissus & Wax",
      "desc": "Tissus africains, wax, broderies, boubous sur mesure"
    },
    {
      "emoji": "💎",
      "type": "Bijoux & Accessoires",
      "desc": "Bijoux traditionnels, perles, accessoires introuvables en ligne"
    },
    {
      "emoji": "🌶️",
      "type": "Épices & Alimentaire",
      "desc": "Épices africaines, produits alimentaires spécifiques"
    },
    {
      "emoji": "🏺",
      "type": "Artisanat",
      "desc": "Sculptures, tableaux, objets d'art sénégalais"
    },
    {
      "emoji": "💊",
      "type": "Médicaments & Santé",
      "desc": "Produits de santé disponibles localement"
    },
    {
      "emoji": "📱",
      "type": "High-Tech",
      "desc": "Appareils électroniques, accessoires tech locaux"
    },
  ];

  Future<void> _wa(String digits) async {
    final uri = Uri.parse(
        "https://wa.me/$digits?text=${Uri.encodeComponent("Bonjour SAMA, je souhaite un achat sur mesure.")}");
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
          const Text("🏪", style: TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          const Text("Sama Achat",
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        ]),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
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
                      ? [const Color(0xFF0A1628), const Color(0xFF0D2A2A)]
                      : [AppThemeProvider.teal, const Color(0xFF00A89D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
            ),
            child: Column(children: [
              const Text("🏪", style: TextStyle(fontSize: 52)),
              const SizedBox(height: 16),
              Text("Vos achats sur mesure\nau Sénégal & en France",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: isDesktop ? 36 : 24,
                      height: 1.2)),
              const SizedBox(height: 10),
              Text(
                "Vous voulez un produit introuvable en ligne ?\nNos agents achètent pour vous directement sur place.",
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
                      icon: const Icon(FontAwesomeIcons.whatsapp, size: 16),
                      label: const Text("Faire une demande",
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppThemeProvider.teal,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 13)),
                      onPressed: () => _wa(_waFrance),
                    ),
                  ]),
            ]),
          ),

          // ── Exemples d'achats ─────────────────────────────────────────
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 64 : 20, vertical: 36),
            child: Center(
                child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(children: [
                Text("Ce que nous pouvons acheter pour vous",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: isDesktop ? 26 : 20)),
                const SizedBox(height: 6),
                Text(
                    "Cette liste est non exhaustive — contactez-nous pour tout besoin",
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
                    "Décrivez votre besoin",
                    "Envoyez-nous par WhatsApp une description précise du produit."
                  ),
                  (
                    "2",
                    "Devis & confirmation",
                    "Nous vous envoyons un devis avec le coût total (produit + frais de service)."
                  ),
                  (
                    "3",
                    "Recherche & achat",
                    "Nos agents trouvent et achètent le produit pour vous."
                  ),
                  (
                    "4",
                    "Expédition",
                    "Le colis est expédié via notre réseau GP vers votre destination."
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
                                    color: AppThemeProvider.teal
                                        .withValues(alpha: 0.15),
                                    shape: BoxShape.circle),
                                child: Center(
                                    child: Text(e.$1,
                                        style: const TextStyle(
                                            color: AppThemeProvider.teal,
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

          // ── CTA ───────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [Color(0xFF0A1628), Color(0xFF0D3060)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight)),
            child: Column(children: [
              const Text("Faites votre demande",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 22)),
              const SizedBox(height: 8),
              Text("Nos agents vous répondent rapidement",
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14)),
              const SizedBox(height: 20),
              Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    _waBtn("WhatsApp France", () => _wa(_waFrance)),
                    _waBtn("WhatsApp Dakar", () => _wa(_waDakar)),
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
                  children: _exemples
                      .sublist(0, 3)
                      .map((e) => _exempleCard(t, e))
                      .toList())),
          const SizedBox(width: 16),
          Expanded(
              child: Column(
                  children: _exemples
                      .sublist(3, 6)
                      .map((e) => _exempleCard(t, e))
                      .toList())),
        ],
      );

  Widget _gridMobile(AppThemeProvider t) =>
      Column(children: _exemples.map((e) => _exempleCard(t, e)).toList());

  Widget _exempleCard(AppThemeProvider t, Map<String, String> e) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: t.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppThemeProvider.teal.withValues(alpha: 0.2))),
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

  Widget _waBtn(String label, VoidCallback onTap) => ElevatedButton.icon(
        icon: const Icon(FontAwesomeIcons.whatsapp, size: 16),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        style: ElevatedButton.styleFrom(
            backgroundColor: AppThemeProvider.green,
            foregroundColor: Colors.white,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
        onPressed: onTap,
      );
}
