// lib/screens/achat_form_screen.dart
//
// Formulaire de création / modification d'un achat sur mesure.
// Adapté depuis commande_form_screen.dart — remplace plateforme/lienProduit
// par marche (text) et typeProduit (dropdown).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../models/achat.dart';
import '../services/achat_service.dart';
import '../services/auth_service.dart';
import '../widgets/phone_input_field.dart';

class AchatFormScreen extends StatefulWidget {
  final Achat? achat;
  const AchatFormScreen({Key? key, this.achat}) : super(key: key);

  @override
  State<AchatFormScreen> createState() => _AchatFormScreenState();
}

class _AchatFormScreenState extends State<AchatFormScreen> {
  static const Color _appBlue = Color(0xFF2296F3);
  static const Color _bgLight = Color(0xFFF4F8FF);
  static const Color _textMain = Color(0xFF0F2040);
  static const Color _textMuted = Color(0xFF6B7A99);
  static const Color _border = Color(0xFFDDE3EF);
  static const Color _amber = Color(0xFFFFB300);
  static const Color _teal = Color(0xFF00BCD4);
  static const Color _green = Color(0xFF22C55E);

  final _formKey = GlobalKey<FormState>();
  final _service = AchatService();
  bool _isLoading = false;

  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _paysLivraisonController = TextEditingController();
  final _villeLivraisonController = TextEditingController();
  final _adresseLivraisonController = TextEditingController();
  final _marcheController = TextEditingController();
  final _descriptionAchatController = TextEditingController();
  final _quantiteController = TextEditingController();
  final _prixEstimeController = TextEditingController();
  final _prixTotalController = TextEditingController();
  final _notesSpecialesController = TextEditingController();

  String? _phoneE164;
  String _typeProduit = 'TISSUS';
  String _devise = 'EUR';

  static const List<String> _typesProduits = [
    'TISSUS',
    'BIJOUX',
    'ALIMENTAIRE',
    'ARTISANAT',
    'MEDICAMENTS',
    'HIGH_TECH',
    'VETEMENTS',
    'CHAUSSURES',
    'DECORATION',
    'AUTRE',
  ];

  static const List<String> _devises = ['EUR', 'USD', 'GBP', 'MAD', 'XOF', 'CAD'];

  static const Map<String, String> _typesProduitLabels = {
    'TISSUS': '🧵 Tissus & Wax',
    'BIJOUX': '💎 Bijoux & Accessoires',
    'ALIMENTAIRE': '🌶️ Épices & Alimentaire',
    'ARTISANAT': '🏺 Artisanat',
    'MEDICAMENTS': '💊 Médicaments & Santé',
    'HIGH_TECH': '📱 High-Tech',
    'VETEMENTS': '👗 Vêtements',
    'CHAUSSURES': '👟 Chaussures',
    'DECORATION': '🪴 Décoration',
    'AUTRE': '📦 Autre',
  };

  double? _parseDecimal(String raw) =>
      double.tryParse(raw.trim().replaceAll(',', '.'));

