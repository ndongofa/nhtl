// lib/screens/commande_form_screen.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/commande.dart';
import '../services/commande_service.dart';
import '../services/auth_service.dart';
import '../widgets/phone_input_field.dart';

class CommandeFormScreen extends StatefulWidget {
  final Commande? commande;
  const CommandeFormScreen({Key? key, this.commande}) : super(key: key);

  @override
  State<CommandeFormScreen> createState() => _CommandeFormScreenState();
}

class _CommandeFormScreenState extends State<CommandeFormScreen> {
  static const Color _appBlue = Color(0xFF2296F3);
  static const Color _bgLight = Color(0xFFF4F8FF);
  static const Color _surface = Colors.white;
  static const Color _textMain = Color(0xFF0F2040);
  static const Color _textMuted = Color(0xFF6B7A99);
  static const Color _border = Color(0xFFDDE3EF);
  static const Color _amber = Color(0xFFFFB300);
  static const Color _teal = Color(0xFF00BCD4);
  static const Color _green = Color(0xFF22C55E);

  final _formKey = GlobalKey<FormState>();
  final _service = CommandeService();
  bool _isLoading = false;

  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _paysLivraisonController = TextEditingController();
  final _villeLivraisonController = TextEditingController();
  final _adresseLivraisonController = TextEditingController();
  final _descriptionCommandeController = TextEditingController();
  final _quantiteController = TextEditingController();
  final _prixUnitaireController = TextEditingController();
  final _prixTotalController = TextEditingController();
  final _notesSpecialesController = TextEditingController();

  // ✅ Liens multiples : liste de contrôleurs (au moins un)
  List<TextEditingController> _lienControllers = [TextEditingController()];

  // ✅ Photos produit : fichiers sélectionnés en attente d'upload
  final List<XFile> _pendingPhotos = [];
  // URLs des photos déjà uploadées (mode édition)
  final List<String> _uploadedPhotoUrls = [];

  final _imagePicker = ImagePicker();

  String? _phoneE164;
  String _plateforme = 'AMAZON';
  String _devise = 'EUR';

  static const List<String> _plateformes = [
    'AMAZON',
    'TEMU',
    'SHEIN',
    'ALIEXPRESS',
    'EBAY',
    'ETSY',
    'AUTRE'
  ];
  static const List<String> _devises = [
    'EUR',
    'USD',
    'GBP',
    'MAD',
    'XOF',
    'CAD'
  ];
  static const Map<String, String> _plateformeLabels = {
    'AMAZON': '📦 Amazon',
    'TEMU': '🛍️ Temu',
    'SHEIN': '👗 Shein',
    'ALIEXPRESS': '🛒 AliExpress',
    'EBAY': '🏷️ eBay',
    'ETSY': '🎨 Etsy',
    'AUTRE': '🌐 Autre site',
  };

  // ✅ Normalise virgule → point et parse en double
  double? _parseDecimal(String raw) =>
      double.tryParse(raw.trim().replaceAll(',', '.'));

