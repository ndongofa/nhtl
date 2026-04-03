// lib/screens/landing_transport_screen.dart
// Landing publique Transport GP — accessible via ServicesHub et /transport

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/sama_account_menu.dart';
import '../providers/app_theme_provider.dart';
import '../services/auth_service.dart';
import '../services/departure_countdown_service.dart';
import 'auth/login_screen.dart';
import 'transport_hub_screen.dart';

class LandingTransportScreen extends StatefulWidget {
  const LandingTransportScreen({Key? key}) : super(key: key);

  @override
  State<LandingTransportScreen> createState() => _LandingTransportScreenState();
}

class _LandingTransportScreenState extends State<LandingTransportScreen> {
  static const String _waFrance = "33768913074";
  static const String _waDakar = "221783042838";

  int _tickerIndex = 0;
  Timer? _tickerTimer;

  static const List<Map<String, String>> _etapes = [
    {
      "n": "1",
      "titre": "Déposez votre colis",
      "desc":
          "Apportez votre colis dans l'un de nos points de collecte en France, au Maroc ou au Sénégal."
    },
    {
      "n": "2",
      "titre": "Prise en charge",
      "desc":
          "Nos agents GP récupèrent votre envoi et le préparent pour le transport."
    },
    {
      "n": "3",
      "titre": "Transit & suivi",
      "desc":
          "Suivez l'avancement de votre colis en temps réel depuis l'application."
    },
    {
      "n": "4",
      "titre": "Livraison à domicile",
      "desc":
          "Votre colis est livré à l'adresse indiquée dans les délais convenus."
    },
  ];

  static const List<Map<String, String>> _avantages = [
    {
      "icon": "🔒",
      "titre": "Sécurisé",
      "desc": "Chaque colis est suivi et assuré tout au long du transport."
    },
    {
      "icon": "⚡",
      "titre": "Rapide",
      "desc": "Délai de 5 à 10 jours selon la destination."
    },
    {
      "icon": "💰",
      "titre": "Économique",
      "desc": "À partir de 10€/kg — tarif dégressif pour les gros volumes."
    },
    {
      "icon": "📱",
      "titre": "Suivi en temps réel",
      "desc": "Notifications SMS et WhatsApp à chaque étape."
    },
  ];

