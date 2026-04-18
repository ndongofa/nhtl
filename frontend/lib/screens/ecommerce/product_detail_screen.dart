// lib/screens/ecommerce/product_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import '../../models/produit.dart';
import '../../providers/app_theme_provider.dart';
import '../../providers/panier_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/sama_account_menu.dart';
import 'panier_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Produit produit;
  final String serviceType;
  final Color accentColor;

  const ProductDetailScreen({
    Key? key,
    required this.produit,
    required this.serviceType,
    required this.accentColor,
  }) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantite = 1;
  bool _adding = false;
  int _currentImageIndex = 0;
  late final PageController _pageController;

  /// Returns the effective list of image URLs for this product.
  List<String> get _imageUrls {
    if (widget.produit.imageUrls.isNotEmpty) return widget.produit.imageUrls;
    if (widget.produit.imageUrl != null &&
        widget.produit.imageUrl!.isNotEmpty) {
      return [widget.produit.imageUrl!];
    }
    return [];
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(Icons.lock_outline, color: widget.accentColor),
          const SizedBox(width: 8),
          const Text('Connexion requise',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        ]),
        content: const Text(
          'Vous devez être connecté pour ajouter des articles au panier.\n\n'
          'Connectez-vous ou créez un compte pour continuer.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler',
                style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).pushNamed('/login');
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: widget.accentColor,
                foregroundColor: Colors.white),
            child: const Text('Se connecter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppThemeProvider>();
    final panier = context.watch<PanierProvider>();
    final p = widget.produit;
    final urls = _imageUrls;

    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.topBarBg,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(p.nom,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        actions: [
          // Panier (toujours visible, avec badge article)
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                tooltip: 'Mon panier',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider.value(
                      value: context.read<PanierProvider>(),
                      child: PanierScreen(
                        serviceType: widget.serviceType,
                        serviceLabel: widget.serviceType,
                        serviceEmoji: '🛒',
                        accentColor: widget.accentColor,
                      ),
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
                        color: widget.accentColor, shape: BoxShape.circle),
                    child: Center(
                      child: Text('${panier.nbArticles}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900)),
                    ),
                  ),
                ),
            ],
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
      body: SingleChildScrollView(
        child: Column(children: [
          // ── Image carousel ────────────────────────────────────────────
          _buildImageCarousel(t, urls),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              // ── Titre + prix ─────────────────────────────────────────
              Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Expanded(
                  child: Text(p.nom,
                      style: TextStyle(
                          color: t.textPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 22)),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('${p.prix} ${p.devise}',
                      style: TextStyle(
                          color: widget.accentColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 22)),
                  if (p.unite != null)
                    Text('/ ${p.unite}',
                        style: TextStyle(
                            color: t.textMuted, fontSize: 12)),
                ]),
              ]),

              const SizedBox(height: 8),

              // ── Stock ────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: p.enStock
                        ? widget.accentColor.withValues(alpha: 0.12)
                        : Colors.red.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(
                  p.enStock
                      ? '✅ En stock (${p.stock}${p.unite != null ? ' ${p.unite}' : ''})'
                      : '❌ Rupture de stock',
                  style: TextStyle(
                      color: p.enStock ? widget.accentColor : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ),
              ),

              if (p.categorie != null) ...[
                const SizedBox(height: 8),
                Text(p.categorie!,
                    style:
                        TextStyle(color: t.textMuted, fontSize: 13)),
              ],

              if (p.description != null && p.description!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Divider(color: t.border),
                const SizedBox(height: 8),
                Text(p.description!,
                    style: TextStyle(
                        color: t.textMuted,
                        fontSize: 14,
                        height: 1.6)),
              ],

              const SizedBox(height: 24),

              // ── Sélecteur de quantité ─────────────────────────────────
              if (p.enStock) ...[
                Row(children: [
                  Text('Quantité :',
                      style: TextStyle(
                          color: t.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  const SizedBox(width: 16),
                  _QtyBtn(
                    icon: Icons.remove,
                    color: t.textMuted,
                    onTap: () {
                      if (_quantite > 1)
                        setState(() => _quantite--);
                    },
                  ),
                  const SizedBox(width: 12),
                  Text('$_quantite',
                      style: TextStyle(
                          color: t.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 18)),
                  const SizedBox(width: 12),
                  _QtyBtn(
                    icon: Icons.add,
                    color: widget.accentColor,
                    onTap: () {
                      if (_quantite < p.stock)
                        setState(() => _quantite++);
                    },
                  ),
                ]),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: _adding
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.add_shopping_cart),
                    label: Text(
                      'Ajouter au panier · ${(p.prix * _quantite).toStringAsFixed(2)} ${p.devise}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: widget.accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0),
                    onPressed: _adding
                        ? null
                        : () async {
                            if (!AuthService.isLoggedIn()) {
                              _showLoginRequiredDialog(context);
                              return;
                            }
                            setState(() => _adding = true);
                            final ok = await panier.ajouter(
                              p.id!,
                              _quantite,
                              nom: p.nom,
                              imageUrl: urls.isNotEmpty ? urls.first : p.imageUrl,
                              prix: p.prix,
                              devise: p.devise,
                            );
                            setState(() => _adding = false);
                            if (ok) {
                              Fluttertoast.showToast(
                                  msg: '✅ Ajouté au panier',
                                  backgroundColor: Colors.green);
                            } else {
                              Fluttertoast.showToast(
                                  msg: '❌ Impossible d\'ajouter au panier. Vérifiez votre connexion et réessayez.',
                                  backgroundColor: Colors.red,
                                  toastLength: Toast.LENGTH_LONG);
                            }
                          },
                  ),
                ),
              ],

              const SizedBox(height: 32),
            ]),
          ),
        ]),
      ),
    );
  }

  void _openLightbox(BuildContext context, List<String> urls, int initialIndex) {
    Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (ctx, _, __) => _LightboxViewer(
        urls: urls,
        initialIndex: initialIndex,
        accentColor: widget.accentColor,
      ),
    ));
  }

  Widget _buildImageCarousel(AppThemeProvider t, List<String> urls) {
    if (urls.isEmpty) {
      return SizedBox(
        height: 280,
        width: double.infinity,
        child: Container(
          color: widget.accentColor.withValues(alpha: 0.08),
          child: Icon(Icons.storefront,
              color: widget.accentColor, size: 80)),
      );
    }

    if (urls.length == 1) {
      return GestureDetector(
        onTap: () => _openLightbox(context, urls, 0),
        child: SizedBox(
          height: 280,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: urls.first,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                    color: t.bgSection,
                    child: Icon(Icons.image_outlined,
                        color: t.textMuted, size: 48)),
                errorWidget: (_, __, ___) => Container(
                    color: t.bgSection,
                    child: Icon(Icons.image_not_supported_outlined,
                        color: t.textMuted, size: 48)),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                      color: Colors.black45, shape: BoxShape.circle),
                  child: const Icon(Icons.zoom_in,
                      color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        SizedBox(
          height: 280,
          child: PageView.builder(
            controller: _pageController,
            itemCount: urls.length,
            onPageChanged: (i) =>
                setState(() => _currentImageIndex = i),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => _openLightbox(context, urls, i),
              child: CachedNetworkImage(
                imageUrl: urls[i],
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (_, __) => Container(
                    color: t.bgSection,
                    child: Icon(Icons.image_outlined,
                        color: t.textMuted, size: 48)),
                errorWidget: (_, __, ___) => Container(
                    color: t.bgSection,
                    child: Icon(Icons.image_not_supported_outlined,
                        color: t.textMuted, size: 48)),
              ),
            ),
          ),
        ),
        // Zoom hint icon
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
                color: Colors.black45, shape: BoxShape.circle),
            child: const Icon(Icons.zoom_in,
                color: Colors.white, size: 18),
          ),
        ),
        // Dots indicator
        Positioned(
          bottom: 10,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(urls.length, (i) {
              final active = i == _currentImageIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 18 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: active
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black26,
                        blurRadius: 2,
                        offset: const Offset(0, 1))
                  ],
                ),
              );
            }),
          ),
        ),
        // Navigation arrows (only on wider screens / tablet)
        if (MediaQuery.of(context).size.width > 500) ...[
          Positioned(
            left: 8,
            top: 110,
            child: _arrowBtn(Icons.chevron_left, () {
              if (_currentImageIndex > 0) {
                _pageController.previousPage(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut);
              }
            }),
          ),
          Positioned(
            right: 8,
            top: 110,
            child: _arrowBtn(Icons.chevron_right, () {
              if (_currentImageIndex < urls.length - 1) {
                _pageController.nextPage(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut);
              }
            }),
          ),
        ],
      ],
    );
  }

  Widget _arrowBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: Colors.black38,
              shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      );
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QtyBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.3))),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

