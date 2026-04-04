// lib/screens/admin/admin_ads_screen.dart
//
// ✅ Liste toutes les publicités du carousel
// ✅ Créer une publicité (formulaire modal)
// ✅ Modifier une publicité
// ✅ Activer / Désactiver
// ✅ Supprimer

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/ad_model.dart';
import '../../../services/ad_api_service.dart';
import '../../../services/ad_service.dart';

class AdminAdsScreen extends StatefulWidget {
  const AdminAdsScreen({Key? key}) : super(key: key);

  @override
  State<AdminAdsScreen> createState() => _AdminAdsScreenState();
}

class _AdminAdsScreenState extends State<AdminAdsScreen> {
  static const Color _bg = Color(0xFF0D1B2E);
  static const Color _bgSection = Color(0xFF112236);
  static const Color _bgCard = Color(0xFF1A2E45);
  static const Color _appBlue = Color(0xFF2296F3);
  static const Color _amber = Color(0xFFFFB300);
  static const Color _green = Color(0xFF22C55E);
  static const Color _textPrimary = Color(0xFFF0F6FF);
  static const Color _textMuted = Color(0xFF7A94B0);
  static const Color _border = Color(0xFF1E3A55);

  final _api = AdApiService();
  List<AdModel> _ads = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _api.adminGetAll();
    if (!mounted) return;
    setState(() {
      _ads = list;
      _loading = false;
    });
  }

  Future<void> _toggleActive(AdModel ad) async {
    if (ad.id == null) return;
    final ok = await _api.adminToggle(ad.id!);
    if (ok) {
      // Reload global AdService too so the carousel reflects the change
      if (mounted) await context.read<AdService>().reload();
      await _load();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors du changement de statut')),
      );
    }
  }

  Future<void> _delete(AdModel ad) async {
    if (ad.id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bgCard,
        title: const Text('Supprimer la publicité',
            style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w800)),
        content: Text('Voulez-vous supprimer "${ad.title}" ?',
            style: const TextStyle(color: _textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler', style: TextStyle(color: _textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final ok = await _api.adminDelete(ad.id!);
    if (ok) {
      if (mounted) await context.read<AdService>().reload();
      await _load();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la suppression')),
      );
    }
  }

  void _openForm({AdModel? ad}) async {
    final result = await showModalBottomSheet<AdModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AdFormSheet(existing: ad),
    );
    if (result != null) {
      bool ok;
      if (result.id != null) {
        final updated = await _api.adminUpdate(result.id!, result);
        ok = updated != null;
      } else {
        final created = await _api.adminCreate(result);
        ok = created != null;
      }
      if (ok) {
        if (mounted) await context.read<AdService>().reload();
        await _load();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la sauvegarde')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bgSection,
        iconTheme: const IconThemeData(color: _textPrimary),
        title: const Text(
          'Publicités carousel',
          style: TextStyle(
              color: _textPrimary, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'Rafraîchir',
            icon: const Icon(Icons.refresh, color: _amber),
            onPressed: _load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _appBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nouvelle pub',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        onPressed: () => _openForm(),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _amber))
          : _ads.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.campaign_outlined,
                          color: _textMuted, size: 48),
                      const SizedBox(height: 12),
                      const Text(
                        'Aucune publicité',
                        style: TextStyle(
                            color: _textMuted,
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ajoutez des publicités pour alimenter le carousel',
                        style: TextStyle(color: _textMuted, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: _ads.length,
                  itemBuilder: (ctx, i) => _AdTile(
                    ad: _ads[i],
                    onEdit: () => _openForm(ad: _ads[i]),
                    onToggle: () => _toggleActive(_ads[i]),
                    onDelete: () => _delete(_ads[i]),
                  ),
                ),
    );
  }
}

// ── Ad tile ───────────────────────────────────────────────────────────────────

class _AdTile extends StatelessWidget {
  final AdModel ad;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  static const Color _bgCard = Color(0xFF1A2E45);
  static const Color _border = Color(0xFF1E3A55);
  static const Color _textPrimary = Color(0xFFF0F6FF);
  static const Color _textMuted = Color(0xFF7A94B0);
  static const Color _green = Color(0xFF22C55E);
  static const Color _amber = Color(0xFFFFB300);

  const _AdTile({
    required this.ad,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  String _adTypeLabel(String adType) {
    switch (adType) {
      case AdModel.typeImage:
        return '🖼️ Image';
      case AdModel.typeYoutube:
        return '▶️ YouTube';
      default:
        return '📝 Texte';
    }
  }

  Widget _buildPreviewSwatch() {
    if (ad.adType == AdModel.typeImage && (ad.imageUrl ?? '').isNotEmpty) {
      return SizedBox(
        width: 54,
        child: CachedNetworkImage(
          imageUrl: ad.imageUrl!,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            color: ad.color.withValues(alpha: 0.18),
            child: const Center(
              child: Icon(Icons.image_outlined, color: Colors.white54, size: 24),
            ),
          ),
          errorWidget: (_, __, ___) => Container(
            color: ad.color.withValues(alpha: 0.18),
            child: const Center(
              child: Icon(Icons.broken_image_outlined, color: Colors.white38, size: 22),
            ),
          ),
        ),
      );
    }
    if (ad.adType == AdModel.typeYoutube) {
      return Container(
        width: 54,
        color: Colors.red.withValues(alpha: 0.15),
        child: const Center(
          child: Icon(Icons.smart_display_outlined,
              color: Colors.redAccent, size: 28),
        ),
      );
    }
    // Default: emoji on gradient swatch
    return Container(
      width: 54,
      color: ad.color.withValues(alpha: 0.18),
      child: Center(
        child: Text(ad.emoji, style: const TextStyle(fontSize: 26)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isActive = ad.isActive;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? _green.withValues(alpha: 0.35)
              : _border.withValues(alpha: 0.7),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Left accent bar
              Container(
                width: 4,
                color: isActive
                    ? _green.withValues(alpha: 0.8)
                    : _textMuted.withValues(alpha: 0.3),
              ),
              // Ad preview swatch: image thumbnail, YouTube icon, or emoji
              _buildPreviewSwatch(),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(
                            ad.title,
                            style: const TextStyle(
                              color: _textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: isActive
                                ? _green.withValues(alpha: 0.15)
                                : _textMuted.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isActive
                                  ? _green.withValues(alpha: 0.5)
                                  : _textMuted.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            isActive ? 'Actif' : 'Inactif',
                            style: TextStyle(
                              color: isActive ? _green : _textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      Text(
                        ad.subtitle,
                        style: const TextStyle(
                            color: _textMuted, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Position: ${ad.position} · ${_adTypeLabel(ad.adType)}',
                        style: const TextStyle(
                            color: _textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
              // Actions
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Modifier',
                    icon: const Icon(Icons.edit_outlined,
                        color: _amber, size: 18),
                    onPressed: onEdit,
                  ),
                  IconButton(
                    tooltip: isActive ? 'Désactiver' : 'Activer',
                    icon: Icon(
                      isActive
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: isActive ? _textMuted : _green,
                      size: 18,
                    ),
                    onPressed: onToggle,
                  ),
                  IconButton(
                    tooltip: 'Supprimer',
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.red, size: 18),
                    onPressed: onDelete,
                  ),
                ],
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Ad form sheet ─────────────────────────────────────────────────────────────

class _AdFormSheet extends StatefulWidget {
  final AdModel? existing;
  const _AdFormSheet({this.existing});

  @override
  State<_AdFormSheet> createState() => _AdFormSheetState();
}

class _AdFormSheetState extends State<_AdFormSheet> {
  static const Color _bg = Color(0xFF0D1B2E);
  static const Color _bgCard = Color(0xFF1A2E45);
  static const Color _appBlue = Color(0xFF2296F3);
  static const Color _amber = Color(0xFFFFB300);
  static const Color _textPrimary = Color(0xFFF0F6FF);
  static const Color _textMuted = Color(0xFF7A94B0);
  static const Color _border = Color(0xFF1E3A55);

  late final TextEditingController _emojiCtrl;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _subtitleCtrl;
  late final TextEditingController _colorCtrl;
  late final TextEditingController _colorEndCtrl;
  late final TextEditingController _positionCtrl;
  late final TextEditingController _imageUrlCtrl;
  late final TextEditingController _youtubeIdCtrl;
  late bool _isActive;
  late String _adType;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final ad = widget.existing;
    _emojiCtrl = TextEditingController(text: ad?.emoji ?? '📢');
    _titleCtrl = TextEditingController(text: ad?.title ?? '');
    _subtitleCtrl = TextEditingController(text: ad?.subtitle ?? '');
    _colorCtrl = TextEditingController(text: ad?.colorHex ?? '#004EDA');
    _colorEndCtrl = TextEditingController(text: ad?.colorEndHex ?? '#0D5BBF');
    _positionCtrl =
        TextEditingController(text: '${ad?.position ?? 0}');
    _imageUrlCtrl = TextEditingController(text: ad?.imageUrl ?? '');
    _youtubeIdCtrl = TextEditingController(text: ad?.youtubeId ?? '');
    _isActive = ad?.isActive ?? true;
    _adType = ad?.adType ?? AdModel.typeText;
  }

  @override
  void dispose() {
    _emojiCtrl.dispose();
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _colorCtrl.dispose();
    _colorEndCtrl.dispose();
    _positionCtrl.dispose();
    _imageUrlCtrl.dispose();
    _youtubeIdCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le titre est obligatoire')),
      );
      return;
    }
    if (_adType == AdModel.typeImage && _imageUrlCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("L'URL de l'image est obligatoire pour ce type")),
      );
      return;
    }
    if (_adType == AdModel.typeYoutube && _youtubeIdCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("L'ID YouTube est obligatoire pour ce type")),
      );
      return;
    }
    setState(() => _saving = true);
    final imageUrl = _imageUrlCtrl.text.trim();
    final youtubeId = _youtubeIdCtrl.text.trim();
    final ad = AdModel(
      id: widget.existing?.id,
      emoji: _emojiCtrl.text.trim().isEmpty ? '📢' : _emojiCtrl.text.trim(),
      title: _titleCtrl.text.trim(),
      subtitle: _subtitleCtrl.text.trim(),
      colorHex:
          _colorCtrl.text.trim().isEmpty ? '#004EDA' : _colorCtrl.text.trim(),
      colorEndHex: _colorEndCtrl.text.trim().isEmpty
          ? '#0D5BBF'
          : _colorEndCtrl.text.trim(),
      position: int.tryParse(_positionCtrl.text.trim()) ?? 0,
      isActive: _isActive,
      adType: _adType,
      imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
      youtubeId: youtubeId.isNotEmpty ? youtubeId : null,
    );
    Navigator.pop(context, ad);
  }

  Widget _typeChip(String type, String label) {
    final selected = _adType == type;
    return GestureDetector(
      onTap: () => setState(() => _adType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? _appBlue.withValues(alpha: 0.18)
              : _bg.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _appBlue : _border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? _appBlue : _textMuted,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: _textMuted),
        hintStyle: TextStyle(color: _textMuted.withValues(alpha: 0.5)),
        filled: true,
        fillColor: _bg,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _appBlue),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Container(
      decoration: const BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _textMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isEdit ? 'Modifier la publicité' : 'Nouvelle publicité',
              style: const TextStyle(
                  color: _textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 18),
            ),
            const SizedBox(height: 20),
            // ── Type selector ───────────────────────────────────────────────
            Text('Type de publicité',
                style: const TextStyle(color: _textMuted, fontSize: 12)),
            const SizedBox(height: 8),
            Row(
              children: [
                _typeChip(AdModel.typeText, '📝 Texte'),
                const SizedBox(width: 8),
                _typeChip(AdModel.typeImage, '🖼️ Image'),
                const SizedBox(width: 8),
                _typeChip(AdModel.typeYoutube, '▶️ YouTube'),
              ],
            ),
            const SizedBox(height: 16),
            // ── Media URL fields (conditional) ──────────────────────────────
            if (_adType == AdModel.typeImage) ...[
              TextField(
                controller: _imageUrlCtrl,
                style: const TextStyle(color: _textPrimary),
                keyboardType: TextInputType.url,
                decoration: _inputDeco('URL de l\'image',
                    hint: 'https://example.com/image.jpg'),
              ),
              const SizedBox(height: 12),
            ],
            if (_adType == AdModel.typeYoutube) ...[
              TextField(
                controller: _youtubeIdCtrl,
                style: const TextStyle(color: _textPrimary),
                decoration: _inputDeco('ID de la vidéo YouTube',
                    hint: 'Ex: dQw4w9WgXcQ'),
              ),
              const SizedBox(height: 6),
              Text(
                'Copiez l\'ID depuis l\'URL YouTube : youtube.com/watch?v=ID_ICI',
                style: TextStyle(
                    color: _textMuted.withValues(alpha: 0.7), fontSize: 11),
              ),
              const SizedBox(height: 12),
            ],
            // ── Title row (emoji shown only for text/image types) ───────────
            Row(children: [
              if (_adType != AdModel.typeYoutube) ...[
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _emojiCtrl,
                    style: const TextStyle(
                        color: _textPrimary, fontSize: 22),
                    textAlign: TextAlign.center,
                    decoration: _inputDeco('Emoji'),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: TextField(
                  controller: _titleCtrl,
                  style: const TextStyle(color: _textPrimary),
                  decoration: _inputDeco('Titre', hint: 'Prochain départ Paris → Dakar'),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            TextField(
              controller: _subtitleCtrl,
              style: const TextStyle(color: _textPrimary),
              maxLines: 2,
              decoration: _inputDeco('Sous-titre',
                  hint: 'Description courte visible dans le carousel'),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _colorCtrl,
                  style: const TextStyle(color: _textPrimary),
                  decoration: _inputDeco('Couleur début',
                      hint: '#004EDA'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _colorEndCtrl,
                  style: const TextStyle(color: _textPrimary),
                  decoration: _inputDeco('Couleur fin',
                      hint: '#0D5BBF'),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              SizedBox(
                width: 100,
                child: TextField(
                  controller: _positionCtrl,
                  style: const TextStyle(color: _textPrimary),
                  keyboardType: TextInputType.number,
                  decoration: _inputDeco('Position', hint: '0'),
                ),
              ),
              const SizedBox(width: 20),
              Row(children: [
                Switch(
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                  activeColor: const Color(0xFF22C55E),
                ),
                const SizedBox(width: 8),
                Text(
                  _isActive ? 'Actif' : 'Inactif',
                  style: TextStyle(
                    color: _isActive
                        ? const Color(0xFF22C55E)
                        : _textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ]),
            ]),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _appBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      isEdit ? 'Enregistrer les modifications' : 'Créer la publicité',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
