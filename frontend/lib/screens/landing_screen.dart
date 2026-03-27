// lib/screens/landing_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/app_theme_provider.dart';
import '../services/departure_countdown_service.dart';

class LandingScreenSamaServicesInternational extends StatefulWidget {
  const LandingScreenSamaServicesInternational({Key? key}) : super(key: key);

  @override
  State<LandingScreenSamaServicesInternational> createState() =>
      _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreenSamaServicesInternational>
    with TickerProviderStateMixin {
  static const Color _appBlue = AppThemeProvider.appBlue;
  static const Color _blueBright = AppThemeProvider.blueBright;
  static const Color _blueMid = AppThemeProvider.blueMid;
  static const Color _amber = AppThemeProvider.amber;
  static const Color _amberLight = AppThemeProvider.amberLight;
  static const Color _teal = AppThemeProvider.teal;
  static const Color _green = AppThemeProvider.green;
  static const Color _textDark = AppThemeProvider.textDark;

  static const String _waFrance = "33768913074";
  static const String _waDakar = "221783042838";
  static const String _email = "tech@ngom-holding.com";

  static const List<Map<String, dynamic>> _services = [
    {
      "icon": FontAwesomeIcons.truckFast,
      "title": "Transport GP",
      "desc": "Groupage, fret aérien & maritime",
      "color": _appBlue
    },
    {
      "icon": FontAwesomeIcons.bagShopping,
      "title": "Shopping",
      "desc": "Amazon, Temu, Shein, AliExpress",
      "color": _amber
    },
    {
      "icon": FontAwesomeIcons.locationDot,
      "title": "Suivi GPS",
      "desc": "Tracking en temps réel 24/7",
      "color": _teal
    },
    {
      "icon": FontAwesomeIcons.store,
      "title": "Achats sur mesure",
      "desc": "Marchés & boutiques spécialisés",
      "color": _blueBright
    },
  ];

  final _pricingKey = GlobalKey();
  final _departuresKey = GlobalKey();
  final _contactKey = GlobalKey();

  late final AnimationController _bgAnim;
  final DepartureCountdownService _countdown = DepartureCountdownService();

  // ✅ Ticker uniquement sur les départs à venir
  int _tickerIndex = 0;
  Timer? _tickerTimer;

  @override
  void initState() {
    super.initState();
    _bgAnim =
        AnimationController(vsync: this, duration: const Duration(seconds: 8))
          ..repeat(reverse: true);

    _countdown.start(() {
      if (mounted) setState(() {});
    });

    _tickerTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      final upcoming = DepartureCountdownService.upcomingDepartures;
      if (upcoming.isEmpty) return;
      setState(() => _tickerIndex = (_tickerIndex + 1) % upcoming.length);
    });
  }

  @override
  void dispose() {
    _bgAnim.dispose();
    _countdown.dispose();
    _tickerTimer?.cancel();
    super.dispose();
  }

  void _push(String route) {
    try {
      Navigator.pushNamed(context, route);
    } catch (_) {}
  }

  Future<void> _scroll(GlobalKey key) async {
    final ctx = key.currentContext;
    if (ctx == null) return;
    await Scrollable.ensureVisible(ctx,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic);
  }

  Future<void> _wa(String digits) async {
    final uri = Uri.parse(
        "https://wa.me/$digits?text=${Uri.encodeComponent("Bonjour SAMA, j'ai besoin de réserver un service.")}");
    if (await canLaunchUrl(uri))
      await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openEmail() async {
    final uri = Uri.parse(
        "mailto:$_email?subject=${Uri.encodeComponent("Demande d'information - SAMA")}");
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _showReservationModal(String departRoute) {
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
                    Text("Réserver",
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
            const SizedBox(height: 16),
            Divider(color: t.border),
            const SizedBox(height: 12),
            _modalContact(t, FontAwesomeIcons.whatsapp, _green,
                "WhatsApp France", "+33 76 891 30 74", () {
              Navigator.pop(ctx);
              _wa(_waFrance);
            }),
            const SizedBox(height: 8),
            _modalContact(t, FontAwesomeIcons.whatsapp, _green,
                "WhatsApp Dakar", "+221 78 304 28 38", () {
              Navigator.pop(ctx);
              _wa(_waDakar);
            }),
            const SizedBox(height: 8),
            _modalContact(t, Icons.email_outlined, _appBlue, "Email", _email,
                () {
              Navigator.pop(ctx);
              _openEmail();
            }),
            const SizedBox(height: 16),
            Divider(color: t.border),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _push('/login');
                },
                style: OutlinedButton.styleFrom(
                    foregroundColor: t.textPrimary,
                    side: BorderSide(color: t.borderBright),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12)),
                child: const Text("Connexion",
                    style: TextStyle(fontWeight: FontWeight.w700)),
              )),
              const SizedBox(width: 10),
              Expanded(
                  child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _push('/signup');
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: _appBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12)),
                child: const Text("S'inscrire",
                    style: TextStyle(fontWeight: FontWeight.w800)),
              )),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _modalContact(AppThemeProvider t, IconData icon, Color color,
      String label, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.22))),
        child: Row(children: [
          Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9)),
              child: Icon(icon, color: color, size: 17)),
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
                Text(subtitle,
                    style: TextStyle(color: t.textMuted, fontSize: 11),
                    overflow: TextOverflow.ellipsis),
              ])),
          Icon(Icons.arrow_forward_ios, color: color, size: 13),
        ]),
      ),
    );
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppThemeProvider>();
    final w = MediaQuery.of(context).size.width;
    final isDesktop = w >= 1024;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      color: t.bg,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
            child: CustomScrollView(slivers: [
          SliverToBoxAdapter(child: _topBar(t, isDesktop)),
          SliverToBoxAdapter(child: _tickerBanner(t)),
          SliverToBoxAdapter(child: _hero(t, isDesktop)),
          SliverToBoxAdapter(child: _countdownBanner(t)),
          SliverToBoxAdapter(
              child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  color: t.bgSection,
                  child: _servicesSection(t, isDesktop))),
          SliverToBoxAdapter(
              child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  key: _pricingKey,
                  color: t.sectionLight,
                  child: _pricingSection(t, isDesktop))),
          SliverToBoxAdapter(
              child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  key: _departuresKey,
                  color: t.bg,
                  child: _departuresSection(t, isDesktop))),
          SliverToBoxAdapter(
              child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  key: _contactKey,
                  color: t.sectionLightAlt,
                  child: _contactSection(t, isDesktop))),
          SliverToBoxAdapter(child: _footer(t)),
        ])),
      ),
    );
  }

  // ── TOP BAR ───────────────────────────────────────────────────────────────
  Widget _topBar(AppThemeProvider t, bool isDesktop) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      padding:
          EdgeInsets.symmetric(horizontal: isDesktop ? 40 : 16, vertical: 12),
      decoration: BoxDecoration(
        color: t.topBarBg,
        border: Border(
            bottom:
                BorderSide(color: t.border.withValues(alpha: 0.4), width: 1)),
      ),
      child: Row(children: [
        _brandLogo(),
        const Spacer(),
        if (!isDesktop)
          Row(children: [
            _themeToggle(t),
            const SizedBox(width: 6),
            _menuButton(t),
          ])
        else ...[
          _navLink("Tarifs", () => _scroll(_pricingKey)),
          _navLink("Départs", () => _scroll(_departuresKey)),
          _navLink("Contact", () => _scroll(_contactKey)),
          const SizedBox(width: 12),
          _themeToggle(t),
          const SizedBox(width: 12),
          _outlineBtn("Connexion", () => _push('/login')),
          const SizedBox(width: 10),
          _solidWhiteBtn("Créer un compte", () => _push('/signup')),
        ],
      ]),
    );
  }

  // ✅ Icône sac sur carré gradient bleu→teal
  Widget _brandLogo() {
    return Row(children: [
      Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(
              colors: [AppThemeProvider.appBlue, AppThemeProvider.teal],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
        ),
        child: const Icon(FontAwesomeIcons.bagShopping,
            color: Colors.white, size: 16),
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
                    fontSize: 16,
                    letterSpacing: 2.2,
                    height: 1.0)),
            Text("SERVICES INTERNATIONAL",
                style: TextStyle(
                    color: Colors.white54,
                    fontWeight: FontWeight.w600,
                    fontSize: 9,
                    letterSpacing: 1.0,
                    height: 1.0)),
          ]),
    ]);
  }

  Widget _themeToggle(AppThemeProvider t) {
    return Tooltip(
      message: t.isDark ? "Thème clair" : "Thème sombre",
      child: GestureDetector(
        onTap: () => context.read<AppThemeProvider>().toggleTheme(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, anim) => RotationTransition(
                turns: anim,
                child: FadeTransition(opacity: anim, child: child)),
            child: Icon(
              t.isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round,
              key: ValueKey(t.isDark),
              color: t.isDark ? _amber : Colors.white,
              size: 17,
            ),
          ),
        ),
      ),
    );
  }

  Widget _navLink(String label, VoidCallback onTap) => TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
            foregroundColor: Colors.white.withValues(alpha: 0.85)),
        child: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      );

  Widget _outlineBtn(String label, VoidCallback onTap) => OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(
              color: Colors.white.withValues(alpha: 0.42), width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      );

  Widget _solidWhiteBtn(String label, VoidCallback onTap) => ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: _appBlue,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        child: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
      );

  Widget _menuButton(AppThemeProvider t) {
    return PopupMenuButton<String>(
      color: t.bgCard,
      onSelected: (v) async {
        switch (v) {
          case 'tarifs':
            await _scroll(_pricingKey);
            break;
          case 'departs':
            await _scroll(_departuresKey);
            break;
          case 'contact':
            await _scroll(_contactKey);
            break;
          case 'wa_fr':
            await _wa(_waFrance);
            break;
          case 'wa_sn':
            await _wa(_waDakar);
            break;
          case 'email':
            await _openEmail();
            break;
          case 'login':
            _push('/login');
            break;
          case 'signup':
            _push('/signup');
            break;
        }
      },
      itemBuilder: (_) => [
        _mi(t, 'tarifs', 'Tarifs', Icons.local_offer_outlined),
        _mi(t, 'departs', 'Départs', Icons.event_available),
        _mi(t, 'contact', 'Contact', Icons.support_agent),
        const PopupMenuDivider(),
        _mi(t, 'wa_fr', 'WhatsApp France', FontAwesomeIcons.whatsapp),
        _mi(t, 'wa_sn', 'WhatsApp Dakar', FontAwesomeIcons.whatsapp),
        _mi(t, 'email', 'Email', Icons.email_outlined),
        const PopupMenuDivider(),
        _mi(t, 'login', 'Connexion', Icons.login),
        _mi(t, 'signup', 'Créer un compte', Icons.person_add_alt_1),
      ],
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
            borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.menu, color: Colors.white, size: 22),
      ),
    );
  }

  PopupMenuItem<String> _mi(
          AppThemeProvider t, String v, String label, IconData icon) =>
      PopupMenuItem(
        value: v,
        child: Row(children: [
          Icon(icon, size: 16, color: _appBlue),
          const SizedBox(width: 10),
          Text(label,
              style:
                  TextStyle(color: t.textPrimary, fontWeight: FontWeight.w600)),
        ]),
      );

  // ── TICKER ✅ uniquement départs à venir ──────────────────────────────────
  Widget _tickerBanner(AppThemeProvider t) {
    final upcoming = DepartureCountdownService.upcomingDepartures;
    if (upcoming.isEmpty) return const SizedBox.shrink();
    final dep = upcoming[_tickerIndex % upcoming.length];
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Container(
        key: ValueKey(_tickerIndex),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: _amber,
        child: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: t.bg, borderRadius: BorderRadius.circular(6)),
            child: Text("DÉPARTS",
                style: TextStyle(
                    color: _amber,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5)),
          ),
          const SizedBox(width: 14),
          Text(dep.flag, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
              child: Text("${dep.date}  ·  ${dep.route}",
                  style: TextStyle(
                      color: t.bg, fontWeight: FontWeight.w800, fontSize: 14),
                  overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showReservationModal(dep.route),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                  color: t.bg, borderRadius: BorderRadius.circular(8)),
              child: Text("Réserver →",
                  style: TextStyle(
                      color: _amber,
                      fontWeight: FontWeight.w800,
                      fontSize: 12)),
            ),
          ),
        ]),
      ),
    );
  }

  // ── COMPTE À REBOURS — alternance auto + swipe ────────────────────────────
  Widget _countdownBanner(AppThemeProvider t) {
    final dep = _countdown.currentDeparture;
    final sameDayCount = _countdown.sameDayCount;
    final inGroupIndex = _countdown.inGroupIndex;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      color: t.bgSection,
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _countdown.isExpired ? t.textMuted : _green)),
          const SizedBox(width: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              key: ValueKey("${dep.date}_$inGroupIndex"),
              _countdown.isExpired
                  ? "TOUS LES DÉPARTS SONT PASSÉS"
                  : "PROCHAIN DÉPART — ${dep.date.toUpperCase()}",
              style: TextStyle(
                  color: _countdown.isExpired ? t.textMuted : _green,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2),
            ),
          ),
        ]),

        const SizedBox(height: 6),

        // ✅ Swipe horizontal pour changer de départ (même jour)
        GestureDetector(
          onHorizontalDragEnd: (d) {
            if (d.primaryVelocity == null) return;
            if (d.primaryVelocity! < -200) {
              _countdown.nextSameDay(() {
                if (mounted) setState(() {});
              });
            } else if (d.primaryVelocity! > 200) {
              _countdown.prevSameDay(() {
                if (mounted) setState(() {});
              });
            }
          },
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (sameDayCount > 1)
              GestureDetector(
                  onTap: () => _countdown.prevSameDay(() {
                        if (mounted) setState(() {});
                      }),
                  child: Icon(Icons.chevron_left,
                      color: t.isDark ? _blueBright : _appBlue, size: 22)),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: Text(
                  key: ValueKey("route_${dep.route}"),
                  "${dep.flag}  ${dep.route}",
                  style: TextStyle(
                      color: t.isDark ? _blueBright : _appBlue,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
            ),
            if (sameDayCount > 1)
              GestureDetector(
                  onTap: () => _countdown.nextSameDay(() {
                        if (mounted) setState(() {});
                      }),
                  child: Icon(Icons.chevron_right,
                      color: t.isDark ? _blueBright : _appBlue, size: 22)),
          ]),
        ),

        // ✅ Points indicateurs (plusieurs départs même jour)
        if (sameDayCount > 1) ...[
          const SizedBox(height: 8),
          Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                  sameDayCount,
                  (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == inGroupIndex ? 18 : 7,
                        height: 6,
                        decoration: BoxDecoration(
                          color: i == inGroupIndex
                              ? _amber
                              : t.textMuted.withValues(alpha: 0.30),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ))),
        ],

        const SizedBox(height: 14),

        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _countUnit(t, _countdown.days, "JOURS", _amber),
          _sep(t),
          _countUnit(t, _countdown.hours, "HEURES", _appBlue),
          _sep(t),
          _countUnit(t, _countdown.minutes, "MIN", _appBlue),
          _sep(t),
          _countUnit(t, _countdown.seconds, "SEC", t.textMuted),
        ]),

        const SizedBox(height: 14),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.flight_takeoff, size: 16),
            label: Text("Réserver ${dep.route}",
                style: const TextStyle(fontWeight: FontWeight.w800)),
            style: ElevatedButton.styleFrom(
                backgroundColor: _amber,
                foregroundColor: _textDark,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12)),
            onPressed: () => _showReservationModal(dep.route),
          ),
        ),
      ]),
    );
  }

  Widget _countUnit(AppThemeProvider t, String v, String label, Color color) {
    return Column(children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.11),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Text(v,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 22,
                letterSpacing: 1)),
      ),
      const SizedBox(height: 4),
      Text(label,
          style: TextStyle(
              color: t.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1)),
    ]);
  }

  Widget _sep(AppThemeProvider t) => Padding(
        padding: const EdgeInsets.only(bottom: 18, left: 6, right: 6),
        child: Text(":",
            style: TextStyle(
                color: t.textMuted, fontSize: 20, fontWeight: FontWeight.w700)),
      );

  // ── HERO ──────────────────────────────────────────────────────────────────
  Widget _hero(AppThemeProvider t, bool isDesktop) {
    return AnimatedBuilder(
      animation: _bgAnim,
      builder: (context, _) {
        final g = t.heroGradient;
        return Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [g[0], g[1], Color.lerp(g[1], g[2], _bgAnim.value)!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight)),
          padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 64 : 20, vertical: isDesktop ? 80 : 52),
          child: Center(
              child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: isDesktop
                ? Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Expanded(flex: 3, child: _heroText(t, isDesktop)),
                    const SizedBox(width: 48),
                    Expanded(flex: 2, child: _heroCard(t)),
                  ])
                : Column(children: [
                    _heroText(t, isDesktop),
                    const SizedBox(height: 32),
                    _heroCard(t),
                  ]),
          )),
        );
      },
    );
  }

  Widget _heroText(AppThemeProvider t, bool isDesktop) {
    return Column(
      crossAxisAlignment:
          isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.28))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 6,
                height: 6,
                decoration:
                    const BoxDecoration(shape: BoxShape.circle, color: _teal)),
            const SizedBox(width: 8),
            const Text("Paris • Casablanca • Dakar",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 0.5)),
          ]),
        ),
        const SizedBox(height: 20),
        Text("SAMA",
            textAlign: isDesktop ? TextAlign.left : TextAlign.center,
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: isDesktop ? 72 : 52,
                letterSpacing: -2,
                height: 0.9)),
        const SizedBox(height: 6),
        Text("Services International",
            textAlign: isDesktop ? TextAlign.left : TextAlign.center,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontWeight: FontWeight.w600,
                fontSize: isDesktop ? 20 : 15,
                letterSpacing: 1)),
        const SizedBox(height: 16),
        Text("Transport · Shopping · Convoyage\nSuivi GPS · Achats sur demande",
            textAlign: isDesktop ? TextAlign.left : TextAlign.center,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.78),
                fontWeight: FontWeight.w400,
                fontSize: 15,
                height: 1.65)),
        const SizedBox(height: 28),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: isDesktop ? WrapAlignment.start : WrapAlignment.center,
          children: [
            _solidWhiteBtn("Créer un compte", () => _push('/signup')),
            _outlineBtn("Connexion", () => _push('/login')),
            _outlineBtn("Tarifs", () => _scroll(_pricingKey)),
          ],
        ),
      ],
    );
  }

  Widget _heroCard(AppThemeProvider t) {
    final dep = _countdown.currentDeparture;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: t.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: t.borderBright, width: 1.5),
        boxShadow: [
          BoxShadow(
              color: _appBlue.withValues(alpha: 0.12),
              blurRadius: 40,
              offset: const Offset(0, 16))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.bolt, color: _amber, size: 16),
          const SizedBox(width: 6),
          Text("Infos essentielles",
              style: TextStyle(
                  color: t.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13)),
        ]),
        const SizedBox(height: 16),
        _infoRow(t, Icons.local_offer_outlined, _appBlue, "Tarifs",
            "10€/kg · 65DH/kg · 6 500 FCFA/kg"),
        const SizedBox(height: 10),
        _infoRow(t, Icons.percent, _amber, "Promo web", "–50 % via l'app"),
        const SizedBox(height: 12),
        // Mini countdown
        AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _amber.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _amber.withValues(alpha: 0.22)),
          ),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.flight_takeoff, color: _amber, size: 13),
              const SizedBox(width: 6),
              Expanded(
                  child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: Text(
                    key: ValueKey("hc_${dep.route}"),
                    "${dep.flag} ${dep.route}",
                    style: const TextStyle(
                        color: _amber,
                        fontWeight: FontWeight.w700,
                        fontSize: 11),
                    overflow: TextOverflow.ellipsis),
              )),
            ]),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _miniUnit(t, _countdown.days, "J", _amber),
              Text(":",
                  style: TextStyle(
                      color: t.textMuted,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
              _miniUnit(t, _countdown.hours, "H", _appBlue),
              Text(":",
                  style: TextStyle(
                      color: t.textMuted,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
              _miniUnit(t, _countdown.minutes, "MIN", _appBlue),
            ]),
          ]),
        ),
        const SizedBox(height: 14),
        Divider(color: t.borderBright),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _waCardBtn(t, "France", _waFrance)),
          const SizedBox(width: 8),
          Expanded(child: _waCardBtn(t, "Dakar", _waDakar)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child: OutlinedButton(
            onPressed: () => _push('/login'),
            style: OutlinedButton.styleFrom(
                foregroundColor: t.textPrimary,
                side: BorderSide(color: t.borderBright),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 11)),
            child: const Text("Connexion",
                style: TextStyle(fontWeight: FontWeight.w700)),
          )),
          const SizedBox(width: 10),
          Expanded(
              child: ElevatedButton(
            onPressed: () => _push('/signup'),
            style: ElevatedButton.styleFrom(
                backgroundColor: _appBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 11)),
            child: const Text("S'inscrire",
                style: TextStyle(fontWeight: FontWeight.w800)),
          )),
        ]),
      ]),
    );
  }

  Widget _waCardBtn(AppThemeProvider t, String label, String digits) =>
      GestureDetector(
        onTap: () => _wa(digits),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: _green.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _green.withValues(alpha: 0.22)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(FontAwesomeIcons.whatsapp, color: _green, size: 13),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12)),
          ]),
        ),
      );

  Widget _miniUnit(AppThemeProvider t, String v, String label, Color color) =>
      Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withValues(alpha: 0.22))),
          child: Text(v,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  letterSpacing: 1)),
        ),
        const SizedBox(height: 3),
        Text(label,
            style: TextStyle(
                color: t.textMuted,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1)),
      ]);

  Widget _infoRow(AppThemeProvider t, IconData icon, Color color, String title,
          String value) =>
      Row(children: [
        Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, color: color, size: 15)),
        const SizedBox(width: 10),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: TextStyle(
                  color: t.textMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 11)),
          Text(value,
              style: TextStyle(
                  color: t.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
        ])),
      ]);

  // ── SERVICES ──────────────────────────────────────────────────────────────
  Widget _servicesSection(AppThemeProvider t, bool isDesktop) => _wrap(
      t,
      isDesktop,
      "Nos Services",
      "Tout ce qu'il faut pour expédier, acheter et suivre.",
      Wrap(
          spacing: 14,
          runSpacing: 14,
          alignment: WrapAlignment.center,
          children: _services
              .map((s) => _serviceCard(
                  t,
                  s['icon'] as IconData,
                  s['title'] as String,
                  s['desc'] as String,
                  s['color'] as Color))
              .toList()));

  Widget _serviceCard(AppThemeProvider t, IconData icon, String title,
          String desc, Color color) =>
      AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        width: 220,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: t.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.18)),
            boxShadow: [
              BoxShadow(
                  color: color.withValues(alpha: 0.07),
                  blurRadius: 14,
                  offset: const Offset(0, 5))
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 18)),
          const SizedBox(height: 12),
          Text(title,
              style: TextStyle(
                  color: t.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 14)),
          const SizedBox(height: 4),
          Text(desc,
              style: TextStyle(
                  color: t.textMuted,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                  height: 1.4)),
        ]),
      );

  // ── TARIFS ────────────────────────────────────────────────────────────────
  Widget _pricingSection(AppThemeProvider t, bool isDesktop) => _wrap(
      t,
      isDesktop,
      "Tarifs",
      "Prix au kilo. Réduction web disponible.",
      Column(children: [
        Wrap(
          spacing: 14,
          runSpacing: 14,
          alignment: WrapAlignment.center,
          children: [
            _priceCard(t, "🇫🇷 Paris", "10 €", "par kg", _appBlue),
            _priceCard(t, "🇲🇦 Casablanca", "65 DH", "par kg", _blueMid),
            _priceCard(t, "🇸🇳 Dakar", "6 500 FCFA", "par kg", _teal),
            _priceCard(t, "🌐 Web", "–50 %", "via l'app", _amber),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
              color: _amberLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _amber.withValues(alpha: 0.35))),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.star, color: _amber, size: 14),
            SizedBox(width: 8),
            Text("Réduction web : –50 % (selon disponibilité)",
                style: TextStyle(
                    color: Color(0xFF7A4F00),
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ]),
        ),
      ]));

  Widget _priceCard(AppThemeProvider t, String location, String price,
          String unit, Color accent) =>
      AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        width: 180,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: t.bgCard,
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: accent.withValues(alpha: 0.18), width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: accent.withValues(alpha: 0.07),
                  blurRadius: 12,
                  offset: const Offset(0, 4))
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(location,
              style: TextStyle(
                  color: t.textMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 12)),
          const SizedBox(height: 8),
          Text(price,
              style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w900,
                  fontSize: 26,
                  letterSpacing: -0.5)),
          Text(unit,
              style: TextStyle(
                  color: t.textMuted,
                  fontWeight: FontWeight.w500,
                  fontSize: 12)),
        ]),
      );

  // ── DÉPARTS ───────────────────────────────────────────────────────────────
  Widget _departuresSection(AppThemeProvider t, bool isDesktop) => _wrap(
      t,
      isDesktop,
      "Départs à venir",
      "Les prochaines dates de convoyage disponibles.",
      Column(
          children: DepartureCountdownService.allDepartures.map((dep) {
        final isCurrent = dep.route == _countdown.currentDeparture.route &&
            dep.date == _countdown.currentDeparture.date;
        final isPast = dep.dateTime.isBefore(DateTime.now());
        return AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: isCurrent
                ? _amber.withValues(alpha: t.isDark ? 0.10 : 0.07)
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
            Text(dep.flag, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(dep.route,
                      style: TextStyle(
                          color: isPast
                              ? t.textMuted
                              : isCurrent
                                  ? _amber
                                  : t.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  Text(dep.date,
                      style: TextStyle(
                          color: t.textMuted,
                          fontWeight: FontWeight.w500,
                          fontSize: 12)),
                  if (isCurrent)
                    const Text("En cours de compte à rebours",
                        style: TextStyle(
                            color: _amber,
                            fontSize: 10,
                            fontWeight: FontWeight.w600)),
                ])),
            if (isPast)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: t.border, borderRadius: BorderRadius.circular(20)),
                child: Text("PASSÉ",
                    style: TextStyle(
                        color: t.textMuted,
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                        letterSpacing: 0.8)),
              )
            else
              ElevatedButton(
                onPressed: () => _showReservationModal(dep.route),
                style: ElevatedButton.styleFrom(
                    backgroundColor: _amber,
                    foregroundColor: _textDark,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                child: const Text("Réserver",
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
              ),
          ]),
        );
      }).toList()));

  // ── CONTACT ───────────────────────────────────────────────────────────────
  Widget _contactSection(AppThemeProvider t, bool isDesktop) => _wrap(
      t,
      isDesktop,
      "Contact",
      "Disponibles 7j/7.",
      Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            _contactBtn(t, FontAwesomeIcons.whatsapp, "WhatsApp France",
                "+33 76 891 30 74", _green, () => _wa(_waFrance)),
            _contactBtn(t, FontAwesomeIcons.whatsapp, "WhatsApp Dakar",
                "+221 78 304 28 38", _green, () => _wa(_waDakar)),
            _contactBtn(
                t, Icons.email_outlined, "Email", _email, _appBlue, _openEmail),
          ]));

  Widget _contactBtn(AppThemeProvider t, IconData icon, String title,
          String subtitle, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          width: 240,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
              color: t.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.16)),
              boxShadow: [
                BoxShadow(
                    color: color.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ]),
          child: Row(children: [
            Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 18)),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      style: TextStyle(
                          color: t.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                  Text(subtitle,
                      style: TextStyle(
                          color: t.textMuted,
                          fontWeight: FontWeight.w500,
                          fontSize: 11),
                      overflow: TextOverflow.ellipsis),
                ])),
          ]),
        ),
      );

  // ── FOOTER ────────────────────────────────────────────────────────────────
  Widget _footer(AppThemeProvider t) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [Color(0xFF0A1628), Color(0xFF0D3060)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight)),
        child: Column(children: [
          _brandLogo(),
          const SizedBox(height: 12),
          Text(
              "© 2026 SAMA · Services International · Paris · Casablanca · Dakar",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w500,
                  fontSize: 12)),
        ]),
      );

  Widget _wrap(AppThemeProvider t, bool isDesktop, String title,
          String subtitle, Widget child) =>
      Padding(
        padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 64 : 20, vertical: isDesktop ? 56 : 36),
        child: Center(
            child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(children: [
            Text(title,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: isDesktop ? 30 : 22,
                    letterSpacing: -0.3)),
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: t.textMuted,
                    fontWeight: FontWeight.w400,
                    fontSize: 14)),
            const SizedBox(height: 28),
            child,
          ]),
        )),
      );
}
