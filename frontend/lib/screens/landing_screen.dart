import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// Landing SAMA — Services international
/// - Scroll vers sections "Tarifs", "Départs", "Contact" (GlobalKey + ensureVisible)
/// - CTA WhatsApp + e-mail branchés via url_launcher
/// - Flutter r��cent: withOpacity() évité -> withValues(alpha: ...)
///
/// À faire côté projet:
/// - pubspec.yaml: url_launcher: ^6.3.0 (ou version compatible)
/// - flutter pub get
///
/// Routes attendues (si configurées):
/// - /login
/// - /signup
/// - /public (optionnel)
class LandingScreenSamaServicesInternational extends StatefulWidget {
  const LandingScreenSamaServicesInternational({Key? key}) : super(key: key);

  @override
  State<LandingScreenSamaServicesInternational> createState() =>
      _LandingScreenSamaServicesInternationalState();
}

class _LandingScreenSamaServicesInternationalState
    extends State<LandingScreenSamaServicesInternational>
    with SingleTickerProviderStateMixin {
  // Brand palette
  final Color mainBlue = const Color(0xFF2296F3);
  final Color turquoise = const Color(0xFF39E4E2);
  final Color orange = const Color(0xFFFFB300);

  // High-contrast neutrals
  final Color text = const Color(0xFF0F172A);
  final Color muted = const Color(0xFF475569);
  final Color surface = Colors.white;
  final Color bg = const Color(0xFFF6F8FC);

  // Contacts (E.164 digits)
  final String whatsappFranceDigits = "33768913074"; // +33768913074
  final String whatsappDakarDigits = "221783042838"; // +221783042838
  final String email = "contact@sama-logistique.com";

  // Pricing (hardcoded)
  final String priceParis = "10 € / kg";
  final String priceCasablanca = "100 DH / kg";
  final String priceDakar = "6 500 FCFA / kg";
  final String promoWeb = "–50 % via l’application web";

  // Departures (hardcoded)
  final List<Map<String, String>> departures = const [
    {"date": "23 mars 2026", "route": "Dakar → Paris"},
    {"date": "25 mars 2026", "route": "Casablanca → Paris"},
    {"date": "28 avril 2026", "route": "Paris → Casablanca"},
    {"date": "29 avril 2026", "route": "Casablanca → Dakar"},
    {"date": "30 avril 2026", "route": "Dakar → Casablanca"},
  ];

  // Scroll keys
  final GlobalKey _pricingKey = GlobalKey();
  final GlobalKey _departuresKey = GlobalKey();
  final GlobalKey _contactKey = GlobalKey();

  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim =
        AnimationController(vsync: this, duration: const Duration(seconds: 6))
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  // ----------------------------
  // Navigation helpers
  // ----------------------------
  void _safePushNamed(BuildContext context, String route) {
    try {
      Navigator.pushNamed(context, route);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Route « $route » introuvable. Vérifie MaterialApp."),
        ),
      );
    }
  }

  Future<void> _scrollTo(GlobalKey key) async {
    final ctx = key.currentContext;
    if (ctx == null) return;

    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      alignment: 0.02,
    );
  }

  // ----------------------------
  // External actions (url_launcher)
  // ----------------------------
  Future<void> _openUrl(Uri uri) async {
    final ok = await canLaunchUrl(uri);
    if (!ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Impossible d’ouvrir: $uri")),
      );
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openWhatsApp({required String digits, String? message}) async {
    final msg = (message ?? "Bonjour SAMA, j’aimerais un devis.").trim();
    final uri =
        Uri.parse("https://wa.me/$digits?text=${Uri.encodeComponent(msg)}");
    await _openUrl(uri);
  }

  Future<void> _openEmail() async {
    // Note: mailto query uses standard query string, simplest is to hand-build it.
    final subject = "Demande d'information - SAMA";
    final body =
        "Bonjour,\n\nJe souhaite obtenir un devis / des informations.\n\nMerci.";
    final uri = Uri.parse(
      "mailto:$email?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}",
    );
    await _openUrl(uri);
  }

  Future<void> _handleMenuSelection(String v) async {
    switch (v) {
      case 'tarifs':
        await _scrollTo(_pricingKey);
        return;
      case 'departs':
        await _scrollTo(_departuresKey);
        return;
      case 'contact':
        await _scrollTo(_contactKey);
        return;
      case 'wa_fr':
        await _openWhatsApp(digits: whatsappFranceDigits);
        return;
      case 'wa_sn':
        await _openWhatsApp(digits: whatsappDakarDigits);
        return;
      case 'email':
        await _openEmail();
        return;
      case 'login':
        _safePushNamed(context, '/login');
        return;
      case 'signup':
        _safePushNamed(context, '/signup');
        return;
      case 'public':
        _safePushNamed(context, '/public');
        return;
    }
  }

  // ----------------------------
  // Formatting helpers
  // ----------------------------
  String _pricesInline() => "$priceParis • $priceCasablanca • $priceDakar";
  String _displayE164(String digits) => "+$digits";

  // ----------------------------
  // UI
  // ----------------------------
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final bool isDesktop = w >= 1024;
    final bool isNarrow = w < 520;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _topBar(isDesktop: isDesktop, isNarrow: isNarrow),
            ),
            SliverToBoxAdapter(child: _hero(isDesktop: isDesktop)),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverToBoxAdapter(child: _primaryInfoCards(isDesktop: isDesktop)),
            const SliverToBoxAdapter(child: SizedBox(height: 18)),
            SliverToBoxAdapter(
              child: _section(
                title: "Services",
                subtitle:
                    "Tout ce qu’il faut pour expédier, acheter et suivre.",
                child: _services(),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverToBoxAdapter(
              child: Container(
                key: _pricingKey,
                child: _section(
                  background: const Color(0xFFF1FBFF),
                  title: "Tarifs & promo",
                  subtitle:
                      "Prix au kilo + réduction web. Clair, simple, immédiat.",
                  child: _pricing(),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverToBoxAdapter(
              child: Container(
                key: _departuresKey,
                child: _section(
                  title: "Départs à venir",
                  subtitle: "Les prochaines dates disponibles.",
                  child: _departures(),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverToBoxAdapter(
              child: Container(
                key: _contactKey,
                child: _section(
                  background: const Color(0xFFFFFBF1),
                  title: "Contact & accès",
                  subtitle: "WhatsApp, e-mail et accès à l’application.",
                  child: _contactAndAccess(),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 10)),
            SliverToBoxAdapter(child: _footer()),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
          ],
        ),
      ),
    );
  }

  // ----------------------------
  // TOP BAR
  // ----------------------------
  Widget _topBar({required bool isDesktop, required bool isNarrow}) {
    return Container(
      color: surface,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 20.0 : 12.0,
        vertical: 10.0,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180.0),
          child: Row(
            children: [
              _brand(),
              const Spacer(),
              if (!isNarrow) ...[
                _textButton(
                  label: "Tarifs",
                  icon: Icons.local_offer_outlined,
                  onTap: () => _scrollTo(_pricingKey),
                ),
                const SizedBox(width: 8),
                _textButton(
                  label: "Départs",
                  icon: Icons.event_available,
                  onTap: () => _scrollTo(_departuresKey),
                ),
                const SizedBox(width: 8),
                _textButton(
                  label: "Contact",
                  icon: Icons.support_agent,
                  onTap: () => _scrollTo(_contactKey),
                ),
                const SizedBox(width: 8),
              ],
              if (isNarrow)
                _moreMenu()
              else
                Wrap(
                  spacing: 10,
                  children: [
                    _primaryButton(
                      label: "Connexion",
                      icon: Icons.login,
                      bg: Colors.white,
                      fg: text,
                      border: text.withValues(alpha: 0.14),
                      onTap: () => _safePushNamed(context, '/login'),
                    ),
                    _primaryButton(
                      label: "Créer un compte",
                      icon: Icons.person_add_alt_1,
                      bg: turquoise,
                      fg: Colors.white,
                      onTap: () => _safePushNamed(context, '/signup'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _brand() {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: [turquoise, mainBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: mainBlue.withValues(alpha: 0.12),
                blurRadius: 14,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: const Icon(FontAwesomeIcons.boxOpen,
              color: Colors.white, size: 16),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "SAMA",
              style: TextStyle(
                color: text,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 0.4,
              ),
            ),
            Text(
              "Services international",
              style: TextStyle(
                color: muted,
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _moreMenu() {
    return PopupMenuButton<String>(
      tooltip: "Menu",
      onSelected: (v) {
        // onSelected is sync; call async handler without returning Future.
        _handleMenuSelection(v);
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'tarifs', child: Text("Tarifs")),
        PopupMenuItem(value: 'departs', child: Text("Départs")),
        PopupMenuItem(value: 'contact', child: Text("Contact")),
        PopupMenuDivider(),
        PopupMenuItem(value: 'wa_fr', child: Text("WhatsApp France")),
        PopupMenuItem(value: 'wa_sn', child: Text("WhatsApp Dakar")),
        PopupMenuItem(value: 'email', child: Text("E-mail")),
        PopupMenuDivider(),
        PopupMenuItem(value: 'login', child: Text("Connexion")),
        PopupMenuItem(value: 'signup', child: Text("Créer un compte")),
        PopupMenuItem(value: 'public', child: Text("Infos publiques")),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: text.withValues(alpha: 0.14)),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu, color: text, size: 18),
            const SizedBox(width: 8),
            Text(
              "Menu",
              style: TextStyle(
                color: text,
                fontWeight: FontWeight.w900,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _textButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 18, color: muted),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: text,
                  fontWeight: FontWeight.w900,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required IconData icon,
    required Color bg,
    required Color fg,
    required VoidCallback onTap,
    Color? border,
  }) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border:
                border != null ? Border.all(color: border, width: 1.2) : null,
            boxShadow: [
              BoxShadow(
                color: bg == Colors.white
                    ? Colors.black.withValues(alpha: 0.05)
                    : bg.withValues(alpha: 0.18),
                blurRadius: 14,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: fg, size: 18),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------
  // HERO
  // ----------------------------
  Widget _hero({required bool isDesktop}) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final t = _anim.value;

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 20 : 12,
            vertical: isDesktop ? 18 : 10,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF07101F),
                              mainBlue,
                              turquoise,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _BlobsPainter(
                            t: t,
                            c1: turquoise,
                            c2: mainBlue,
                            c3: orange,
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF07101F).withValues(alpha: 0.42),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.16),
                            width: 1.4,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 34 : 16,
                        vertical: isDesktop ? 30 : 18,
                      ),
                      child: isDesktop
                          ? Row(
                              children: [
                                Expanded(child: _heroCopy(isDesktop: true)),
                                const SizedBox(width: 16),
                                SizedBox(width: 420, child: _heroKeyInfoCard()),
                              ],
                            )
                          : Column(
                              children: [
                                _heroCopy(isDesktop: false),
                                const SizedBox(height: 14),
                                _heroKeyInfoCard(),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _heroCopy({required bool isDesktop}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _floatingIcon(),
            const SizedBox(width: 12),
            Text(
              "SAMA",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: isDesktop ? 56 : 40,
                color: Colors.white,
                letterSpacing: -1.0,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 22,
                  )
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          "Services international",
          textAlign: isDesktop ? TextAlign.left : TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: isDesktop ? 18 : 15,
            color: Colors.white.withValues(alpha: 0.96),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "Transport • Shopping • Convoyage • Suivi GPS • Achats sur demande",
          textAlign: isDesktop ? TextAlign.left : TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            height: 1.35,
            fontSize: isDesktop ? 16.5 : 13.8,
            color: Colors.white.withValues(alpha: 0.92),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: isDesktop ? WrapAlignment.start : WrapAlignment.center,
          children: [
            _pill(label: "Paris", icon: Icons.location_on, accent: turquoise),
            _pill(
                label: "Casablanca", icon: Icons.location_on, accent: mainBlue),
            _pill(label: "Dakar", icon: Icons.location_on, accent: orange),
            _pill(
                label: "Promo web –50 %", icon: Icons.percent, accent: orange),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: isDesktop ? WrapAlignment.start : WrapAlignment.center,
          children: [
            _primaryButton(
              label: "Tarifs",
              icon: Icons.local_offer_outlined,
              bg: Colors.white,
              fg: text,
              border: Colors.white.withValues(alpha: 0.0),
              onTap: () => _scrollTo(_pricingKey),
            ),
            _primaryButton(
              label: "Départs",
              icon: Icons.event_available,
              bg: orange,
              fg: Colors.white,
              onTap: () => _scrollTo(_departuresKey),
            ),
            _primaryButton(
              label: "WhatsApp",
              icon: FontAwesomeIcons.whatsapp,
              bg: turquoise,
              fg: Colors.white,
              onTap: () => _openWhatsApp(digits: whatsappFranceDigits),
            ),
          ],
        ),
      ],
    );
  }

  Widget _floatingIcon() {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        final dy = (1.0 - _anim.value) * 6.0;
        return Transform.translate(
          offset: Offset(0, dy),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: const Icon(FontAwesomeIcons.plane,
                color: Colors.white, size: 22),
          ),
        );
      },
    );
  }

  Widget _pill({
    required String label,
    required IconData icon,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.45), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.95)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroKeyInfoCard() {
    final first = departures.isNotEmpty ? departures.first : null;

    return _GlassCard(
      radius: 24,
      border: Colors.white.withValues(alpha: 0.18),
      background: Colors.white.withValues(alpha: 0.10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.bolt, color: orange, size: 18),
                const SizedBox(width: 8),
                const Text(
                  "Infos clés",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                )
              ],
            ),
            const SizedBox(height: 12),
            _keyRow(
              icon: Icons.local_offer,
              title: "Tarifs",
              value: _pricesInline(),
              accent: orange,
            ),
            const SizedBox(height: 10),
            _keyRow(
              icon: Icons.percent,
              title: "Promo web",
              value: promoWeb,
              accent: orange,
            ),
            if (first != null) ...[
              const SizedBox(height: 10),
              _keyRow(
                icon: Icons.event_available,
                title: "Prochain départ",
                value: "${first["date"]} • ${first["route"]}",
                accent: turquoise,
              ),
            ],
            const SizedBox(height: 12),
            _keyRow(
              icon: FontAwesomeIcons.whatsapp,
              title: "WhatsApp",
              value:
                  "${_displayE164(whatsappFranceDigits)} • ${_displayE164(whatsappDakarDigits)}",
              accent: mainBlue,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                _primaryButton(
                  label: "Connexion",
                  icon: Icons.login,
                  bg: Colors.white,
                  fg: text,
                  border: Colors.white.withValues(alpha: 0.0),
                  onTap: () => _safePushNamed(context, '/login'),
                ),
                _primaryButton(
                  label: "Créer un compte",
                  icon: Icons.person_add_alt_1,
                  bg: turquoise,
                  fg: Colors.white,
                  onTap: () => _safePushNamed(context, '/signup'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _keyRow({
    required IconData icon,
    required String title,
    required String value,
    required Color accent,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF07101F).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.14), width: 1.1),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: accent.withValues(alpha: 0.30), width: 1.0),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.96),
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.90),
                    fontWeight: FontWeight.w700,
                    fontSize: 12.2,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // ----------------------------
  // PRIMARY INFO CARDS
  // ----------------------------
  Widget _primaryInfoCards({required bool isDesktop}) {
    final firstDate = departures.isNotEmpty ? departures.first["date"]! : "—";

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 20 : 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _infoCard(
                title: "Tarifs",
                value: _pricesInline(),
                icon: Icons.local_offer_outlined,
                accent: orange,
              ),
              _infoCard(
                title: "Promo web",
                value: promoWeb,
                icon: Icons.percent,
                accent: orange,
              ),
              _infoCard(
                title: "Départ le plus proche",
                value: firstDate,
                icon: Icons.event_available,
                accent: turquoise,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accent,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 260, maxWidth: 380),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent.withValues(alpha: 0.16), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: accent.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: text,
                      fontWeight: FontWeight.w900,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: muted,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // ----------------------------
  // SECTION WRAPPER
  // ----------------------------
  Widget _section({
    required String title,
    required String subtitle,
    required Widget child,
    Color background = Colors.transparent,
  }) {
    final w = MediaQuery.of(context).size.width;
    final bool isDesktop = w >= 1024;

    return Container(
      width: double.infinity,
      color: background,
      padding: EdgeInsets.symmetric(
        vertical: isDesktop ? 26 : 16,
        horizontal: isDesktop ? 20 : 12,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: text,
                  fontWeight: FontWeight.w900,
                  fontSize: isDesktop ? 28 : 20,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: muted,
                  fontWeight: FontWeight.w700,
                  fontSize: isDesktop ? 14 : 12.8,
                ),
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------
  // SERVICES
  // ----------------------------
  Widget _services() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        _serviceCard(
          title: "Transport international",
          subtitle: "GP, fret aérien, bateau…",
          icon: FontAwesomeIcons.truckFast,
          accent: turquoise,
          bullets: const [
            "Groupage (GP)",
            "Fret aérien",
            "Maritime",
            "Sur mesure"
          ],
        ),
        _serviceCard(
          title: "Shopping international",
          subtitle: "Amazon, Temu, Shein, AliExpress…",
          icon: FontAwesomeIcons.bagShopping,
          accent: orange,
          bullets: const [
            "Commande",
            "Réception",
            "Consolidation",
            "Livraison"
          ],
        ),
        _serviceCard(
          title: "Convoyage",
          subtitle: "Véhicules et transferts.",
          icon: FontAwesomeIcons.car,
          accent: mainBlue,
          bullets: const ["Véhicules", "Transferts", "Sécurité", "Traçabilité"],
        ),
        _serviceCard(
          title: "Suivi GPS",
          subtitle: "Visibilité en temps réel.",
          icon: FontAwesomeIcons.locationDot,
          accent: turquoise,
          bullets: const ["Tracking", "Notifications", "Statut", "Support"],
        ),
        _serviceCard(
          title: "Achats sur demande",
          subtitle: "Magasins spécialisés, marchés…",
          icon: FontAwesomeIcons.store,
          accent: orange,
          bullets: const ["Achat", "Contrôle", "Emballage", "Livraison"],
        ),
      ],
    );
  }

  Widget _serviceCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required List<String> bullets,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 260, maxWidth: 380),
      child: _HoverCard(
        border: accent.withValues(alpha: 0.16),
        shadow: accent.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: accent.withValues(alpha: 0.12),
                      border: Border.all(
                          color: accent.withValues(alpha: 0.18), width: 1.0),
                    ),
                    child: Icon(icon, color: accent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                              color: text,
                              fontWeight: FontWeight.w900,
                              fontSize: 14.8),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                              color: muted,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.8),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: bullets
                    .map(
                      (b) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(999),
                          border:
                              Border.all(color: text.withValues(alpha: 0.08)),
                        ),
                        child: Text(
                          b,
                          style: TextStyle(
                              color: text,
                              fontWeight: FontWeight.w800,
                              fontSize: 12.0),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------
  // PRICING
  // ----------------------------
  Widget _pricing() {
    return Column(
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            _priceCard("Paris", priceParis, mainBlue, note: "FR"),
            _priceCard("Casablanca", priceCasablanca, turquoise, note: "MA"),
            _priceCard("Dakar", priceDakar, orange, note: "SN"),
            _priceCard("Promo web", promoWeb, orange, note: "WEB"),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: orange.withValues(alpha: 0.25), width: 1.2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(FontAwesomeIcons.star, color: orange, size: 14),
              const SizedBox(width: 8),
              Text(
                "Réduction web : –50 % (selon disponibilité)",
                style: TextStyle(
                    color: text, fontWeight: FontWeight.w900, fontSize: 12.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _priceCard(String title, String value, Color accent,
      {required String note}) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 260, maxWidth: 380),
      child: _HoverCard(
        border: accent.withValues(alpha: 0.16),
        shadow: accent.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                      color: accent.withValues(alpha: 0.18), width: 1.1),
                ),
                child: Text(
                  note,
                  style: TextStyle(
                      color: accent, fontWeight: FontWeight.w900, fontSize: 12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            color: text,
                            fontWeight: FontWeight.w900,
                            fontSize: 13.2)),
                    const SizedBox(height: 8),
                    Text(value,
                        style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w900,
                            fontSize: 18)),
                  ],
                ),
              ),
              Icon(FontAwesomeIcons.tag,
                  color: accent.withValues(alpha: 0.70), size: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------
  // DEPARTURES
  // ----------------------------
  Widget _departures() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: departures.map((d) {
        final date = d["date"]!;
        final route = d["route"]!;
        final accent = _accentForRoute(route);
        return _departureCard(date, route, accent);
      }).toList(),
    );
  }

  Color _accentForRoute(String route) {
    if (route.contains("Dakar") && route.contains("Paris")) return mainBlue;
    if (route.contains("Casablanca") && route.contains("Paris"))
      return turquoise;
    if (route.contains("Paris") && route.contains("Casablanca")) return orange;
    if (route.contains("Casablanca") && route.contains("Dakar"))
      return turquoise;
    return orange;
  }

  Widget _departureCard(String date, String route, Color accent) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 260, maxWidth: 380),
      child: _HoverCard(
        border: accent.withValues(alpha: 0.14),
        shadow: accent.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(FontAwesomeIcons.calendarDays, size: 16, color: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "$date • $route",
                  style: TextStyle(
                      color: text, fontWeight: FontWeight.w900, fontSize: 13.6),
                ),
              ),
              Icon(FontAwesomeIcons.arrowRight,
                  size: 14, color: accent.withValues(alpha: 0.70)),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------
  // CONTACT + ACCESS
  // ----------------------------
  Widget _contactAndAccess() {
    return Column(
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            _primaryButton(
              label: "WhatsApp France",
              icon: FontAwesomeIcons.whatsapp,
              bg: turquoise,
              fg: Colors.white,
              onTap: () => _openWhatsApp(digits: whatsappFranceDigits),
            ),
            _primaryButton(
              label: "WhatsApp Dakar",
              icon: FontAwesomeIcons.whatsapp,
              bg: mainBlue,
              fg: Colors.white,
              onTap: () => _openWhatsApp(digits: whatsappDakarDigits),
            ),
            _primaryButton(
              label: "E-mail",
              icon: Icons.email,
              bg: Colors.white,
              fg: text,
              border: text.withValues(alpha: 0.14),
              onTap: _openEmail,
            ),
            _primaryButton(
              label: "Connexion",
              icon: Icons.login,
              bg: Colors.white,
              fg: text,
              border: text.withValues(alpha: 0.14),
              onTap: () => _safePushNamed(context, '/login'),
            ),
            _primaryButton(
              label: "Créer un compte",
              icon: Icons.person_add_alt_1,
              bg: orange,
              fg: Colors.white,
              onTap: () => _safePushNamed(context, '/signup'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: turquoise.withValues(alpha: 0.14)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                _infoPill(
                    "🇫🇷 ${_displayE164(whatsappFranceDigits)}", turquoise),
                _infoPill(
                    "🇸🇳 ${_displayE164(whatsappDakarDigits)}", mainBlue),
                _infoPill("✉️ $email", orange),
                _infoPill("📍 Suivi GPS 24/7", turquoise),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoPill(String value, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.18), width: 1.1),
      ),
      child: Text(
        value,
        style:
            TextStyle(color: text, fontWeight: FontWeight.w900, fontSize: 12.0),
      ),
    );
  }

  // ----------------------------
  // FOOTER
  // ----------------------------
  Widget _footer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Column(
        children: [
          Divider(color: text.withValues(alpha: 0.10)),
          const SizedBox(height: 14),
          Text(
            "© 2026 SAMA • Services international • Paris • Casablanca • Dakar",
            textAlign: TextAlign.center,
            style: TextStyle(
                color: muted, fontWeight: FontWeight.w800, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final double radius;
  final Color border;
  final Color background;

  const _GlassCard({
    required this.child,
    required this.radius,
    required this.border,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border, width: 1.2),
      ),
      child: child,
    );
  }
}

class _HoverCard extends StatefulWidget {
  final Widget child;
  final Color border;
  final Color shadow;

  const _HoverCard({
    required this.child,
    required this.border,
    required this.shadow,
  });

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: widget.border, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _hover ? 0.08 : 0.05),
              blurRadius: _hover ? 24 : 12,
              offset: Offset(0, _hover ? 14 : 7),
            ),
            BoxShadow(
              color: widget.shadow.withValues(alpha: _hover ? 0.10 : 0.06),
              blurRadius: _hover ? 24 : 14,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}

class _BlobsPainter extends CustomPainter {
  final double t;
  final Color c1;
  final Color c2;
  final Color c3;

  _BlobsPainter({
    required this.t,
    required this.c1,
    required this.c2,
    required this.c3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;

    void blob(Offset center, double r, Color color) {
      p
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 70);
      canvas.drawCircle(center, r, p);
    }

    final a = (0.26 + 0.20 * t).clamp(0.0, 1.0);
    final b = (0.22 + 0.18 * (1 - t)).clamp(0.0, 1.0);

    blob(Offset(size.width * 0.18, size.height * 0.24), 220.0,
        c1.withValues(alpha: a));
    blob(Offset(size.width * 0.90, size.height * 0.30), 260.0,
        c2.withValues(alpha: b));
    blob(
      Offset(size.width * 0.55, size.height * 0.92),
      300.0,
      c3.withValues(alpha: (0.16 + 0.10 * t).clamp(0.0, 1.0)),
    );
  }

  @override
  bool shouldRepaint(covariant _BlobsPainter oldDelegate) => oldDelegate.t != t;
}