  @override
  void initState() {
    super.initState();
    _tickerTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      final svc = context.read<DepartureCountdownService>();
      if (svc.upcomingDepartures.isEmpty) return;
      setState(() =>
          _tickerIndex = (_tickerIndex + 1) % svc.upcomingDepartures.length);
    });
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    super.dispose();
  }

  Future<void> _wa(String digits) async {
    final uri = Uri.parse(
      "https://wa.me/$digits?text=${Uri.encodeComponent("Bonjour SAMA, je souhaite envoyer un colis via le service Transport GP.")}",
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _handleCTA(BuildContext context) {
    if (AuthService.isLoggedIn()) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TransportHubScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LoginScreen(redirectTo: const TransportHubScreen()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppThemeProvider>();
    final svc = context.watch<DepartureCountdownService>();
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
              Text("✈️", style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text(
                "Sama GP",
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
                IconButton(
                  tooltip: t.isDark ? "Thème clair" : "Thème sombre",
                  onPressed: () =>
                      context.read<AppThemeProvider>().toggleTheme(),
                  icon: Icon(
                    t.isDark
                        ? Icons.wb_sunny_outlined
                        : Icons.nightlight_round,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
              ]
            : [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  tooltip: "Menu",
                  onSelected: (value) {
                    if (value == 'account') SamaAccountMenu.open(context);
                    if (value == 'theme')
                      context.read<AppThemeProvider>().toggleTheme();
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
                        Icon(
                          t.isDark
                              ? Icons.wb_sunny_outlined
                              : Icons.nightlight_round,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(t.isDark ? "Thème clair" : "Thème sombre"),
                      ]),
                    ),
                  ],
                ),
              ],
      ),
      body: Column(children: [
        _buildTicker(t, svc),
        Expanded(
          child: SingleChildScrollView(
            child: Column(children: [
              _buildHero(t, isDesktop, isLoggedIn, svc, context),
              _buildCountdownSection(t, isDesktop, svc, context),
              _buildEtapes(t, isDesktop),
              _buildAvantages(t, isDesktop),
              _buildTarifs(t, isDesktop),
              _buildCtaFinal(t, isDesktop, isLoggedIn, context),
              const SizedBox(height: 40),
            ]),
          ),
        ),
      ]),
    );
  }

  // ── Ticker ────────────────────────────────────────────────────────────────
  Widget _buildTicker(AppThemeProvider t, DepartureCountdownService svc) {
    final upcoming = svc.upcomingDepartures;
    if (upcoming.isEmpty) return const SizedBox.shrink();
    final dep = upcoming[_tickerIndex % upcoming.length];
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
              position:
                  Tween<Offset>(begin: const Offset(0, -0.4), end: Offset.zero)
                      .animate(CurvedAnimation(
                          parent: anim, curve: Curves.easeOut)),
              child: child)),
      child: Container(
        key: ValueKey(_tickerIndex),
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppThemeProvider.amberDeep, AppThemeProvider.amber, AppThemeProvider.amberBright],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              const Text(
                "DÉPARTS",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ]),
          ),
          const SizedBox(width: 10),
          Text(dep.flag, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              "${dep.route}  ·  ${dep.date}",
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppThemeProvider.textDark,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _handleCTA(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppThemeProvider.textDark,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                "Réserver →",
                style: TextStyle(
                  color: AppThemeProvider.amber,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Le reste du fichier reste identique à ton existant ────────────────────
  // (Hero, countdown section, étapes, avantages, tarifs, CTA final)
  // Pour éviter toute régression, on conserve tes méthodes telles qu'elles sont.

  Widget _buildHero(AppThemeProvider t, bool isDesktop, bool isLoggedIn,
      DepartureCountdownService svc, BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 64 : 24, vertical: isDesktop ? 64 : 48),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: t.isDark
                ? [const Color(0xFF0A1628), const Color(0xFF0D2040)]
                : [AppThemeProvider.appBlue, const Color(0xFF0D5BBF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
      ),
      child: Column(children: [
        const FaIcon(FontAwesomeIcons.planeDeparture, color: Colors.white, size: 48),
        const SizedBox(height: 20),
        Text("Envoyez vos colis\npartout dans le monde",
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: isDesktop ? 38 : 26,
                height: 1.2)),
        const SizedBox(height: 12),
        Text("France · Maroc · Sénégal — Délai 5 à 10 jours",
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75), fontSize: 15)),
        const SizedBox(height: 28),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: Icon(
                  isLoggedIn ? Icons.local_shipping_outlined : Icons.login_outlined,
                  size: 16),
              label: Text(isLoggedIn ? "Créer un transport" : "Se connecter",
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppThemeProvider.appBlue,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 14)),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 14)),
              onPressed: () => _wa(_waFrance),
            ),
            if (!isLoggedIn)
              OutlinedButton.icon(
                icon: const Icon(Icons.person_add_outlined, size: 16),
                label: const Text("Créer un compte",
                    style: TextStyle(fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side:
                        BorderSide(color: Colors.white.withValues(alpha: 0.5)),
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
  }

  Widget _buildCountdownSection(AppThemeProvider t, bool isDesktop,
      DepartureCountdownService svc, BuildContext context) {
    final dep = svc.currentDeparture;
    final allDeps = svc.allDepartures;
    return Container(
      color: t.bgSection,
      padding:
          EdgeInsets.symmetric(horizontal: isDesktop ? 64 : 20, vertical: 40),
      child: Center(
          child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(children: [
          // ── Section header ──────────────────────────────────────────────
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
                width: 28,
                height: 1.5,
                color: AppThemeProvider.amber.withValues(alpha: 0.45)),
            const SizedBox(width: 10),
            const Icon(Icons.flight_takeoff_rounded,
                color: AppThemeProvider.amber, size: 14),
            const SizedBox(width: 6),
            Text("PROCHAINS DÉPARTS",
                style: TextStyle(
                    color: t.textMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 2.0)),
            const SizedBox(width: 10),
            Container(
                width: 28,
                height: 1.5,
                color: AppThemeProvider.amber.withValues(alpha: 0.45)),
          ]),
          const SizedBox(height: 20),
          // ── Main countdown card ──────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
                color: t.bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppThemeProvider.amber.withValues(alpha: 0.35),
                    width: 1.5),
                boxShadow: [
                  BoxShadow(
                      color: AppThemeProvider.amber.withValues(alpha: 0.12),
                      blurRadius: 28,
                      spreadRadius: 0,
                      offset: const Offset(0, 6)),
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2)),
                ]),
            child: Column(children: [
              // Route header band
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [
                          AppThemeProvider.amber.withValues(alpha: 0.14),
                          AppThemeProvider.amber.withValues(alpha: 0.03),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight),
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18))),
                child: Column(children: [
                  Text(dep.route,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: t.textPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          letterSpacing: 0.3)),
                  const SizedBox(height: 6),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 11, color: AppThemeProvider.amber),
                    const SizedBox(width: 5),
                    Text(dep.date.toUpperCase(),
                        style: const TextStyle(
                            color: AppThemeProvider.amber,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            letterSpacing: 1.5)),
                  ]),
                ]),
              ),
              Divider(
                  height: 1,
                  thickness: 1,
                  color: AppThemeProvider.amber.withValues(alpha: 0.15)),
              // Countdown + CTA
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    _cu(t, svc.days, "JOURS", AppThemeProvider.amber),
                    _sp(t),
                    _cu(t, svc.hours, "HEURES", AppThemeProvider.appBlue),
                    _sp(t),
                    _cu(t, svc.minutes, "MIN", AppThemeProvider.appBlue),
                    _sp(t),
                    _cu(t, svc.seconds, "SEC", AppThemeProvider.teal),
                  ]),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppThemeProvider.amber,
                          foregroundColor: AppThemeProvider.textDark,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14)),
                      onPressed: () => _handleCTA(context),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                      label: Text("Réserver ce départ — ${dep.route}",
                          style:
                              const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          // ── Departure list ───────────────────────────────────────────────
          ...allDeps.map((d) {
            final isPast = d.dateTime.isBefore(DateTime.now());
            final isCurrent = d.route == dep.route && d.date == dep.date;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                  color: isCurrent
                      ? AppThemeProvider.amber.withValues(alpha: 0.07)
                      : isPast
                          ? t.bgCard.withValues(alpha: 0.5)
                          : t.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: isCurrent
                          ? AppThemeProvider.amber.withValues(alpha: 0.45)
                          : t.border.withValues(alpha: isPast ? 0.4 : 1),
                      width: isCurrent ? 1.5 : 1)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: IntrinsicHeight(
                  child: Row(children: [
                    // Left accent bar
                    Container(
                        width: 4,
                        color: isCurrent
                            ? AppThemeProvider.amber
                            : isPast
                                ? Colors.transparent
                                : AppThemeProvider.appBlue
                                    .withValues(alpha: 0.45)),
                    // Content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        child: Row(children: [
                          Text(d.flag,
                              style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                Text(d.route,
                                    style: TextStyle(
                                        color: isPast
                                            ? t.textMuted
                                            : isCurrent
                                                ? AppThemeProvider.amber
                                                : t.textPrimary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14)),
                                const SizedBox(height: 2),
                                Text(d.date,
                                    style: TextStyle(
                                        color: t.textMuted,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500)),
                              ])),
                          const SizedBox(width: 8),
                          if (isPast)
                            Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                    color: t.border.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(20)),
                                child: Text("PASSÉ",
                                    style: TextStyle(
                                        color: t.textMuted,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8)))
                          else if (isCurrent)
                            GestureDetector(
                              onTap: () => _handleCTA(context),
                              child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                      color: AppThemeProvider.amber,
                                      borderRadius:
                                          BorderRadius.circular(8)),
                                  child: const Text("Réserver",
                                      style: TextStyle(
                                          color: AppThemeProvider.textDark,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 11))),
                            )
                          else
                            GestureDetector(
                              onTap: () => _handleCTA(context),
                              child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                      color: AppThemeProvider.appBlue
                                          .withValues(alpha: 0.10),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      border: Border.all(
                                          color: AppThemeProvider.appBlue
                                              .withValues(alpha: 0.3))),
                                  child: Text("Réserver",
                                      style: TextStyle(
                                          color: AppThemeProvider.appBlue,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 11))),
                            ),
                        ]),
                      ),
                    ),
                  ]),
                ),
              ),
            );
          }),
        ]),
      )),
    );
  }

  Widget _buildEtapes(AppThemeProvider t, bool isDesktop) => Container(
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
            Text("Simple, rapide et sécurisé",
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
                          color:
                              AppThemeProvider.appBlue.withValues(alpha: 0.12),
                          shape: BoxShape.circle),
                      child: Center(
                          child: Text(e['n']!,
                              style: const TextStyle(
                                  color: AppThemeProvider.appBlue,
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

  Widget _buildAvantages(AppThemeProvider t, bool isDesktop) => Container(
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
            Text("Nos tarifs",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: isDesktop ? 26 : 20)),
            const SizedBox(height: 6),
            Text("Paiement à la livraison disponible",
                textAlign: TextAlign.center,
                style: TextStyle(color: t.textMuted, fontSize: 14)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: t.isDark
                          ? [const Color(0xFF0D3060), const Color(0xFF0A1628)]
                          : [AppThemeProvider.appBlue, const Color(0xFF0D5BBF)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: AppThemeProvider.appBlue.withValues(alpha: 0.20),
                        blurRadius: 16,
                        offset: const Offset(0, 6))
                  ]),
              child: Column(children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _tarifCard("🇫🇷", "Paris", "10€", "/kg"),
                      _tarifCard("🇲🇦", "Casablanca", "65 DH", "/kg"),
                      _tarifCard("🇸🇳", "Dakar", "6 500", "FCFA/kg"),
                    ]),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline, color: Colors.white, size: 14),
                      SizedBox(width: 6),
                      Text("Tarifs web : −50% sur le prix comptoir",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12)),
                    ],
                  ),
                ),
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
                color: Colors.white.withValues(alpha: 0.75),
                fontWeight: FontWeight.w600,
                fontSize: 12)),
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
                  ? "Accédez à votre espace Transport"
                  : "Prêt à envoyer votre colis ?",
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 22)),
          const SizedBox(height: 8),
          Text(
            isLoggedIn
                ? "Créez un nouveau transport ou suivez vos envois."
                : "Créez un compte gratuit et réservez votre transport dès maintenant.",
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
          ),
          const SizedBox(height: 24),
          Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: Icon(
                      isLoggedIn
                          ? Icons.local_shipping_outlined
                          : Icons.login_outlined,
                      size: 16),
                  label: Text(
                      isLoggedIn ? "Créer un transport" : "Se connecter",
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppThemeProvider.appBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 13)),
                  onPressed: () => _handleCTA(context),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 13)),
                  onPressed: () => _wa(_waFrance),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 13)),
                  onPressed: () => _wa(_waDakar),
                ),
              ]),
        ]),
      );

  Widget _cu(AppThemeProvider t, String v, String label, Color color) =>
      Column(children: [
        Container(
          constraints: const BoxConstraints(minWidth: 58),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.18),
                    color.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.35))),
          child: Text(v,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                  letterSpacing: 2,
                  height: 1)),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: TextStyle(
                color: t.textMuted,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0)),
      ]);

  Widget _sp(AppThemeProvider t) => Padding(
        padding: const EdgeInsets.only(bottom: 24, left: 6, right: 6),
        child: Text(":",
            style: TextStyle(
                color: AppThemeProvider.amber.withValues(alpha: 0.6),
                fontSize: 26,
                fontWeight: FontWeight.w900,
                height: 1)),
      );
}