  void _recalcTotal() {
    final q = _parseDecimal(_quantiteController.text);
    final p = _parseDecimal(_prixEstimeController.text);
    if (q != null && p != null && q > 0 && p > 0) {
      final total = q * p;
      final formatted = total == total.truncateToDouble()
          ? total.toInt().toString()
          : total.toStringAsFixed(2);
      if (_prixTotalController.text != formatted) {
        _prixTotalController.text = formatted;
        _prixTotalController.selection =
            TextSelection.fromPosition(TextPosition(offset: formatted.length));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    final a = widget.achat;
    if (a != null) {
      _nomController.text = a.nom;
      _prenomController.text = a.prenom;
      _phoneE164 = a.numeroTelephone;
      _emailController.text = a.email ?? '';
      _paysLivraisonController.text = a.paysLivraison;
      _villeLivraisonController.text = a.villeLivraison;
      _adresseLivraisonController.text = a.adresseLivraison;
      _marcheController.text = a.marche;
      _descriptionAchatController.text = a.descriptionAchat;
      _quantiteController.text = a.quantite.toString();
      _prixEstimeController.text = a.prixEstime.toString();
      _prixTotalController.text = a.prixTotal.toString();
      _notesSpecialesController.text = a.notesSpeciales ?? '';
      _typeProduit = a.typeProduit.isNotEmpty ? a.typeProduit : 'TISSUS';
      _devise = a.devise;
    } else {
      final meta = AuthService.userMetadata;
      final user = AuthService.currentUser;
      if (meta != null || user != null) {
        _nomController.text = meta?['nom']?.toString().trim() ?? '';
        _prenomController.text = meta?['prenom']?.toString().trim() ?? '';
        _emailController.text = user?.email?.trim() ?? '';
        _phoneE164 = user?.phone != null ? '+${user!.phone}' : null;
      }
    }
    _quantiteController.addListener(_recalcTotal);
    _prixEstimeController.addListener(_recalcTotal);
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _paysLivraisonController.dispose();
    _villeLivraisonController.dispose();
    _adresseLivraisonController.dispose();
    _marcheController.dispose();
    _descriptionAchatController.dispose();
    _quantiteController.dispose();
    _prixEstimeController.dispose();
    _prixTotalController.dispose();
    _notesSpecialesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_phoneE164 == null || _phoneE164!.isEmpty) {
      Fluttertoast.showToast(
          msg: 'Veuillez entrer un numéro de téléphone valide.',
          backgroundColor: Colors.red,
          toastLength: Toast.LENGTH_LONG);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final qte = int.parse(_quantiteController.text.trim());
      final prixEstime = _parseDecimal(_prixEstimeController.text) ?? 0;
      final prixTotal = _parseDecimal(_prixTotalController.text) ?? 0;

      final data = Achat(
        id: widget.achat?.id,
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        numeroTelephone: _phoneE164!,
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        paysLivraison: _paysLivraisonController.text.trim(),
        villeLivraison: _villeLivraisonController.text.trim(),
        adresseLivraison: _adresseLivraisonController.text.trim(),
        marche: _marcheController.text.trim(),
        typeProduit: _typeProduit,
        descriptionAchat: _descriptionAchatController.text.trim(),
        quantite: qte,
        prixEstime: prixEstime,
        prixTotal: prixTotal,
        devise: _devise,
        notesSpeciales: _notesSpecialesController.text.trim().isEmpty
            ? null
            : _notesSpecialesController.text.trim(),
      );

      final result = widget.achat == null
          ? await _service.createAchat(data)
          : await _service.updateAchat(data);

      if (result != null) {
        Fluttertoast.showToast(
            msg: widget.achat == null ? '✅ Achat créé !' : '✅ Achat modifié !',
            backgroundColor: Colors.green);
        Navigator.pop(context, true);
      } else {
        Fluttertoast.showToast(
            msg: '❌ Une erreur est survenue.', backgroundColor: Colors.red);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: '❌ Erreur : $e', backgroundColor: Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.achat != null;
    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        backgroundColor: _teal,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(isEdit ? 'Modifier l\'achat' : 'Nouvelle demande d\'achat',
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Form(
              key: _formKey,
              child: Column(children: [
                // ── Section 1 : Destinataire ──────────────────────────────
                _card(children: [
                  _sectionHeader(Icons.person_outline, _appBlue, "Destinataire",
                      "Qui va recevoir la commande ?"),
                  const SizedBox(height: 20),
                  Row(children: [
                    Expanded(
                        child: _field(_nomController, "Nom", Icons.badge_outlined,
                            hint: "Ex : Diallo", required: true)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _field(_prenomController, "Prénom",
                            Icons.person_outline,
                            hint: "Ex : Fatou", required: true)),
                  ]),
                  const SizedBox(height: 14),
                  PhoneInputField(
                    label: 'Téléphone',
                    initialCountryCode: 'SN',
                    initialValue: _phoneE164,
                    onChanged: (e164) => setState(() => _phoneE164 = e164),
                  ),
                  const SizedBox(height: 14),
                  _field(_emailController, "Email (optionnel)",
                      Icons.alternate_email,
                      hint: "votre@email.com",
                      required: false,
                      keyboardType: TextInputType.emailAddress, validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final regex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                    return regex.hasMatch(v.trim()) ? null : 'Email invalide';
                  }),
                ]),

                const SizedBox(height: 16),

                // ── Section 2 : Livraison ─────────────────────────────────
                _card(children: [
                  _sectionHeader(Icons.local_shipping_outlined, _teal,
                      "Livraison", "Où livrer la commande ?"),
                  const SizedBox(height: 20),
                  _field(_paysLivraisonController, "Pays de livraison",
                      Icons.flag_outlined,
                      hint: "Ex : Sénégal, France, Maroc", required: true),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(
                        child: _field(_villeLivraisonController, "Ville",
                            Icons.location_city_outlined,
                            hint: "Ex : Dakar", required: true)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _field(_adresseLivraisonController,
                            "Adresse complète", Icons.home_outlined,
                            hint: "N°, rue, quartier, code postal...",
                            required: true,
                            maxLines: 2, validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Requis';
                      if (v.trim().length < 5) return 'Minimum 5 caractères';
                      return null;
                    })),
                  ]),
                ]),

                const SizedBox(height: 16),

                // ── Section 3 : Produit ───────────────────────────────────
                _card(children: [
                  _sectionHeader(Icons.shopping_bag_outlined, _amber, "Produit",
                      "Détails de l'article à acheter"),
                  const SizedBox(height: 20),
                  _dropdown(
                      "Type de produit",
                      _typeProduit,
                      _typesProduits,
                      Icons.category_outlined,
                      (v) => setState(() => _typeProduit = v!),
                      displayLabels: _typesProduitLabels),
                  const SizedBox(height: 14),
                  _field(_marcheController, "Marché / Boutique cible",
                      Icons.store_outlined,
                      hint: "Ex : Marché Sandaga, Grand Yoff, Boutique XYZ...",
                      required: true),
                  const SizedBox(height: 14),
                  _field(_descriptionAchatController, "Description de l'article",
                      Icons.description_outlined,
                      hint:
                          "Couleur, taille, modèle, quantité exacte... Soyez précis !",
                      required: true,
                      maxLines: 3, validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Requis';
                    if (v.trim().length < 10) return 'Minimum 10 caractères';
                    return null;
                  }),
                ]),

                const SizedBox(height: 16),

                // ── Section 4 : Prix & quantité ───────────────────────────
                _card(children: [
                  _sectionHeader(Icons.payments_outlined, _green,
                      "Prix & Quantité", "Combien et à quel prix ?"),
                  const SizedBox(height: 20),
                  Row(children: [
                    Expanded(
                        child: _field(_quantiteController, "Quantité",
                            Icons.add_box_outlined,
                            hint: "Ex : 2",
                            keyboardType: TextInputType.number, validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Requis';
                      final n = int.tryParse(v.trim());
                      if (n == null || n < 1) return 'Min 1';
                      return null;
                    })),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _field(_prixEstimeController, "Prix estimé / unité",
                            Icons.price_change_outlined,
                            hint: "Ex : 15.50",
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.,]'))
                            ], validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Requis';
                      if (_parseDecimal(v) == null) return 'Nombre invalide';
                      return null;
                    })),
                  ]),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(
                        child: _field(
                            _prixTotalController, "Prix total estimé",
                            Icons.calculate_outlined,
                            hint: "Auto-calculé",
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.,]'))
                            ])),
                    const SizedBox(width: 12),
                    Expanded(child: _deviseDropdown()),
                  ]),
                ]),

                const SizedBox(height: 16),

                // ── Section 5 : Notes ─────────────────────────────────────
                _card(children: [
                  _sectionHeader(Icons.notes_outlined, _textMuted, "Notes",
                      "Informations complémentaires"),
                  const SizedBox(height: 20),
                  _field(_notesSpecialesController, "Notes spéciales (optionnel)",
                      Icons.comment_outlined,
                      hint:
                          "Urgence, préférences de livraison, budget max...",
                      required: false,
                      maxLines: 3),
                ]),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(
                            isEdit ? 'Enregistrer les modifications' : 'Envoyer ma demande',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers UI ──────────────────────────────────────────────────────────────

  Widget _card({required List<Widget> children}) => Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );

  Widget _sectionHeader(
          IconData icon, Color color, String title, String subtitle) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(title,
                  style: TextStyle(
                      color: _textMain,
                      fontWeight: FontWeight.w800,
                      fontSize: 15)),
              Text(subtitle,
                  style: TextStyle(color: _textMuted, fontSize: 12)),
            ])),
      ]);

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    String? hint,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, size: 20, color: _textMuted),
          labelStyle: TextStyle(color: _textMuted, fontSize: 13),
          hintStyle: TextStyle(color: _textMuted.withValues(alpha: 0.5)),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _teal, width: 1.5)),
          filled: true,
          fillColor: const Color(0xFFF8FAFF),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        validator: validator ??
            (required
                ? (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null
                : null),
      );

  Widget _dropdown(
    String label,
    String value,
    List<String> items,
    IconData icon,
    void Function(String?) onChanged, {
    Map<String, String>? displayLabels,
  }) =>
      DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20, color: _textMuted),
          labelStyle: TextStyle(color: _textMuted, fontSize: 13),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _teal, width: 1.5)),
          filled: true,
          fillColor: const Color(0xFFF8FAFF),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        items: items
            .map((v) => DropdownMenuItem<String>(
                  value: v,
                  child: Text(displayLabels?[v] ?? v,
                      style: TextStyle(color: _textMain, fontSize: 14)),
                ))
            .toList(),
        onChanged: onChanged,
      );

  Widget _deviseDropdown() => DropdownButtonFormField<String>(
        value: _devise,
        decoration: InputDecoration(
          labelText: "Devise",
          prefixIcon:
              Icon(Icons.currency_exchange, size: 20, color: _textMuted),
          labelStyle: TextStyle(color: _textMuted, fontSize: 13),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _teal, width: 1.5)),
          filled: true,
          fillColor: const Color(0xFFF8FAFF),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        items: _devises
            .map((d) => DropdownMenuItem<String>(
                  value: d,
                  child: Text(d,
                      style: TextStyle(color: _textMain, fontSize: 14)),
                ))
            .toList(),
        onChanged: (v) => setState(() => _devise = v!),
      );
}
