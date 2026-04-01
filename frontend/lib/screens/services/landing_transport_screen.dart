import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../providers/app_theme_provider.dart';
import '../../../services/departure_countdown_service.dart';

class LandingTransportScreen extends StatelessWidget {
  static const String _waFrance = "33768913074";
  static const String _waDakar = "221783042838";
  static const String _email = "tech@ngom-holding.com";

  const LandingTransportScreen({Key? key}) : super(key: key);

  Future<void> _wa(String digits) async {
    final uri = Uri.parse(
        "https://wa.me/$digits?text=${Uri.encodeComponent("Bonjour SAMA, j'ai besoin d'un transport GP.")}");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openEmail() async {
    final uri = Uri.parse(
        "mailto:$_email?subject=${Uri.encodeComponent("GP - Demande d'information SAMA")}");
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppThemeProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final svc = context.watch<DepartureCountdownService>();

    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.topBarBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            const Icon(Icons.flight_takeoff, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            const Text("Sama GP - Transport",
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemeProvider.appBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              child: const Text("Connexion",
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/signup'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppThemeProvider.appBlue,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              child: const Text("Créer un compte",
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(children: [
          // Hero section
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 64 : 20, vertical: isDesktop ? 56 : 36),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: t.isDark
                    ? [const Color(0xFF0A1628), const Color(0xFF1A2E45)]
                    : [AppThemeProvider.appBlue, AppThemeProvider.blueBright],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(children: [
              Text("✈️", style: TextStyle(fontSize: isDesktop ? 60 : 44)),
              const SizedBox(height: 16),
              Text("Transport GP – Convoyage de colis",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color:
                          t.isDark ? Colors.white : AppThemeProvider.textDark,
                      fontWeight: FontWeight.w900,
                      fontSize: isDesktop ? 36 : 24)),
              const SizedBox(height: 12),
              Text(
                "Paris • Casablanca • Dakar – Fret aérien et maritime groupé",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: t.textMuted,
                    fontSize: 15,
                    height: 1.7,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 19),
                label: const Text("Demander un devis",
                    style: TextStyle(fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppThemeProvider.amber,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 15)),
                onPressed: () => _wa(_waFrance),
              ),
              const SizedBox(height: 16),
              // Compte à rebours (prochain départ)
              _CountdownBanner(svc: svc, t: t),
            ]),
          ),
          // Tarifs section
          _Section(
            t: t,
            isDesktop: isDesktop,
            title: "Tarifs Transport GP",
            subtitle: "Tarif unique au kilo, toutes destinations.",
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: const [
                _TarifCard(flag: "🇫🇷", label: "Paris", value: "10 €/KG"),
                _TarifCard(flag: "🇸🇳", label: "Dakar", value: "6500 FCFA/KG"),
                _TarifCard(
                    flag: "🇲🇦", label: "Casablanca", value: "65 DH/KG"),
                _TarifCard(
                    flag: "🌍", label: "Promo web (via app)", value: "-50%"),
              ],
            ),
          ),
          // Comment ça marche
          _Section(
            t: t,
            isDesktop: isDesktop,
            title: "Comment ça marche ?",
            subtitle: "Simple, rapide, sécurisé, accompagné.",
            child: Column(children: const [
              _StepTile(
                  emoji: "1️⃣",
                  title: "Simulation",
                  desc: "Recevez un devis personnalisé via WhatsApp."),
              _StepTile(
                  emoji: "2️⃣",
                  title: "Dépôt et paiement",
                  desc: "Déposez votre colis puis validez le paiement."),
              _StepTile(
                  emoji: "3️⃣",
                  title: "Expédition",
                  desc: "Votre colis part en groupage aérien ou maritime."),
              _StepTile(
                  emoji: "4️⃣",
                  title: "Notification",
                  desc:
                      "Vous recevez un suivi et notification à chaque étape."),
              _StepTile(
                  emoji: "5️⃣",
                  title: "Livraison ou retrait",
                  desc: "Retrait ou livraison selon la destination."),
            ]),
          ),
          // WhatsApp/Contact section
          _Section(
            t: t,
            isDesktop: isDesktop,
            title: "Contact & Assistance",
            subtitle:
                "Besoin d’un conseil ou d’un devis immédiat ? Contactez-nous.",
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 16),
                  label: const Text("WhatsApp France"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppThemeProvider.green,
                      foregroundColor: Colors.white),
                  onPressed: () => _wa(_waFrance),
                ),
                ElevatedButton.icon(
                  icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 16),
                  label: const Text("WhatsApp Dakar"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppThemeProvider.green,
                      foregroundColor: Colors.white),
                  onPressed: () => _wa(_waDakar),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.email_outlined),
                  label: const Text("Email"),
                  onPressed: _openEmail,
                ),
              ],
            ),
          ),
          // Témoignages / avantages (placeholder)
          _Section(
              t: t,
              isDesktop: isDesktop,
              title: "Pourquoi choisir SAMA ?",
              subtitle: "",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Advantage(
                      icon: Icons.check_circle,
                      text: "Départs fréquents, suivi en temps réel."),
                  _Advantage(
                      icon: Icons.check_circle,
                      text: "Service client réactif 7j/7 WhatsApp + Email."),
                  _Advantage(
                      icon: Icons.check_circle,
                      text: "Tarifs transparents et fixes au kilo."),
                  _Advantage(
                      icon: Icons.shield,
                      text: "Emballage et transport sécurisés."),
                ],
              )),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }
}

