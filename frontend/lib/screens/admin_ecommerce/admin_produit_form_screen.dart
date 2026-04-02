// lib/screens/admin_ecommerce/admin_produit_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import '../../models/produit.dart';
import '../../providers/app_theme_provider.dart';
import '../../services/ecommerce_service.dart';

class AdminProduitFormScreen extends StatefulWidget {
  final String serviceType;
  final String serviceLabel;
  final Produit? produit;

  const AdminProduitFormScreen({
    Key? key,
    required this.serviceType,
    required this.serviceLabel,
    this.produit,
  }) : super(key: key);

  @override
  State<AdminProduitFormScreen> createState() =>
      _AdminProduitFormScreenState();
}

class _AdminProduitFormScreenState extends State<AdminProduitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _prixController = TextEditingController();
  final _stockController = TextEditingController();
  final _categorieController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _uniteController = TextEditingController();

  String _devise = 'EUR';
  bool _actif = true;
  bool _loading = false;

  late EcommerceService _service;

  static const List<String> _devises = [
    'EUR', 'USD', 'GBP', 'MAD', 'XOF', 'CAD'
  ];

  @override
  void initState() {
    super.initState();
    _service = EcommerceService(serviceType: widget.serviceType);
    final p = widget.produit;
    if (p != null) {
      _nomController.text = p.nom;
      _descriptionController.text = p.description ?? '';
      _prixController.text = p.prix.toString();
      _stockController.text = p.stock.toString();
      _categorieController.text = p.categorie ?? '';
      _imageUrlController.text = p.imageUrl ?? '';
      _uniteController.text = p.unite ?? '';
      _devise = p.devise;
      _actif = p.actif;
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _descriptionController.dispose();
    _prixController.dispose();
    _stockController.dispose();
    _categorieController.dispose();
    _imageUrlController.dispose();
    _uniteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final prix = double.tryParse(
              _prixController.text.trim().replaceAll(',', '.')) ??
          0.0;
      final stock =
          int.tryParse(_stockController.text.trim()) ?? 0;

      final produit = Produit(
        id: widget.produit?.id,
        serviceType: widget.serviceType.toUpperCase(),
        nom: _nomController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        prix: prix,
        devise: _devise,
        categorie: _categorieController.text.trim().isEmpty
            ? null
            : _categorieController.text.trim(),
        imageUrl: _imageUrlController.text.trim().isEmpty
            ? null
            : _imageUrlController.text.trim(),
        stock: stock,
        unite: _uniteController.text.trim().isEmpty
            ? null
            : _uniteController.text.trim(),
        actif: _actif,
      );

      Produit? result;
      if (widget.produit == null) {
        result = await _service.createProduit(produit);
      } else {
        result = await _service.updateProduit(widget.produit!.id!, produit);
      }

      if (result != null) {
        Fluttertoast.showToast(
            msg: widget.produit == null
                ? '✅ Produit créé'
                : '✅ Produit modifié',
            backgroundColor: Colors.green);
        if (mounted) Navigator.pop(context, true);
      } else {
        Fluttertoast.showToast(
            msg: '❌ Erreur lors de l\'enregistrement',
            backgroundColor: Colors.red);
      }
    } catch (e) {
      Fluttertoast.showToast(
          msg: '❌ Erreur : $e', backgroundColor: Colors.red);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppThemeProvider>();
    final isEdit = widget.produit != null;

    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.topBarBg,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
            isEdit
                ? 'Modifier le produit'
                : 'Nouveau produit — ${widget.serviceLabel}',
            style: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 16)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(children: [
                _field(t, _nomController, 'Nom du produit',
                    Icons.label_outline, required: true),
                const SizedBox(height: 14),
                _field(t, _descriptionController, 'Description',
                    Icons.description_outlined,
                    maxLines: 3),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                    child: _field(t, _prixController, 'Prix',
                        Icons.price_change_outlined,
                        required: true,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.,]'))
                        ], validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Requis';
                      if (double.tryParse(v.replaceAll(',', '.')) == null)
                        return 'Invalide';
                      return null;
                    }),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _devise,
                      decoration: _inputDeco(t, 'Devise',
                          Icons.currency_exchange),
                      items: _devises
                          .map((d) => DropdownMenuItem(
                              value: d,
                              child: Text(d,
                                  style: TextStyle(
                                      color: t.textPrimary))))
                          .toList(),
                      onChanged: (v) => setState(() => _devise = v!),
                    ),
                  ),
                ]),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                    child: _field(t, _stockController, 'Stock',
                        Icons.inventory_2_outlined,
                        required: true,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ], validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Requis';
                      if (int.tryParse(v.trim()) == null)
                        return 'Invalide';
                      return null;
                    }),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(t, _uniteController, 'Unité (optionnel)',
                        Icons.straighten_outlined),
                  ),
                ]),
                const SizedBox(height: 14),
                _field(t, _categorieController, 'Catégorie',
                    Icons.category_outlined),
                const SizedBox(height: 14),
                _field(t, _imageUrlController, 'URL image (optionnel)',
                    Icons.image_outlined,
                    keyboardType: TextInputType.url),
                const SizedBox(height: 14),
                Row(children: [
                  Icon(Icons.toggle_on_outlined,
                      color: t.textMuted, size: 20),
                  const SizedBox(width: 10),
                  Text('Produit actif',
                      style: TextStyle(
                          color: t.textPrimary, fontSize: 14)),
                  const Spacer(),
                  Switch(
                    value: _actif,
                    onChanged: (v) => setState(() => _actif = v),
                    activeColor: AppThemeProvider.appBlue,
                  ),
                ]),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppThemeProvider.appBlue,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0),
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(
                            isEdit ? 'Enregistrer' : 'Créer le produit',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 15)),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(AppThemeProvider t, String label, IconData icon) =>
      InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: t.textMuted),
        labelStyle: TextStyle(color: t.textMuted, fontSize: 13),
        filled: true,
        fillColor: t.bgCard,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: t.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: t.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
                color: AppThemeProvider.appBlue, width: 1.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );

  Widget _field(AppThemeProvider t, TextEditingController controller,
      String label, IconData icon,
      {bool required = false,
      int maxLines = 1,
      TextInputType? keyboardType,
      List<TextInputFormatter>? inputFormatters,
      String? Function(String?)? validator}) =>
      TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: TextStyle(color: t.textPrimary),
        decoration: _inputDeco(t, label, icon),
        validator: validator ??
            (required
                ? (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requis' : null
                : null),
      );
}
