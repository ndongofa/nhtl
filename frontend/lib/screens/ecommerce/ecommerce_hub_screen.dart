// lib/screens/ecommerce/ecommerce_hub_screen.dart
// Tableau de bord utilisateur pour les services e-commerce.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/commande_ecommerce.dart';
import '../../providers/app_theme_provider.dart';
import '../../providers/panier_provider.dart';
import '../../services/auth_service.dart';
import '../../services/ecommerce_service.dart';
import '../../widgets/sama_account_menu.dart';
import 'ecommerce_tracking_screen.dart';
import 'catalogue_screen.dart';
import 'ecommerce_archives_screen.dart';

class EcommerceHubScreen extends StatefulWidget {
  final String serviceType;
  final String serviceLabel;
  final Color accentColor;

  const EcommerceHubScreen({
    Key? key,
    required this.serviceType,
    required this.serviceLabel,
    required this.accentColor,
  }) : super(key: key);

  @override
  State<EcommerceHubScreen> createState() => _EcommerceHubScreenState();
}

class _EcommerceHubScreenState extends State<EcommerceHubScreen> {
  static const double _fabBottomPadding = 96;

  late EcommerceService _service;
  List<CommandeEcommerce> _commandes = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _service = EcommerceService(serviceType: widget.serviceType);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _commandes = await _service.getMesCommandes();
    if (mounted) setState(() => _loading = false);
  }

  void _ouvrirCatalogue() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => PanierProvider(serviceType: widget.serviceType),
          child: CatalogueScreen(
            serviceType: widget.serviceType,
            serviceLabel: widget.serviceLabel,
            serviceEmoji: '🛍️',
            accentColor: widget.accentColor,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppThemeProvider>();

    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.topBarBg,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(widget.serviceLabel,
            style: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 16)),
        actions: [
          IconButton(
            tooltip: "Mon espace",
            icon: const Icon(Icons.dashboard_outlined),
            onPressed: () => SamaAccountMenu.open(context),
          ),
          IconButton(
            tooltip: "Déconnexion",
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.logout();
              if (!context.mounted) return;
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/', (_) => false);
            },
          ),
          IconButton(
            icon: const Icon(Icons.archive_outlined),
            tooltip: 'Archives',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EcommerceArchivesScreen(
                  serviceType: widget.serviceType,
                  serviceLabel: widget.serviceLabel,
                  accentColor: widget.accentColor,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _ouvrirCatalogue,
        backgroundColor: widget.accentColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.store_outlined),
        label: const Text('Catalogue',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _catalogueBanner(t),
          Expanded(
            child: _loading
                ? Center(
                    child: CircularProgressIndicator(
                        color: widget.accentColor))
                : _commandes.isEmpty
                    ? _emptyState(t)
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: widget.accentColor,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(
                              16, 0, 16, _fabBottomPadding),
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 12, top: 4),
                              child: Text('Mes commandes en cours',
                                  style: TextStyle(
                                      color: t.textPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14)),
                            ),
                            ..._commandes.map((c) => _CommandeTile(
                                  commande: c,
                                  accentColor: widget.accentColor,
                                  t: t,
                                )),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _catalogueBanner(AppThemeProvider t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: InkWell(
        onTap: _ouvrirCatalogue,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.accentColor,
                widget.accentColor.withValues(alpha: 0.75),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            const Icon(Icons.store_outlined, color: Colors.white, size: 26),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Text('Parcourir le catalogue',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15)),
                const SizedBox(height: 2),
                Text('Découvrez tous les produits disponibles',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12)),
              ]),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white, size: 16),
          ]),
        ),
      ),
    );
  }

  Widget _emptyState(AppThemeProvider t) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('📦', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 16),
          Text('Aucune commande en cours',
              style: TextStyle(
                  color: t.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16)),
          const SizedBox(height: 8),
          Text('Commandez depuis le catalogue',
              style: TextStyle(color: t.textMuted, fontSize: 13)),
        ]),
      );
}

// ── Tuile commande ────────────────────────────────────────────────────────────

class _CommandeTile extends StatelessWidget {
  final CommandeEcommerce commande;
  final Color accentColor;
  final AppThemeProvider t;

  const _CommandeTile(
      {required this.commande, required this.accentColor, required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
          color: t.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.border)),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EcommerceTrackingScreen(
                commande: commande,
                accentColor: accentColor,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('#${commande.id} — ${commande.serviceType}',
                      style: TextStyle(
                          color: t.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    '${commande.items.length} article(s) · ${commande.prixTotal.toStringAsFixed(2)} ${commande.devise}',
                    style: TextStyle(color: t.textMuted, fontSize: 12),
                  ),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: accentColor.withValues(alpha: 0.3))),
                child: Text(commande.statut,
                    style: TextStyle(
                        color: accentColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
