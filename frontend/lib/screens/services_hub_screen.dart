// lib/screens/services_hub_screen.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/sama_account_menu.dart';
import '../providers/app_theme_provider.dart';
import '../services/auth_service.dart';
import '../widgets/sama_logo_widget.dart';

import 'commande_hub_screen.dart';
import 'landing_commande_screen.dart';
import 'landing_transport_screen.dart';
import 'transport_hub_screen.dart';

import 'services/sama_achat_screen.dart';
import 'services/sama_best_seller_screen.dart';
import 'services/sama_maad_screen.dart';
import 'services/sama_teranga_screen.dart';

class ServicesHubScreen extends StatelessWidget {
  const ServicesHubScreen({Key? key}) : super(key: key);

  static const String _waFrance = "33768913074";
  static const String _waDakar = "221783042838";
  static const String _email = "tech@ngom-holding.com";

  static const List<_ServiceItem> _services = [
    _ServiceItem(
        id: 'gp',
        emoji: '✈️',
        name: 'Sama GP',
        tagline: 'Transport par GP',
        desc: 'Groupage, fret aérien & maritime\nParis · Casablanca · Dakar',
        color: AppThemeProvider.appBlue,
        isLive: true),
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
        isLive: false),
    _ServiceItem(
        id: 'teranga',
        emoji: '🥂',
        name: 'Sama Téranga Apéro',
        tagline: 'Apéro sénégalais',
        desc: 'Bissap, Gnamakoudji, Ditax\net spécialités sénégalaises',
        color: Color(0xFFDC2626),
        isLive: false),
    _ServiceItem(
        id: 'bestseller',
        emoji: '⭐',
        name: 'Sama Best Seller',
        tagline: 'Articles best seller',
        desc: 'Sélection des articles\nles plus demandés du moment',
        color: Color(0xFF7C3AED),
        isLive: false),
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
      default:
        return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppThemeProvider>();
    final isLogged = AuthService.isLoggedIn();
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
              _TopBar(t: t, isLogged: isLogged, isDesktop: isDesktop),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _HeroSection(t: t, isDesktop: isDesktop),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 48 : 16,
                          vertical: 32,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1100),
                            child: Column(
                              children: [
                                _sectionLabel(t, "Nos services"),
                                const SizedBox(height: 24),
                                isDesktop
                                    ? _gridDesktop(context, t)
                                    : _gridMobile(context, t),
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

  Widget _gridDesktop(BuildContext context, AppThemeProvider t) =>
      Column(children: [
        Row(
            children: _services
                .sublist(0, 3)
                .map((s) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16, bottom: 16),
                        child: _ServiceCard(
                          service: s,
                          t: t,
                          onTap: () => _openService(context, s),
                        ),
                      ),
                    ))
                .toList()),
        Row(
            children: _services
                .sublist(3, 6)
                .map((s) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16, bottom: 16),
                        child: _ServiceCard(
                          service: s,
                          t: t,
                          onTap: () => _openService(context, s),
                        ),
                      ),
                    ))
                .toList()),
      ]);

  Widget _gridMobile(BuildContext context, AppThemeProvider t) => Column(
        children: List.generate((_services.length / 2).ceil(), (row) {
          final a = _services[row * 2];
          final bIdx = row * 2 + 1;
          final b = bIdx < _services.length ? _services[bIdx] : null;
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
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child:
                    Text(service.emoji, style: const TextStyle(fontSize: 26)),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: service.isLive
                    ? AppThemeProvider.green.withValues(alpha: 0.12)
                    : color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: service.isLive
                      ? AppThemeProvider.green.withValues(alpha: 0.35)
                      : color.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                service.isLive ? "● Disponible" : "Bientôt",
                style: TextStyle(
                  color: service.isLive ? AppThemeProvider.green : color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ]),
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
                backgroundColor:
                    service.isLive ? color : color.withValues(alpha: 0.15),
                foregroundColor: service.isLive ? Colors.white : color,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 11),
              ),
              child: Text(
                service.isLive ? "Découvrir →" : "En savoir plus",
                style: const TextStyle(
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
  const _TopBar({
    required this.t,
    required this.isLogged,
    required this.isDesktop,
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
          const SamaTopBarLogo(),
          const Spacer(),

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
                border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, anim) => RotationTransition(
                  turns: anim,
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: Icon(
                  t.isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round,
                  key: ValueKey(t.isDark),
                  color: t.isDark ? AppThemeProvider.amber : Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Mon espace (menu)
          if (isLogged)
            (isDesktop
                ? ElevatedButton.icon(
                    icon: const Icon(Icons.dashboard_outlined, size: 14),
                    label: const Text(
                      "Mon espace",
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
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
                : IconButton(
                    icon: const Icon(Icons.dashboard_outlined,
                        color: Colors.white, size: 20),
                    tooltip: "Mon espace",
                    onPressed: () => SamaAccountMenu.open(context),
                    padding: const EdgeInsets.all(6),
                    constraints:
                        const BoxConstraints(minWidth: 34, minHeight: 34),
                  ))
          else ...[
            if (!isDesktop) ...[
              IconButton(
                icon: const Icon(Icons.login, color: Colors.white, size: 20),
                tooltip: "Connexion",
                onPressed: () => Navigator.pushNamed(context, '/login'),
              ),
              IconButton(
                icon: const Icon(Icons.person_add_alt_1_outlined,
                    color: Colors.white, size: 20),
                tooltip: "Créer un compte",
                onPressed: () => Navigator.pushNamed(context, '/signup'),
              ),
            ] else ...[
              OutlinedButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
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
