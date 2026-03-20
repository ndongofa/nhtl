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

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  // ── Palette (cohérente avec le landing) ───────────────────────────────────
  static const Color _navy = Color(0xFF080E1C);
  static const Color _navySurface = Color(0xFF162035);
  static const Color _navyCard = Color(0xFF1A2640);
  static const Color _teal = Color(0xFF00D4C8);
  static const Color _amber = Color(0xFFFFB300);
  static const Color _textPrimary = Color(0xFFF0F4FF);
  static const Color _textMuted = Color(0xFF8A9BBF);
  static const Color _border = Color(0xFF1E2E48);
  static const Color _green = Color(0xFF22C55E);

  // ── Brand data ────────────────────────────────────────────────────────────
  static const String _waFrance = "33768913074";
  static const String _waDakar = "221783042838";

  static const List<Map<String, String>> _departures = [
    {"date": "23 mars 2026", "route": "Dakar → Paris", "flag": "🇸🇳🇫🇷"},
    {"date": "25 mars 2026", "route": "Casablanca → Paris", "flag": "🇲🇦🇫🇷"},
    {
      "date": "28 avril 2026",
      "route": "Paris → Casablanca",
      "flag": "🇫🇷🇲🇦"
    },
  ];

  // ── Helpers ───────────────────────────────────────────────────────────────
  Future<void> _wa(String digits) async {
    final uri = Uri.parse(
        "https://wa.me/$digits?text=${Uri.encodeComponent("Bonjour SAMA, j'aimerais un devis.")}");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _navySurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Déconnexion",
            style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w800)),
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
                    .pushNamedAndRemoveUntil('/login', (_) => false);
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                elevation: 0),
            child: const Text("Déconnecter",
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final user = LoggedUser.fromSupabase();
    final w = MediaQuery.of(context).size.width;
    final isDesktop = w >= 900;
    final isAdmin = user.role == 'admin';

    return Scaffold(
      backgroundColor: _navy,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(context, user),
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
                        const SizedBox(height: 24),
                        _quickActions(context, isDesktop),
                        const SizedBox(height: 28),
                        _myActivitiesSection(context, isDesktop),
                        const SizedBox(height: 28),
                        _samaInfoBand(context),
                        const SizedBox(height: 28),
                        _nextDepartures(context),
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

  // ── TOP BAR ───────────────────────────────────────────────────────────────
  Widget _topBar(BuildContext context, LoggedUser user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: _navy,
        border: Border(bottom: BorderSide(color: _border, width: 1)),
      ),
      child: Row(
        children: [
          // Logo
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  gradient: const LinearGradient(
                    colors: [_teal, Color(0xFF0099CC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(FontAwesomeIcons.boxOpen,
                    color: Colors.white, size: 14),
              ),
              const SizedBox(width: 8),
              const Text("SAMA",
                  style: TextStyle(
                      color: _textPrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 2)),
            ],
          ),
          const Spacer(),
          // Notifications
          _iconBtn(Icons.notifications_outlined, _textMuted, () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()));
          }),
          // Debug (dev only)
          _iconBtn(Icons.bug_report_outlined, _border, () {
            printSupabaseTokens();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text("Token imprimé dans la console.")));
          }),
          // Profil
          _iconBtn(Icons.person_outline, _textMuted, () {
            Navigator.of(context).pushNamed('/profile');
          }),
          // Logout
          _iconBtn(Icons.logout, Colors.red.shade400, () {
            _logout(context);
          }),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return IconButton(
      icon: Icon(icon, color: color, size: 20),
      onPressed: onTap,
      splashRadius: 20,
    );
  }

  // ── GREETING ──────────────────────────────────────────────────────────────
  Widget _greeting(LoggedUser user) {
    final hour = DateTime.now().hour;
    final salut = hour < 12
        ? "Bonjour"
        : hour < 18
            ? "Bon après-midi"
            : "Bonsoir";
    final displayName =
        user.fullName?.isNotEmpty == true ? user.fullName! : "vous";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$salut, $displayName 👋",
            style: const TextStyle(
                color: _textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 22,
                letterSpacing: -0.3)),
        const SizedBox(height: 4),
        const Text("Que souhaitez-vous faire aujourd'hui ?",
            style: TextStyle(
                color: _textMuted, fontWeight: FontWeight.w500, fontSize: 14)),
      ],
    );
  }

  // ── QUICK ACTIONS ─────────────────────────────────────────────────────────
  Widget _quickActions(BuildContext context, bool isDesktop) {
    final actions = [
      {
        "icon": FontAwesomeIcons.truckFast,
        "label": "Nouveau\nTransport",
        "color": _teal,
        "onTap": () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => TransportFormScreen())),
      },
      {
        "icon": FontAwesomeIcons.bagShopping,
        "label": "Nouvelle\nCommande",
        "color": _amber,
        "onTap": () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => CommandeFormScreen())),
      },
      {
        "icon": FontAwesomeIcons.whatsapp,
        "label": "WhatsApp\nFrance",
        "color": _green,
        "onTap": () => _wa(_waFrance),
      },
      {
        "icon": FontAwesomeIcons.whatsapp,
        "label": "WhatsApp\nDakar",
        "color": _green,
        "onTap": () => _wa(_waDakar),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel("Actions rapides"),
        const SizedBox(height: 12),
        Row(
          children: actions.asMap().entries.map((e) {
            final a = e.value;
            return Expanded(
              child: Padding(
                padding:
                    EdgeInsets.only(right: e.key < actions.length - 1 ? 10 : 0),
                child: _quickActionCard(
                  a['icon'] as IconData,
                  a['label'] as String,
                  a['color'] as Color,
                  a['onTap'] as VoidCallback,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _quickActionCard(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: _navySurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    height: 1.3)),
          ],
        ),
      ),
    );
  }

  // ── MY ACTIVITIES ─────────────────────────────────────────────────────────
  Widget _myActivitiesSection(BuildContext context, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel("Mes activités"),
        const SizedBox(height: 12),
        isDesktop
            ? Row(
                children: [
                  Expanded(
                      child: _activityCard(
                          context,
                          Icons.local_shipping_outlined,
                          _teal,
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
                ],
              )
            : Column(
                children: [
                  _activityCard(
                      context,
                      Icons.local_shipping_outlined,
                      _teal,
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
                ],
              ),
      ],
    );
  }

  Widget _activityCard(BuildContext context, IconData icon, Color color,
      String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _navyCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: _textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 15)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: _textMuted,
                          fontWeight: FontWeight.w500,
                          fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: _textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  // ── SAMA INFO BAND ────────────────────────────────────────────────────────
  Widget _samaInfoBand(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _teal.withValues(alpha: 0.10),
            _amber.withValues(alpha: 0.06),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _teal.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_offer_outlined, color: _amber, size: 16),
              const SizedBox(width: 8),
              const Text("Tarifs SAMA",
                  style: TextStyle(
                      color: _textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 14)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text("–50% WEB",
                    style: TextStyle(
                        color: _amber,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        letterSpacing: 0.5)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _tarif("🇫🇷", "Paris", "10€/kg"),
              _tarifDivider(),
              _tarif("🇲🇦", "Casablanca", "100DH/kg"),
              _tarifDivider(),
              _tarif("🇸🇳", "Dakar", "6500 FCFA/kg"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tarif(String flag, String city, String price) {
    return Expanded(
      child: Column(
        children: [
          Text("$flag $city",
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: _textMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 11)),
          const SizedBox(height: 4),
          Text(price,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: _teal, fontWeight: FontWeight.w800, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _tarifDivider() {
    return Container(
        width: 1,
        height: 32,
        color: _border,
        margin: const EdgeInsets.symmetric(horizontal: 4));
  }

  // ── NEXT DEPARTURES ───────────────────────────────────────────────────────
  Widget _nextDepartures(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _sectionLabel("Prochains départs"),
            const Spacer(),
            GestureDetector(
              onTap: () => _wa(_waDakar),
              child: const Text("Réserver →",
                  style: TextStyle(
                      color: _teal,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                      decorationColor: _teal)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._departures.asMap().entries.map((e) {
          final dep = e.value;
          final isFirst = e.key == 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isFirst ? _teal.withValues(alpha: 0.07) : _navySurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isFirst ? _teal.withValues(alpha: 0.25) : _border),
            ),
            child: Row(
              children: [
                Text(dep['flag']!, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "${dep['route']} · ${dep['date']}",
                    style: TextStyle(
                        color: isFirst ? _teal : _textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                  ),
                ),
                if (isFirst)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _teal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text("PROCHAIN",
                        style: TextStyle(
                            color: _teal,
                            fontWeight: FontWeight.w800,
                            fontSize: 9,
                            letterSpacing: 0.8)),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── ADMIN SECTION ─────────────────────────────────────────────────────────
  Widget _adminSection(BuildContext context, bool isDesktop) {
    final items = [
      {
        "icon": Icons.badge_outlined,
        "label": "GP Agents",
        "color": _teal,
        "onTap": () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const GpListScreen())),
      },
      {
        "icon": Icons.people_outline,
        "label": "Utilisateurs",
        "color": _amber,
        "onTap": () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => AdminUserScreen())),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _amber.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: _amber, size: 12),
                  SizedBox(width: 5),
                  Text("Admin",
                      style: TextStyle(
                          color: _amber,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 0.5)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: items.asMap().entries.map((e) {
            final item = e.value;
            return Expanded(
              child: Padding(
                padding:
                    EdgeInsets.only(right: e.key < items.length - 1 ? 12 : 0),
                child: GestureDetector(
                  onTap: item['onTap'] as VoidCallback,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _navySurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color:
                              (item['color'] as Color).withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(item['icon'] as IconData,
                            color: item['color'] as Color, size: 20),
                        const SizedBox(width: 10),
                        Text(item['label'] as String,
                            style: const TextStyle(
                                color: _textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── UTILS ─────────────────────────────────────────────────────────────────
  Widget _sectionLabel(String label) {
    return Text(label,
        style: const TextStyle(
            color: _textMuted,
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 1));
  }
}