// Compte à rebours GP
class _CountdownBanner extends StatelessWidget {
  final DepartureCountdownService svc;
  final AppThemeProvider t;

  const _CountdownBanner({required this.svc, required this.t});

  @override
  Widget build(BuildContext context) {
    final dep = svc.currentDeparture;
    if (dep.route.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8),
      child: Column(
        children: [
          Text("Prochain départ prévu :",
              style: TextStyle(
                  color: t.textMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 15)),
          const SizedBox(height: 3),
          Text("${dep.route} — ${dep.date}",
              style: TextStyle(
                  color: t.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 18)),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _countUnit(t, svc.days, "JOURS", AppThemeProvider.amber),
            const _Dot(),
            _countUnit(t, svc.hours, "HEURES", AppThemeProvider.appBlue),
            const _Dot(),
            _countUnit(t, svc.minutes, "MIN", AppThemeProvider.appBlue),
            const _Dot(),
            _countUnit(t, svc.seconds, "SEC", t.textMuted),
          ]),
        ],
      ),
    );
  }

  Widget _countUnit(AppThemeProvider t, String v, String label, Color color) =>
      Column(children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: color.withOpacity(0.11),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.28)),
          ),
          child: Text(v,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w900, fontSize: 16)),
        ),
        Text(label,
            style: TextStyle(
                color: t.textMuted, fontSize: 10, fontWeight: FontWeight.w600)),
      ]);
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(":",
          style: TextStyle(
              color: Theme.of(context).disabledColor,
              fontSize: 18,
              fontWeight: FontWeight.w900)),
    );
  }
}

class _Advantage extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Advantage({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    final t = Provider.of<AppThemeProvider>(context, listen: false);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Icon(icon, color: AppThemeProvider.green, size: 19),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: TextStyle(
                  color: t.textPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 14)),
        )
      ]),
    );
  }
}

// ---------- MISE EN FORME LANDING ----------

class _Section extends StatelessWidget {
  final AppThemeProvider t;
  final bool isDesktop;
  final String title;
  final String subtitle;
  final Widget child;
  const _Section({
    required this.t,
    required this.isDesktop,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.symmetric(horizontal: isDesktop ? 64 : 20, vertical: 36),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      color: t.textPrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: isDesktop ? 26 : 18)),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(subtitle,
                    style: TextStyle(color: t.textMuted, fontSize: 14)),
              ],
              const SizedBox(height: 24),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _TarifCard extends StatelessWidget {
  final String flag;
  final String label;
  final String value;
  const _TarifCard(
      {required this.flag, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    final t = Provider.of<AppThemeProvider>(context, listen: false);
    return Container(
      width: 135,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.border),
      ),
      child: Column(
        children: [
          Text(flag, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 6),
          Text(label,
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: t.textMuted)),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: AppThemeProvider.appBlue,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  final String emoji;
  final String title;
  final String desc;
  const _StepTile(
      {required this.emoji, required this.title, required this.desc});
  @override
  Widget build(BuildContext context) {
    final t = Provider.of<AppThemeProvider>(context, listen: false);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 9),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: TextStyle(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
            Text(desc, style: TextStyle(color: t.textMuted, fontSize: 12)),
          ]),
        ),
      ]),
    );
  }
}
