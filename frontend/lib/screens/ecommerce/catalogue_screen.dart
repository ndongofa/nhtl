// lib/screens/ecommerce/catalogue_screen.dart
//
// Écran catalogue produits partagé par Maad, Téranga, BestSeller.
// Paramétré par serviceType.

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import '../../models/produit.dart';
import '../../providers/app_theme_provider.dart';
import '../../providers/panier_provider.dart';
import '../../services/ecommerce_service.dart';
import 'product_detail_screen.dart';
import 'panier_screen.dart';

class CatalogueScreen extends StatefulWidget {
  final String serviceType; // 'maad' | 'teranga' | 'bestseller'
  final String serviceLabel;
  final String serviceEmoji;
  final Color accentColor;

  const CatalogueScreen({
    Key? key,
    required this.serviceType,
    required this.serviceLabel,
    required this.serviceEmoji,
    required this.accentColor,
  }) : super(key: key);

  @override
  State<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends State<CatalogueScreen> {
  late EcommerceService _service;
  List<Produit> _produits = [];
  List<Produit> _filtered = [];
  String _searchQuery = '';
  String? _selectedCategorie;
  bool _loading = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _service = EcommerceService(serviceType: widget.serviceType);
    _loadProduits();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProduits() async {
    setState(() => _loading = true);
    _produits = await _service.getProduits();
    _applyFilters();
    if (mounted) setState(() => _loading = false);
  }

  void _onSearch() {
    _searchQuery = _searchController.text.trim().toLowerCase();
    _applyFilters();
    if (mounted) setState(() {});
  }

  void _applyFilters() {
    _filtered = _produits.where((p) {
      final matchCat = _selectedCategorie == null ||
          p.categorie == _selectedCategorie;
      final matchSearch = _searchQuery.isEmpty ||
          p.nom.toLowerCase().contains(_searchQuery) ||
          (p.description?.toLowerCase().contains(_searchQuery) ?? false);
      return matchCat && matchSearch;
    }).toList();
  }

  List<String> get _categories {
    final cats = _produits
        .map((p) => p.categorie)
        .where((c) => c != null)
        .cast<String>()
        .toSet()
        .toList()
      ..sort();
    return cats;
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
          Text(widget.serviceEmoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text(widget.serviceLabel,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 17)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
            onPressed: _loading ? null : _loadProduits,
          ),
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PanierScreen(
                      serviceType: widget.serviceType,
                      serviceLabel: widget.serviceLabel,
                      serviceEmoji: widget.serviceEmoji,
                      accentColor: widget.accentColor,
                    ),
                  ),
                ),
              ),
              if (panier.nbArticles > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                        color: widget.accentColor,
                        shape: BoxShape.circle),
                    child: Center(
                      child: Text(
                        '${panier.nbArticles}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(children: [
        // ── Barre de recherche ─────────────────────────────────────────
        Container(
          color: t.topBarBg.withValues(alpha: 0.9),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: TextField(
            controller: _searchController,
            style: TextStyle(color: t.textPrimary),
            decoration: InputDecoration(
              hintText: 'Rechercher un produit...',
              hintStyle: TextStyle(color: t.textMuted),
              prefixIcon:
                  Icon(Icons.search, color: t.textMuted, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: t.textMuted, size: 18),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
              filled: true,
              fillColor: t.bgCard,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
            ),
          ),
        ),

        // ── Filtres par catégorie ──────────────────────────────────────
        if (_categories.isNotEmpty)
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              children: [
                _catChip(null, 'Tous', t),
                ..._categories.map((c) => _catChip(c, c, t)),
              ],
            ),
          ),

        // ── Liste de produits ──────────────────────────────────────────
        Expanded(
          child: _loading
              ? Center(
                  child: CircularProgressIndicator(
                      color: widget.accentColor))
              : RefreshIndicator(
                  onRefresh: _loadProduits,
                  color: widget.accentColor,
                  child: _filtered.isEmpty
                      ? ListView(
                          physics:
                              const AlwaysScrollableScrollPhysics(),
                          children: [_emptyState(t)],
                        )
                      : GridView.builder(
                          physics:
                              const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 200,
                            childAspectRatio: 0.72,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: _filtered.length,
                          itemBuilder: (ctx, i) => _ProduitCard(
                            produit: _filtered[i],
                            accentColor: widget.accentColor,
                            t: t,
                            onTap: () => Navigator.push(
                              ctx,
                              MaterialPageRoute(
                                builder: (_) => ProductDetailScreen(
                                  produit: _filtered[i],
                                  serviceType: widget.serviceType,
                                  accentColor: widget.accentColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
        ),
      ]),
    );
  }

  Widget _catChip(String? value, String label, AppThemeProvider t) {
    final selected = _selectedCategorie == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategorie = value;
          _applyFilters();
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? widget.accentColor
              : t.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected
                  ? widget.accentColor
                  : t.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : t.textMuted,
            fontSize: 12,
            fontWeight:
                selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _emptyState(AppThemeProvider t) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.55,
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(widget.serviceEmoji,
                style: const TextStyle(fontSize: 52)),
            const SizedBox(height: 16),
            Text('Aucun produit disponible',
                style: TextStyle(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
            const SizedBox(height: 8),
            Text('Revenez bientôt !',
                style: TextStyle(color: t.textMuted, fontSize: 13)),
            const SizedBox(height: 20),
            TextButton.icon(
              icon: Icon(Icons.refresh, color: t.textMuted, size: 16),
              label: Text('Actualiser',
                  style: TextStyle(color: t.textMuted, fontSize: 13)),
              onPressed: _loadProduits,
            ),
          ]),
        ),
      );
}

// ── Carte produit ─────────────────────────────────────────────────────────────

class _ProduitCard extends StatelessWidget {
  final Produit produit;
  final Color accentColor;
  final AppThemeProvider t;
  final VoidCallback onTap;

  const _ProduitCard({
    required this.produit,
    required this.accentColor,
    required this.t,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: t.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(13)),
                child: produit.imageUrl != null && produit.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: produit.imageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (_, __) => Container(
                            color: t.bgSection,
                            child: Icon(Icons.image_outlined,
                                color: t.textMuted, size: 32)),
                        errorWidget: (_, __, ___) => Container(
                            color: t.bgSection,
                            child: Icon(Icons.image_not_supported_outlined,
                                color: t.textMuted, size: 32)),
                      )
                    : Container(
                        color: accentColor.withValues(alpha: 0.08),
                        child:
                            Icon(Icons.storefront, color: accentColor, size: 36),
                      ),
              ),
            ),
            // Infos
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(produit.nom,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
                const SizedBox(height: 4),
                Row(children: [
                  Text(
                    '${produit.prix} ${produit.devise}',
                    style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 14),
                  ),
                  if (produit.unite != null) ...[
                    const SizedBox(width: 3),
                    Text(
                      '/ ${produit.unite}',
                      style: TextStyle(
                          color: t.textMuted, fontSize: 10),
                    ),
                  ],
                ]),
                const SizedBox(height: 4),
                if (!produit.enStock)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6)),
                    child: const Text('Rupture',
                        style: TextStyle(
                            color: Colors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
