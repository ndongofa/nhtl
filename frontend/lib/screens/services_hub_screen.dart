// lib/screens/services_hub_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/sama_account_menu.dart';
import '../widgets/sama_logo_widget.dart';
import '../widgets/sama_service_icon.dart';
import '../providers/app_theme_provider.dart';
import '../services/auth_service.dart';
import '../services/departure_countdown_service.dart';
import '../models/logged_user.dart';

import 'commande_hub_screen.dart';
import 'landing_commande_screen.dart';
import 'landing_transport_screen.dart';
import 'transport_hub_screen.dart';

import 'services/sama_achat_screen.dart';
import 'services/sama_best_seller_screen.dart';
import 'services/sama_maad_screen.dart';
import 'services/sama_tech_digital_screen.dart';
import 'services/sama_teranga_screen.dart';

class ServicesHubScreen extends StatelessWidget {
  const ServicesHubScreen({Key? key}) : super(key: key);

  static const String _waFrance = "33768913074";
  static const String _waDakar = "221783042838";
  static const String _email = "tech@ngom-holding.com";

  // ── Service phare (Sama GP) affiché en hero card pleine largeur ──────────
  static const _ServiceItem _gpService = _ServiceItem(
      id: 'gp',
      emoji: '✈️',
      name: 'Sama GP',
      tagline: 'Transport par GP',
      desc: 'Groupage, fret aérien & maritime\nParis · Casablanca · Dakar',
      color: AppThemeProvider.appBlue,
      isLive: true);

  // ── Les 6 autres services affichés en grille équilibrée 3×2 / 2×3 ────────
  static const List<_ServiceItem> _otherServices = [
    _ServiceItem(
        id: 'commande',
        emoji: '🛒',
        name: 'Sama Commande',
        tagline: 'Shopping en ligne',
        desc: 'Amazon · Temu · Shein · AliExpress\nAchats livrés chez vous',
        color: AppThemeProvider.amber,
        isLive: true),
    _ServiceItem(
        id: 'achat',
        emoji: '🏪',
        name: 'Sama Achat',
        tagline: 'Achats sur mesure',
        desc:
            'Marchés & boutiques spécialisées\nProduits introuvables en ligne',
        color: AppThemeProvider.teal,
        isLive: true),
    _ServiceItem(
        id: 'maad',
        emoji: '🌿',
        name: 'Sama Maad',
        tagline: 'Vente de Maad',
        desc: 'Maad frais de qualité\ndirectement depuis le Sénégal',
        color: Color(0xFF16A34A),
        isLive: true),
    _ServiceItem(
        id: 'teranga',
        emoji: '🥂',
        name: 'Sama Téranga Apéro',
        tagline: 'Apéro sénégalais',
        desc: 'Bissap, Gnamakoudji, Ditax\net spécialités sénégalaises',
        color: Color(0xFFDC2626),
        isLive: true),
    _ServiceItem(
        id: 'bestseller',
        emoji: '⭐',
        name: 'Sama Best Seller',
        tagline: 'Articles best seller',
        desc: 'Sélection des articles\nles plus demandés du moment',
        color: Color(0xFF7C3AED),
        isLive: true),
    _ServiceItem(
        id: 'techdigital',
        emoji: '💻',
        name: 'Sama Tech Digital',
        tagline: 'Services digitaux',
        desc: 'Création de sites web\net solutions digitales sur mesure',
        color: Color(0xFF0EA5E9),
        isLive: true),
  ];

