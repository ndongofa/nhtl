// lib/screens/home_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/app_theme_provider.dart';
import '../services/auth_service.dart';
import '../services/departure_countdown_service.dart';
import '../models/logged_user.dart';
import '../debug/debug_token.dart';
import 'admin/admin_departures_screen.dart';
import 'admin/admin_user_screen.dart';
import 'commande_form_screen.dart';
import 'commandes_list_screen.dart';
import 'gp/gp_list_screen.dart';
import 'notifications/notifications_screen.dart';
import 'transport_form_screen.dart';
import 'transports_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color _appBlue = AppThemeProvider.appBlue;
  static const Color _blueBright = AppThemeProvider.blueBright;
  static const Color _amber = AppThemeProvider.amber;
  static const Color _amberLight = AppThemeProvider.amberLight;
  static const Color _teal = AppThemeProvider.teal;
  static const Color _green = AppThemeProvider.green;
  static const Color _textDark = AppThemeProvider.textDark;

  static const String _waFrance = "33768913074";
  static const String _waDakar = "221783042838";
  static const String _email = "tech@ngom-holding.com";

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
        "https://wa.me/$digits?text=${Uri.encodeComponent("Bonjour SAMA, j'ai besoin de réserver un service.")}");
    if (await canLaunchUrl(uri))
      await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openEmail() async {
    final uri = Uri.parse(
        "mailto:$_email?subject=${Uri.encodeComponent("Demande de réservation - SAMA")}");
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _logout(BuildContext context) {
    final t = context.read<AppThemeProvider>();
    final navigator = Navigator.of(context);
    showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Déconnexion",
            style:
                TextStyle(color: t.textPrimary, fontWeight: FontWeight.w800)),
        content: Text("Êtes-vous sûr de vouloir vous déconnecter ?",
            style: TextStyle(color: t.textMuted)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text("Annuler", style: TextStyle(color: t.textMuted))),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            child: const Text("Déconnecter",
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed != true) return;
      await AuthService.logout();
      navigator.pushNamedAndRemoveUntil('/', (_) => false);
    });
  }

  void _showReservationModal(BuildContext context, String departRoute) {
    final t = context.read<AppThemeProvider>();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: t.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: _amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.flight_takeoff,
                      color: _amber, size: 20)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text("Réserver ce départ",
                        style: TextStyle(
                            color: t.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 16)),
                    Text(departRoute,
                        style: TextStyle(color: t.textMuted, fontSize: 12)),
                  ])),
              IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: Icon(Icons.close, color: t.textMuted, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints()),
            ]),
            const SizedBox(height: 20),
            Divider(color: t.border),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(FontAwesomeIcons.truckFast, size: 16),
                label: const Text("Nouveau Transport",
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: _appBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => TransportFormScreen()));
                },
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(FontAwesomeIcons.bagShopping, size: 16),
                label: const Text("Nouvelle Commande",
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: _amber,
                    foregroundColor: _textDark,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => CommandeFormScreen()));
                },
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: t.border),
            const SizedBox(height: 12),
            _mBtn(t, FontAwesomeIcons.whatsapp, _green, "WhatsApp France",
                "+33 76 891 30 74", () {
              Navigator.pop(ctx);
              _wa(_waFrance);
            }),
            const SizedBox(height: 8),
            _mBtn(t, FontAwesomeIcons.whatsapp, _green, "WhatsApp Dakar",
                "+221 78 304 28 38", () {
              Navigator.pop(ctx);
              _wa(_waDakar);
            }),
            const SizedBox(height: 8),
            _mBtn(t, Icons.email_outlined, _appBlue, "Email", _email, () {
              Navigator.pop(ctx);
              _openEmail();
            }),
          ]),
        ),
      ),
    );
  }

  Widget _mBtn(AppThemeProvider t, IconData icon, Color color, String label,
          String sub, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.25))),
          child: Row(children: [
            Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 18)),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(label,
                      style: TextStyle(
                          color: t.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                  Text(sub,
                      style: TextStyle(color: t.textMuted, fontSize: 11),
                      overflow: TextOverflow.ellipsis),
                ])),
            Icon(Icons.arrow_forward_ios, color: color, size: 14),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppThemeProvider>();
    final svc = context.watch<DepartureCountdownService>(); // ✅ ChangeNotifier
    final user = LoggedUser.fromSupabase();
    final w = MediaQuery.of(context).size.width;
    final isDesktop = w >= 900;
    final isAdmin = user.role == 'admin';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      color: t.bg,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
            child: Column(children: [
          _topBar(context, t, user, isAdmin),
          _ticker(t, svc),
          Expanded(
              child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 40 : 16, vertical: 20),
            child: Center(
                child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _greeting(t, user),
                    const SizedBox(height: 20),
                    _countdownSection(context, t, svc),
                    const SizedBox(height: 24),
                    _quickActions(context, t),
                    const SizedBox(height: 28),
                    _activities(context, t, isDesktop),
                    const SizedBox(height: 28),
                    _infoBand(t),
                    const SizedBox(height: 28),
                    _departures(context, t, svc),
                    if (isAdmin) ...[
                      const SizedBox(height: 28),
                      _admin(context, t)
                    ],
                    const SizedBox(height: 40),
                  ]),
            )),
          )),
        ])),
      ),
    );
  }

  // ── TOP BAR ───────────────────────────────────────────────────────────────
  Widget _topBar(BuildContext context, AppThemeProvider t, LoggedUser user,
          bool isAdmin) =>
      AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: t.topBarBg,
          border: Border(
              bottom:
                  BorderSide(color: t.border.withValues(alpha: 0.4), width: 1)),
        ),
        child: Row(children: [
          _logo(),
          const Spacer(),
          IconButton(
              icon: Icon(Icons.notifications_outlined,
                  color: Colors.white.withValues(alpha: 0.90), size: 20),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const NotificationsScreen())),
              splashRadius: 20),
          if (isAdmin)
            IconButton(
                icon: Icon(Icons.bug_report_outlined,
                    color: Colors.white.withValues(alpha: 0.45), size: 20),
                onPressed: () {
                  printSupabaseTokens();
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Token imprimé.")));
                },
                splashRadius: 20),
          IconButton(
              icon: Icon(Icons.person_outline,
                  color: Colors.white.withValues(alpha: 0.90), size: 20),
              onPressed: () => Navigator.of(context).pushNamed('/profile'),
              splashRadius: 20),
          Tooltip(
            message: t.isDark ? "Thème clair" : "Thème sombre",
            child: GestureDetector(
              onTap: () => context.read<AppThemeProvider>().toggleTheme(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.28)),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, anim) => RotationTransition(
                      turns: anim,
                      child: FadeTransition(opacity: anim, child: child)),
                  child: Icon(
                      t.isDark
                          ? Icons.wb_sunny_outlined
                          : Icons.nightlight_round,
                      key: ValueKey(t.isDark),
                      color: t.isDark ? _amber : Colors.white,
                      size: 16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
              icon: Icon(Icons.logout,
                  color: Colors.white.withValues(alpha: 0.75), size: 20),
              onPressed: () => _logout(context),
              splashRadius: 20),
        ]),
      );

  Widget _logo() => Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
                colors: [AppThemeProvider.appBlue, AppThemeProvider.teal],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
          ),
          child: const Icon(FontAwesomeIcons.bagShopping,
              color: Colors.white, size: 15),
        ),
        const SizedBox(width: 10),
        Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text("SAMA",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: 2.2,
                      height: 1.0)),
              Text("SERVICES INTERNATIONAL",
                  style: TextStyle(
                      color: Colors.white54,
                      fontWeight: FontWeight.w600,
                      fontSize: 8.5,
                      letterSpacing: 1.0,
                      height: 1.0)),
            ]),
      ]);

  // ── TICKER ────────────────────────────────────────────────────────────────
  Widget _ticker(AppThemeProvider t, DepartureCountdownService svc) {
    final upcoming = svc.upcomingDepartures;
    if (upcoming.isEmpty) return const SizedBox.shrink();
    final dep = upcoming[_tickerIndex % upcoming.length];
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Container(
        key: ValueKey(_tickerIndex),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: _amber,
        child: Row(children: [
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: t.bg, borderRadius: BorderRadius.circular(5)),
              child: Text("DÉPARTS",
                  style: TextStyle(
                      color: _amber,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5))),
          const SizedBox(width: 10),
          Text(dep.flag, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          // ✅ Route en gras, date secondaire
          Expanded(
              child: RichText(
            overflow: TextOverflow.ellipsis,
            text: TextSpan(children: [
              TextSpan(
                  text: dep.route,
                  style: TextStyle(
                      color: t.bg, fontWeight: FontWeight.w900, fontSize: 14)),
              TextSpan(
                  text: "  ·  ${dep.date}",
                  style: TextStyle(
                      color: t.bg.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w600,
                      fontSize: 12)),
            ]),
          )),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showReservationModal(context, dep.route),
            child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: t.bg, borderRadius: BorderRadius.circular(7)),
                child: Text("Réserver →",
                    style: TextStyle(
                        color: _amber,
                        fontWeight: FontWeight.w800,
                        fontSize: 11))),
          ),
        ]),
      ),
    );
  }

  // ── COMPTE À REBOURS ✅ Route + date mis en avant ─────────────────────────
  Widget _countdownSection(
      BuildContext context, AppThemeProvider t, DepartureCountdownService svc) {
    final dep = svc.currentDeparture;
    final sameDayCount = svc.sameDayCount;
    final groupCount = svc.groupCount;
    final groupIndex = svc.groupIndex;
    final inGroupIndex = svc.inGroupIndex;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: t.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _amber.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
              color: _amber.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(children: [
        // ✅ 1 — Flag + Route en grand
        GestureDetector(
          onHorizontalDragEnd: (d) {
            if (d.primaryVelocity == null) return;
            if (d.primaryVelocity! < -200)
              svc.nextSameDay();
            else if (d.primaryVelocity! > 200) svc.prevSameDay();
          },
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (groupCount > 1 || sameDayCount > 1)
              GestureDetector(
                  onTap: svc.prevSameDay,
                  child: Icon(Icons.chevron_left,
                      color: t.isDark ? _blueBright : _appBlue, size: 26)),
            Column(children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                    key: ValueKey("flag_${dep.flag}_$groupIndex"),
                    dep.flag,
                    style: const TextStyle(fontSize: 30)),
              ),
              const SizedBox(height: 4),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: Text(
                  key: ValueKey("route_${dep.route}_$groupIndex"),
                  dep.route,
                  style: TextStyle(
                      color: t.textPrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: -0.3),
                ),
              ),
            ]),
            if (groupCount > 1 || sameDayCount > 1)
              GestureDetector(
                  onTap: svc.nextSameDay,
                  child: Icon(Icons.chevron_right,
                      color: t.isDark ? _blueBright : _appBlue, size: 26)),
          ]),
        ),

        const SizedBox(height: 4),

        // ✅ 2 — Date bien visible
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            key: ValueKey("date_${dep.date}_$groupIndex"),
            dep.date.toUpperCase(),
            style: TextStyle(
                color: svc.isExpired ? t.textMuted : _amber,
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: 1.5),
          ),
        ),

        const SizedBox(height: 4),

        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: svc.isExpired ? t.textMuted : _green)),
          const SizedBox(width: 6),
          Text(svc.isExpired ? "PASSÉ" : "DÉPART CONFIRMÉ",
              style: TextStyle(
                  color: svc.isExpired ? t.textMuted : _green,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1)),
        ]),

        if (groupCount > 1 || sameDayCount > 1) ...[
          const SizedBox(height: 10),
          _dotsIndicator(t, sameDayCount, groupCount, inGroupIndex, groupIndex),
        ],

        const SizedBox(height: 14),

        // ✅ 3 — Compte à rebours en support
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _cu(t, svc.days, "JOURS", _amber),
          _sp(t),
          _cu(t, svc.hours, "HEURES", _appBlue),
          _sp(t),
          _cu(t, svc.minutes, "MIN", _appBlue),
          _sp(t),
          _cu(t, svc.seconds, "SEC", t.textMuted),
        ]),

        const SizedBox(height: 14),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.flight_takeoff, size: 16),
            label: Text("Réserver — ${dep.route}",
                style: const TextStyle(fontWeight: FontWeight.w800)),
            style: ElevatedButton.styleFrom(
                backgroundColor: _amber,
                foregroundColor: _textDark,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12)),
            onPressed: () => _showReservationModal(context, dep.route),
          ),
        ),
      ]),
    );
  }

  Widget _dotsIndicator(AppThemeProvider t, int sameDayCount, int groupCount,
      int inGroupIndex, int groupIndex) {
    final total = groupCount > 1 ? groupCount : sameDayCount;
    final current = groupCount > 1 ? groupIndex : inGroupIndex;
    return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
            total,
            (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == current ? 20 : 7,
                  height: 6,
                  decoration: BoxDecoration(
                      color: i == current
                          ? _amber
                          : t.textMuted.withValues(alpha: 0.30),
                      borderRadius: BorderRadius.circular(3)),
                )));
  }

  Widget _cu(AppThemeProvider t, String v, String label, Color color) =>
      Column(children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.28))),
          child: Text(v,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 19,
                  letterSpacing: 1)),
        ),
        const SizedBox(height: 3),
        Text(label,
            style: TextStyle(
                color: t.textMuted,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8)),
      ]);

  Widget _sp(AppThemeProvider t) => Padding(
        padding: const EdgeInsets.only(bottom: 14, left: 5, right: 5),
        child: Text(":",
            style: TextStyle(
                color: t.textMuted, fontSize: 17, fontWeight: FontWeight.w700)),
      );

  // ── GREETING ──────────────────────────────────────────────────────────────
  Widget _greeting(AppThemeProvider t, LoggedUser user) {
    final hour = DateTime.now().hour;
    final salut = hour < 12
        ? "Bonjour"
        : hour < 18
            ? "Bon après-midi"
            : "Bonsoir";
    final meta = AuthService.userMetadata;
    String prenom = '';
    if (meta != null) prenom = meta['prenom']?.toString().trim() ?? '';
    if (prenom.isEmpty) {
      final full = user.fullName?.trim() ?? '';
      if (full.isNotEmpty) {
        final p = full.split(' ');
        if (p.isNotEmpty && p[0].isNotEmpty)
          prenom = p[0][0].toUpperCase() + p[0].substring(1).toLowerCase();
      }
    } else {
      prenom = prenom[0].toUpperCase() + prenom.substring(1).toLowerCase();
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("$salut, ${prenom.isNotEmpty ? prenom : 'vous'} 👋",
          style: TextStyle(
              color: t.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 22,
              letterSpacing: -0.3)),
      const SizedBox(height: 4),
      Text("Que souhaitez-vous faire aujourd'hui ?",
          style: TextStyle(color: t.textMuted, fontSize: 14)),
    ]);
  }

  // ── QUICK ACTIONS ─────────────────────────────────────────────────────────
  Widget _quickActions(BuildContext context, AppThemeProvider t) {
    final actions = [
      {
        "icon": FontAwesomeIcons.truckFast,
        "label": "Nouveau\nTransport",
        "color": _appBlue,
        "onTap": () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => TransportFormScreen()))
      },
      {
        "icon": FontAwesomeIcons.bagShopping,
        "label": "Nouvelle\nCommande",
        "color": _amber,
        "onTap": () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => CommandeFormScreen()))
      },
      {
        "icon": FontAwesomeIcons.whatsapp,
        "label": "WhatsApp\nFrance",
        "color": _green,
        "onTap": () => _wa(_waFrance)
      },
      {
        "icon": FontAwesomeIcons.whatsapp,
        "label": "WhatsApp\nDakar",
        "color": _green,
        "onTap": () => _wa(_waDakar)
      },
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _lbl(t, "Actions rapides"),
      const SizedBox(height: 12),
      Row(
          children: actions.asMap().entries.map((e) {
        final a = e.value;
        return Expanded(
            child: Padding(
          padding: EdgeInsets.only(right: e.key < actions.length - 1 ? 10 : 0),
          child: GestureDetector(
            onTap: a['onTap'] as VoidCallback,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              decoration: BoxDecoration(
                  color: t.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: (a['color'] as Color).withValues(alpha: 0.22)),
                  boxShadow: [
                    BoxShadow(
                        color: (a['color'] as Color).withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4))
                  ]),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                        color: (a['color'] as Color).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(a['icon'] as IconData,
                        color: a['color'] as Color, size: 18)),
                const SizedBox(height: 8),
                Text(a['label'] as String,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        height: 1.3)),
              ]),
            ),
          ),
        ));
      }).toList()),
    ]);
  }

  // ── ACTIVITIES ────────────────────────────────────────────────────────────
  Widget _activities(BuildContext context, AppThemeProvider t, bool isDesktop) {
    Widget card(IconData icon, Color color, String title, String sub,
            VoidCallback onTap) =>
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                color: t.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.20)),
                boxShadow: [
                  BoxShadow(
                      color: color.withValues(alpha: 0.07),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ]),
            child: Row(children: [
              Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14)),
                  child: Icon(icon, color: color, size: 22)),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(title,
                        style: TextStyle(
                            color: t.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 15)),
                    Text(sub,
                        style: TextStyle(
                            color: t.textMuted,
                            fontWeight: FontWeight.w400,
                            fontSize: 12)),
                  ])),
              Icon(Icons.chevron_right, color: t.textMuted, size: 20),
            ]),
          ),
        );

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _lbl(t, "Mes activités"),
      const SizedBox(height: 12),
      isDesktop
          ? Row(children: [
              Expanded(
                  child: card(
                      Icons.local_shipping_outlined,
                      _appBlue,
                      "Mes Transports",
                      "Suivre & gérer",
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => TransportListScreen())))),
              const SizedBox(width: 12),
              Expanded(
                  child: card(
                      Icons.receipt_long_outlined,
                      _amber,
                      "Mes Commandes",
                      "Achats en cours",
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => CommandesListScreen())))),
            ])
          : Column(children: [
              card(
                  Icons.local_shipping_outlined,
                  _appBlue,
                  "Mes Transports",
                  "Suivre & gérer",
                  () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => TransportListScreen()))),
              const SizedBox(height: 12),
              card(
                  Icons.receipt_long_outlined,
                  _amber,
                  "Mes Commandes",
                  "Achats en cours",
                  () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => CommandesListScreen()))),
            ]),
    ]);
  }

  // ── INFO BAND ─────────────────────────────────────────────────────────────
  Widget _infoBand(AppThemeProvider t) => AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: t.isDark
                  ? [const Color(0xFF0D3060), const Color(0xFF0A1628)]
                  : [_appBlue, AppThemeProvider.blueMid],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: _appBlue.withValues(alpha: 0.20),
                blurRadius: 16,
                offset: const Offset(0, 6))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.local_offer_outlined, color: _amber, size: 16),
            const SizedBox(width: 8),
            const Text("Tarifs SAMA",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14)),
            const Spacer(),
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: _amberLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _amber.withValues(alpha: 0.4))),
                child: const Text("–50% WEB",
                    style: TextStyle(
                        color: Color(0xFF7A4F00),
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        letterSpacing: 0.5))),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            _tf("🇫🇷", "Paris", "10€/kg"),
            _td(),
            _tf("🇲🇦", "Casablanca", "65DH/kg"),
            _td(),
            _tf("🇸🇳", "Dakar", "6500 FCFA"),
          ]),
        ]),
      );

  Widget _tf(String flag, String city, String price) => Expanded(
          child: Column(children: [
        Text("$flag $city",
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontWeight: FontWeight.w600,
                fontSize: 11)),
        const SizedBox(height: 4),
        Text(price,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14)),
      ]));

  Widget _td() => Container(
      width: 1,
      height: 32,
      color: Colors.white.withValues(alpha: 0.20),
      margin: const EdgeInsets.symmetric(horizontal: 4));

  // ── TOUS LES DÉPARTS ✅ route + date mis en avant ─────────────────────────
  Widget _departures(
      BuildContext context, AppThemeProvider t, DepartureCountdownService svc) {
    final allDeps = svc.allDepartures;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        _lbl(t, "Tous les départs"),
        const Spacer(),
        GestureDetector(
          onTap: () =>
              _showReservationModal(context, svc.currentDeparture.route),
          child: Text("Réserver →",
              style: TextStyle(
                  color: t.isDark ? _blueBright : _appBlue,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                  decorationColor: t.isDark ? _blueBright : _appBlue)),
        ),
      ]),
      const SizedBox(height: 12),
      ...allDeps.map((dep) {
        final isCurrent = dep.route == svc.currentDeparture.route &&
            dep.date == svc.currentDeparture.date;
        final isPast = dep.dateTime.isBefore(DateTime.now());
        return AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isCurrent
                ? _amber.withValues(alpha: t.isDark ? 0.12 : 0.07)
                : isPast
                    ? t.bgCard.withValues(alpha: 0.5)
                    : t.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isCurrent
                    ? _amber.withValues(alpha: 0.35)
                    : isPast
                        ? t.border.withValues(alpha: 0.4)
                        : t.border),
          ),
          child: Row(children: [
            Text(dep.flag, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  // ✅ Route en premier, grande
                  Text(dep.route,
                      style: TextStyle(
                          color: isPast
                              ? t.textMuted
                              : isCurrent
                                  ? _amber
                                  : t.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 14)),
                  const SizedBox(height: 2),
                  // ✅ Date avec icône calendrier
                  Row(children: [
                    Icon(Icons.calendar_today,
                        size: 11, color: isPast ? t.textMuted : _amber),
                    const SizedBox(width: 4),
                    Text(dep.date,
                        style: TextStyle(
                            color: isPast ? t.textMuted : _amber,
                            fontWeight: FontWeight.w700,
                            fontSize: 12)),
                  ]),
                  if (isCurrent) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                          color: _green.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8)),
                      child: const Text("● En cours",
                          style: TextStyle(
                              color: _green,
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ])),
            if (isPast)
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: t.border, borderRadius: BorderRadius.circular(20)),
                  child: Text("PASSÉ",
                      style: TextStyle(
                          color: t.textMuted,
                          fontWeight: FontWeight.w700,
                          fontSize: 9,
                          letterSpacing: 0.8)))
            else
              GestureDetector(
                onTap: () => _showReservationModal(context, dep.route),
                child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: _amber, borderRadius: BorderRadius.circular(8)),
                    child: const Text("Réserver",
                        style: TextStyle(
                            color: AppThemeProvider.textDark,
                            fontWeight: FontWeight.w800,
                            fontSize: 12))),
              ),
          ]),
        );
      }),
    ]);
  }

  // ── ADMIN ─────────────────────────────────────────────────────────────────
  Widget _admin(BuildContext context, AppThemeProvider t) {
    final items = [
      {
        "icon": Icons.flight_takeoff,
        "label": "Départs",
        "color": _teal,
        "onTap": () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AdminDeparturesScreen()))
      },
      {
        "icon": Icons.badge_outlined,
        "label": "GP Agents",
        "color": _appBlue,
        "onTap": () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const GpListScreen()))
      },
      {
        "icon": Icons.people_outline,
        "label": "Utilisateurs",
        "color": _amber,
        "onTap": () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => AdminUserScreen()))
      },
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: _amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _amber.withValues(alpha: 0.3))),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.shield_outlined, color: _amber, size: 12),
            SizedBox(width: 5),
            Text("Administration",
                style: TextStyle(
                    color: _amber,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 0.5)),
          ])),
      const SizedBox(height: 12),
      Row(
          children: items.asMap().entries.map((e) {
        final item = e.value;
        return Expanded(
            child: Padding(
          padding: EdgeInsets.only(right: e.key < items.length - 1 ? 10 : 0),
          child: GestureDetector(
            onTap: item['onTap'] as VoidCallback,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: t.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: (item['color'] as Color).withValues(alpha: 0.20)),
                  boxShadow: [
                    BoxShadow(
                        color: (item['color'] as Color).withValues(alpha: 0.07),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ]),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(item['icon'] as IconData,
                    color: item['color'] as Color, size: 22),
                const SizedBox(height: 6),
                Text(item['label'] as String,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
              ]),
            ),
          ),
        ));
      }).toList()),
    ]);
  }

  Widget _lbl(AppThemeProvider t, String label) => Text(
        label.toUpperCase(),
        style: TextStyle(
            color: t.textMuted,
            fontWeight: FontWeight.w700,
            fontSize: 11,
            letterSpacing: 1.2),
      );
}
