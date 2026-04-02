// lib/screens/admin_ecommerce/admin_produit_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/produit.dart';
import '../../providers/app_theme_provider.dart';
import '../../services/ecommerce_service.dart';
import 'admin_produit_form_screen.dart';
import 'admin_stock_screen.dart';

class AdminProduitListScreen extends StatefulWidget {
  final String serviceType;
  final String serviceLabel;

  const AdminProduitListScreen({
    Key? key,
    required this.serviceType,
    required this.serviceLabel,
  }) : super(key: key);

  @override
  State<AdminProduitListScreen> createState() =>
      _AdminProduitListScreenState();
}

class _AdminProduitListScreenState extends State<AdminProduitListScreen> {
  late EcommerceService _service;
  List<Produit> _produits = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _service = EcommerceService(serviceType: widget.serviceType);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _produits = await _service.getProduitsAdmin();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _delete(Produit p) async {
    if (p.id == null) return;
    final ok = await _service.deleteProduit(p.id!);
    if (ok) _load();
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
        title: Text('Produits — ${widget.serviceLabel}',
            style: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined),
            tooltip: 'Gestion stock',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AdminStockScreen(
                  serviceType: widget.serviceType,
                  serviceLabel: widget.serviceLabel,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Ajouter un produit',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminProduitFormScreen(
                    serviceType: widget.serviceType,
                    serviceLabel: widget.serviceLabel,
                  ),
                ),
              );
              _load();
            },
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _produits.isEmpty
              ? _empty(t)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _produits.length,
                    itemBuilder: (ctx, i) => _ProduitAdminTile(
                      produit: _produits[i],
                      t: t,
                      onEdit: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdminProduitFormScreen(
                              serviceType: widget.serviceType,
                              serviceLabel: widget.serviceLabel,
                              produit: _produits[i],
                            ),
                          ),
                        );
                        _load();
                      },
                      onDelete: () => _delete(_produits[i]),
                    ),
                  ),
                ),
    );
  }

  Widget _empty(AppThemeProvider t) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('📦', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('Aucun produit',
              style: TextStyle(
                  color: t.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16)),
        ]),
      );
}

class _ProduitAdminTile extends StatelessWidget {
  final Produit produit;
  final AppThemeProvider t;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProduitAdminTile(
      {required this.produit,
      required this.t,
      required this.onEdit,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: t.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.border)),
      child: Row(children: [
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Row(children: [
              Expanded(
                  child: Text(produit.nom,
                      style: TextStyle(
                          color: t.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 14))),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: produit.actif
                        ? Colors.green.withValues(alpha: 0.12)
                        : Colors.grey.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(produit.actif ? 'Actif' : 'Inactif',
                    style: TextStyle(
                        color:
                            produit.actif ? Colors.green : Colors.grey,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            ]),
            const SizedBox(height: 4),
            Text(
                '${produit.prix} ${produit.devise}${produit.unite != null ? ' / ${produit.unite}' : ''}',
                style: TextStyle(
                    color: t.textMuted, fontSize: 13)),
            const SizedBox(height: 4),
            Text('Stock : ${produit.stock}',
                style: TextStyle(
                    color: produit.enStock
                        ? AppThemeProvider.green
                        : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ]),
        ),
        Column(children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            color: AppThemeProvider.appBlue,
            onPressed: onEdit,
            tooltip: 'Modifier',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(height: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            color: Colors.red,
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: t.bgCard,
                  title: Text('Supprimer ?',
                      style: TextStyle(color: t.textPrimary)),
                  content: Text(
                      'Supprimer définitivement "${produit.nom}" ?',
                      style: TextStyle(color: t.textMuted)),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('Annuler',
                            style: TextStyle(color: t.textMuted))),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Supprimer',
                            style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
              if (ok == true) onDelete();
            },
            tooltip: 'Supprimer',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ]),
      ]),
    );
  }
}