  Future<void> _wa(BuildContext context, String digits) async {
    final uri = Uri.parse(
      "https://wa.me/$digits?text=${Uri.encodeComponent("Bonjour SAMA, j'ai besoin de renseignements sur vos services.")}",
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openEmail() async {
    final uri = Uri.parse(
      "mailto:$_email?subject=${Uri.encodeComponent("Demande d'information - SAMA")}",
    );
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _openService(BuildContext context, _ServiceItem s) {
    Widget screen;
    switch (s.id) {
      case 'gp':
        screen = const LandingTransportScreen();
        break;
      case 'commande':
        screen = const LandingCommandeScreen();
        break;
      case 'achat':
        screen = const SamaAchatScreen();
        break;
      case 'maad':
        screen = const SamaMaadScreen();
        break;
      case 'teranga':
        screen = const SamaTerangaScreen();
        break;
      case 'bestseller':
        screen = const SamaBestSellerScreen();
        break;
      case 'techdigital':
        screen = const SamaTechDigitalScreen();
        break;
      default:
        return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppThemeProvider>();
    final isLogged = AuthService.isLoggedIn();
    final isAdmin = isLogged &&
        LoggedUser.fromSupabase().role == 'admin';
    final w = MediaQuery.of(context).size.width;
    final isDesktop = w >= 900;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      color: t.bg,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              _TopBar(t: t, isLogged: isLogged, isDesktop: isDesktop, isAdmin: isAdmin),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _HeroSection(t: t, isDesktop: isDesktop),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 24 : 16,
                          vertical: 32,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1400),
                            child: Column(
                              children: [
                                _sectionLabel(t, "Nos services"),
                                const SizedBox(height: 24),
                                // ── 1. Sama GP — hero card pleine largeur ──
                                _FeaturedGpCard(
                                  t: t,
                                  isDesktop: isDesktop,
                                  onTap: () => _openService(context, _gpService),
                                ),
                                const SizedBox(height: 16),
                                // ── 2. Compte à rebours prochain départ ───
                                _CountdownBannerCard(
                                  t: t,
                                  isDesktop: isDesktop,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const LandingTransportScreen(),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _sectionLabel(t, "Autres services"),
                                const SizedBox(height: 16),
                                // ── 3. Grille équilibrée des 6 autres services
                                isDesktop
                                    ? _gridDesktop(context, t)
                                    : _gridMobile(context, t),
                                const SizedBox(height: 8),
                                // ── 4. Bandeau annonces / promotions ──────
                                _AdsBannerCard(t: t, isDesktop: isDesktop),
                              ],
                            ),
                          ),
                        ),
                      ),
                      _ContactBand(
                        t: t,
                        onWaFrance: () => _wa(context, _waFrance),
                        onWaDakar: () => _wa(context, _waDakar),
                        onEmail: _openEmail,
                      ),
                      _Footer(t: t),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gridDesktop(BuildContext context, AppThemeProvider t) {
    const itemsPerRow = 3;
    final rows = (_otherServices.length / itemsPerRow).ceil();
    return Column(
      children: List.generate(rows, (rowIdx) {
        final start = rowIdx * itemsPerRow;
        final end = (start + itemsPerRow).clamp(0, _otherServices.length);
        final rowServices = _otherServices.sublist(start, end);
        final fillers = itemsPerRow - rowServices.length;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...rowServices.map((s) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16, bottom: 16),
                    child: _ServiceCard(
                      service: s,
                      t: t,
                      onTap: () => _openService(context, s),
                    ),
                  ),
                )),
            ...List.generate(fillers, (_) => const Expanded(child: SizedBox())),
          ],
        );
      }),
    );
  }

  Widget _gridMobile(BuildContext context, AppThemeProvider t) => Column(
        children: List.generate((_otherServices.length / 2).ceil(), (row) {
          final a = _otherServices[row * 2];
          final bIdx = row * 2 + 1;
          final b = bIdx < _otherServices.length ? _otherServices[bIdx] : null;
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 12),
                child: _ServiceCard(
                  service: a,
                  t: t,
                  onTap: () => _openService(context, a),
                ),
              ),
            ),
            Expanded(
              child: b != null
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 12),
                      child: _ServiceCard(
                        service: b,
                        t: t,
                        onTap: () => _openService(context, b),
                      ),
                    )
                  : const SizedBox(),
            ),
          ]);
        }),
      );

  Widget _sectionLabel(AppThemeProvider t, String label) => Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: t.textMuted,
            fontWeight: FontWeight.w700,
            fontSize: 11,
            letterSpacing: 1.5,
          ),
        ),
      );
}

// ── FEATURED GP CARD ─────────────────────────────────────────────────────────

