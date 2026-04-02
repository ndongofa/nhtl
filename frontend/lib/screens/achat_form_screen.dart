// lib/screens/achat_form_screen.dart
//
// Formulaire de création / modification d'un achat sur mesure.
// Supporte un formulaire multi-articles (liens et/ou photos)
// identique à commande_form_screen.dart.

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/achat.dart';
import '../models/article_item.dart';
import '../services/achat_service.dart';
import '../services/auth_service.dart';
import '../widgets/phone_input_field.dart';

// ── Classe interne représentant un article en cours d'édition ──────────────

class _ArticleForm {
  String type; // 'lien' ou 'photo'
  final TextEditingController lienCtrl;
  final TextEditingController quantiteCtrl;
  final TextEditingController prixUnitaireCtrl;
  final TextEditingController prixTotalCtrl;
  final TextEditingController titreCtrl;
  final TextEditingController descriptionCtrl;
  XFile? pendingPhoto;
  String? uploadedPhotoUrl;

  _ArticleForm({
    this.type = 'lien',
    String lien = '',
    String quantite = '1',
    String prixUnitaire = '',
    String prixTotal = '',
    String titre = '',
    String description = '',
    this.pendingPhoto,
    this.uploadedPhotoUrl,
  })  : lienCtrl = TextEditingController(text: lien),
        quantiteCtrl = TextEditingController(text: quantite),
        prixUnitaireCtrl = TextEditingController(text: prixUnitaire),
        prixTotalCtrl = TextEditingController(text: prixTotal),
        titreCtrl = TextEditingController(text: titre),
        descriptionCtrl = TextEditingController(text: description);

  bool get hasPhoto =>
      pendingPhoto != null || (uploadedPhotoUrl?.isNotEmpty ?? false);

