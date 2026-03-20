import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class LandingScreenSamaServicesInternational extends StatefulWidget {
  const LandingScreenSamaServicesInternational({Key? key}) : super(key: key);

  @override
  State<LandingScreenSamaServicesInternational> createState() =>
      _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreenSamaServicesInternational>
    with TickerProviderStateMixin {
  static const Color _bg = Color(0xFF0D1B2E);
  static const Color _bgSection = Color(0xFF112236);
  static const Color _bgCard = Color(0xFF1A2E45);
  static const Color _appBlue = Color(0xFF2296F3);
  static const Color _blueBright = Color(0xFF42AAFE);
  static const Color _blueMid = Color(0xFF1A7ED4);
  static const Color _amber = Color(0xFFFFB300);
  static const Color _teal = Color(0xFF00D4C8);
  static const Color _green = Color(0xFF22C55E);
  static const Color _textPrimary = Color(0xFFF0F6FF);
  static const Color _textSecond = Color(0xFFB0C4DE);
  static const Color _textMuted = Color(0xFF7A94B0);
  static const Color _border = Color(0xFF1E3A55);
  static const Color _borderBright = Color(0xFF2A5070);
  static const Color _sectionLight = Color(0xFFF0F6FF);
  static const Color _sectionLightAlt = Color(0xFFE8F4FE);
  static const Color _textDark = Color(0xFF0F2040);
  static const Color _textDarkMuted = Color(0xFF4A6A8A);

  static const String _waFrance = "33768913074";
  static const String _waDakar = "221783042838";
  static const String _email = "contact@sama-logistique.com";

  static const List<Map<String, String>> _departures = [
    {"date": "23 mars 2026", "route": "Dakar → Paris", "flag": "🇸🇳🇫🇷"},
    {"date": "23 mars 2026", "route": "Dakar → Casablanca", "flag": "🇸🇳🇲🇦"},
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
  ];

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

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isDesktop = w >= 1024;
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _topBar(isDesktop)),
            SliverToBoxAdapter(child: _hero(isDesktop)),
            SliverToBoxAdapter(child: _ticker()),
            SliverToBoxAdapter(
                child: Container(
                    color: _bgSection, child: _servicesSection(isDesktop))),
            SliverToBoxAdapter(
                child: Container(
                    key: _pricingKey,
                    color: _sectionLight,
                    child: _pricingSection(isDesktop))),
            SliverToBoxAdapter(
                child: Container(
                    key: _departuresKey,
                    color: _bg,
                    child: _departuresSection(isDesktop))),
            SliverToBoxAdapter(
                child: Container(
                    key: _contactKey,
                    color: _sectionLightAlt,
                    child: _contactSection(isDesktop))),
            SliverToBoxAdapter(child: _footer()),
          ],
        ),
      ),
    );
  }

  Widget _topBar(bool isDesktop) {
    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: isDesktop ? 40 : 16, vertical: 14),
      decoration: BoxDecoration(
        color: _bg,
        border: const Border(bottom: BorderSide(color: _border, width: 1)),
      ),
      child: Row(children: [
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
          _solidBtn("Créer un compte", _appBlue, Colors.white,
              () => _push('/signup')),
        ],
      ]),
    );
  }

  Widget _brandLogo() {
    return Row(children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(
              colors: [_appBlue, _teal],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
        ),
        child:
            const Icon(FontAwesomeIcons.boxOpen, color: Colors.white, size: 16),
      ),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("SAMA",
            style: TextStyle(
                color: _textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 15,
                letterSpacing: 2)),
        const Text("Services International",
            style: TextStyle(
                color: _textMuted,
                fontWeight: FontWeight.w600,
                fontSize: 10,
                letterSpacing: 0.5)),
      ]),
    ]);
  }

  Widget _navLink(String label, VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(foregroundColor: _textSecond),
      child: Text(label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }

  Widget _outlineBtn(String label, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: _textPrimary,
        side: const BorderSide(color: _borderBright, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }

  Widget _solidBtn(String label, Color bg, Color fg, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
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
      color: _bgCard,
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
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            border: Border.all(color: _borderBright),
            borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.menu, color: _textPrimary, size: 22),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String value, String label, IconData icon) {
    return PopupMenuItem(
      value: value,
      child: Row(children: [
        Icon(icon, size: 16, color: _appBlue),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(
                color: _textPrimary, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _hero(bool isDesktop) {
    return AnimatedBuilder(
      animation: _bgAnim,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF0A1628),
                const Color(0xFF0D3060),
                Color.lerp(const Color(0xFF0D3060), const Color(0xFF1565C0),
                    _bgAnim.value)!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 64 : 20, vertical: isDesktop ? 80 : 52),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                          Expanded(flex: 3, child: _heroText(isDesktop)),
                          const SizedBox(width: 48),
                          Expanded(flex: 2, child: _heroCard()),
                        ])
                  : Column(children: [
                      _heroText(isDesktop),
                      const SizedBox(height: 32),
                      _heroCard(),
                    ]),
            ),
          ),
        );
      },
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
            color: _appBlue.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _appBlue.withValues(alpha: 0.4)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 6,
                height: 6,
                decoration:
                    const BoxDecoration(shape: BoxShape.circle, color: _teal)),
            const SizedBox(width: 8),
            const Text("Paris • Casablanca • Dakar",
                style: TextStyle(
                    color: _teal,
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
                color: _blueBright,
                fontWeight: FontWeight.w600,
                fontSize: isDesktop ? 20 : 15,
                letterSpacing: 1)),
        const SizedBox(height: 16),
        Text("Transport · Shopping · Convoyage\nSuivi GPS · Achats sur demande",
            textAlign: isDesktop ? TextAlign.left : TextAlign.center,
            style: const TextStyle(
                color: _textSecond,
                fontWeight: FontWeight.w400,
                fontSize: 15,
                height: 1.65)),
        const SizedBox(height: 28),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: isDesktop ? WrapAlignment.start : WrapAlignment.center,
          children: [
            _solidBtn("Créer un compte", _appBlue, Colors.white,
                () => _push('/signup')),
            _solidBtn("WhatsApp", _amber, Colors.white, () => _wa(_waFrance)),
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
        color: _bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderBright, width: 1.5),
        boxShadow: [
          BoxShadow(
              color: _appBlue.withValues(alpha: 0.15),
              blurRadius: 40,
              offset: const Offset(0, 16))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.bolt, color: _amber, size: 16),
          const SizedBox(width: 6),
          const Text("Infos essentielles",
              style: TextStyle(
                  color: _textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13)),
        ]),
        const SizedBox(height: 16),
        _heroInfoRow(Icons.local_offer_outlined, _appBlue, "Tarifs",
            "10€/kg · 65DH/kg · 6 500 FCFA/kg"),
        const SizedBox(height: 12),
        _heroInfoRow(Icons.percent, _amber, "Promo web", "–50 % via l'app"),
        const SizedBox(height: 12),
        _heroInfoRow(Icons.event_available, _teal, "Prochain départ",
            "${_departures[0]['date']} · ${_departures[0]['route']}"),
        const SizedBox(height: 20),
        Divider(color: _borderBright),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
              child: OutlinedButton(
            onPressed: () => _push('/login'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _textPrimary,
              side: const BorderSide(color: _borderBright),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
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
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text("S'inscrire",
                style: TextStyle(fontWeight: FontWeight.w800)),
          )),
        ]),
      ]),
    );
  }

  Widget _heroInfoRow(IconData icon, Color color, String title, String value) {
    return Row(children: [
      Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 16)),
      const SizedBox(width: 12),
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                color: _textMuted, fontWeight: FontWeight.w600, fontSize: 11)),
        Text(value,
            style: const TextStyle(
                color: _textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13)),
      ])),
    ]);
  }

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
            color: _amber.withValues(alpha: 0.12),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.flight_takeoff, color: _amber, size: 14),
              const SizedBox(width: 8),
              Text("Départ · ${dep['flag']} ${dep['date']} · ${dep['route']}",
                  style: const TextStyle(
                      color: _amber,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      letterSpacing: 0.3)),
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
              ),
            ]),
          ),
        );
      },
    );
  }

  Widget _servicesSection(bool isDesktop) {
    return _sectionWrap(
      isDesktop: isDesktop,
      dark: true,
      title: "Nos Services",
      subtitle: "Tout ce qu'il faut pour expédier, acheter et suivre.",
      child: Wrap(
        spacing: 14,
        runSpacing: 14,
        alignment: WrapAlignment.center,
        children: _services
            .map((s) => _serviceCard(s['icon'] as IconData,
                s['title'] as String, s['desc'] as String, s['color'] as Color))
            .toList(),
      ),
    );
  }

  Widget _serviceCard(IconData icon, String title, String desc, Color color) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 18)),
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
      ]),
    );
  }

  Widget _pricingSection(bool isDesktop) {
    return _sectionWrap(
      isDesktop: isDesktop,
      dark: false,
      title: "Tarifs",
      subtitle: "Prix au kilo. Réduction web disponible.",
      child: Column(children: [
        Wrap(
          spacing: 14,
          runSpacing: 14,
          alignment: WrapAlignment.center,
          children: [
            _priceCard("🇫🇷 Paris", "10 €", "par kg", _appBlue),
            _priceCard("🇲🇦 Casablanca", "65 DH", "par kg", _blueMid),
            _priceCard("🇸🇳 Dakar", "6 500 FCFA", "par kg", _teal),
            _priceCard("🌐 Web", "–50 %", "via l'app", _amber),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3D0),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _amber.withValues(alpha: 0.35)),
          ),
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
      ]),
    );
  }

  Widget _priceCard(String location, String price, String unit, Color accent) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: accent.withValues(alpha: 0.10),
              blurRadius: 16,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(location,
            style: const TextStyle(
                color: _textDarkMuted,
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
                color: _textDarkMuted,
                fontWeight: FontWeight.w500,
                fontSize: 12)),
      ]),
    );
  }

  Widget _departuresSection(bool isDesktop) {
    return _sectionWrap(
      isDesktop: isDesktop,
      dark: true,
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
    final highlight = index <= 1;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: highlight ? _appBlue.withValues(alpha: 0.12) : _bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: highlight ? _appBlue.withValues(alpha: 0.40) : _border),
      ),
      child: Row(children: [
        Text(dep['flag']!, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 14),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(dep['route']!,
              style: TextStyle(
                  color: highlight ? _blueBright : _textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
          Text(dep['date']!,
              style: const TextStyle(
                  color: _textMuted,
                  fontWeight: FontWeight.w500,
                  fontSize: 12)),
        ])),
        if (highlight)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: _appBlue.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(20)),
            child: const Text("BIENTÔT",
                style: TextStyle(
                    color: _blueBright,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                    letterSpacing: 1)),
          ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: () => _wa(_waDakar),
          style: ElevatedButton.styleFrom(
            backgroundColor: _amber,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text("Réserver",
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
        ),
      ]),
    );
  }

  Widget _contactSection(bool isDesktop) {
    return _sectionWrap(
      isDesktop: isDesktop,
      dark: false,
      title: "Contact",
      subtitle: "Nous sommes disponibles 7j/7.",
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: [
          _contactBtn(FontAwesomeIcons.whatsapp, "WhatsApp France",
              "+33 76 891 30 74", _green, () => _wa(_waFrance)),
          _contactBtn(FontAwesomeIcons.whatsapp, "WhatsApp Dakar",
              "+221 78 304 28 38", _green, () => _wa(_waDakar)),
          _contactBtn(
              Icons.email_outlined, "Email", _email, _appBlue, _openEmail),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.20)),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6))
          ],
        ),
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
                    style: const TextStyle(
                        color: _textDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
                Text(subtitle,
                    style: const TextStyle(
                        color: _textDarkMuted,
                        fontWeight: FontWeight.w500,
                        fontSize: 11),
                    overflow: TextOverflow.ellipsis),
              ])),
        ]),
      ),
    );
  }

  Widget _footer() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
            colors: [Color(0xFF0A1628), Color(0xFF0D3060)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight),
      ),
      child: Column(children: [
        _brandLogo(),
        const SizedBox(height: 12),
        Text(
            "© 2026 SAMA · Services International · Paris · Casablanca · Dakar",
            textAlign: TextAlign.center,
            style: TextStyle(
                color: _textMuted.withValues(alpha: 0.80),
                fontWeight: FontWeight.w500,
                fontSize: 12)),
      ]),
    );
  }

  Widget _sectionWrap({
    required bool isDesktop,
    required bool dark,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final titleColor = dark ? _textPrimary : _textDark;
    final subtitleColor = dark ? _textMuted : _textDarkMuted;
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 64 : 20, vertical: isDesktop ? 56 : 36),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(children: [
            Text(title,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: titleColor,
                    fontWeight: FontWeight.w900,
                    fontSize: isDesktop ? 30 : 22,
                    letterSpacing: -0.3)),
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: subtitleColor,
                    fontWeight: FontWeight.w400,
                    fontSize: 14)),
            const SizedBox(height: 28),
            child,
          ]),
        ),
      ),
    );
  }
}