class _FeaturedGpCard extends StatelessWidget {
  final AppThemeProvider t;
  final bool isDesktop;
  final VoidCallback onTap;
  const _FeaturedGpCard({
    required this.t,
    required this.isDesktop,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: t.isDark
                ? [const Color(0xFF0A1628), const Color(0xFF0D2545)]
                : [AppThemeProvider.appBlue, AppThemeProvider.blueMid],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppThemeProvider.appBlue.withValues(alpha: 0.28),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: EdgeInsets.all(isDesktop ? 28 : 20),
        child: isDesktop
            ? _desktopLayout(context)
            : _mobileLayout(context),
      ),
    );
  }

  Widget _desktopLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── Left: text content ────────────────────────────────────────────
        Expanded(
          flex: 3,
          child: _textContent(showBadge: true),
        ),
        const SizedBox(width: 32),
        // ── Right: icon + routes ──────────────────────────────────────────
        _rightPanel(),
      ],
    );
  }

  Widget _mobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: _rightPanel(),
        ),
        const SizedBox(height: 16),
        _textContent(showBadge: true),
      ],
    );
  }

  Widget _badge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Text("⭐", style: TextStyle(fontSize: 11)),
        const SizedBox(width: 5),
        const Text(
          "Service phare",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 11,
            letterSpacing: 0.4,
          ),
        ),
      ]),
    );
  }

  Widget _textContent({bool showBadge = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showBadge) ...[
          _badge(),
          const SizedBox(height: 14),
        ],
        const Text(
          "Sama GP",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 26,
            height: 1.1,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Transport par GP",
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.82),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Groupage, fret aérien & maritime",
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.68),
            fontWeight: FontWeight.w400,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppThemeProvider.appBlue,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
          ),
          child: const Text(
            "Découvrir →",
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _rightPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
          ),
          child: const Center(
            child: Text("✈️", style: TextStyle(fontSize: 36)),
          ),
        ),
        const SizedBox(height: 16),
        ...[
          ("🇫🇷", "Paris"),
          ("🇲🇦", "Casablanca"),
          ("🇸🇳", "Dakar"),
        ].map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(r.$1, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    r.$2,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

// ── COUNTDOWN BANNER CARD ────────────────────────────────────────────────────

class _CountdownBannerCard extends StatelessWidget {
  final AppThemeProvider t;
  final bool isDesktop;
  final VoidCallback onTap;
  const _CountdownBannerCard({
    required this.t,
    required this.isDesktop,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<DepartureCountdownService>();
    final dep = svc.currentDeparture;
    final hasCountdown = !svc.isExpired;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 24 : 16,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          color: t.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppThemeProvider.amber.withValues(alpha: 0.38),
          ),
          boxShadow: [
            BoxShadow(
              color: AppThemeProvider.amber.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: isDesktop
            ? _desktopLayout(context, svc, dep, hasCountdown)
            : _mobileLayout(context, svc, dep, hasCountdown),
      ),
    );
  }

  Widget _desktopLayout(BuildContext context, DepartureCountdownService svc,
      Departure dep, bool hasCountdown) {
    return Row(
      children: [
        // Label
        _label(t),
        const SizedBox(width: 20),
        // Route + flag
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(dep.flag, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  dep.route,
                  style: TextStyle(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ]),
              const SizedBox(height: 2),
              Text(
                dep.date,
                style: TextStyle(
                  color: AppThemeProvider.amber,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        // Countdown digits
        if (hasCountdown) ...[
          _countdownRow(svc, t),
          const SizedBox(width: 20),
        ],
        // CTA
        _ctaButton(t),
      ],
    );
  }

  Widget _mobileLayout(BuildContext context, DepartureCountdownService svc,
      Departure dep, bool hasCountdown) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _label(t),
            const Spacer(),
            _ctaButton(t),
          ],
        ),
        const SizedBox(height: 12),
        Row(children: [
          Text(dep.flag, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              dep.route,
              style: TextStyle(
                color: t.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ]),
        const SizedBox(height: 2),
        Text(
          dep.date,
          style: const TextStyle(
            color: AppThemeProvider.amber,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        if (hasCountdown) ...[
          const SizedBox(height: 12),
          _countdownRow(svc, t),
        ],
      ],
    );
  }

  Widget _label(AppThemeProvider t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppThemeProvider.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: AppThemeProvider.amber.withValues(alpha: 0.35)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.timer_outlined,
            color: AppThemeProvider.amber, size: 14),
        const SizedBox(width: 5),
        const Text(
          "PROCHAIN DÉPART",
          style: TextStyle(
            color: AppThemeProvider.amber,
            fontWeight: FontWeight.w800,
            fontSize: 10,
            letterSpacing: 0.8,
          ),
        ),
      ]),
    );
  }

  Widget _countdownRow(DepartureCountdownService svc, AppThemeProvider t) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _unit(t, svc.days, "J"),
        _sep(t),
        _unit(t, svc.hours, "H"),
        _sep(t),
        _unit(t, svc.minutes, "M"),
        _sep(t),
        _unit(t, svc.seconds, "S"),
      ],
    );
  }

  Widget _unit(AppThemeProvider t, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: AppThemeProvider.amber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
                color: AppThemeProvider.amber.withValues(alpha: 0.3)),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: AppThemeProvider.amber,
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: t.textMuted,
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _sep(AppThemeProvider t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 2, right: 2),
      child: Text(
        ":",
        style: TextStyle(
          color: t.textMuted,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _ctaButton(AppThemeProvider t) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppThemeProvider.amber,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          "Voir →",
          style: TextStyle(
            color: AppThemeProvider.textDark,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// ── ADS BANNER CARD ──────────────────────────────────────────────────────────

class _AdItem {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final Color colorEnd;
  const _AdItem({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.colorEnd,
  });
}

class _AdsBannerCard extends StatefulWidget {
  final AppThemeProvider t;
  final bool isDesktop;
  const _AdsBannerCard({required this.t, required this.isDesktop});

  @override
  State<_AdsBannerCard> createState() => _AdsBannerCardState();
}

class _AdsBannerCardState extends State<_AdsBannerCard>
    with WidgetsBindingObserver {
  static const List<_AdItem> _ads = [
    _AdItem(
      emoji: "✈️",
      title: "Prochain départ Paris → Dakar",
      subtitle: "Envoyez vos colis en 5 à 10 jours · Tarifs compétitifs",
      color: AppThemeProvider.appBlue,
      colorEnd: Color(0xFF0D5BBF),
    ),
    _AdItem(
      emoji: "🛒",
      title: "Commandez depuis Amazon, Temu & Shein",
      subtitle: "Livraison directe chez vous — Paris · Casablanca · Dakar",
      color: AppThemeProvider.amber,
      colorEnd: Color(0xFFE65100),
    ),
    _AdItem(
      emoji: "🌿",
      title: "Sama Maad — Fraîcheur du Sénégal",
      subtitle: "Maad de qualité directement depuis le terroir sénégalais",
      color: Color(0xFF16A34A),
      colorEnd: Color(0xFF14532D),
    ),
  ];

  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        setState(() => _index = (_index + 1) % _ads.length);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _timer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ads[_index];
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      child: Container(
        key: ValueKey(_index),
        width: double.infinity,
        padding: EdgeInsets.all(widget.isDesktop ? 22 : 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: widget.t.isDark
                ? [
                    ad.color.withValues(alpha: 0.22),
                    ad.colorEnd.withValues(alpha: 0.14),
                  ]
                : [
                    ad.color.withValues(alpha: 0.9),
                    ad.colorEnd,
                  ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Row(
          children: [
            Text(ad.emoji,
                style: TextStyle(fontSize: widget.isDesktop ? 32 : 26)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ad.title,
                    style: TextStyle(
                      color: widget.t.isDark ? widget.t.textPrimary : Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: widget.isDesktop ? 15 : 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    ad.subtitle,
                    style: TextStyle(
                      color: widget.t.isDark
                          ? widget.t.textMuted
                          : Colors.white.withValues(alpha: 0.82),
                      fontWeight: FontWeight.w400,
                      fontSize: widget.isDesktop ? 13 : 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Dot indicators
            Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                _ads.length,
                (i) => GestureDetector(
                  onTap: () => setState(() => _index = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    width: _index == i ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white
                          .withValues(alpha: _index == i ? 0.95 : 0.38),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Card service ─────────────────────────────────────────────────────────────

class _ServiceCard extends StatelessWidget {
  final _ServiceItem service;
  final AppThemeProvider t;
  final VoidCallback onTap;
  const _ServiceCard({
    required this.service,
    required this.t,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = service.color;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: t.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.22)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SamaServiceIcon(emoji: service.emoji, color: color),
          const SizedBox(height: 14),
          Text(
            service.name,
            style: TextStyle(
              color: t.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            service.tagline,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            service.desc,
            style: TextStyle(
              color: t.textMuted,
              fontWeight: FontWeight.w400,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 11),
              ),
              child: const Text(
                "Découvrir →",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── TOP BAR ──────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final AppThemeProvider t;
  final bool isLogged;
  final bool isDesktop;
  final bool isAdmin;
  const _TopBar({
    required this.t,
    required this.isLogged,
    required this.isDesktop,
    required this.isAdmin,
  });

  Future<void> _openAccountMenu(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: t.bgCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            border: Border.all(color: t.border.withValues(alpha: 0.6)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: t.border.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        "Mon espace",
                        style: TextStyle(
                          color: t.textPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: t.isDark ? "Thème clair" : "Thème sombre",
                        onPressed: () =>
                            context.read<AppThemeProvider>().toggleTheme(),
                        icon: Icon(
                          t.isDark
                              ? Icons.wb_sunny_outlined
                              : Icons.nightlight_round,
                          color: t.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _menuItem(
                    ctx,
                    icon: Icons.local_shipping_outlined,
                    title: "Transport GP",
                    subtitle: "Accéder au service Transport",
                    value: "transport",
                  ),
                  _menuItem(
                    ctx,
                    icon: Icons.shopping_bag_outlined,
                    title: "Commande",
                    subtitle: "Accéder au service Commande",
                    value: "commande",
                  ),
                  const SizedBox(height: 6),
                  if (isLogged) ...[
                    _menuItem(
                      ctx,
                      icon: Icons.person_outline,
                      title: "Profil",
                      subtitle: "Gérer mes informations",
                      value: "profile",
                    ),
                    if (isAdmin)
                      _menuItem(
                        ctx,
                        icon: Icons.admin_panel_settings_outlined,
                        title: "Espace Admin",
                        subtitle: "Tableau de bord administrateur",
                        value: "admin",
                      ),
                    _menuItem(
                      ctx,
                      icon: Icons.logout,
                      title: "Déconnexion",
                      subtitle: "Se déconnecter",
                      value: "logout",
                      danger: true,
                    ),
                  ] else ...[
                    _menuItem(
                      ctx,
                      icon: Icons.login_outlined,
                      title: "Connexion",
                      subtitle: "Se connecter",
                      value: "login",
                    ),
                    _menuItem(
                      ctx,
                      icon: Icons.person_add_alt_1_outlined,
                      title: "Créer un compte",
                      subtitle: "Créer un compte gratuitement",
                      value: "signup",
                    ),
                  ],
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (selected == null) return;

    switch (selected) {
      case "transport":
        if (isLogged) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TransportHubScreen()),
          );
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LandingTransportScreen()),
          );
        }
        break;

      case "commande":
        if (isLogged) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CommandeHubScreen()),
          );
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LandingCommandeScreen()),
          );
        }
        break;

      case "profile":
        Navigator.pushNamed(context, '/profile');
        break;

      case "admin":
        Navigator.pushNamed(context, '/admin');
        break;

      case "logout":
        await AuthService.logout();
        if (!context.mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
        break;

      case "login":
        Navigator.pushNamed(context, '/login');
        break;

      case "signup":
        Navigator.pushNamed(context, '/signup');
        break;
    }
  }

  Widget _menuItem(
    BuildContext ctx, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    bool danger = false,
  }) {
    final titleColor = danger ? Colors.red.shade700 : t.textPrimary;
    final iconColor = danger ? Colors.red.shade700 : AppThemeProvider.appBlue;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 6),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(
        title,
        style: TextStyle(color: titleColor, fontWeight: FontWeight.w800),
      ),
      subtitle: Text(subtitle, style: TextStyle(color: t.textMuted)),
      onTap: () => Navigator.of(ctx).pop(value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 40 : 16,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: t.topBarBg,
        border: Border(
          bottom: BorderSide(
            color: t.border.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          SamaTopBarLogo(),
          const Spacer(),

          if (!isDesktop) ...[
            // ── Mobile: all actions collapsed into a single hamburger menu ──
            PopupMenuButton<String>(
              icon: const Icon(Icons.menu, color: Colors.white),
              tooltip: "Menu",
              color: t.bgCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: t.border.withValues(alpha: 0.5)),
              ),
              onSelected: (value) async {
                switch (value) {
                  case 'theme':
                    context.read<AppThemeProvider>().toggleTheme();
                    break;
                  case 'account':
                    SamaAccountMenu.open(context);
                    break;
                  case 'admin':
                    Navigator.pushNamed(context, '/admin');
                    break;
                  case 'login':
                    Navigator.pushNamed(context, '/login');
                    break;
                  case 'signup':
                    Navigator.pushNamed(context, '/signup');
                    break;
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem<String>(
                  value: 'theme',
                  child: Row(children: [
                    Icon(
                      t.isDark
                          ? Icons.wb_sunny_outlined
                          : Icons.nightlight_round,
                      size: 18,
                      color: t.isDark
                          ? AppThemeProvider.amber
                          : AppThemeProvider.appBlue,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      t.isDark ? "Thème clair" : "Thème sombre",
                      style: TextStyle(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ]),
                ),
                if (isLogged)
                  PopupMenuItem<String>(
                    value: 'account',
                    child: Row(children: [
                      Icon(Icons.dashboard_outlined,
                          size: 18, color: AppThemeProvider.appBlue),
                      const SizedBox(width: 10),
                      Text(
                        "Mon espace",
                        style: TextStyle(
                          color: t.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ]),
                  ),
                if (isAdmin)
                  PopupMenuItem<String>(
                    value: 'admin',
                    child: Row(children: [
                      Icon(Icons.admin_panel_settings_outlined,
                          size: 18, color: AppThemeProvider.amber),
                      const SizedBox(width: 10),
                      Text(
                        "Espace Admin",
                        style: TextStyle(
                          color: t.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ]),
                  )
                // Non-admin non-logged: show login/signup
                else if (!isLogged) ...[
                  PopupMenuItem<String>(
                    value: 'login',
                    child: Row(children: [
                      Icon(Icons.login_outlined,
                          size: 18, color: AppThemeProvider.appBlue),
                      const SizedBox(width: 10),
                      Text(
                        "Connexion",
                        style: TextStyle(
                          color: t.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ]),
                  ),
                  PopupMenuItem<String>(
                    value: 'signup',
                    child: Row(children: [
                      Icon(Icons.person_add_alt_1_outlined,
                          size: 18, color: AppThemeProvider.appBlue),
                      const SizedBox(width: 10),
                      Text(
                        "S'inscrire",
                        style: TextStyle(
                          color: t.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ]),
                  ),
                ],
              ],
            ),
          ] else ...[
            // ── Desktop: keep full action bar ──────────────────────────────

            // Toggle thème
            GestureDetector(
              onTap: () => context.read<AppThemeProvider>().toggleTheme(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.28)),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, anim) => RotationTransition(
                    turns: anim,
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: Icon(
                    t.isDark
                        ? Icons.wb_sunny_outlined
                        : Icons.nightlight_round,
                    key: ValueKey(t.isDark),
                    color: t.isDark ? AppThemeProvider.amber : Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Espace Admin (si admin)
            if (isAdmin) ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.admin_panel_settings_outlined, size: 14),
                label: const Text(
                  "Espace Admin",
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppThemeProvider.amber.withValues(alpha: 0.18),
                  foregroundColor: AppThemeProvider.amber,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                        color: AppThemeProvider.amber.withValues(alpha: 0.45)),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                ),
                onPressed: () => Navigator.pushNamed(context, '/admin'),
              ),
              const SizedBox(width: 8),
            ],

            // Mon espace (menu)
            if (isLogged)
              ElevatedButton.icon(
                icon: const Icon(Icons.dashboard_outlined, size: 14),
                label: const Text(
                  "Mon espace",
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.14),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                ),
                onPressed: () => SamaAccountMenu.open(context),
              )
            else ...[
              OutlinedButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side:
                      BorderSide(color: Colors.white.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Connexion",
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/signup'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppThemeProvider.appBlue,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "S'inscrire",
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

// ── HERO ─────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final AppThemeProvider t;
  final bool isDesktop;
  const _HeroSection({required this.t, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: t.isDark
              ? [const Color(0xFF0A1628), const Color(0xFF0D2545)]
              : [AppThemeProvider.appBlue, AppThemeProvider.blueMid],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 64 : 20,
        vertical: isDesktop ? 56 : 40,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppThemeProvider.teal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Paris • Casablanca • Dakar",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 20),
              Text(
                "Tous vos services\nen un seul endroit",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: isDesktop ? 44 : 28,
                  height: 1.15,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Transport · Commandes · Achats sur mesure · Spécialités sénégalaises",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontWeight: FontWeight.w400,
                  fontSize: isDesktop ? 16 : 13,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── CONTACT ──────────────────────────────────────────────────────────────────

class _ContactBand extends StatelessWidget {
  final AppThemeProvider t;
  final VoidCallback onWaFrance;
  final VoidCallback onWaDakar;
  final VoidCallback onEmail;
  const _ContactBand({
    required this.t,
    required this.onWaFrance,
    required this.onWaDakar,
    required this.onEmail,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      color: t.sectionLightAlt,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Column(children: [
        Text(
          "NOUS CONTACTER",
          style: TextStyle(
            color: t.textMuted,
            fontWeight: FontWeight.w700,
            fontSize: 11,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            _chip(
              const FaIcon(FontAwesomeIcons.whatsapp,
                  color: AppThemeProvider.green, size: 17),
              AppThemeProvider.green,
              "WhatsApp France",
              "+33 76 891 30 74",
              onWaFrance,
            ),
            _chip(
              const FaIcon(FontAwesomeIcons.whatsapp,
                  color: AppThemeProvider.green, size: 17),
              AppThemeProvider.green,
              "WhatsApp Dakar",
              "+221 78 304 28 38",
              onWaDakar,
            ),
            _chip(
              const Icon(Icons.email_outlined,
                  color: AppThemeProvider.appBlue, size: 17),
              AppThemeProvider.appBlue,
              "Email",
              "tech@ngom-holding.com",
              onEmail,
            ),
          ],
        ),
      ]),
    );
  }

  Widget _chip(
    Widget icon,
    Color color,
    String label,
    String sub,
    VoidCallback onTap,
  ) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: t.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.22)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Center(child: icon),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                label,
                style: TextStyle(
                  color: t.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              Text(sub, style: TextStyle(color: t.textMuted, fontSize: 11)),
            ]),
          ]),
        ),
      );
}

// ── FOOTER ───────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  final AppThemeProvider t;
  const _Footer({required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A1628), Color(0xFF0D3060)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: const LinearGradient(
                colors: [AppThemeProvider.appBlue, AppThemeProvider.teal],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Center(
              child:
                  FaIcon(FontAwesomeIcons.globe, color: Colors.white, size: 14),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            "SAMA SERVICES INTERNATIONAL",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
              letterSpacing: 1.5,
            ),
          ),
        ]),
        const SizedBox(height: 10),
        Text(
          "© 2026 · Paris · Casablanca · Dakar",
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 12,
          ),
        ),
      ]),
    );
  }
}

// ── MODEL ────────────────────────────────────────────────────────────────────

class _ServiceItem {
  final String id, emoji, name, tagline, desc;
  final Color color;
  final bool isLive;
  const _ServiceItem({
    required this.id,
    required this.emoji,
    required this.name,
    required this.tagline,
    required this.desc,
    required this.color,
    required this.isLive,
  });
}
