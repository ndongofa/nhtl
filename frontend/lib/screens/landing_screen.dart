import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// Landing SAMA — Services international
/// Design: Cargo Premium — dark navy / ambre / turquoise électrique
class LandingScreenSamaServicesInternational extends StatefulWidget {
  const LandingScreenSamaServicesInternational({Key? key}) : super(key: key);

  @override
  State<LandingScreenSamaServicesInternational> createState() =>
      _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreenSamaServicesInternational>
    with TickerProviderStateMixin {
  // ── Palette ────────────────────────────────────────────────────────────────
  static const Color _navy = Color(0xFF080E1C);
  static const Color _navyMid = Color(0xFF0F1A2E);
  static const Color _navySurface = Color(0xFF162035);
  static const Color _teal = Color(0xFF00D4C8);
  static const Color _amber = Color(0xFFFFB300);
  static const Color _amberLight = Color(0xFFFFD166);
  static const Color _textPrimary = Color(0xFFF0F4FF);
  static const Color _textMuted = Color(0xFF8A9BBF);
  static const Color _border = Color(0xFF1E2E48);

  // ── Brand data ──────────────────────────────────────────────────────────────
  static const String _waFrance = "33768913074";
  static const String _waDakar = "221783042838";
  static const String _email = "contact@sama-logistique.com";

  static const List<Map<String, String>> _departures = [
    {"date": "23 mars 2026", "route": "Dakar → Paris", "flag": "🇸🇳🇫🇷"},
    {"date": "25 mars 2026", "route": "Casablanca → Paris", "flag": "🇲🇦🇫🇷"},
    {
      "date": "28 avril 2026",
      "route": "Paris → Casablanca",
      "flag": "🇫🇷🇲🇦"
    },
    {
      "date": "29 avril 2026",
      "route": "Casablanca → Dakar",
      "flag": "🇲🇦🇸🇳"
    },
    {
      "date": "30 avril 2026",
      "route": "Dakar → Casablanca",
      "flag": "🇸🇳🇲🇦"
    },
  ];

  static const List<Map<String, dynamic>> _services = [
    {
      "icon": FontAwesomeIcons.truckFast,
      "title": "Transport GP",
      "desc": "Groupage, fret aérien & maritime",
      "color": _teal,
    },
    {
      "icon": FontAwesomeIcons.bagShopping,
      "title": "Shopping",
      "desc": "Amazon, Temu, Shein, AliExpress",
      "color": _amber,
    },
    {
      "icon": FontAwesomeIcons.locationDot,
      "title": "Suivi GPS",
      "desc": "Tracking en temps réel 24/7",
      "color": _teal,
    },
    {
      "icon": FontAwesomeIcons.store,
      "title": "Achats sur mesure",
      "desc": "Marchés & boutiques spécialisés",
      "color": _amber,
    },
  ];

  // ── Scroll keys ─────────────────────────────────────────────────────────────
  final _pricingKey = GlobalKey();
  final _departuresKey = GlobalKey();
  final _contactKey = GlobalKey();

  // ── Animations ──────────────────────────────────────────────────────────────
  late final AnimationController _bgAnim;
  late final AnimationController _tickerAnim;
  int _tickerIndex = 0;

  @override
  void initState() {
    super.initState();
    _bgAnim =
        AnimationController(vsync: this, duration: const Duration(seconds: 8))
          ..repeat(reverse: true);

    _tickerAnim =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..addStatusListener((s) {
            if (s == AnimationStatus.completed) {
              setState(
                  () => _tickerIndex = (_tickerIndex + 1) % _departures.length);
              _tickerAnim.forward(from: 0);
            }
          })
          ..forward();
  }

  @override
  void dispose() {
    _bgAnim.dispose();
    _tickerAnim.dispose();
    super.dispose();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
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
        "https://wa.me/$digits?text=${Uri.encodeComponent("Bonjour SAMA, j'aimerais un devis.")}");
    if (await canLaunchUrl(uri))
      await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openEmail() async {
    final uri = Uri.parse(
        "mailto:$_email?subject=${Uri.encodeComponent("Demande d'information - SAMA")}");
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isDesktop = w >= 1024;

    return Scaffold(
      backgroundColor: _navy,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _topBar(isDesktop)),
            SliverToBoxAdapter(child: _hero(isDesktop)),
            SliverToBoxAdapter(child: _ticker()),
            SliverToBoxAdapter(child: _servicesSection(isDesktop)),
            SliverToBoxAdapter(
              child: Container(
                  key: _pricingKey, child: _pricingSection(isDesktop)),
            ),
            SliverToBoxAdapter(
              child: Container(
                  key: _departuresKey, child: _departuresSection(isDesktop)),
            ),
            SliverToBoxAdapter(
              child: Container(
                  key: _contactKey, child: _contactSection(isDesktop)),
            ),
            SliverToBoxAdapter(child: _footer()),
          ],
        ),
      ),
    );
  }

  // ── TOP BAR ──────────────────────────────────────────────────────────────────
  Widget _topBar(bool isDesktop) {
    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 16, vertical: 14),
      decoration: BoxDecoration(
        color: _navy.withValues(alpha: 0.95),
        border: const Border(bottom: BorderSide(color: _border, width: 1)),
      ),
      child: Row(
        children: [
          _brandLogo(),
          const Spacer(),
          if (!isDesktop)
            _menuButton()
          else ...[
            _navLink("Tarifs", () => _scroll(_pricingKey)),
            _navLink("Départs", () => _scroll(_departuresKey)),
            _navLink("Contact", () => _scroll(_contactKey)),
            const SizedBox(width: 16),
            _outlineBtn("Connexion", () => _push('/login')),
            const SizedBox(width: 10),
            _solidBtn("Créer un compte", _teal, () => _push('/signup')),
          ],
        ],
      ),
    );
  }

  Widget _brandLogo() {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
              colors: [_teal, Color(0xFF0099CC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(FontAwesomeIcons.boxOpen,
              color: Colors.white, size: 16),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("SAMA",
                style: TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    letterSpacing: 2)),
            Text("Services International",
                style: TextStyle(
                    color: _textMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                    letterSpacing: 0.5)),
          ],
        ),
      ],
    );
  }

  Widget _navLink(String label, VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(foregroundColor: _textMuted),
      child: Text(label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }

  Widget _outlineBtn(String label, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: _textPrimary,
        side: const BorderSide(color: _border, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }

  Widget _solidBtn(String label, Color bg, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: _navy,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
      child: Text(label,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
    );
  }

  Widget _menuButton() {
    return PopupMenuButton<String>(
      color: _navySurface,
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
        _menuItem('tarifs', 'Tarifs', Icons.local_offer_outlined),
        _menuItem('departs', 'Départs', Icons.event_available),
        _menuItem('contact', 'Contact', Icons.support_agent),
        const PopupMenuDivider(),
        _menuItem('wa_fr', 'WhatsApp France', FontAwesomeIcons.whatsapp),
        _menuItem('wa_sn', 'WhatsApp Dakar', FontAwesomeIcons.whatsapp),
        _menuItem('email', 'Email', Icons.email_outlined),
        const PopupMenuDivider(),
        _menuItem('login', 'Connexion', Icons.login),
        _menuItem('signup', 'Créer un compte', Icons.person_add_alt_1),
      ],
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: _border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.menu, color: _textPrimary, size: 20),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String value, String label, IconData icon) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 16, color: _teal),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(
                  color: _textPrimary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── HERO ─────────────────────────────────────────────────────────────────────
  Widget _hero(bool isDesktop) {
    return AnimatedBuilder(
      animation: _bgAnim,
      builder: (context, _) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 64 : 20, vertical: isDesktop ? 80 : 48),
          child: Stack(
            children: [
              // Blobs de fond
              Positioned(
                top: -40,
                right: isDesktop ? 60 : -20,
                child: _blob(
                    280, _teal.withValues(alpha: 0.06 + 0.04 * _bgAnim.value)),
              ),
              Positioned(
                bottom: -20,
                left: isDesktop ? 100 : -40,
                child: _blob(
                    220, _amber.withValues(alpha: 0.05 + 0.03 * _bgAnim.value)),
              ),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: isDesktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(flex: 3, child: _heroText(isDesktop)),
                            const SizedBox(width: 48),
                            Expanded(flex: 2, child: _heroCard()),
                          ],
                        )
                      : Column(
                          children: [
                            _heroText(isDesktop),
                            const SizedBox(height: 32),
                            _heroCard(),
                          ],
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color, blurRadius: 80, spreadRadius: 20)],
      ),
    );
  }

  Widget _heroText(bool isDesktop) {
    return Column(
      crossAxisAlignment:
          isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _teal.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _teal.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: _teal)),
              const SizedBox(width: 8),
              const Text("Paris • Casablanca • Dakar",
                  style: TextStyle(
                      color: _teal,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 0.5)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          "SAMA",
          textAlign: isDesktop ? TextAlign.left : TextAlign.center,
          style: TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: isDesktop ? 72 : 52,
            letterSpacing: -2,
            height: 0.9,
          ),
        ),
        Text(
          "Services International",
          textAlign: isDesktop ? TextAlign.left : TextAlign.center,
          style: TextStyle(
            color: _teal,
            fontWeight: FontWeight.w700,
            fontSize: isDesktop ? 22 : 16,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "Transport • Shopping • Convoyage\nSuivi GPS • Achats sur demande",
          textAlign: isDesktop ? TextAlign.left : TextAlign.center,
          style: const TextStyle(
            color: _textMuted,
            fontWeight: FontWeight.w500,
            fontSize: 15,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: isDesktop ? WrapAlignment.start : WrapAlignment.center,
          children: [
            _solidBtn("Créer un compte", _teal, () => _push('/signup')),
            _solidBtn("WhatsApp", _amber, () => _wa(_waFrance)),
            _outlineBtn("Tarifs", () => _scroll(_pricingKey)),
          ],
        ),
      ],
    );
  }

  Widget _heroCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _navySurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border, width: 1.5),
        boxShadow: [
          BoxShadow(
              color: _teal.withValues(alpha: 0.06),
              blurRadius: 40,
              spreadRadius: 5)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt, color: _amber, size: 16),
              const SizedBox(width: 6),
              const Text("Infos essentielles",
                  style: TextStyle(
                      color: _textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13)),
            ],
          ),
          const SizedBox(height: 16),
          _heroInfoRow(Icons.local_offer_outlined, _amber, "Tarifs",
              "10€/kg · 100DH/kg · 6500 FCFA/kg"),
          const SizedBox(height: 12),
          _heroInfoRow(Icons.percent, _teal, "Promo web", "–50 % via l'app"),
          const SizedBox(height: 12),
          _heroInfoRow(Icons.event_available, _teal, "Prochain départ",
              "${_departures[0]['date']} · ${_departures[0]['route']}"),
          const SizedBox(height: 20),
          const Divider(color: _border),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _solidBtn("Connexion", _navyMid, () => _push('/login')),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _solidBtn("S'inscrire", _teal, () => _push('/signup')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroInfoRow(IconData icon, Color color, String title, String value) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: _textMuted,
                      fontWeight: FontWeight.w600,
                      fontSize: 11)),
              Text(value,
                  style: const TextStyle(
                      color: _textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  // ── TICKER ───────────────────────────────────────────────────────────────────
  Widget _ticker() {
    final dep = _departures[_tickerIndex];
    return AnimatedBuilder(
      animation: _tickerAnim,
      builder: (context, _) {
        final opacity = _tickerAnim.value < 0.2 ? _tickerAnim.value / 0.2 : 1.0;
        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: _amber.withValues(alpha: 0.10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.flight_takeoff, color: _amber, size: 14),
                const SizedBox(width: 8),
                Text(
                  "Prochain départ · ${dep['flag']} ${dep['date']} · ${dep['route']}",
                  style: const TextStyle(
                      color: _amber,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      letterSpacing: 0.3),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () => _scroll(_departuresKey),
                  child: const Text("Voir tous →",
                      style: TextStyle(
                          color: _amber,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          decoration: TextDecoration.underline,
                          decorationColor: _amber)),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // ── SERVICES ─────────────────────────────────────────────────────────────────
  Widget _servicesSection(bool isDesktop) {
    return _sectionWrap(
      isDesktop: isDesktop,
      title: "Nos Services",
      subtitle: "Tout ce qu'il faut pour expédier, acheter et suivre.",
      child: Wrap(
        spacing: 14,
        runSpacing: 14,
        alignment: WrapAlignment.center,
        children: _services
            .map((s) => _serviceCard(
                  s['icon'] as IconData,
                  s['title'] as String,
                  s['desc'] as String,
                  s['color'] as Color,
                ))
            .toList(),
      ),
    );
  }

  Widget _serviceCard(IconData icon, String title, String desc, Color color) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _navySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(title,
              style: const TextStyle(
                  color: _textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 14)),
          const SizedBox(height: 4),
          Text(desc,
              style: const TextStyle(
                  color: _textMuted,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                  height: 1.4)),
        ],
      ),
    );
  }

  // ── PRICING ──────────────────────────────────────────────────────────────────
  Widget _pricingSection(bool isDesktop) {
    return _sectionWrap(
      isDesktop: isDesktop,
      title: "Tarifs",
      subtitle: "Prix au kilo. Réduction web disponible.",
      child: Column(
        children: [
          Wrap(
            spacing: 14,
            runSpacing: 14,
            alignment: WrapAlignment.center,
            children: [
              _priceCard("🇫🇷 Paris", "10 €", "par kg", _teal),
              _priceCard("🇲🇦 Casablanca", "100 DH", "par kg", _amber),
              _priceCard("🇸🇳 Dakar", "6 500 FCFA", "par kg", _teal),
              _priceCard("🌐 Web", "–50 %", "via l'app", _amber),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceCard(String location, String price, String unit, Color accent) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _navySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(location,
              style: const TextStyle(
                  color: _textMuted,
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
              style: const TextStyle(
                  color: _textMuted,
                  fontWeight: FontWeight.w500,
                  fontSize: 12)),
        ],
      ),
    );
  }

  // ── DEPARTURES ───────────────────────────────────────────────────────────────
  Widget _departuresSection(bool isDesktop) {
    return _sectionWrap(
      isDesktop: isDesktop,
      title: "Départs à venir",
      subtitle: "Les prochaines dates de convoyage disponibles.",
      child: Column(
        children: _departures
            .asMap()
            .entries
            .map((e) => _departureRow(e.key, e.value))
            .toList(),
      ),
    );
  }

  Widget _departureRow(int index, Map<String, String> dep) {
    final isFirst = index == 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isFirst ? _teal.withValues(alpha: 0.08) : _navySurface,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: isFirst ? _teal.withValues(alpha: 0.3) : _border),
      ),
      child: Row(
        children: [
          Text(dep['flag']!, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dep['route']!,
                    style: TextStyle(
                        color: isFirst ? _teal : _textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                Text(dep['date']!,
                    style: const TextStyle(
                        color: _textMuted,
                        fontWeight: FontWeight.w500,
                        fontSize: 12)),
              ],
            ),
          ),
          if (isFirst)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _teal.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text("PROCHAIN",
                  style: TextStyle(
                      color: _teal,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      letterSpacing: 1)),
            ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () => _wa(_waDakar),
            style: ElevatedButton.styleFrom(
              backgroundColor: _amber,
              foregroundColor: _navy,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 0,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text("Réserver",
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // ── CONTACT ──────────────────────────────────────────────────────────────────
  Widget _contactSection(bool isDesktop) {
    return _sectionWrap(
      isDesktop: isDesktop,
      title: "Contact",
      subtitle: "Nous sommes disponibles 7j/7.",
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: [
          _contactBtn(FontAwesomeIcons.whatsapp, "WhatsApp France",
              "+33 76 891 30 74", _teal, () => _wa(_waFrance)),
          _contactBtn(FontAwesomeIcons.whatsapp, "WhatsApp Dakar",
              "+221 78 304 28 38", _teal, () => _wa(_waDakar)),
          _contactBtn(
              Icons.email_outlined, "Email", _email, _amber, _openEmail),
        ],
      ),
    );
  }

  Widget _contactBtn(IconData icon, String title, String subtitle, Color color,
      VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _navySurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: _textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: _textMuted,
                          fontWeight: FontWeight.w500,
                          fontSize: 11),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── FOOTER ───────────────────────────────────────────────────────────────────
  Widget _footer() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration:
          const BoxDecoration(border: Border(top: BorderSide(color: _border))),
      child: Column(
        children: [
          _brandLogo(),
          const SizedBox(height: 12),
          const Text(
            "© 2026 SAMA · Services International · Paris · Casablanca · Dakar",
            textAlign: TextAlign.center,
            style: TextStyle(
                color: _textMuted, fontWeight: FontWeight.w500, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ── SECTION WRAPPER ───────────────────────────────────────────────────────────
  Widget _sectionWrap({
    required bool isDesktop,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 64 : 20, vertical: isDesktop ? 56 : 36),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              Text(title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: _textPrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: isDesktop ? 32 : 24,
                      letterSpacing: -0.5)),
              const SizedBox(height: 6),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: _textMuted,
                      fontWeight: FontWeight.w500,
                      fontSize: 14)),
              const SizedBox(height: 28),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
