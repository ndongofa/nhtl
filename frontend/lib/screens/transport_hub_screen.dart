// lib/screens/transport_hub_screen.dart
// Page intermédiaire post-login Transport
// Accès : après connexion depuis LandingTransportScreen

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/sama_account_menu.dart';
import '../providers/app_theme_provider.dart';
import '../services/auth_service.dart';
import '../services/departure_countdown_service.dart';
import 'transport_form_screen.dart';
import 'transports_list_screen.dart';

class TransportHubScreen extends StatefulWidget {
  const TransportHubScreen({Key? key}) : super(key: key);

  @override
  State<TransportHubScreen> createState() => _TransportHubScreenState();
}

class _TransportHubScreenState extends State<TransportHubScreen> {
  static const String _waFrance = "33768913074";
  static const String _waDakar = "221783042838";

  int _tickerIndex = 0;
  Timer? _tickerTimer;

  @override
  void initState() {
    super.initState();
    _tickerTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      final svc = context.read<DepartureCountdownService>();
      final upcoming = svc.upcomingDepartures;
      if (upcoming.isEmpty) return;
      setState(() => _tickerIndex = (_tickerIndex + 1) % upcoming.length);
    });
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    super.dispose();
  }

  Future<void> _wa(String digits) async {
    final uri = Uri.parse(
      "https://wa.me/$digits?text=${Uri.encodeComponent("Bonjour SAMA, j'ai besoin d'aide pour mon transport.")}",
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
    final svc = context.watch<DepartureCountdownService>();
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
                  tooltip: t.isDark ? "Thème clair" : "Thème sombre",
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
                        Text(t.isDark ? "Thème clair" : "Thème sombre"),
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
      ), // ── Ticker départs ────────────────────────────────────────────────
      body: Column(children: [
        _buildTicker(t, svc),
        Expanded(
          child: SingleChildScrollView(
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

                    // ── Actions principales ──────────────────────────────────
                    isDesktop
                        ? Row(children: [
                            Expanded(
                              child: _actionCard(
                                t,
                                icon: FontAwesomeIcons.planeDeparture,
                                color: AppThemeProvider.appBlue,
                                title: "Nouveau transport par GP",
                                subtitle: "Envoyer un colis ou marchandise",
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TransportFormScreen(),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _actionCard(
                                t,
                                icon: Icons.list_alt_outlined,
                                color: AppThemeProvider.teal,
                                title: "Mes transports par GP",
                                subtitle: "Suivre mes envois en cours",
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TransportListScreen(),
                                  ),
                                ),
                              ),
                            ),
                          ])
                        : Column(children: [
                            _actionCard(
                              t,
                              icon: FontAwesomeIcons.planeDeparture,
                              color: AppThemeProvider.appBlue,
                              title: "Nouveau transport par GP",
                              subtitle: "Envoyer un colis ou marchandise",
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TransportFormScreen(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _actionCard(
                              t,
                              icon: Icons.list_alt_outlined,
                              color: AppThemeProvider.teal,
                              title: "Mes transports par GP",
                              subtitle: "Suivre mes envois en cours",
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TransportListScreen(),
                                ),
                              ),
                            ),
                          ]),

                    const SizedBox(height: 28),

                    _buildCountdown(t, svc),

                    const SizedBox(height: 28),

                    _buildTarifs(t),

                    const SizedBox(height: 28),

                    _buildContact(t),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
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
      duration: const Duration(milliseconds: 400),
      child: Container(
        key: ValueKey(_tickerIndex),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: AppThemeProvider.amber,
        child: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: t.bg,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              "DÉPARTS",
              style: TextStyle(
                color: AppThemeProvider.amber,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(dep.flag, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              "${dep.route}  ·  ${dep.date}",
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: t.bg,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Compte à rebours ──────────────────────────────────────────────────────
  Widget _buildCountdown(AppThemeProvider t, DepartureCountdownService svc) {
    final dep = svc.currentDeparture;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: t.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppThemeProvider.amber.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: AppThemeProvider.amber.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: svc.isExpired ? t.textMuted : AppThemeProvider.green,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            svc.isExpired
                ? "TOUS LES DÉPARTS SONT PASSÉS"
                : "PROCHAIN DÉPART — ${dep.date.toUpperCase()}",
            style: TextStyle(
              color: svc.isExpired ? t.textMuted : AppThemeProvider.green,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ]),
        const SizedBox(height: 8),
        Text(
          dep.route,
          style: TextStyle(
            color: t.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _cu(t, svc.days, "JOURS", AppThemeProvider.amber),
          _sp(t),
          _cu(t, svc.hours, "HEURES", AppThemeProvider.appBlue),
          _sp(t),
          _cu(t, svc.minutes, "MIN", AppThemeProvider.appBlue),
          _sp(t),
          _cu(t, svc.seconds, "SEC", t.textMuted),
        ]),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add_box_outlined, size: 16),
            label: Text(
              "Réserver ce départ par GP — ${dep.route}",
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppThemeProvider.amber,
              foregroundColor: AppThemeProvider.textDark,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TransportFormScreen()),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _cu(AppThemeProvider t, String v, String label, Color color) =>
      Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.11),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.28)),
          ),
          child: Text(
            v,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 20,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: t.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ]);

  Widget _sp(AppThemeProvider t) => Padding(
        padding: const EdgeInsets.only(bottom: 16, left: 5, right: 5),
        child: Text(
          ":",
          style: TextStyle(
            color: t.textMuted,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      );

  // ── Tarifs ───────────────────────────────────────────────────────────────
  Widget _buildTarifs(AppThemeProvider t) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: t.isDark
                ? [const Color(0xFF0D3060), const Color(0xFF0A1628)]
                : [AppThemeProvider.appBlue, AppThemeProvider.blueMid],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppThemeProvider.appBlue.withValues(alpha: 0.20),
              blurRadius: 16,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.local_offer_outlined,
                color: AppThemeProvider.amber, size: 16),
            const SizedBox(width: 8),
            const Text(
              "Tarifs Sama GP",
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
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppThemeProvider.amber.withValues(alpha: 0.4),
                ),
              ),
              child: const Text(
                "−50% WEB",
                style: TextStyle(
                  color: Color(0xFF7A4F00),
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            _tarif("🇫🇷", "Paris", "10€/kg"),
            _tarifDiv(),
            _tarif("🇲🇦", "Casablanca", "65DH/kg"),
            _tarifDiv(),
            _tarif("🇸🇳", "Dakar", "6500 FCFA"),
          ]),
          const SizedBox(height: 12),
          Text(
            "Prix affiché par kg · Poids minimum : 1kg · Délai : 5–10 jours",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
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
              color: Colors.white.withValues(alpha: 0.75),
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

  // ── Contact ───────────────────────────────────────────────────────────────
  Widget _buildContact(AppThemeProvider t) => Column(
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
            Expanded(child: _waBtn(t, "WhatsApp France", _waFrance)),
            const SizedBox(width: 10),
            Expanded(child: _waBtn(t, "WhatsApp Dakar", _waDakar)),
          ]),
        ],
      );

  Widget _waBtn(AppThemeProvider t, String label, String digits) =>
      GestureDetector(
        onTap: () => _wa(digits),
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
