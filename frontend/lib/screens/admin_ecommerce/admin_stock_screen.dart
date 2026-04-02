// lib/screens/admin_ecommerce/admin_stock_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import '../../models/produit.dart';
import '../../providers/app_theme_provider.dart';
import '../../services/ecommerce_service.dart';

class AdminStockScreen extends StatefulWidget {
  final String serviceType;
  final String serviceLabel;

  const AdminStockScreen({
    Key? key,
    required this.serviceType,
    required this.serviceLabel,
  }) : super(key: key);

  @override
  State<AdminStockScreen> createState() => _AdminStockScreenState();
}

class _AdminStockScreenState extends State<AdminStockScreen> {
  late EcommerceService _service;
  List<Produit> _produits = [];
  bool _loading = false;
  final Map<int, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _service = EcommerceService(serviceType: widget.serviceType);
    _load();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _produits = await _service.getProduitsAdmin();
    for (final p in _produits) {
      if (p.id != null) {
        _controllers[p.id!] ??= TextEditingController(
            text: p.stock.toString());
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveStock(Produit p) async {
    if (p.id == null) return;
    final ctrl = _controllers[p.id!];
    if (ctrl == null) return;
    final newStock = int.tryParse(ctrl.text.trim()) ?? p.stock;
    final result = await _service.updateStock(p.id!, newStock);
    if (result != null) {
      Fluttertoast.showToast(
          msg: '✅ Stock mis à jour', backgroundColor: Colors.green);
    } else {
      Fluttertoast.showToast(
          msg: '❌ Erreur', backgroundColor: Colors.red);
    }
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
        title: Text('Stock — ${widget.serviceLabel}',
            style: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 16)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _produits.isEmpty
              ? Center(
                  child: Text('Aucun produit',
                      style: TextStyle(color: t.textPrimary)))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _produits.length,
                  separatorBuilder: (_, __) => Divider(
                      color: t.border, height: 1),
                  itemBuilder: (ctx, i) {
                    final p = _produits[i];
                    if (p.id == null) return const SizedBox.shrink();
                    final ctrl = _controllers[p.id!];
                    if (ctrl == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10),
                      child: Row(children: [
                        Expanded(
                          child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                            Text(p.nom,
                                style: TextStyle(
                                    color: t.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text(
                              '${p.prix} ${p.devise}${p.unite != null ? ' / ${p.unite}' : ''}',
                              style: TextStyle(
                                  color: t.textMuted, fontSize: 12),
                            ),
                          ]),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 80,
                          child: TextFormField(
                            controller: ctrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            style: TextStyle(
                                color: t.textPrimary,
                                fontWeight: FontWeight.w700),
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 10),
                              filled: true,
                              fillColor: t.bgCard,
                              border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(8),
                                  borderSide:
                                      BorderSide(color: t.border)),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(8),
                                  borderSide:
                                      BorderSide(color: t.border)),
                            ),
                            onFieldSubmitted: (_) => _saveStock(p),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _saveStock(p),
                          style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  AppThemeProvider.appBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              minimumSize: Size.zero,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(8)),
                              elevation: 0),
                          child: const Text('OK',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12)),
                        ),
                      ]),
                    );
                  },
                ),
    );
  }
}