  void dispose() {
    lienCtrl.dispose();
    quantiteCtrl.dispose();
    prixUnitaireCtrl.dispose();
    prixTotalCtrl.dispose();
    titreCtrl.dispose();
    descriptionCtrl.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class AchatFormScreen extends StatefulWidget {
  final Achat? achat;
  const AchatFormScreen({Key? key, this.achat}) : super(key: key);

  @override
  State<AchatFormScreen> createState() => _AchatFormScreenState();
}

class _AchatFormScreenState extends State<AchatFormScreen> {
  static const Color _appBlue = Color(0xFF2296F3);
  static const Color _bgLight = Color(0xFFF4F8FF);
  static const Color _surface = Colors.white;
  static const Color _textMain = Color(0xFF0F2040);
  static const Color _textMuted = Color(0xFF6B7A99);
  static const Color _border = Color(0xFFDDE3EF);
  static const Color _amber = Color(0xFFFFB300);
  static const Color _teal = Color(0xFF00BCD4);
  static const Color _green = Color(0xFF22C55E);
  static const Color _red = Color(0xFFEF4444);

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
  final _notesSpecialesController = TextEditingController();

  String? _phoneE164;
  String _typeProduit = 'TISSUS';
  String _devise = 'EUR';

  // ✅ Liste des articles
  final List<_ArticleForm> _articles = [];

  final _imagePicker = ImagePicker();

  static const List<String> _typesProduits = [
    'TISSUS', 'BIJOUX', 'ALIMENTAIRE', 'ARTISANAT', 'MEDICAMENTS',
    'HIGH_TECH', 'VETEMENTS', 'CHAUSSURES', 'DECORATION', 'AUTRE',
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

  void _recalcArticleTotal(_ArticleForm art) {
    final q = _parseDecimal(art.quantiteCtrl.text);
    final p = _parseDecimal(art.prixUnitaireCtrl.text);
    if (q != null && p != null && q > 0 && p > 0) {
      final total = q * p;
      final formatted = total == total.truncateToDouble()
          ? total.toInt().toString()
          : total.toStringAsFixed(2);
      if (art.prixTotalCtrl.text != formatted) {
        art.prixTotalCtrl.text = formatted;
        art.prixTotalCtrl.selection =
            TextSelection.fromPosition(TextPosition(offset: formatted.length));
      }
    }
    if (mounted) setState(() {});
  }

  int get _totalArticlesCount {
    int count = 0;
    for (final art in _articles) {
      if (art.type == 'lien') {
        count += (int.tryParse(art.quantiteCtrl.text.trim()) ?? 0).clamp(0, 9999);
      } else {
        count += 1;
      }
    }
    return count;
  }

  double get _globalTotal {
    double total = 0.0;
    for (final art in _articles) {
      if (art.type == 'lien') {
        total += _parseDecimal(art.prixTotalCtrl.text) ?? 0.0;
      }
    }
    return total;
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
      _notesSpecialesController.text = a.notesSpeciales ?? '';
      _typeProduit = a.typeProduit.isNotEmpty ? a.typeProduit : 'TISSUS';
      _devise = a.devise.isNotEmpty ? a.devise : 'EUR';

      // ✅ Priorité à articlesJson
      if (a.articlesJson != null && a.articlesJson!.isNotEmpty) {
        try {
          final List<dynamic> raw = jsonDecode(a.articlesJson!);
          for (final item in raw) {
            final ai = ArticleItem.fromJson(item as Map<String, dynamic>);
            final form = _ArticleForm(
              type: ai.type,
              lien: ai.lien,
              quantite: ai.quantite.toString(),
              prixUnitaire: ai.prixUnitaire > 0 ? ai.prixUnitaire.toString() : '',
              prixTotal: ai.prixTotal > 0 ? ai.prixTotal.toString() : '',
              titre: ai.titre,
              description: ai.description,
              uploadedPhotoUrl: ai.photoUrl.isNotEmpty ? ai.photoUrl : null,
            );
            _addArticleListeners(form);
            _articles.add(form);
          }
        } catch (_) {}
      }

      // Fallback format héritage
      if (_articles.isEmpty) {
        for (final lien in a.liensProduits) {
          final form = _ArticleForm(
            type: 'lien',
            lien: lien,
            quantite: a.quantite > 0 ? a.quantite.toString() : '1',
            prixUnitaire: a.prixEstime > 0 ? a.prixEstime.toString() : '',
            prixTotal: a.prixTotal > 0 ? a.prixTotal.toString() : '',
          );
          _addArticleListeners(form);
          _articles.add(form);
        }
        for (final photoUrl in a.photosProduits) {
          final form = _ArticleForm(
            type: 'photo',
            uploadedPhotoUrl: photoUrl,
            description: a.descriptionAchat,
          );
          _articles.add(form);
        }
        // Si pas de lien/photo, créer un article depuis la description
        if (_articles.isEmpty && a.descriptionAchat.isNotEmpty) {
          final form = _ArticleForm(
            type: 'photo',
            description: a.descriptionAchat,
            titre: '',
          );
          _articles.add(form);
        }
      }
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

    if (_articles.isEmpty) {
      _addNewArticle();
    }
  }

  void _addArticleListeners(_ArticleForm form) {
    form.quantiteCtrl.addListener(() => _recalcArticleTotal(form));
    form.prixUnitaireCtrl.addListener(() => _recalcArticleTotal(form));
  }

  void _addNewArticle({String type = 'lien'}) {
    final form = _ArticleForm(type: type);
    _addArticleListeners(form);
    setState(() => _articles.add(form));
  }

  void _removeArticle(int index) {
    setState(() {
      _articles[index].dispose();
      _articles.removeAt(index);
      if (_articles.isEmpty) {
        final form = _ArticleForm();
        _addArticleListeners(form);
        _articles.add(form);
      }
    });
  }

  Future<void> _pickPhotoForArticle(_ArticleForm art) async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (file != null) {
      setState(() => art.pendingPhoto = file);
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_phoneE164 == null || _phoneE164!.isEmpty) {
      Fluttertoast.showToast(
          msg: 'Veuillez entrer un numéro de téléphone valide.',
          backgroundColor: Colors.red,
          toastLength: Toast.LENGTH_LONG);
      return;
    }

    bool hasValidArticle = false;
    for (final art in _articles) {
      if (art.type == 'lien' && art.lienCtrl.text.trim().isNotEmpty) {
        hasValidArticle = true;
        break;
      }
      if (art.type == 'photo' && art.hasPhoto) {
        hasValidArticle = true;
        break;
      }
      // Article photo sans photo mais avec titre/description
      if (art.type == 'photo' &&
          (art.titreCtrl.text.trim().isNotEmpty ||
              art.descriptionCtrl.text.trim().isNotEmpty)) {
        hasValidArticle = true;
        break;
      }
    }
    if (!hasValidArticle) {
      Fluttertoast.showToast(
          msg: '⚠️ Ajoutez au moins un article (lien ou photo).',
          backgroundColor: Colors.orange,
          toastLength: Toast.LENGTH_LONG);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final supa = Supabase.instance.client;
      final List<ArticleItem> finalArticles = [];

      for (final art in _articles) {
        if (art.type == 'lien') {
          final lien = art.lienCtrl.text.trim();
          if (lien.isEmpty) continue;
          final q = int.tryParse(art.quantiteCtrl.text.trim()) ?? 1;
          final pu = _parseDecimal(art.prixUnitaireCtrl.text) ?? 0.0;
          final pt = _parseDecimal(art.prixTotalCtrl.text) ?? 0.0;
          finalArticles.add(ArticleItem(
            type: 'lien',
            lien: lien,
            quantite: q,
            prixUnitaire: pu,
            prixTotal: pt,
          ));
        } else {
          String photoUrl = art.uploadedPhotoUrl ?? '';
          if (art.pendingPhoto != null) {
            final file = art.pendingPhoto!;
            final ext = _resolveExt(file);
            final path =
                'achats/produits/${DateTime.now().millisecondsSinceEpoch}_${_articles.indexOf(art)}.$ext';
            final bytes = await file.readAsBytes();
            await supa.storage.from('sama-postal').uploadBinary(
                  path,
                  bytes,
                  fileOptions: FileOptions(contentType: 'image/$ext', upsert: true),
                );
            photoUrl = supa.storage.from('sama-postal').getPublicUrl(path);
          }
          final titre = art.titreCtrl.text.trim();
          final desc = art.descriptionCtrl.text.trim();
          // Inclure si au moins un champ est rempli
          if (photoUrl.isEmpty && titre.isEmpty && desc.isEmpty) continue;
          finalArticles.add(ArticleItem(
            type: 'photo',
            photoUrl: photoUrl,
            titre: titre,
            description: desc,
          ));
        }
      }

      if (finalArticles.isEmpty) {
        Fluttertoast.showToast(
            msg: '⚠️ Ajoutez au moins un article valide.',
            backgroundColor: Colors.orange,
            toastLength: Toast.LENGTH_LONG);
        setState(() => _isLoading = false);
        return;
      }

      final lienArticles = finalArticles.where((a) => a.isLien).toList();
      final photoArticles = finalArticles.where((a) => a.isPhoto).toList();
      final allLinks = lienArticles.map((a) => a.lien).toList();
      final allPhotos = photoArticles.map((a) => a.photoUrl).toList();
      final totalQte = lienArticles.fold<int>(0, (s, a) => s + a.quantite);
      final totalPrice = finalArticles.fold<double>(0.0, (s, a) => s + a.prixTotal);

      final descParts = <String>[];
      for (final a in finalArticles) {
        if (a.isLien) {
          descParts.add('Lien: ${a.lien}');
        } else if (a.titre.isNotEmpty) {
          descParts.add(a.titre);
        } else if (a.description.isNotEmpty) {
          descParts.add(a.description);
        }
      }
      final descAchat = descParts.isNotEmpty ? descParts.join(' | ') : 'Articles';
      final articlesJson = jsonEncode(finalArticles.map((a) => a.toJson()).toList());
      final prixEstime =
          lienArticles.isNotEmpty ? lienArticles.first.prixUnitaire : 0.0;

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
        descriptionAchat: descAchat,
        liensProduits: allLinks,
        photosProduits: allPhotos,
        articlesJson: articlesJson,
        quantite: totalQte > 0 ? totalQte : finalArticles.length,
        prixEstime: prixEstime,
        prixTotal: totalPrice,
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
        if (mounted) Navigator.pop(context, true);
      } else {
        Fluttertoast.showToast(
            msg: '❌ Une erreur est survenue.', backgroundColor: Colors.red);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: '❌ Erreur : $e', backgroundColor: Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
    _notesSpecialesController.dispose();
    for (final art in _articles) {
      art.dispose();
    }
    super.dispose();
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
        title: Text(isEdit ? "Modifier l'achat" : "Nouvelle demande d'achat",
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
                  _sectionHeader(Icons.person_outline, _teal, "Destinataire",
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

                // ── Section 3 : Produit (Marché + Type) ──────────────────
                _card(children: [
                  _sectionHeader(Icons.storefront_outlined, _amber,
                      "Produit", "Catégorie et lieu d'achat"),
                  const SizedBox(height: 20),
                  _dropdown("Type de produit", _typeProduit, _typesProduits,
                      Icons.category_outlined,
                      (v) => setState(() => _typeProduit = v!),
                      displayLabels: _typesProduitLabels),
                  const SizedBox(height: 14),
                  _field(_marcheController, "Marché / Boutique cible",
                      Icons.store_outlined,
                      hint: "Ex : Marché Sandaga, Grand Yoff, Boutique XYZ...",
                      required: true),
                ]),

                const SizedBox(height: 16),

                // ── Section 4 : Articles ──────────────────────────────────
                _card(children: [
                  _sectionHeader(Icons.shopping_bag_outlined, _amber,
                      "Articles",
                      "Ajoutez vos articles (liens et/ou photos)"),
                  const SizedBox(height: 16),
                  ...List.generate(_articles.length,
                      (i) => _buildArticleCard(i)),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _addNewArticle(),
                      icon: const Icon(Icons.add, size: 16, color: _teal),
                      label: const Text('Ajouter un article',
                          style: TextStyle(color: _teal, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _teal),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ]),

                const SizedBox(height: 16),

                // ── Section 5 : Récapitulatif ─────────────────────────────
                _buildSummaryCard(),

                const SizedBox(height: 16),

                // ── Section 6 : Notes ─────────────────────────────────────
                _card(children: [
                  _sectionHeader(Icons.notes_outlined, _textMuted, "Notes",
                      "Informations complémentaires"),
                  const SizedBox(height: 20),
                  _field(_notesSpecialesController,
                      "Notes spéciales (optionnel)", Icons.comment_outlined,
                      hint: "Urgence, préférences de livraison, budget max...",
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
                            isEdit
                                ? 'Enregistrer les modifications'
                                : 'Envoyer ma demande',
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

  // ── Article card ──────────────────────────────────────────────────────────

  Widget _buildArticleCard(int index) {
    final art = _articles[index];
    final isLien = art.type == 'lien';
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _bgLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isLien
                  ? _teal.withValues(alpha: 0.08)
                  : _amber.withValues(alpha: 0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Text('Article ${index + 1}',
                    style: const TextStyle(
                        color: _textMain,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
                const SizedBox(width: 12),
                _typeToggle(art),
                const Spacer(),
                if (_articles.length > 1)
                  GestureDetector(
                    onTap: () => _removeArticle(index),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _red.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.close, color: _red, size: 16),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: isLien
                ? _buildLienContent(art)
                : _buildPhotoContent(art),
          ),
        ],
      ),
    );
  }

  Widget _typeToggle(_ArticleForm art) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _typeBtn('🔗 Lien', art.type == 'lien',
              () => setState(() => art.type = 'lien')),
          _typeBtn('📷 Photo', art.type == 'photo',
              () => setState(() => art.type = 'photo')),
        ],
      ),
    );
  }

  Widget _typeBtn(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? _teal : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(label,
            style: TextStyle(
                color: active ? Colors.white : _textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildLienContent(_ArticleForm art) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: art.lienCtrl,
          keyboardType: TextInputType.url,
          style: const TextStyle(
              color: _textMain, fontWeight: FontWeight.w500, fontSize: 14),
          decoration: InputDecoration(
            labelText: 'Lien du produit',
            hintText: 'https://...',
            prefixIcon: const Icon(Icons.link, color: _teal, size: 18),
            hintStyle: const TextStyle(color: Color(0xFFB0BBCC), fontSize: 13),
            labelStyle: const TextStyle(color: _textMuted, fontSize: 13),
            filled: true,
            fillColor: _surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _teal, width: 1.8)),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _red)),
          ),
          validator: (v) {
            if (art.type == 'lien' && (v == null || v.trim().isEmpty)) {
              return 'URL requise';
            }
            return null;
          },
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _articleDecimalField(art.quantiteCtrl, "Quantité",
                  Icons.add_box_outlined, hint: "1", isInt: true),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _articleDecimalField(art.prixUnitaireCtrl, "Prix estimé / unité",
                  Icons.price_change_outlined,
                  hint: "Ex : 15.50"),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _green.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _green.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.calculate_outlined, color: _green, size: 16),
              const SizedBox(width: 8),
              const Text('Sous-total : ',
                  style: TextStyle(color: _textMuted, fontSize: 13)),
              Text(
                art.prixTotalCtrl.text.isNotEmpty
                    ? '${art.prixTotalCtrl.text} $_devise'
                    : '—',
                style: const TextStyle(
                    color: _green,
                    fontWeight: FontWeight.w700,
                    fontSize: 13),
              ),
              const Spacer(),
              const Icon(Icons.auto_fix_high, size: 12, color: _green),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoContent(_ArticleForm art) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _pickPhotoForArticle(art),
          child: _buildPhotoArea(art),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: art.titreCtrl,
          style: const TextStyle(
              color: _textMain, fontWeight: FontWeight.w500, fontSize: 14),
          decoration: InputDecoration(
            labelText: 'Titre du produit',
            hintText: 'Ex : Pagne wax 6 yards',
            prefixIcon: const Icon(Icons.title, color: _amber, size: 18),
            hintStyle: const TextStyle(color: Color(0xFFB0BBCC), fontSize: 13),
            labelStyle: const TextStyle(color: _textMuted, fontSize: 13),
            filled: true,
            fillColor: _surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _amber, width: 1.8)),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _red)),
          ),
          validator: (v) {
            if (art.type == 'photo') {
              if (v == null || v.trim().isEmpty) return 'Titre requis';
            }
            return null;
          },
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: art.descriptionCtrl,
          maxLines: 3,
          style: const TextStyle(
              color: _textMain, fontWeight: FontWeight.w500, fontSize: 14),
          decoration: InputDecoration(
            labelText: 'Description',
            hintText: 'Couleur, taille, quantité exacte... Soyez précis !',
            prefixIcon:
                const Icon(Icons.description_outlined, color: _amber, size: 18),
            hintStyle: const TextStyle(color: Color(0xFFB0BBCC), fontSize: 13),
            labelStyle: const TextStyle(color: _textMuted, fontSize: 13),
            filled: true,
            fillColor: _surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _amber, width: 1.8)),
          ),
          validator: (v) {
            if (art.type == 'photo') {
              if (v == null || v.trim().isEmpty) return 'Description requise';
              if (v.trim().length < 5) return 'Minimum 5 caractères';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPhotoArea(_ArticleForm art) {
    final hasPhoto = art.hasPhoto;
    Widget content;
    if (art.pendingPhoto != null) {
      content = FutureBuilder<Uint8List>(
        future: art.pendingPhoto!.readAsBytes(),
        builder: (ctx, snap) {
          if (snap.hasData) {
            return Image.memory(snap.data!,
                fit: BoxFit.cover, width: double.infinity, height: 130);
          }
          return const Center(
              child: CircularProgressIndicator(strokeWidth: 2));
        },
      );
    } else if (art.uploadedPhotoUrl != null &&
        art.uploadedPhotoUrl!.isNotEmpty) {
      content = Image.network(art.uploadedPhotoUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: 130,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.broken_image, color: _textMuted));
    } else {
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.add_photo_alternate_outlined, color: _amber, size: 32),
          SizedBox(height: 6),
          Text('Appuyer pour ajouter une photo (optionnel)',
              style: TextStyle(color: _textMuted, fontSize: 12)),
        ],
      );
    }

    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: hasPhoto ? 130 : 80,
          decoration: BoxDecoration(
            color: _amber.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: hasPhoto ? _amber : _border),
          ),
          clipBehavior: Clip.antiAlias,
          child: content,
        ),
        if (hasPhoto)
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: () => setState(() {
                art.pendingPhoto = null;
                art.uploadedPhotoUrl = null;
              }),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
      ],
    );
  }

  // ── Summary card ──────────────────────────────────────────────────────────

  Widget _buildSummaryCard() {
    final total = _globalTotal;
    final count = _totalArticlesCount;
    final formatted = total == total.truncateToDouble()
        ? total.toInt().toString()
        : total.toStringAsFixed(2);

    return _card(children: [
      _sectionHeader(Icons.receipt_long_outlined, _green, "Récapitulatif",
          "Total calculé automatiquement"),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(
          child: _summaryTile(
            icon: Icons.inventory_2_outlined,
            label: "Nombre d'articles",
            value: '$count article${count > 1 ? 's' : ''}',
            color: _teal,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryTile(
            icon: Icons.payments_outlined,
            label: 'Total estimé',
            value: total > 0 ? '$formatted $_devise' : '—',
            color: _green,
          ),
        ),
      ]),
      const SizedBox(height: 14),
      _deviseDropdown(),
    ]);
  }

  Widget _summaryTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: _textMuted, fontSize: 11)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w800, fontSize: 14)),
        ],
      ),
    );
  }

  // ── Helpers UI ─────────────────────────────────────────────────────────────

  Widget _card({required List<Widget> children}) => Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _surface,
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

  Widget _articleDecimalField(
    TextEditingController controller,
    String label,
    IconData icon, {
    String? hint,
    bool isInt = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isInt
          ? TextInputType.number
          : const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
            isInt ? RegExp(r'[0-9]') : RegExp(r'[0-9.,]')),
      ],
      style: const TextStyle(
          color: _textMain, fontWeight: FontWeight.w500, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(
            color: _textMuted, fontWeight: FontWeight.w500, fontSize: 14),
        hintStyle: const TextStyle(color: Color(0xFFB0BBCC), fontSize: 13),
        prefixIcon: Icon(icon, color: _teal, size: 18),
        filled: true,
        fillColor: _surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _teal, width: 1.8)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _red)),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Requis';
        if (isInt) {
          final n = int.tryParse(v.trim());
          return (n == null || n < 1) ? 'Min 1' : null;
        }
        final p = _parseDecimal(v);
        return (p == null || p <= 0) ? 'Nombre invalide' : null;
      },
    );
  }

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
                  child: Text(d, style: TextStyle(color: _textMain, fontSize: 14)),
                ))
            .toList(),
        onChanged: (v) => setState(() => _devise = v!),
      );
}
