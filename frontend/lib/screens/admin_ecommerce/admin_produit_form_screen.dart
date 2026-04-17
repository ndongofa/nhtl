// lib/screens/admin_ecommerce/admin_produit_form_screen.dart

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final _uniteController = TextEditingController();

  String _devise = 'EUR';
  bool _actif = true;
  bool _loading = false;

  // Multi-image state: list of (XFile?, Uint8List?, existingUrl?)
  // Each entry represents one image slot
  final List<_ImageEntry> _images = [];
  bool _uploadingImage = false;

  static const _imageBucket = 'sama-produits';
  static const _allowedMimes = {'image/jpeg', 'image/png', 'image/webp'};
  static const _allowedExts = {'jpg', 'jpeg', 'png', 'webp'};

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
      _uniteController.text = p.unite ?? '';
      _devise = p.devise;
      _actif = p.actif;
      // Populate images from existing imageUrls (fall back to imageUrl)
      final urls = p.imageUrls.isNotEmpty
          ? p.imageUrls
          : (p.imageUrl != null ? [p.imageUrl!] : []);
      for (final url in urls) {
        _images.add(_ImageEntry(existingUrl: url));
      }
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _descriptionController.dispose();
    _prixController.dispose();
    _stockController.dispose();
    _categorieController.dispose();
    _uniteController.dispose();
    super.dispose();
  }

  Future<void> _addImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (picked == null) return;

    final mime = (picked.mimeType ?? '').toLowerCase();
    final ext = _resolveExt(picked);
    if (!_allowedMimes.contains(mime) && !_allowedExts.contains(ext)) {
      Fluttertoast.showToast(
          msg: '❌ Format non supporté. Utilisez JPEG, PNG ou WebP.',
          backgroundColor: Colors.red);
      return;
    }

    final bytes = await picked.readAsBytes();
    setState(() {
      _images.add(_ImageEntry(file: picked, bytes: bytes));
    });
  }

  Future<void> _replaceImage(int index) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (picked == null) return;

    final mime = (picked.mimeType ?? '').toLowerCase();
    final ext = _resolveExt(picked);
    if (!_allowedMimes.contains(mime) && !_allowedExts.contains(ext)) {
      Fluttertoast.showToast(
          msg: '❌ Format non supporté. Utilisez JPEG, PNG ou WebP.',
          backgroundColor: Colors.red);
      return;
    }

    final bytes = await picked.readAsBytes();
    setState(() {
      _images[index] = _ImageEntry(file: picked, bytes: bytes);
    });
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  Future<String?> _uploadImage(XFile file, Uint8List bytes) async {
    final supa = Supabase.instance.client;
    final ext = _resolveExt(file);
    final rnd = Random.secure();
    final randomSuffix = List.generate(
            8, (_) => rnd.nextInt(256).toRadixString(16).padLeft(2, '0'))
        .join();
    final path =
        '${widget.serviceType.toLowerCase()}/${DateTime.now().millisecondsSinceEpoch}_$randomSuffix.$ext';
    await supa.storage.from(_imageBucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
              contentType: _extToMime(ext), upsert: false),
        );
    return supa.storage.from(_imageBucket).getPublicUrl(path);
  }

  String _resolveExt(XFile file) {
    final name = file.name.toLowerCase();
    if (name.endsWith('.jpg') || name.endsWith('.jpeg')) return 'jpg';
    if (name.endsWith('.png')) return 'png';
    if (name.endsWith('.webp')) return 'webp';
    final mime = file.mimeType ?? '';
    if (mime.contains('jpeg') || mime.contains('jpg')) return 'jpg';
    if (mime.contains('png')) return 'png';
    if (mime.contains('webp')) return 'webp';
    return 'jpg';
  }

  String _extToMime(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      setState(() => _uploadingImage = true);
      final List<String> imageUrls = [];
      for (final entry in _images) {
        if (entry.file != null && entry.bytes != null) {
          final url = await _uploadImage(entry.file!, entry.bytes!);
          if (url == null) {
            Fluttertoast.showToast(
                msg: '❌ Erreur upload image',
                backgroundColor: Colors.red);
            return;
          }
          imageUrls.add(url);
        } else if (entry.existingUrl != null) {
          imageUrls.add(entry.existingUrl!);
        }
      }
      if (mounted) setState(() => _uploadingImage = false);

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
        imageUrl: imageUrls.isNotEmpty ? imageUrls.first : null,
        imageUrls: imageUrls,
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
      if (mounted) setState(() { _loading = false; _uploadingImage = false; });
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
                _multiImagePickerWidget(t),
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
                    onPressed: _loading || _uploadingImage ? null : _submit,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppThemeProvider.appBlue,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0),
                    child: _loading || _uploadingImage
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

  Widget _multiImagePickerWidget(AppThemeProvider t) {
    return Container(
      decoration: BoxDecoration(
        color: t.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: t.border),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.photo_library_outlined, color: t.textMuted, size: 18),
            const SizedBox(width: 8),
            Text('Photos du produit',
                style: TextStyle(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
            const Spacer(),
            Text('${_images.length} photo${_images.length > 1 ? 's' : ''}',
                style: TextStyle(color: t.textMuted, fontSize: 12)),
          ]),
          if (_images.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 110,
              child: ReorderableListView.builder(
                scrollDirection: Axis.horizontal,
                buildDefaultDragHandles: false,
                itemCount: _images.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex--;
                    final item = _images.removeAt(oldIndex);
                    _images.insert(newIndex, item);
                  });
                },
                itemBuilder: (ctx, i) {
                  final entry = _images[i];
                  return ReorderableDragStartListener(
                    key: ValueKey('img_$i'),
                    index: i,
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        GestureDetector(
                          onTap: () => _replaceImage(i),
                          child: Container(
                            width: 100,
                            height: 100,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: i == 0
                                      ? AppThemeProvider.appBlue
                                      : t.border,
                                  width: i == 0 ? 2 : 1),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(7),
                              child: _buildThumbnail(entry, t),
                            ),
                          ),
                        ),
                        // Badge "principale" for first image
                        if (i == 0)
                          Positioned(
                            bottom: 4,
                            left: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppThemeProvider.appBlue,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('1ère',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800)),
                            ),
                          ),
                        // Delete button
                        Positioned(
                          top: 2,
                          right: 10,
                          child: GestureDetector(
                            onTap: () => _removeImage(i),
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
            Text('Maintenez et glissez pour réordonner • Appuyez pour changer',
                style: TextStyle(color: t.textMuted, fontSize: 11)),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
              label: const Text('Ajouter une photo',
                  style: TextStyle(fontSize: 13)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppThemeProvider.appBlue,
                side: const BorderSide(color: AppThemeProvider.appBlue),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _uploadingImage ? null : _addImage,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(_ImageEntry entry, AppThemeProvider t) {
    if (entry.bytes != null) {
      return Image.memory(entry.bytes!, fit: BoxFit.cover,
          width: double.infinity, height: double.infinity);
    }
    if (entry.existingUrl != null) {
      return Image.network(
        entry.existingUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _imagePlaceholder(t),
      );
    }
    return _imagePlaceholder(t);
  }

  Widget _imagePlaceholder(AppThemeProvider t) => Container(
        color: t.bgSection,
        child: Icon(Icons.image_outlined, color: t.textMuted, size: 32),
      );

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

/// Represents one image slot in the multi-image picker.
class _ImageEntry {
  final XFile? file;
  final Uint8List? bytes;
  final String? existingUrl;

  _ImageEntry({this.file, this.bytes, this.existingUrl});
}

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
  final _uniteController = TextEditingController();

  String _devise = 'EUR';
  bool _actif = true;
  bool _loading = false;

  // Image state
  XFile? _pickedImage;
  Uint8List? _pickedImageBytes;
  String? _currentImageUrl;
  bool _uploadingImage = false;

  static const _imageBucket = 'sama-produits';
  static const _allowedMimes = {'image/jpeg', 'image/png', 'image/webp'};
  static const _allowedExts = {'jpg', 'jpeg', 'png', 'webp'};

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
      _currentImageUrl = p.imageUrl;
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
    _uniteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (picked == null) return;

    // Validate MIME type / extension
    final mime = (picked.mimeType ?? '').toLowerCase();
    final ext = _resolveExt(picked);
    if (!_allowedMimes.contains(mime) && !_allowedExts.contains(ext)) {
      Fluttertoast.showToast(
          msg: '❌ Format non supporté. Utilisez JPEG, PNG ou WebP.',
          backgroundColor: Colors.red);
      return;
    }

    final bytes = await picked.readAsBytes();
    setState(() {
      _pickedImage = picked;
      _pickedImageBytes = bytes;
      _currentImageUrl = null;
    });
  }

  Future<String?> _uploadImage(XFile file) async {
    try {
      setState(() => _uploadingImage = true);
      final supa = Supabase.instance.client;
      final bytes = _pickedImageBytes ?? await file.readAsBytes();
      final ext = _resolveExt(file);
      final rnd = Random.secure();
      final randomSuffix = List.generate(
              8, (_) => rnd.nextInt(256).toRadixString(16).padLeft(2, '0'))
          .join();
      final path =
          '${widget.serviceType.toLowerCase()}/${DateTime.now().millisecondsSinceEpoch}_$randomSuffix.$ext';
      await supa.storage.from(_imageBucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
                contentType: _extToMime(ext), upsert: false),
          );
      return supa.storage.from(_imageBucket).getPublicUrl(path);
    } catch (e) {
      Fluttertoast.showToast(
          msg: '❌ Erreur upload image : $e', backgroundColor: Colors.red);
      return null;
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  String _resolveExt(XFile file) {
    final name = file.name.toLowerCase();
    if (name.endsWith('.jpg') || name.endsWith('.jpeg')) return 'jpg';
    if (name.endsWith('.png')) return 'png';
    if (name.endsWith('.webp')) return 'webp';
    final mime = file.mimeType ?? '';
    if (mime.contains('jpeg') || mime.contains('jpg')) return 'jpg';
    if (mime.contains('png')) return 'png';
    if (mime.contains('webp')) return 'webp';
    return 'jpg';
  }

  String _extToMime(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      // Upload image if a new one was picked
      String? imageUrl = _currentImageUrl;
      if (_pickedImage != null) {
        imageUrl = await _uploadImage(_pickedImage!);
        if (imageUrl == null) {
          // Upload failed; error already shown — abort
          return;
        }
      }
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
        imageUrl: imageUrl,
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
                _imagePickerWidget(t),
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
                    onPressed: _loading || _uploadingImage ? null : _submit,
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

  Widget _imagePickerWidget(AppThemeProvider t) {
    final hasImage = _pickedImage != null || (_currentImageUrl?.isNotEmpty == true);

    return Container(
      decoration: BoxDecoration(
        color: t.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(9)),
            child: SizedBox(
              height: 160,
              width: double.infinity,
              child: _buildImagePreview(t),
            ),
          ),
          // Actions
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(
                        hasImage
                            ? Icons.image_search_outlined
                            : Icons.add_photo_alternate_outlined,
                        size: 18),
                    label: Text(
                        hasImage ? 'Changer la photo' : 'Choisir une photo',
                        style: const TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppThemeProvider.appBlue,
                      side: const BorderSide(color: AppThemeProvider.appBlue),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _uploadingImage ? null : _pickImage,
                  ),
                ),
                if (hasImage) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon:
                        const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    tooltip: 'Supprimer la photo',
                    onPressed: () => setState(() {
                      _pickedImage = null;
                      _pickedImageBytes = null;
                      _currentImageUrl = null;
                    }),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(AppThemeProvider t) {
    if (_pickedImageBytes != null) {
      return Image.memory(_pickedImageBytes!, fit: BoxFit.cover,
          width: double.infinity);
    }
    if (_currentImageUrl?.isNotEmpty == true) {
      return Image.network(
        _currentImageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, __, ___) => _imagePlaceholder(t),
      );
    }
    return _imagePlaceholder(t);
  }

  Widget _imagePlaceholder(AppThemeProvider t) => Container(
        color: t.bgSection,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.image_outlined, color: t.textMuted, size: 40),
          const SizedBox(height: 8),
          Text('Aucune photo',
              style: TextStyle(color: t.textMuted, fontSize: 12)),
        ]),
      );

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