// ── Fullscreen lightbox viewer ────────────────────────────────────────────────

class _LightboxViewer extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;
  final Color accentColor;

  const _LightboxViewer({
    required this.urls,
    required this.initialIndex,
    required this.accentColor,
  });

  @override
  State<_LightboxViewer> createState() => _LightboxViewerState();
}

class _LightboxViewerState extends State<_LightboxViewer> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.urls.length;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Photo viewer ───────────────────────────────────────────────
          PageView.builder(
            controller: _pageController,
            itemCount: total,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (_, i) => InteractiveViewer(
              minScale: 0.8,
              maxScale: 4.0,
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: widget.urls[i],
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const Center(
                    child: CircularProgressIndicator(color: Colors.white54),
                  ),
                  errorWidget: (_, __, ___) => const Center(
                    child: Icon(Icons.image_not_supported_outlined,
                        color: Colors.white54, size: 64),
                  ),
                ),
              ),
            ),
          ),

          // ── Top bar: close button + counter ───────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.white, size: 28),
                      tooltip: 'Fermer',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    if (total > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_currentIndex + 1} / $total',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ── Navigation arrows ─────────────────────────────────────────
          if (total > 1) ...[
            if (_currentIndex > 0)
              Positioned(
                left: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _LightboxArrow(
                    icon: Icons.chevron_left,
                    onTap: () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut),
                  ),
                ),
              ),
            if (_currentIndex < total - 1)
              Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _LightboxArrow(
                    icon: Icons.chevron_right,
                    onTap: () => _pageController.nextPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut),
                  ),
                ),
              ),
          ],

          // ── Dots indicator ────────────────────────────────────────────
          if (total > 1)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(total, (i) {
                  final active = i == _currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 18 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: active
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

class _LightboxArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _LightboxArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
            color: Colors.black54, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 26),
      ),
    );
  }
}