  // ✅ Recalcule le total dès que qté ou prix unitaire change
  void _recalcTotal() {
    final q = _parseDecimal(_quantiteController.text);
    final p = _parseDecimal(_prixUnitaireController.text);
    if (q != null && p != null && q > 0 && p > 0) {
      final total = q * p;
      // Affiche sans décimale inutile : 2 × 14.5 → "29.0" → "29" ; 2.5 × 4 → "10"
      final formatted = total == total.truncateToDouble()
          ? total.toInt().toString()
          : total.toStringAsFixed(2);
      if (_prixTotalController.text != formatted) {
        _prixTotalController.text = formatted;
        // Positionner le curseur à la fin
        _prixTotalController.selection =
            TextSelection.fromPosition(TextPosition(offset: formatted.length));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    final c = widget.commande;
    if (c != null) {
      // ── Mode édition : remplir depuis l'objet existant ──────────────
      _nomController.text = c.nom ?? '';
      _prenomController.text = c.prenom ?? '';
      _phoneE164 = c.numeroTelephone;
      _emailController.text = c.email ?? '';
      _paysLivraisonController.text = c.paysLivraison ?? '';
      _villeLivraisonController.text = c.villeLivraison ?? '';
      _adresseLivraisonController.text = c.adresseLivraison ?? '';
      _descriptionCommandeController.text = c.descriptionCommande ?? '';
      _quantiteController.text = c.quantite?.toString() ?? '';
      _prixUnitaireController.text = c.prixUnitaire?.toString() ?? '';
      _prixTotalController.text = c.prixTotal?.toString() ?? '';
      _notesSpecialesController.text = c.notesSpeciales ?? '';
      _plateforme = c.plateforme ?? 'AMAZON';
      _devise = c.devise ?? 'EUR';

      // ✅ Liens multiples — priorité à liensProduits, sinon lienProduit
      final liens = c.liensProduits.isNotEmpty
          ? c.liensProduits
          : (c.lienProduit.isNotEmpty ? [c.lienProduit] : []);
      _lienControllers = liens.isNotEmpty
          ? liens.map((l) => TextEditingController(text: l)).toList()
          : [TextEditingController()];

      // ✅ Photos produit déjà uploadées
      _uploadedPhotoUrls.addAll(c.photosProduits);
    } else {
      // ── Nouveau formulaire : auto-remplissage depuis le profil connecté ──
      final meta = AuthService.userMetadata;
      final user = AuthService.currentUser;
      if (meta != null || user != null) {
        _nomController.text = meta?['nom']?.toString().trim() ?? '';
        _prenomController.text = meta?['prenom']?.toString().trim() ?? '';
        _emailController.text = user?.email?.trim() ?? '';
        _phoneE164 = user?.phone != null ? '+${user!.phone}' : null;
      }
    }

    // ✅ Listeners calcul automatique du total
    _quantiteController.addListener(_recalcTotal);
    _prixUnitaireController.addListener(_recalcTotal);
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _paysLivraisonController.dispose();
    _villeLivraisonController.dispose();
    _adresseLivraisonController.dispose();
    for (final c in _lienControllers) {
      c.dispose();
    }
    _descriptionCommandeController.dispose();
    _quantiteController.dispose();
    _prixUnitaireController.dispose();
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

    // ✅ Valider qu'au moins un lien ou une photo est fourni
    final validLinks = _lienControllers
        .map((c) => c.text.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (validLinks.isEmpty &&
        _pendingPhotos.isEmpty &&
        _uploadedPhotoUrls.isEmpty) {
      Fluttertoast.showToast(
          msg:
              '⚠️ Ajoutez au moins un lien ou une photo de produit.',
          backgroundColor: Colors.orange,
          toastLength: Toast.LENGTH_LONG);
      return;
    }

    setState(() => _isLoading = true);
    try {
      // ✅ Upload des nouvelles photos vers Supabase
      final List<String> newPhotoUrls = [];
      final supa = Supabase.instance.client;
      for (int i = 0; i < _pendingPhotos.length; i++) {
        final file = _pendingPhotos[i];
        final ext = _resolveExt(file);
        final path =
            'commandes/produits/${DateTime.now().millisecondsSinceEpoch}_$i.$ext';
        final bytes = await file.readAsBytes();
        await supa.storage.from('sama-postal').uploadBinary(
              path,
              bytes,
              fileOptions: FileOptions(contentType: 'image/$ext', upsert: true),
            );
        final url = supa.storage.from('sama-postal').getPublicUrl(path);
        newPhotoUrls.add(url);
      }

      final allPhotoUrls = [..._uploadedPhotoUrls, ...newPhotoUrls];

      final qte = int.parse(_quantiteController.text.trim());
      final prix = _parseDecimal(_prixUnitaireController.text) ?? 0;
      final total = _parseDecimal(_prixTotalController.text) ?? 0;

      final data = Commande(
        id: widget.commande?.id,
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        numeroTelephone: _phoneE164!,
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        paysLivraison: _paysLivraisonController.text.trim(),
        villeLivraison: _villeLivraisonController.text.trim(),
        adresseLivraison: _adresseLivraisonController.text.trim(),
        plateforme: _plateforme,
        lienProduit: validLinks.isNotEmpty ? validLinks.first : '',
        liensProduits: validLinks,
        photosProduits: allPhotoUrls,
        descriptionCommande: _descriptionCommandeController.text.trim(),
        quantite: qte,
        prixUnitaire: prix,
        prixTotal: total,
        devise: _devise,
        notesSpeciales: _notesSpecialesController.text.trim().isEmpty
            ? null
            : _notesSpecialesController.text.trim(),
      );
      final result = widget.commande == null
          ? await _service.createCommande(data)
          : await _service.updateCommande(data);
      if (result != null) {
        Fluttertoast.showToast(
            msg: widget.commande == null
                ? '✅ Commande créée !'
                : '✅ Commande modifiée !',
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

  String _resolveExt(XFile file) {
    final name = file.name;
    if (name.contains('.')) {
      final ext = name.split('.').last.toLowerCase();
      if (['jpg', 'jpeg', 'png', 'webp'].contains(ext)) {
        return ext == 'jpeg' ? 'jpg' : ext;
      }
    }
    final mime = file.mimeType ?? '';
    if (mime.contains('jpeg') || mime.contains('jpg')) return 'jpg';
    if (mime.contains('png')) return 'png';
    if (mime.contains('webp')) return 'webp';
    return 'jpg';
  }

  Future<void> _pickProductPhoto() async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (file != null) {
      setState(() => _pendingPhotos.add(file));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.commande != null;
    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        backgroundColor: _appBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(isEdit ? 'Modifier la commande' : 'Nouvelle commande',
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
                        child: _field(
                            _nomController, "Nom", Icons.badge_outlined,
                            hint: "Ex : Diallo", required: true)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _field(
                            _prenomController, "Prénom", Icons.person_outline,
                            hint: "Ex : Fatou", required: true)),
                  ]),
                  const SizedBox(height: 14),
                  // ✅ PhoneInputField avec initialValue depuis le profil
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

                // ── Section 2 : Adresse de livraison ─────────────────────
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
                      if (v.trim().length < 10) return 'Minimum 10 caractères';
                      return null;
                    })),
                  ]),
                ]),

                const SizedBox(height: 16),

                // ── Section 3 : Produit ───────────────────────────────────
                _card(children: [
                  _sectionHeader(Icons.shopping_bag_outlined, _amber, "Produit",
                      "Détails de l'article à commander"),
                  const SizedBox(height: 20),
                  _dropdown(
                      "Site d'achat",
                      _plateforme,
                      _plateformes.map((p) => p).toList(),
                      Icons.store_outlined,
                      (v) => setState(() => _plateforme = v!),
                      displayLabels: _plateformeLabels),
                  const SizedBox(height: 16),

                  // ✅ Liens multiples
                  Row(children: [
                    const Icon(Icons.link, color: _appBlue, size: 18),
                    const SizedBox(width: 8),
                    const Text('Liens des produits',
                        style: TextStyle(
                            color: _textMain,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ]),
                  const SizedBox(height: 8),
                  ...List.generate(_lienControllers.length, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _lienControllers[i],
                              keyboardType: TextInputType.url,
                              style: const TextStyle(
                                  color: _textMain,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14),
                              decoration: InputDecoration(
                                hintText:
                                    'https://www.amazon.fr/produit/...',
                                hintStyle: const TextStyle(
                                    color: Color(0xFFB0BBCC), fontSize: 13),
                                prefixIcon: const Icon(Icons.link,
                                    color: _appBlue, size: 18),
                                filled: true,
                                fillColor: _bgLight,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        const BorderSide(color: _border)),
                                enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        const BorderSide(color: _border)),
                                focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: _appBlue, width: 1.8)),
                                errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: Colors.red)),
                              ),
                            ),
                          ),
                          if (_lienControllers.length > 1)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: InkWell(
                                onTap: () {
                                  final ctrl = _lienControllers[i];
                                  setState(() => _lienControllers.removeAt(i));
                                  ctrl.dispose();
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.close,
                                      color: Colors.red, size: 18),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                  TextButton.icon(
                    onPressed: () => setState(() =>
                        _lienControllers.add(TextEditingController())),
                    icon: const Icon(Icons.add, size: 16, color: _appBlue),
                    label: const Text('Ajouter un lien',
                        style: TextStyle(color: _appBlue, fontSize: 13)),
                  ),

                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // ✅ Photos produit
                  Row(children: [
                    const Icon(Icons.photo_camera_outlined,
                        color: _amber, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                          'Photos des produits (si pas de lien disponible)',
                          style: TextStyle(
                              color: _textMain,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  const Text(
                    'Pour les produits sans lien, ajoutez une photo.',
                    style:
                        TextStyle(color: _textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  if (_uploadedPhotoUrls.isNotEmpty ||
                      _pendingPhotos.isNotEmpty)
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        // Photos déjà uploadées (mode édition)
                        ...List.generate(_uploadedPhotoUrls.length, (i) {
                          return _photoTile(
                            child: Image.network(
                              _uploadedPhotoUrls[i],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.broken_image,
                                      color: _textMuted),
                            ),
                            onRemove: () => setState(
                                () => _uploadedPhotoUrls.removeAt(i)),
                          );
                        }),
                        // Nouvelles photos en attente d'upload
                        ...List.generate(_pendingPhotos.length, (i) {
                          return FutureBuilder<Uint8List>(
                            future: _pendingPhotos[i].readAsBytes(),
                            builder: (ctx, snap) {
                              return _photoTile(
                                child: snap.hasData
                                    ? Image.memory(
                                        snap.data!,
                                        fit: BoxFit.cover)
                                    : const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2)),
                                onRemove: () => setState(
                                    () => _pendingPhotos.removeAt(i)),
                              );
                            },
                          );
                        }),
                      ],
                    ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _pickProductPhoto,
                    icon: const Icon(Icons.add_photo_alternate_outlined,
                        size: 16, color: _amber),
                    label: const Text('Ajouter une photo',
                        style: TextStyle(color: _amber, fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _amber),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),

                  const SizedBox(height: 14),
                  _field(_descriptionCommandeController,
                      "Description du produit", Icons.description_outlined,
                      hint:
                          "Taille, couleur, modèle, référence... soyez précis !",
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
                      final q = int.tryParse(v.trim());
                      return (q == null || q < 1) ? 'Min. 1' : null;
                    })),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _dropdown(
                            "Devise",
                            _devise,
                            _devises,
                            Icons.currency_exchange,
                            (v) => setState(() => _devise = v!))),
                  ]),
                  const SizedBox(height: 14),
                  Row(children: [
                    // ✅ Prix unitaire — virgule acceptée
                    Expanded(
                        child: _decimalField(_prixUnitaireController,
                            "Prix unitaire", Icons.sell_outlined,
                            hint: "Ex : 29,99")),
                    const SizedBox(width: 12),
                    // ✅ Prix total — calculé automatiquement, toujours éditable
                    Expanded(
                        child: _decimalField(_prixTotalController, "Prix total",
                            Icons.calculate_outlined,
                            hint: "Calculé auto",
                            suffix: const Icon(Icons.auto_fix_high,
                                size: 14, color: Color(0xFF22C55E)))),
                  ]),
                ]),

                const SizedBox(height: 16),

                // ── Section 5 : Notes ─────────────────────────────────────
                _card(children: [
                  _sectionHeader(Icons.sticky_note_2_outlined, _textMuted,
                      "Notes", "Informations supplémentaires (optionnel)"),
                  const SizedBox(height: 16),
                  _field(_notesSpecialesController, "Notes spéciales",
                      Icons.notes_outlined,
                      hint: "Ex : Emballage cadeau, livraison urgente...",
                      required: false,
                      maxLines: 3),
                ]),

                const SizedBox(height: 20),

                // ── Bouton soumettre ──────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Icon(
                            isEdit
                                ? Icons.save_outlined
                                : Icons.shopping_cart_checkout,
                            size: 18),
                    label: Text(
                      _isLoading
                          ? "Envoi en cours..."
                          : isEdit
                              ? "Enregistrer les modifications"
                              : "Passer la commande",
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _appBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _isLoading ? null : _submit,
                  ),
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers UI ─────────────────────────────────────────────────────────────

  Widget _card({required List<Widget> children}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );

  Widget _sectionHeader(
          IconData icon, Color color, String title, String subtitle) =>
      Row(children: [
        Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  color: _textMain, fontWeight: FontWeight.w800, fontSize: 15)),
          Text(subtitle,
              style: const TextStyle(
                  color: _textMuted,
                  fontWeight: FontWeight.w400,
                  fontSize: 12)),
        ]),
      ]);

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    String? hint,
    bool required = true,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(
          color: _textMain, fontWeight: FontWeight.w500, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(
            color: _textMuted, fontWeight: FontWeight.w500, fontSize: 14),
        hintStyle: const TextStyle(color: Color(0xFFB0BBCC), fontSize: 13),
        prefixIcon: Icon(icon, color: _appBlue, size: 18),
        filled: true,
        fillColor: _bgLight,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _appBlue, width: 1.8)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red)),
      ),
      validator: validator ??
          (required
              ? (v) =>
                  (v == null || v.trim().isEmpty) ? 'Ce champ est requis' : null
              : null),
    );
  }

  // ✅ Champ numérique décimal : accepte virgule ET point, valide les deux
  Widget _decimalField(
    TextEditingController controller,
    String label,
    IconData icon, {
    String? hint,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      // ✅ Autorise chiffres, point, virgule uniquement
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      style: const TextStyle(
          color: _textMain, fontWeight: FontWeight.w500, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(
            color: _textMuted, fontWeight: FontWeight.w500, fontSize: 14),
        hintStyle: const TextStyle(color: Color(0xFFB0BBCC), fontSize: 13),
        prefixIcon: Icon(icon, color: _appBlue, size: 18),
        suffixIcon: suffix,
        filled: true,
        fillColor: _bgLight,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _appBlue, width: 1.8)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red)),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Requis';
        final p = _parseDecimal(v);
        return (p == null || p <= 0) ? 'Invalide' : null;
      },
    );
  }

  Widget _dropdown(
    String label,
    String value,
    List<String> items,
    IconData icon,
    Function(String?) onChanged, {
    Map<String, String>? displayLabels,
  }) {
    final safeValue = items.contains(value) ? value : items.first;
    return DropdownButtonFormField<String>(
      value: safeValue,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
            color: _textMuted, fontWeight: FontWeight.w500, fontSize: 14),
        prefixIcon: Icon(icon, color: _appBlue, size: 18),
        filled: true,
        fillColor: _bgLight,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _appBlue, width: 1.8)),
      ),
      style: const TextStyle(
          color: _textMain, fontWeight: FontWeight.w500, fontSize: 14),
      dropdownColor: _surface,
      borderRadius: BorderRadius.circular(12),
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(displayLabels?[item] ?? item,
                    style: const TextStyle(color: _textMain)),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _photoTile({required Widget child, required VoidCallback onRemove}) {
    return Stack(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _border),
            color: _bgLight,
          ),
          clipBehavior: Clip.antiAlias,
          child: child,
        ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}
