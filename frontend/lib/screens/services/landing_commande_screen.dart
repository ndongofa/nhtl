import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/app_theme_provider.dart';

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
      "titre": "Envoyez le lien",
      "desc": "Partagez le lien du produit à acheter et la quantité."
    },
    {
      "n": "2",
      "titre": "Confirmation & paiement",
      "desc": "On confirme la dispo, le prix et vous payez en toute sécurité."
    },
    {
      "n": "3",
      "titre": "Achat & expédition",
      "desc": "On commande et on expédie via notre service GP."
    },
    {
      "n": "4",
      "titre": "Livraison",
      "desc": "Vous récupérez le colis dès réception à destination."
    },
  ];

  Future<void> _wa(String digits) async {
    final uri = Uri.parse(
        "https://wa.me/$digits?text=${Uri.encodeComponent("Bonjour, je souhaite passer une commande en ligne !")}");
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
          const FaIcon(FontAwesomeIcons.bagShopping, size: 20),
          const SizedBox(width: 10),
          const Text(
            "Commander en ligne",
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
          ),
        ]),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Hero ───────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 64 : 24,
                  vertical: isDesktop ? 56 : 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: t.isDark
                      ? [const Color(0xFF0A1628), const Color(0xFF1A2E45)]
                      : [AppThemeProvider.amber, AppThemeProvider.appBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  const FaIcon(FontAwesomeIcons.bagShopping,
                      size: 48, color: AppThemeProvider.amber),
                  const SizedBox(height: 20),
                  Text("Commandez sur tous les sites",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color:
                            t.isDark ? Colors.white : AppThemeProvider.textDark,
                        fontWeight: FontWeight.w900,
                        fontSize: isDesktop ? 36 : 24,
                      )),
                  const SizedBox(height: 14),
                  Text(
                      "Amazon, Temu, Shein, AliExpress, Alibaba, tout est possible.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: (t.isDark
                                ? Colors.white
                                : AppThemeProvider.textDark)
                            .withOpacity(0.78),
                        fontSize: 15,
                        height: 1.6,
                      )),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 16),
                    label: const Text("Passer une commande WhatsApp"),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppThemeProvider.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 13)),
                    onPressed: () => _wa(_waFrance),
                  ),
                ],
              ),
            ),

            // ── Plateformes supportées ────────────────
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 64 : 18,
                  vertical: isDesktop ? 32 : 24),
              child: Card(
                color: t.bgCard,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Plateformes supportées",
                          style: TextStyle(
                              color: t.textPrimary,
                              fontWeight: FontWeight.w900,
                              fontSize: isDesktop ? 22 : 17)),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 13,
                        children: _plateformes
                            .map((p) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 13, vertical: 10),
                                  decoration: BoxDecoration(
                                    color:
                                        (p['color'] as Color).withOpacity(0.07),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(p['emoji'] as String,
                                            style:
                                                const TextStyle(fontSize: 20)),
                                        const SizedBox(width: 6),
                                        Text(p['name'] as String,
                                            style: TextStyle(
                                                color: t.textPrimary,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14)),
                                      ]),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Étapes commande ────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 64 : 18,
                  vertical: isDesktop ? 32 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Comment ça marche ?",
                      style: TextStyle(
                          color: t.textPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: isDesktop ? 22 : 17)),
                  const SizedBox(height: 14),
                  ..._etapes.map((e) => Container(
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
                                color: AppThemeProvider.amber.withOpacity(0.16),
                                shape: BoxShape.circle),
                            child: Center(
                              child: Text(e['n']!,
                                  style: const TextStyle(
                                      color: AppThemeProvider.amber,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16)),
                            ),
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
                      )),
                ],
              ),
            ),

            // ── CTA WhatsApp (sous la page) ─────────────
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 64 : 18,
                  vertical: isDesktop ? 24 : 18),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 12,
                children: [
                  _contactBtn("WhatsApp France", "+33 76 891 30 74",
                      AppThemeProvider.green, () => _wa(_waFrance)),
                  _contactBtn("WhatsApp Dakar", "+221 78 304 28 38",
                      AppThemeProvider.green, () => _wa(_waDakar)),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _contactBtn(
          String label, String sub, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
              color: color.withOpacity(0.13),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: color.withOpacity(0.28))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            FaIcon(FontAwesomeIcons.whatsapp, color: color, size: 18),
            const SizedBox(width: 9),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
              Text(sub,
                  style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
            ]),
          ]),
        ),
      );
}
