import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/auth_service.dart';
import '../models/logged_user.dart';
import '../debug/debug_token.dart';
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
  // ── Palette style signup — fond clair ─────────────────────────────────────
  static const Color _appBlue = Color(0xFF2296F3);
  static const Color _blueDark = Color(0xFF0D5EBF);
  static const Color _blueLight = Color(0xFFE8F4FE);
  static const Color _amber = Color(0xFFFFB300);
  static const Color _amberLight = Color(0xFFFFF3D0);
  static const Color _teal = Color(0xFF00BCD4);
  static const Color _green = Color(0xFF22C55E);
  static const Color _bg = Color(0xFFF4F8FF);
  static const Color _surface = Colors.white;
  static const Color _textMain = Color(0xFF0F2040);
  static const Color _textMuted = Color(0xFF6B7A99);
  static const Color _border = Color(0xFFDDE3EF);
  static const Color _sectionAlt = Color(0xFFEEF5FF);

  static const String _waFrance = "33768913074";
  static const String _waDakar = "221783042838";

  static final DateTime _targetDate = DateTime(2026, 3, 23);

  static const List<Map<String, String>> _nextDepartures = [
    {"route": "Dakar → Paris", "flag": "🇸🇳🇫🇷"},
    {"route": "Dakar → Casablanca", "flag": "🇸🇳🇲🇦"},
  ];

  static const List<Map<String, String>> _allDepartures = [
    {"date": "23 mars 2026", "route": "Dakar → Paris", "flag": "🇸🇳🇫🇷"},
    {"date": "23 mars 2026", "route": "Dakar → Casablanca", "flag": "🇸🇳🇲🇦"},
    {"date": "25 mars 2026", "route": "Casablanca → Paris", "flag": "🇲🇦🇫🇷"},
  ];

  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;
  int _tickerIndex = 0;
  Timer? _tickerTimer;

  @override
  void initState() {
    super.initState();
    _updateCountdown();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _updateCountdown();
    });
    _tickerTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted)
        setState(
            () => _tickerIndex = (_tickerIndex + 1) % _nextDepartures.length);
    });
  }

  void _updateCountdown() {
    final now = DateTime.now();
    final diff = _targetDate.difference(now);
    setState(() => _remaining = diff.isNegative ? Duration.zero : diff);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _tickerTimer?.cancel();
    super.dispose();
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  Future<void> _wa(String digits) async {
    final uri = Uri.parse(
        "https://wa.me/$digits?text=${Uri.encodeComponent("Bonjour SAMA, j'aimerais un devis.")}");
    if (await canLaunchUrl(uri))
      await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Déconnexion",
            style: TextStyle(color: _textMain, fontWeight: FontWeight.w800)),
        content: const Text("Êtes-vous sûr de vouloir vous déconnecter ?",
            style: TextStyle(color: _textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Annuler", style: TextStyle(color: _textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService.logout();
              if (context.mounted) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/', (_) => false);
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            child: const Text("Déconnecter",
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = LoggedUser.fromSupabase();
    final w = MediaQuery.of(context).size.width;
    final isDesktop = w >= 900;
    final isAdmin = user.role == 'admin';

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(context, user, isAdmin),
            _tickerBanner(),
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
                        _greeting(user),
                        const SizedBox(height: 20),
                        _countdownSection(),
                        const SizedBox(height: 24),
                        _quickActions(context, isDesktop),
                        const SizedBox(height: 28),
                        _myActivitiesSection(context, isDesktop),
                        const SizedBox(height: 28),
                        _samaInfoBand(),
                        const SizedBox(height: 28),
                        _nextDeparturesSection(),
                        if (isAdmin) ...[
                          const SizedBox(height: 28),
                          _adminSection(context, isDesktop),
                        ],
                        const SizedBox(height: 40),
                      ],
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

  Widget _tickerBanner() {
    final dep = _nextDepartures[_tickerIndex];
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Container(
        key: ValueKey(_tickerIndex),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        color: _amber,
        child: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: _textMain, borderRadius: BorderRadius.circular(5)),
            child: const Text("DÉPARTS",
                style: TextStyle(
                    color: _amber,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5)),
          ),
          const SizedBox(width: 12),
          Text(dep['flag']!, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Expanded(
              child: Text("23 mars 2026  ·  ${dep['route']}",
                  style: const TextStyle(
                      color: _textMain,
                      fontWeight: FontWeight.w800,
                      fontSize: 13),
                  overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _wa(_waDakar),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: _textMain, borderRadius: BorderRadius.circular(7)),
              child: const Text("Réserver →",
                  style: TextStyle(
                      color: _amber,
                      fontWeight: FontWeight.w800,
                      fontSize: 11)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _countdownSection() {
    final days = _remaining.inDays;
    final hours = _remaining.inHours % 24;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _amber.withValues(alpha: 0.30)),
        boxShadow: [
          BoxShadow(
              color: _amber.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
              width: 7,
              height: 7,
              decoration:
                  const BoxDecoration(shape: BoxShape.circle, color: _green)),
          const SizedBox(width: 8),
          const Text("PROCHAINS DÉPARTS — 23 MARS 2026",
              style: TextStyle(
                  color: _green,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2)),
        ]),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _countUnit(_pad(days), "JOURS", _amber),
          _sep(),
          _countUnit(_pad(hours), "HEURES", _appBlue),
          _sep(),
          _countUnit(_pad(minutes), "MIN", _appBlue),
          _sep(),
          _countUnit(_pad(seconds), "SEC", _textMuted),
        ]),
        const SizedBox(height: 16),
        LayoutBuilder(builder: (context, constraints) {
          final isWide = constraints.maxWidth > 420;
          final cards = _nextDepartures.map((dep) => _departCard(dep)).toList();
          return isWide
              ? Row(children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 10),
                  Expanded(child: cards[1]),
                ])
              : Column(
                  children: [cards[0], const SizedBox(height: 8), cards[1]]);
        }),
      ]),
    );
  }

  Widget _countUnit(String value, String label, Color color) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Text(value,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 20,
                letterSpacing: 1)),
      ),
      const SizedBox(height: 4),
      Text(label,
          style: const TextStyle(
              color: _textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8)),
    ]);
  }

  Widget _sep() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 16, left: 5, right: 5),
      child: Text(":",
          style: TextStyle(
              color: _textMuted, fontSize: 18, fontWeight: FontWeight.w700)),
    );
  }

  Widget _departCard(Map<String, String> dep) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _blueLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _appBlue.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        Text(dep['flag']!, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Expanded(
            child: Text(dep['route']!,
                style: const TextStyle(
                    color: _appBlue,
                    fontWeight: FontWeight.w700,
                    fontSize: 12))),
        GestureDetector(
          onTap: () => _wa(_waDakar),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: _amber, borderRadius: BorderRadius.circular(7)),
            child: const Text("Réserver",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11)),
          ),
        ),
      ]),
    );
  }

  Widget _topBar(BuildContext context, LoggedUser user, bool isAdmin) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: _appBlue,
        boxShadow: [
          BoxShadow(
              color: Color(0x202296F3), blurRadius: 16, offset: Offset(0, 4))
        ],
      ),
      child: Row(children: [
        Row(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(FontAwesomeIcons.boxOpen,
                color: Colors.white, size: 14),
          ),
          const SizedBox(width: 8),
          const Text("SAMA",
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 2)),
        ]),
        const Spacer(),
        _topBarIcon(Icons.notifications_outlined, () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()));
        }),
        if (isAdmin)
          _topBarIcon(Icons.bug_report_outlined, () {
            printSupabaseTokens();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text("Token imprimé dans la console.")));
          }, color: Colors.white.withValues(alpha: 0.55)),
        _topBarIcon(Icons.person_outline,
            () => Navigator.of(context).pushNamed('/profile')),
        _topBarIcon(Icons.logout, () => _logout(context),
            color: Colors.white.withValues(alpha: 0.75)),
      ]),
    );
  }

  Widget _topBarIcon(IconData icon, VoidCallback onTap, {Color? color}) {
    return IconButton(
      icon: Icon(icon,
          color: color ?? Colors.white.withValues(alpha: 0.90), size: 20),
      onPressed: onTap,
      splashRadius: 20,
    );
  }

  Widget _greeting(LoggedUser user) {
    final hour = DateTime.now().hour;
    final salut = hour < 12
        ? "Bonjour"
        : hour < 18
            ? "Bon après-midi"
            : "Bonsoir";
    final prenom = _extractPrenom(user);
    final displayName = prenom.isNotEmpty ? prenom : "vous";
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("$salut, $displayName 👋",
          style: const TextStyle(
              color: _textMain,
              fontWeight: FontWeight.w900,
              fontSize: 22,
              letterSpacing: -0.3)),
      const SizedBox(height: 4),
      const Text("Que souhaitez-vous faire aujourd'hui ?",
          style: TextStyle(
              color: _textMuted, fontWeight: FontWeight.w400, fontSize: 14)),
    ]);
  }

  String _extractPrenom(LoggedUser user) {
    final metadata = AuthService.userMetadata;
    if (metadata != null) {
      final prenom = metadata['prenom']?.toString().trim() ?? '';
      if (prenom.isNotEmpty) return _capitalize(prenom);
    }
    final fullName = user.fullName?.trim() ?? '';
    if (fullName.isNotEmpty) {
      final parts = fullName.split(' ');
      if (parts.isNotEmpty && parts[0].isNotEmpty) return _capitalize(parts[0]);
    }
    return '';
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  Widget _quickActions(BuildContext context, bool isDesktop) {
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
      _sectionLabel("Actions rapides"),
      const SizedBox(height: 12),
      Row(
          children: actions.asMap().entries.map((e) {
        final a = e.value;
        return Expanded(
          child: Padding(
            padding:
                EdgeInsets.only(right: e.key < actions.length - 1 ? 10 : 0),
            child: _quickActionCard(a['icon'] as IconData, a['label'] as String,
                a['color'] as Color, a['onTap'] as VoidCallback),
          ),
        );
      }).toList()),
    ]);
  }

  Widget _quickActionCard(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.20)),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 18)),
          const SizedBox(height: 8),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: _textMain,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  height: 1.3)),
        ]),
      ),
    );
  }

  Widget _myActivitiesSection(BuildContext context, bool isDesktop) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionLabel("Mes activités"),
      const SizedBox(height: 12),
      isDesktop
          ? Row(children: [
              Expanded(
                  child: _activityCard(
                      context,
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
                  child: _activityCard(
                      context,
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
              _activityCard(
                  context,
                  Icons.local_shipping_outlined,
                  _appBlue,
                  "Mes Transports",
                  "Suivre & gérer",
                  () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => TransportListScreen()))),
              const SizedBox(height: 12),
              _activityCard(
                  context,
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

  Widget _activityCard(BuildContext context, IconData icon, Color color,
      String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(children: [
          Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: color, size: 22)),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: const TextStyle(
                        color: _textMain,
                        fontWeight: FontWeight.w800,
                        fontSize: 15)),
                Text(subtitle,
                    style: const TextStyle(
                        color: _textMuted,
                        fontWeight: FontWeight.w400,
                        fontSize: 12)),
              ])),
          const Icon(Icons.chevron_right, color: _textMuted, size: 20),
        ]),
      ),
    );
  }

  Widget _samaInfoBand() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [_appBlue, _blueDark],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: _appBlue.withValues(alpha: 0.25),
              blurRadius: 20,
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _amberLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _amber.withValues(alpha: 0.4)),
            ),
            child: const Text("–50% WEB",
                style: TextStyle(
                    color: Color(0xFF7A4F00),
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                    letterSpacing: 0.5)),
          ),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          _tarif("🇫🇷", "Paris", "10€/kg", _appBlue),
          _tarifDivider(),
          _tarif("🇲🇦", "Casablanca", "65DH/kg", const Color(0xFF1A7ED4)),
          _tarifDivider(),
          _tarif("🇸🇳", "Dakar", "6500 FCFA", _teal),
        ]),
      ]),
    );
  }

  Widget _tarif(String flag, String city, String price, Color color) {
    return Expanded(
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
              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
    ]));
  }

  Widget _tarifDivider() {
    return Container(
        width: 1,
        height: 32,
        color: Colors.white.withValues(alpha: 0.20),
        margin: const EdgeInsets.symmetric(horizontal: 4));
  }

  Widget _nextDeparturesSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        _sectionLabel("Tous les départs"),
        const Spacer(),
        GestureDetector(
          onTap: () => _wa(_waDakar),
          child: const Text("Réserver →",
              style: TextStyle(
                  color: _appBlue,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                  decorationColor: _appBlue)),
        ),
      ]),
      const SizedBox(height: 12),
      ..._allDepartures.asMap().entries.map((e) {
        final dep = e.value;
        final highlight = e.key <= 1;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: highlight ? _blueLight : _surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: highlight ? _appBlue.withValues(alpha: 0.25) : _border),
          ),
          child: Row(children: [
            Text(dep['flag']!, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 12),
            Expanded(
                child: Text("${dep['route']} · ${dep['date']}",
                    style: TextStyle(
                        color: highlight ? _appBlue : _textMain,
                        fontWeight: FontWeight.w700,
                        fontSize: 13))),
            if (highlight)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: _amberLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _amber.withValues(alpha: 0.4))),
                child: const Text("BIENTÔT",
                    style: TextStyle(
                        color: Color(0xFF7A4F00),
                        fontWeight: FontWeight.w800,
                        fontSize: 9,
                        letterSpacing: 0.8)),
              ),
          ]),
        );
      }),
    ]);
  }

  Widget _adminSection(BuildContext context, bool isDesktop) {
    final items = [
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
            color: _amber.withValues(alpha: 0.10),
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
        ]),
      ),
      const SizedBox(height: 12),
      Row(
          children: items.asMap().entries.map((e) {
        final item = e.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: e.key < items.length - 1 ? 12 : 0),
            child: GestureDetector(
              onTap: item['onTap'] as VoidCallback,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: (item['color'] as Color).withValues(alpha: 0.20)),
                  boxShadow: [
                    BoxShadow(
                        color: (item['color'] as Color).withValues(alpha: 0.07),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Row(children: [
                  Icon(item['icon'] as IconData,
                      color: item['color'] as Color, size: 20),
                  const SizedBox(width: 10),
                  Text(item['label'] as String,
                      style: const TextStyle(
                          color: _textMain,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ]),
              ),
            ),
          ),
        );
      }).toList()),
    ]);
  }

  Widget _sectionLabel(String label) {
    return Text(label.toUpperCase(),
        style: const TextStyle(
            color: _textMuted,
            fontWeight: FontWeight.w700,
            fontSize: 11,
            letterSpacing: 1.2));
  }
}
