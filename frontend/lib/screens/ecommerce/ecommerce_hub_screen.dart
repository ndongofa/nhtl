// lib/screens/ecommerce/ecommerce_hub_screen.dart
// Tableau de bord utilisateur pour les services e-commerce.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/commande_ecommerce.dart';
import '../../providers/app_theme_provider.dart';
import '../../providers/panier_provider.dart';
import '../../services/ecommerce_service.dart';
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

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppThemeProvider>();

    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.topBarBg,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('Mes commandes — ${widget.serviceLabel}',
            style: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 16)),
        actions: [
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
            icon: const Icon(Icons.store_outlined),
            tooltip: 'Catalogue',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider(
                  create: (_) =>
                      PanierProvider(serviceType: widget.serviceType),
                  child: CatalogueScreen(
                    serviceType: widget.serviceType,
                    serviceLabel: widget.serviceLabel,
                    serviceEmoji: '🛍️',
                    accentColor: widget.accentColor,
                  ),
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
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                  color: widget.accentColor))
          : _commandes.isEmpty
              ? _emptyState(t)
              : RefreshIndicator(
                  onRefresh: _load,
                  color: widget.accentColor,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _commandes.length,
                    itemBuilder: (ctx, i) => _CommandeTile(
                      commande: _commandes[i],
                      accentColor: widget.accentColor,
                      t: t,
                    ),
                  ),
                ),
    );
  }

  Widget _emptyState(AppThemeProvider t) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🛍️', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 16),
          Text('Aucune commande en cours',
              style: TextStyle(
                  color: t.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16)),
          const SizedBox(height: 8),
          Text('Commandez depuis le catalogue',
              style: TextStyle(color: t.textMuted, fontSize: 13)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.store_outlined, size: 18),
            label: const Text('Aller au catalogue',
                style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
                backgroundColor: widget.accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider(
                  create: (_) =>
                      PanierProvider(serviceType: widget.serviceType),
                  child: CatalogueScreen(
                    serviceType: widget.serviceType,
                    serviceLabel: widget.serviceLabel,
                    serviceEmoji: '🛍️',
                    accentColor: widget.accentColor,
                  ),
                ),
              ),
            ),
          ),
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
