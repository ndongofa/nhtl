// lib/screens/commande_form_screen.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/commande.dart';
import '../models/article_item.dart';
import '../services/commande_service.dart';
import '../services/auth_service.dart';
import '../widgets/phone_input_field.dart';
import '../widgets/sama_account_menu.dart';

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
  static const Color _red = Color(0xFFEF4444);
  static const int _maxArticleQuantity = 9999;

  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _service = CommandeService();
  bool _isLoading = false;

  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _paysLivraisonController = TextEditingController();
  final _villeLivraisonController = TextEditingController();
  final _adresseLivraisonController = TextEditingController();
  final _notesSpecialesController = TextEditingController();

  String? _phoneE164;
  String _plateforme = 'AMAZON';
  String _devise = 'EUR';

  // ✅ Liste des articles (formulaire multi-articles)
  final List<_ArticleForm> _articles = [];

  final _imagePicker = ImagePicker();

  static const List<String> _plateformes = [
    'AMAZON', 'TEMU', 'SHEIN', 'ALIEXPRESS', 'EBAY', 'ETSY', 'AUTRE'
  ];
  static const List<String> _devises = ['EUR', 'USD', 'GBP', 'MAD', 'XOF', 'CAD'];
  static const Map<String, String> _plateformeLabels = {
    'AMAZON': '📦 Amazon',
    'TEMU': '🛍️ Temu',
    'SHEIN': '👗 Shein',
    'ALIEXPRESS': '🛒 AliExpress',
    'EBAY': '🏷️ eBay',
    'ETSY': '🎨 Etsy',
    'AUTRE': '🌐 Autre site',
  };

  double? _parseDecimal(String raw) =>
      double.tryParse(raw.trim().replaceAll(',', '.'));

  // ✅ Recalcule le sous-total d'un article lien
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

  // ✅ Nombre total d'articles
  int get _totalArticlesCount {
    int count = 0;
    for (final art in _articles) {
      if (art.type == 'lien') {
        count += (int.tryParse(art.quantiteCtrl.text.trim()) ?? 0).clamp(0, _maxArticleQuantity);
      } else {
        count += 1;
      }
    }
    return count;
  }

  // ✅ Total global (somme des sous-totaux des articles lien)
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
    final c = widget.commande;
    if (c != null) {
      // ── Mode édition ────────────────────────────────────────────
      _nomController.text = c.nom;
      _prenomController.text = c.prenom;
      _phoneE164 = c.numeroTelephone;
      _emailController.text = c.email ?? '';
      _paysLivraisonController.text = c.paysLivraison;
      _villeLivraisonController.text = c.villeLivraison;
      _adresseLivraisonController.text = c.adresseLivraison;
      _notesSpecialesController.text = c.notesSpeciales ?? '';
      _plateforme = c.plateforme.isNotEmpty ? c.plateforme : 'AMAZON';
      _devise = c.devise.isNotEmpty ? c.devise : 'EUR';

      // ✅ Priorité à articlesJson (nouveau format)
      if (c.articlesJson != null && c.articlesJson!.isNotEmpty) {
        try {
          final List<dynamic> raw = jsonDecode(c.articlesJson!);
          for (final item in raw) {
            final a = ArticleItem.fromJson(item as Map<String, dynamic>);
            final form = _ArticleForm(
              type: a.type,
              lien: a.lien,
              quantite: a.quantite.toString(),
              prixUnitaire: a.prixUnitaire > 0 ? a.prixUnitaire.toString() : '',
              prixTotal: a.prixTotal > 0 ? a.prixTotal.toString() : '',
              titre: a.titre,
              description: a.description,
              uploadedPhotoUrl: a.photoUrl.isNotEmpty ? a.photoUrl : null,
            );
            _addArticleListeners(form);
            _articles.add(form);
          }
        } catch (_) {}
      }

      // ✅ Fallback : format héritage (liensProduits / photosProduits)
      if (_articles.isEmpty) {
        final liens = c.liensProduits.isNotEmpty
            ? c.liensProduits
            : (c.lienProduit.isNotEmpty ? [c.lienProduit] : []);
        for (final lien in liens) {
          final form = _ArticleForm(
            type: 'lien',
            lien: lien,
            quantite: c.quantite > 0 ? c.quantite.toString() : '1',
            prixUnitaire: c.prixUnitaire > 0 ? c.prixUnitaire.toString() : '',
            prixTotal: c.prixTotal > 0 ? c.prixTotal.toString() : '',
          );
          _addArticleListeners(form);
          _articles.add(form);
        }
        for (final photoUrl in c.photosProduits) {
          final form = _ArticleForm(
            type: 'photo',
            uploadedPhotoUrl: photoUrl,
            description: c.descriptionCommande,
          );
          _articles.add(form);
        }
      }
    } else {
      // ── Nouveau formulaire : auto-remplissage profil ─────────────
      final meta = AuthService.userMetadata;
      final user = AuthService.currentUser;
      if (meta != null || user != null) {
        _nomController.text = meta?['nom']?.toString().trim() ?? '';
        _prenomController.text = meta?['prenom']?.toString().trim() ?? '';
        _emailController.text = user?.email?.trim() ?? '';
        _phoneE164 = user?.phone != null ? '+${user!.phone}' : null;
      }
    }

    // Ajouter un article vide si la liste est vide
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
    final formValid = _formKey.currentState!.validate();
    final errors = _collectErrors();

    if (!formValid || errors.isNotEmpty) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
      _showValidationDialog(errors.isNotEmpty
          ? errors
          : ['Veuillez corriger les champs indiqués en rouge.']);
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
          // Article photo : upload si en attente
          String photoUrl = art.uploadedPhotoUrl ?? '';
          if (art.pendingPhoto != null) {
            final file = art.pendingPhoto!;
            final ext = _resolveExt(file);
            final path =
                'commandes/produits/${DateTime.now().millisecondsSinceEpoch}_${_articles.indexOf(art)}.$ext';
            final bytes = await file.readAsBytes();
            await supa.storage.from('sama-postal').uploadBinary(
                  path,
                  bytes,
                  fileOptions: FileOptions(contentType: 'image/$ext', upsert: true),
                );
            photoUrl = supa.storage.from('sama-postal').getPublicUrl(path);
          }
          if (photoUrl.isEmpty) continue;
          finalArticles.add(ArticleItem(
            type: 'photo',
            photoUrl: photoUrl,
            titre: art.titreCtrl.text.trim(),
            description: art.descriptionCtrl.text.trim(),
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

      // ✅ Dériver les champs hérités depuis la liste d'articles
      final lienArticles = finalArticles.where((a) => a.isLien).toList();
      final photoArticles = finalArticles.where((a) => a.isPhoto).toList();
      final allLinks = lienArticles.map((a) => a.lien).toList();
      final allPhotos = photoArticles.map((a) => a.photoUrl).toList();
      final totalQte = lienArticles.fold<int>(0, (s, a) => s + a.quantite);
      final totalPrice = finalArticles.fold<double>(0.0, (s, a) => s + a.prixTotal);

      // Description synthétique pour l'admin
      final descParts = <String>[];
      for (final a in finalArticles) {
        if (a.isLien && a.lien.isNotEmpty) {
          descParts.add('Lien: ${a.lien}');
        } else if (a.isPhoto && a.titre.isNotEmpty) {
          descParts.add(a.titre);
        }
      }
      final descCommande = descParts.isNotEmpty ? descParts.join(' | ') : 'Articles';
      final articlesJson = jsonEncode(finalArticles.map((a) => a.toJson()).toList());

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
        lienProduit: allLinks.isNotEmpty ? allLinks.first : '',
        liensProduits: allLinks,
        photosProduits: allPhotos,
        articlesJson: articlesJson,
        descriptionCommande: descCommande,
        quantite: _totalArticlesCount > 0 ? _totalArticlesCount : finalArticles.length,
        prixUnitaire:
            lienArticles.isNotEmpty ? lienArticles.first.prixUnitaire : 0.0,
        prixTotal: totalPrice,
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

  // ✅ Collecte toutes les erreurs de validation en langage clair
  List<String> _collectErrors() {
    final errors = <String>[];

    if (_nomController.text.trim().isEmpty) errors.add('Le nom est requis');
    if (_prenomController.text.trim().isEmpty) errors.add('Le prénom est requis');
    if (_phoneE164 == null || _phoneE164!.isEmpty) {
      errors.add('Un numéro de téléphone valide est requis');
    }
    if (_emailController.text.trim().isNotEmpty &&
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
            .hasMatch(_emailController.text.trim())) {
      errors.add("L'adresse email est invalide");
    }
    if (_paysLivraisonController.text.trim().isEmpty) {
      errors.add('Le pays de livraison est requis');
    }
    if (_villeLivraisonController.text.trim().isEmpty) {
      errors.add('La ville de livraison est requise');
    }
    if (_adresseLivraisonController.text.trim().isEmpty) {
      errors.add("L'adresse complète est requise");
    } else if (_adresseLivraisonController.text.trim().length < 5) {
      errors.add("L'adresse complète doit contenir au moins 5 caractères");
    }

    bool hasValidArticle = false;
    for (int i = 0; i < _articles.length; i++) {
      final art = _articles[i];
      final n = i + 1;
      if (art.type == 'lien') {
        if (art.lienCtrl.text.trim().isNotEmpty) {
          hasValidArticle = true;
          final q = int.tryParse(art.quantiteCtrl.text.trim());
          if (q == null || q < 1) {
            errors.add('Article $n : la quantité doit être au moins 1');
          }
          if (art.prixUnitaireCtrl.text.trim().isNotEmpty) {
            final p = _parseDecimal(art.prixUnitaireCtrl.text);
            if (p == null || p <= 0) {
              errors.add('Article $n : le prix unitaire est invalide');
            }
          }
        }
      } else {
        if (art.hasPhoto || art.titreCtrl.text.trim().isNotEmpty) {
          hasValidArticle = true;
          if (art.titreCtrl.text.trim().isEmpty) {
            errors.add('Article $n (photo) : le titre est requis');
          }
          if (art.descriptionCtrl.text.trim().isEmpty) {
            errors.add('Article $n (photo) : la description est requise');
          } else if (art.descriptionCtrl.text.trim().length < 5) {
            errors
                .add('Article $n (photo) : la description est trop courte (min 5 caractères)');
          }
        }
      }
    }
    if (!hasValidArticle) {
      errors.add('Ajoutez au moins un article valide (lien ou photo)');
    }

    return errors;
  }

  // ✅ Affiche un dialogue récapitulatif des erreurs de validation
  void _showValidationDialog(List<String> errors) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: _amber),
          SizedBox(width: 8),
          Text('Corrections requises',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        ]),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Veuillez corriger les points suivants avant de soumettre :',
                style: TextStyle(color: _textMuted, fontSize: 13),
              ),
              const SizedBox(height: 12),
              ...errors.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ',
                            style: TextStyle(
                                color: _red, fontWeight: FontWeight.w700)),
                        Expanded(
                            child: Text(e,
                                style: const TextStyle(
                                    fontSize: 13, color: _textMain))),
                      ],
                    ),
                  )),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: _appBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('OK, je corrige'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _paysLivraisonController.dispose();
    _villeLivraisonController.dispose();
    _adresseLivraisonController.dispose();
    _notesSpecialesController.dispose();
    for (final art in _articles) {
      art.dispose();
    }
    super.dispose();
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
        actions: [
          IconButton(
            tooltip: "Mon espace",
            onPressed: () => SamaAccountMenu.open(context),
            icon: const Icon(Icons.dashboard_outlined, color: Colors.white),
          ),
          IconButton(
            tooltip: "Déconnexion",
            onPressed: () async {
              await AuthService.logout();
              if (!context.mounted) return;
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/', (_) => false);
            },
            icon: const Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          controller: _scrollController,
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
                      if (v.trim().length < 5) return 'Minimum 5 caractères';
                      return null;
                    })),
                  ]),
                ]),

                const SizedBox(height: 16),

                // ── Section 3 : Plateforme ────────────────────────────────
                _card(children: [
                  _sectionHeader(Icons.store_outlined, _appBlue, "Plateforme",
                      "Sur quel site souhaitez-vous commander ?"),
                  const SizedBox(height: 16),
                  _dropdown(
                      "Site d'achat",
                      _plateforme,
                      _plateformes,
                      Icons.store_outlined,
                      (v) => setState(() => _plateforme = v!),
                      displayLabels: _plateformeLabels),
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
                      icon: const Icon(Icons.add, size: 16, color: _appBlue),
                      label: const Text('Ajouter un article',
                          style: TextStyle(color: _appBlue, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _appBlue),
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
          // ── En-tête : numéro + type toggle + supprimer ──────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isLien
                  ? _appBlue.withValues(alpha: 0.08)
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
          // ── Contenu selon le type ────────────────────────────────
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
          color: active ? _appBlue : Colors.transparent,
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
            hintText: 'https://www.amazon.fr/produit/...',
            prefixIcon: const Icon(Icons.link, color: _appBlue, size: 18),
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
                borderSide: const BorderSide(color: _appBlue, width: 1.8)),
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
              child: _articleDecimalField(art.prixUnitaireCtrl, "Prix unitaire",
                  Icons.sell_outlined,
                  hint: "Ex : 29,99", isRequired: false),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Sous-total auto-calculé
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
            hintText: 'Ex : Robe traditionnelle rouge',
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
            hintText: 'Couleur, taille, matière, modèle... Soyez précis !',
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
          Text('Appuyer pour ajouter une photo',
              style: TextStyle(color: _textMuted, fontSize: 12)),
        ],
      );
    }

    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: hasPhoto ? 130 : 90,
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
            color: _appBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryTile(
            icon: Icons.payments_outlined,
            label: 'Total global',
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
            borderSide: const BorderSide(color: _red)),
      ),
      validator: validator ??
          (required
              ? (v) =>
                  (v == null || v.trim().isEmpty) ? 'Ce champ est requis' : null
              : null),
    );
  }

  Widget _articleDecimalField(
    TextEditingController controller,
    String label,
    IconData icon, {
    String? hint,
    bool isInt = false,
    bool isRequired = true,
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
        prefixIcon: Icon(icon, color: _appBlue, size: 18),
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
            borderSide: const BorderSide(color: _appBlue, width: 1.8)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _red)),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) {
          return isRequired ? 'Requis' : null;
        }
        if (isInt) {
          final n = int.tryParse(v.trim());
          return (n == null || n < 1) ? 'Min 1' : null;
        }
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

  Widget _deviseDropdown() => DropdownButtonFormField<String>(
        value: _devise,
        decoration: InputDecoration(
          labelText: "Devise",
          prefixIcon:
              Icon(Icons.currency_exchange, size: 18, color: _textMuted),
          labelStyle: const TextStyle(color: _textMuted, fontSize: 13),
          filled: true,
          fillColor: _bgLight,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
        items: _devises
            .map((d) => DropdownMenuItem<String>(
                  value: d,
                  child: Text(d, style: const TextStyle(color: _textMain)),
                ))
            .toList(),
        onChanged: (v) => setState(() => _devise = v!),
      );
}
