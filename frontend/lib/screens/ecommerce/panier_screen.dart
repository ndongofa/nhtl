// lib/screens/ecommerce/panier_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/panier_item.dart';
import '../../providers/app_theme_provider.dart';
import '../../providers/panier_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/sama_account_menu.dart';
import '../auth/login_screen.dart';
import 'checkout_screen.dart';

class PanierScreen extends StatefulWidget {
  final String serviceType;
  final String serviceLabel;
  final String serviceEmoji;
  final Color accentColor;

  const PanierScreen({
    Key? key,
    required this.serviceType,
    required this.serviceLabel,
    required this.serviceEmoji,
    required this.accentColor,
  }) : super(key: key);

  @override
  State<PanierScreen> createState() => _PanierScreenState();
}

class _PanierScreenState extends State<PanierScreen> {
  String get serviceType => widget.serviceType;
  String get serviceLabel => widget.serviceLabel;
  String get serviceEmoji => widget.serviceEmoji;
  Color get accentColor => widget.accentColor;

  void _validerCommande(BuildContext context, PanierProvider panier) {
    if (AuthService.isLoggedIn()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: panier,
            child: CheckoutScreen(
              serviceType: serviceType,
              serviceLabel: serviceLabel,
              accentColor: accentColor,
              totalAmount: panier.total,
              devise: panier.devise,
            ),
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Connexion requise'),
          content: const Text(
              'Vous devez être connecté pour finaliser votre commande.\n\nSouhaitez-vous vous connecter ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                // Crée un nouveau PanierProvider qui rechargera depuis le
                // cache SharedPreferences (le panier actuel est toujours
                // persisté). On ne réutilise pas le provider existant car
                // il sera disposé lors du pushAndRemoveUntil dans LoginScreen.
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LoginScreen(
                      redirectTo: ChangeNotifierProvider(
                        create: (_) => PanierProvider(serviceType: serviceType),
                        child: PanierScreen(
                          serviceType: serviceType,
                          serviceLabel: serviceLabel,
                          serviceEmoji: serviceEmoji,
                          accentColor: accentColor,
                        ),
                      ),
                    ),
                  ),
                );
              },
              child: const Text('Se connecter'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppThemeProvider>();
    final panier = context.watch<PanierProvider>();

    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.topBarBg,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(children: [
          const Text('🛒', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text('Mon panier — $serviceLabel',
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 16)),
        ]),
        actions: [
          if (!panier.isEmpty)
            TextButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: t.bgCard,
                    title: Text('Vider le panier ?',
                        style: TextStyle(color: t.textPrimary)),
                    content: Text(
                        'Tous les articles seront supprimés.',
                        style: TextStyle(color: t.textMuted)),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('Annuler',
                              style: TextStyle(color: t.textMuted))),
                      TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Vider',
                              style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (confirm == true) panier.vider();
              },
              child: const Text('Vider',
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.w700)),
            ),
          // Menu burger : actions secondaires
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Menu',
            onSelected: (value) async {
              switch (value) {
                case 'mon_espace':
                  SamaAccountMenu.open(context);
                  break;
                case 'deconnexion':
                  await AuthService.logout();
                  if (!context.mounted) return;
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/', (_) => false);
                  break;
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'mon_espace',
                child: ListTile(
                  leading: Icon(Icons.dashboard_outlined),
                  title: Text('Mon espace'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              if (AuthService.isLoggedIn())
                const PopupMenuItem(
                  value: 'deconnexion',
                  child: ListTile(
                    leading: Icon(Icons.logout),
                    title: Text('Déconnexion'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
            ],
          ),
        ],
      ),
      body: panier.isEmpty
          ? _emptyState(context, t)
          : Column(children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: panier.items.length,
                  itemBuilder: (ctx, i) => _PanierItemTile(
                    item: panier.items[i],
                    accentColor: accentColor,
                    t: t,
                    onRetirer: () => panier.retirer(panier.items[i].produitId),
                    onChanger: (q) => panier.changerQuantite(
                        panier.items[i].produitId, q),
                  ),
                ),
              ),
              // ── Récap + Valider ──────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: t.bgCard,
                    border: Border(top: BorderSide(color: t.border))),
                child: Column(children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                    Text('Total',
                        style: TextStyle(
                            color: t.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 16)),
                    Text(
                      '${panier.total.toStringAsFixed(2)} ${panier.devise}',
                      style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 20),
                    ),
                  ]),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.payment_outlined),
                      label: Text(
                          'Valider la commande (${panier.nbArticles} art.)',
                          style:
                              const TextStyle(fontWeight: FontWeight.w800)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0),
                      onPressed: () => _validerCommande(context, panier),
                    ),
                  ),
                ]),
              ),
            ]),
    );
  }

  Widget _emptyState(BuildContext context, AppThemeProvider t) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🛒', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 16),
          Text('Votre panier est vide',
              style: TextStyle(
                  color: t.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16)),
          const SizedBox(height: 8),
          Text('Ajoutez des articles depuis le catalogue',
              style: TextStyle(color: t.textMuted, fontSize: 13)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Retour au catalogue',
                style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12)),
            onPressed: () => Navigator.pop(context),
          ),
        ]),
      );
}

// ── Tuile article panier ───────────────────────────────────────────────────────

class _PanierItemTile extends StatelessWidget {
  final PanierItem item;
  final Color accentColor;
  final AppThemeProvider t;
  final VoidCallback onRetirer;
  final void Function(int) onChanger;

  const _PanierItemTile({
    required this.item,
    required this.accentColor,
    required this.t,
    required this.onRetirer,
    required this.onChanger,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: t.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.border)),
      child: Row(children: [
        if (item.produitImageUrl != null && item.produitImageUrl!.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(item.produitImageUrl!,
                width: 56, height: 56, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                    width: 56,
                    height: 56,
                    color: accentColor.withValues(alpha: 0.1),
                    child: Icon(Icons.image_outlined,
                        color: accentColor, size: 24))),
          )
        else
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.shopping_bag_outlined,
                color: accentColor, size: 24),
          ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(item.produitNom ?? 'Article',
                style: TextStyle(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(
                '${item.prixUnitaire} ${item.devise} / unité',
                style: TextStyle(color: t.textMuted, fontSize: 12)),
            const SizedBox(height: 6),
            Row(children: [
              _QtyButton(
                  icon: Icons.remove,
                  color: t.textMuted,
                  onTap: () => onChanger(item.quantite - 1)),
              const SizedBox(width: 8),
              Text('${item.quantite}',
                  style: TextStyle(
                      color: t.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 15)),
              const SizedBox(width: 8),
              _QtyButton(
                  icon: Icons.add,
                  color: accentColor,
                  onTap: () => onChanger(item.quantite + 1)),
            ]),
          ]),
        ),
        const SizedBox(width: 8),
        Column(children: [
          Text('${item.sousTotal.toStringAsFixed(2)} ${item.devise}',
              style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 14)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onRetirer,
            child: const Icon(Icons.delete_outline,
                color: Colors.red, size: 20),
          ),
        ]),
      ]),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QtyButton(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}
