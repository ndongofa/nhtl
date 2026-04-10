import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_theme_provider.dart';
import '../services/auth_service.dart';

import '../screens/landing_transport_screen.dart';
import '../screens/landing_commande_screen.dart';
import '../screens/transport_hub_screen.dart';
import '../screens/commande_hub_screen.dart';
import '../screens/services/sama_achat_screen.dart';
import '../screens/services/sama_maad_screen.dart';
import '../screens/services/sama_teranga_screen.dart';
import '../screens/services/sama_tech_digital_screen.dart';
import '../screens/services/sama_best_seller_screen.dart';
import '../screens/services/sama_maillot_screen.dart';

class SamaAccountMenu {
  static Future<void> open(BuildContext context) async {
    final t = context.read<AppThemeProvider>();
    final isLogged = AuthService.isLoggedIn();

    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
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
              child: SingleChildScrollView(
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
                          tooltip: t.themeTooltip,
                          onPressed: () =>
                              context.read<AppThemeProvider>().toggleTheme(),
                          icon: Icon(
                            t.themeIcon,
                            color: t.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _menuItem(
                      ctx,
                      t,
                      icon: Icons.local_shipping_outlined,
                      title: "Transport GP",
                      subtitle: "Accéder au service Transport",
                      value: "transport",
                    ),
                    _menuItem(
                      ctx,
                      t,
                      icon: Icons.shopping_bag_outlined,
                      title: "Sama Commande",
                      subtitle: "Shopping en ligne",
                      value: "commande",
                    ),
                    _menuItem(
                      ctx,
                      t,
                      icon: Icons.storefront_outlined,
                      title: "Sama Achat",
                      subtitle: "Achats sur mesure",
                      value: "achat",
                    ),
                    _menuItem(
                      ctx,
                      t,
                      icon: Icons.eco_outlined,
                      title: "Sama Maad",
                      subtitle: "Vente de Maad",
                      value: "maad",
                    ),
                    _menuItem(
                      ctx,
                      t,
                      icon: Icons.local_bar_outlined,
                      title: "Sama Téranga Apéro",
                      subtitle: "Apéro sénégalais",
                      value: "teranga",
                    ),
                    _menuItem(
                      ctx,
                      t,
                      icon: Icons.computer_outlined,
                      title: "Sama Tech Digital",
                      subtitle: "Services digitaux",
                      value: "techdigital",
                    ),
                    _menuItem(
                      ctx,
                      t,
                      icon: Icons.star_outline,
                      title: "Sama Best Seller",
                      subtitle: "Articles best seller",
                      value: "bestseller",
                    ),
                    _menuItem(
                      ctx,
                      t,
                      icon: Icons.sports_soccer_outlined,
                      title: "Sama Maillot",
                      subtitle: "Maillots des Lions de la Téranga",
                      value: "maillot",
                    ),
                    const SizedBox(height: 6),
                    if (isLogged) ...[
                      _menuItem(
                        ctx,
                        t,
                        icon: Icons.person_outline,
                        title: "Profil",
                        subtitle: "Gérer mes informations",
                        value: "profile",
                      ),
                    ] else ...[
                      _menuItem(
                        ctx,
                        t,
                        icon: Icons.login_outlined,
                        title: "Connexion",
                        subtitle: "Se connecter",
                        value: "login",
                      ),
                      _menuItem(
                        ctx,
                        t,
                        icon: Icons.person_add_alt_1_outlined,
                        title: "Créer un compte",
                        subtitle: "Créer un compte gratuitement",
                        value: "signup",
                      ),
                    ],
                  ],
                ),
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

      case "achat":
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SamaAchatScreen()),
        );
        break;

      case "maad":
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SamaMaadScreen()),
        );
        break;

      case "teranga":
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SamaTerangaScreen()),
        );
        break;

      case "techdigital":
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SamaTechDigitalScreen()),
        );
        break;

      case "bestseller":
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SamaBestSellerScreen()),
        );
        break;

      case "maillot":
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SamaMaillotScreen()),
        );
        break;

      case "profile":
        Navigator.pushNamed(context, '/profile');
        break;

      case "login":
        Navigator.pushNamed(context, '/login');
        break;

      case "signup":
        Navigator.pushNamed(context, '/signup');
        break;
    }
  }

  static Widget _menuItem(
    BuildContext ctx,
    AppThemeProvider t, {
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
}
