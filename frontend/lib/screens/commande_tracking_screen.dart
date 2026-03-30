// lib/screens/commande_tracking_screen.dart
//
// ✅ Lit commande.statutSuivi (suivi LOGISTIQUE)
// ✅ Section suivi postal : photos colis + bordereau (client voit, admin upload)
// ✅ Bouton admin "📬 Déposé à la poste" → bottom sheet upload
// ✅ StatefulWidget pour gérer upload + refresh local

import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/commande.dart';
import '../models/logged_user.dart';
import '../providers/app_theme_provider.dart';
import '../services/postal_tracking_service.dart';

class CommandeTrackingScreen extends StatefulWidget {
  final Commande commande;
  const CommandeTrackingScreen({Key? key, required this.commande})
      : super(key: key);

  @override
  State<CommandeTrackingScreen> createState() => _CommandeTrackingScreenState();
}

class _CommandeTrackingScreenState extends State<CommandeTrackingScreen> {
  static const Color _amber = AppThemeProvider.amber;
  static const Color _green = AppThemeProvider.green;
  static const Color _appBlue = AppThemeProvider.appBlue;

  static const List<_Step> _steps = [
    _Step('EN_ATTENTE', '⏳', 'En attente',
        'Votre demande de commande a été reçue.'),
    _Step('COMMANDE_CONFIRMEE', '✅', 'Commande confirmée',
        'Votre commande a été confirmée et est en cours de traitement.'),
    _Step('EN_TRANSIT', '🚚', 'En transit',
        'Votre colis est en cours d\'acheminement.'),
    _Step('EN_DOUANE', '🛃', 'En douane', 'Traitement douanier en cours.'),
    _Step('ARRIVE', '📍', 'Arrivé à destination',
        'Votre colis est arrivé. Vous serez contacté.'),
    _Step('PRET_LIVRAISON', '📦', 'Prêt pour livraison',
        'Votre colis est prêt. La livraison est en cours de planification.'),
    _Step('LIVRE', '🎉', 'Livré', 'Votre commande a été livrée. Merci !'),
  ];

  late Commande _commande;
  final _postalSvc = PostalTrackingService();
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _commande = widget.commande;
    _isAdmin = LoggedUser.fromSupabase().role == 'admin';
  }

  void _showPostalUploadSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PostalUploadSheet(
        commande: _commande,
        service: _postalSvc,
        onSuccess: (updated) {
          if (mounted) setState(() => _commande = updated);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('✅ Dépôt postal enregistré — client notifié')));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppThemeProvider>();

    final currentStatut = _commande.statutSuivi.toUpperCase().trim();
    final currentIdx = _steps
        .indexWhere((s) => s.key == currentStatut)
        .clamp(0, _steps.length - 1);
    final currentStep = _steps[currentIdx];
    final isFinal = currentIdx == _steps.length - 1;

    final refLabel = '#${_commande.id ?? '?'} — '
        '${_commande.plateforme.isNotEmpty ? _commande.plateforme : "Commande"}';

    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.topBarBg,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Suivi commande',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          Text(refLabel,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65), fontSize: 12)),
        ]),
        actions: [
          if (_isAdmin && !_commande.isDeposePoste)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                icon: const Text('📬', style: TextStyle(fontSize: 16)),
                label: const Text('Poste',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
                style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
                onPressed: _showPostalUploadSheet,
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // ── Carte statut actuel ──────────────────────────────────────
          _StatusCard(
              t: t, step: currentStep, isFinal: isFinal, accentColor: _amber),
          const SizedBox(height: 20),

          // ── Section suivi postal (si déposé) ─────────────────────────
          if (_commande.isDeposePoste) ...[
            _PostalSection(t: t, commande: _commande),
            const SizedBox(height: 20),
          ],

          // ── Bouton admin déposer à la poste ──────────────────────────
          if (_isAdmin && !_commande.isDeposePoste) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Text('📬', style: TextStyle(fontSize: 18)),
                label: const Text('Enregistrer dépôt à la poste',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                    foregroundColor: _amber,
                    side: BorderSide(color: _amber.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 13)),
                onPressed: _showPostalUploadSheet,
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ── Timeline ────────────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: t.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: t.border)),
            child: Column(
              children: _steps
                  .asMap()
                  .entries
                  .map((e) => _TimelineItem(
                        t: t,
                        step: e.value,
                        done: e.key <= currentIdx,
                        isActive: e.key == currentIdx,
                        isLast: e.key == _steps.length - 1,
                        activeColor: _amber,
                      ))
                  .toList(),
            ),
          ),

          const SizedBox(height: 20),

          // ── Infos commande ───────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                color: t.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: t.border)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Détails de la commande',
                  style: TextStyle(
                      color: t.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 14)),
              const SizedBox(height: 14),
              _InfoRow(
                  t: t,
                  label: 'Plateforme',
                  value: _commande.plateforme.isNotEmpty
                      ? _commande.plateforme
                      : '—'),
              _InfoRow(
                  t: t,
                  label: 'Livraison',
                  value: '${_commande.villeLivraison}, '
                      '${_commande.paysLivraison}'),
              if (_commande.lienProduit.isNotEmpty)
                _InfoRow(
                    t: t,
                    label: 'Produit',
                    value: _commande.lienProduit.length > 50
                        ? '${_commande.lienProduit.substring(0, 50)}…'
                        : _commande.lienProduit),
              _InfoRow(t: t, label: 'Quantité', value: '${_commande.quantite}'),
              if (_commande.prixTotal > 0)
                _InfoRow(
                    t: t,
                    label: 'Total',
                    value: '${_commande.prixTotal} ${_commande.devise}'),
              if (_commande.gpNom != null && _commande.gpNom!.isNotEmpty)
                _InfoRow(
                    t: t,
                    label: 'Agent GP',
                    value: '${_commande.gpPrenom ?? ''} '
                            '${_commande.gpNom ?? ''}'
                        .trim()),
              const Divider(height: 24),
              _InfoRow(t: t, label: 'Suivi', value: currentStep.label),
              _InfoRow(t: t, label: 'Dossier', value: _commande.statut),
            ]),
          ),

          const SizedBox(height: 32),
        ]),
      ),
    );
  }
}

// ── Section suivi postal ──────────────────────────────────────────────────────

class _PostalSection extends StatelessWidget {
  final AppThemeProvider t;
  final Commande commande;
  const _PostalSection({required this.t, required this.commande});

  @override
  Widget build(BuildContext context) {
    final date = commande.deposePosteAt != null
        ? DateFormat('dd/MM/yyyy à HH:mm').format(commande.deposePosteAt!)
        : '';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppThemeProvider.amber.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppThemeProvider.amber.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── En-tête ────────────────────────────────────────────────────
        Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                color: AppThemeProvider.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12)),
            child:
                const Center(child: Text('📬', style: TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Colis déposé à la poste',
                    style: TextStyle(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 15)),
                if (date.isNotEmpty)
                  Text('Le $date',
                      style: TextStyle(color: t.textMuted, fontSize: 12)),
              ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: AppThemeProvider.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppThemeProvider.green.withValues(alpha: 0.4))),
            child: const Text('En cours de livraison',
                style: TextStyle(
                    color: AppThemeProvider.green,
                    fontWeight: FontWeight.w700,
                    fontSize: 10)),
          ),
        ]),

        // ── Numéro de bordereau ────────────────────────────────────────
        if (commande.numeroBordereau != null &&
            commande.numeroBordereau!.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
                color: t.bgCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: t.border)),
            child: Row(children: [
              Icon(Icons.local_post_office_outlined,
                  color: AppThemeProvider.amber, size: 18),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Numéro de suivi postal',
                    style: TextStyle(
                        color: t.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
                Text(commande.numeroBordereau!,
                    style: TextStyle(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: 1)),
              ]),
            ]),
          ),
        ],

        // ── Photos ────────────────────────────────────────────────────
        if (commande.photoColisUrl != null ||
            commande.photoBordereauUrl != null) ...[
          const SizedBox(height: 16),
          Text('Photos',
              style: TextStyle(
                  color: t.textMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 1)),
          const SizedBox(height: 10),
          Row(children: [
            if (commande.photoColisUrl != null)
              Expanded(
                  child: _PhotoCard(
                      t: t, url: commande.photoColisUrl!, label: '📦 Colis')),
            if (commande.photoColisUrl != null &&
                commande.photoBordereauUrl != null)
              const SizedBox(width: 10),
            if (commande.photoBordereauUrl != null)
              Expanded(
                  child: _PhotoCard(
                      t: t,
                      url: commande.photoBordereauUrl!,
                      label: '🏷️ Bordereau')),
          ]),
        ],
      ]),
    );
  }
}

// ── Photo Card ────────────────────────────────────────────────────────────────

class _PhotoCard extends StatelessWidget {
  final AppThemeProvider t;
  final String url;
  final String label;
  const _PhotoCard({required this.t, required this.url, required this.label});

  void _showFullscreen(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(children: [
          InteractiveViewer(
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
              placeholder: (_, __) => const Center(
                  child: CircularProgressIndicator(color: Colors.white)),
              errorWidget: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image_outlined,
                      color: Colors.white54, size: 48)),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                    color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 22),
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white70, fontWeight: FontWeight.w600)),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showFullscreen(context),
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: t.border)),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          CachedNetworkImage(
            imageUrl: url,
            height: 130,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
                height: 130,
                color: t.bgSection,
                child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2))),
            errorWidget: (_, __, ___) => Container(
                height: 130,
                color: t.bgSection,
                child: Icon(Icons.broken_image_outlined,
                    color: t.textMuted, size: 32)),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            color: t.bgCard,
            child: Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12)),
          ),
        ]),
      ),
    );
  }
}

// ── Bottom Sheet Upload Postal ─────────────────────────────────────────────────

class _PostalUploadSheet extends StatefulWidget {
  final Commande commande;
  final PostalTrackingService service;
  final void Function(Commande) onSuccess;
  const _PostalUploadSheet({
    required this.commande,
    required this.service,
    required this.onSuccess,
  });

  @override
  State<_PostalUploadSheet> createState() => _PostalUploadSheetState();
}

class _PostalUploadSheetState extends State<_PostalUploadSheet> {
  static const Color _amber = AppThemeProvider.amber;

  final _bordereauCtrl = TextEditingController();
  XFile? _photoColis;
  XFile? _photoBordereau;
  bool _uploading = false;
  String _status = '';

  @override
  void dispose() {
    _bordereauCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isColis) async {
    final file = await widget.service.pickImage(fromCamera: false);
    if (file != null)
      setState(() {
        if (isColis)
          _photoColis = file;
        else
          _photoBordereau = file;
      });
  }

  Future<void> _pickFromCamera(bool isColis) async {
    final file = await widget.service.pickImage(fromCamera: true);
    if (file != null)
      setState(() {
        if (isColis)
          _photoColis = file;
        else
          _photoBordereau = file;
      });
  }

  Future<void> _submit() async {
    if (_photoColis == null) {
      setState(() => _status = '⚠️ La photo du colis est obligatoire');
      return;
    }
    if (_photoBordereau == null) {
      setState(() => _status = '⚠️ La photo du bordereau est obligatoire');
      return;
    }

    setState(() {
      _uploading = true;
      _status = 'Upload photo colis…';
    });

    final colisUrl = await widget.service.uploadPhoto(
      file: _photoColis!,
      folder: 'commandes',
      entityId: widget.commande.id!,
      label: 'colis',
    );
    if (colisUrl == null) {
      setState(() {
        _uploading = false;
        _status = '❌ Erreur upload photo colis';
      });
      return;
    }

    setState(() => _status = 'Upload photo bordereau…');
    final bordereauUrl = await widget.service.uploadPhoto(
      file: _photoBordereau!,
      folder: 'commandes',
      entityId: widget.commande.id!,
      label: 'bordereau',
    );
    if (bordereauUrl == null) {
      setState(() {
        _uploading = false;
        _status = '❌ Erreur upload photo bordereau';
      });
      return;
    }

    setState(() => _status = 'Enregistrement…');
    final ok = await widget.service.savePostalCommande(
      id: widget.commande.id!,
      photoColisUrl: colisUrl,
      photoBordereauUrl: bordereauUrl,
      numeroBordereau: _bordereauCtrl.text.trim(),
    );

    setState(() => _uploading = false);

    if (ok) {
      final updated = widget.commande.copyWith(
        photoColisUrl: colisUrl,
        photoBordereauUrl: bordereauUrl,
        numeroBordereau: _bordereauCtrl.text.trim(),
        deposePosteAt: DateTime.now(),
        statutSuivi: 'PRET_LIVRAISON',
      );
      if (mounted) Navigator.pop(context);
      widget.onSuccess(updated);
    } else {
      setState(() => _status = '❌ Erreur enregistrement — réessayez');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppThemeProvider>();
    return Container(
      decoration: BoxDecoration(
          color: t.bgCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: t.border,
                      borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Row(children: [
            const Text('📬', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Dépôt à la poste',
                      style: TextStyle(
                          color: t.textPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 17)),
                  Text('Commande #${widget.commande.id}',
                      style: TextStyle(color: t.textMuted, fontSize: 13)),
                ])),
          ]),
          const SizedBox(height: 20),
          _PhotoPicker(
            t: t,
            label: '📦 Photo du colis *',
            file: _photoColis,
            onGallery: () => _pickImage(true),
            onCamera: () => _pickFromCamera(true),
          ),
          const SizedBox(height: 14),
          _PhotoPicker(
            t: t,
            label: '🏷️ Photo du bordereau *',
            file: _photoBordereau,
            onGallery: () => _pickImage(false),
            onCamera: () => _pickFromCamera(false),
          ),
          const SizedBox(height: 14),
          Text('Numéro de suivi postal (optionnel)',
              style: TextStyle(
                  color: t.textMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 12)),
          const SizedBox(height: 6),
          TextField(
            controller: _bordereauCtrl,
            textCapitalization: TextCapitalization.characters,
            style: TextStyle(
                color: t.textPrimary,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2),
            decoration: InputDecoration(
              hintText: 'Ex: 3C12345678FR',
              hintStyle: TextStyle(color: t.textMuted),
              prefixIcon: Icon(Icons.local_post_office_outlined,
                  color: _amber, size: 20),
              filled: true,
              fillColor: t.bg,
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: t.border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _amber, width: 1.5)),
            ),
          ),
          if (_status.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                  color: _status.startsWith('❌')
                      ? Colors.red.withValues(alpha: 0.08)
                      : _status.startsWith('⚠️')
                          ? _amber.withValues(alpha: 0.08)
                          : _amber.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: _status.startsWith('❌')
                          ? Colors.red.withValues(alpha: 0.3)
                          : _amber.withValues(alpha: 0.3))),
              child: Row(children: [
                if (_uploading) ...[
                  SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _amber)),
                  const SizedBox(width: 10),
                ],
                Text(_status,
                    style: TextStyle(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ]),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: _uploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('📬', style: TextStyle(fontSize: 18)),
              label: Text(
                  _uploading
                      ? 'Envoi en cours…'
                      : 'Valider le dépôt à la poste',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 14)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _amber,
                  foregroundColor: AppThemeProvider.textDark,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 15)),
              onPressed: _uploading ? null : _submit,
            ),
          ),
        ],
      )),
    );
  }
}

// ── Photo Picker Widget ───────────────────────────────────────────────────────

class _PhotoPicker extends StatelessWidget {
  final AppThemeProvider t;
  final String label;
  final XFile? file;
  final VoidCallback onGallery;
  final VoidCallback onCamera;
  const _PhotoPicker(
      {required this.t,
      required this.label,
      required this.file,
      required this.onGallery,
      required this.onCamera});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: TextStyle(
              color: t.textMuted, fontWeight: FontWeight.w600, fontSize: 12)),
      const SizedBox(height: 6),
      if (file != null)
        Stack(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: kIsWeb
                ? Image.network(file!.path,
                    height: 140, width: double.infinity, fit: BoxFit.cover)
                : Image.file(File(file!.path),
                    height: 140, width: double.infinity, fit: BoxFit.cover),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: onGallery,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                    color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.edit, color: Colors.white, size: 16),
              ),
            ),
          ),
        ])
      else
        Row(children: [
          Expanded(
              child: _PickBtn(
                  icon: Icons.photo_library_outlined,
                  label: 'Galerie',
                  color: AppThemeProvider.amber,
                  t: t,
                  onTap: onGallery)),
          const SizedBox(width: 10),
          Expanded(
              child: _PickBtn(
                  icon: Icons.camera_alt_outlined,
                  label: 'Appareil photo',
                  color: AppThemeProvider.teal,
                  t: t,
                  onTap: onCamera)),
        ]),
    ]);
  }
}

class _PickBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final AppThemeProvider t;
  final VoidCallback onTap;
  const _PickBtn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.t,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3))),
        child: Column(children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  color: t.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 11)),
        ]),
      ),
    );
  }
}

// ── Widgets internes ──────────────────────────────────────────────────────────

class _Step {
  final String key, emoji, label, description;
  const _Step(this.key, this.emoji, this.label, this.description);
}

class _StatusCard extends StatelessWidget {
  final AppThemeProvider t;
  final _Step step;
  final bool isFinal;
  final Color accentColor;
  const _StatusCard(
      {required this.t,
      required this.step,
      required this.isFinal,
      required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final color = isFinal ? AppThemeProvider.green : accentColor;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5)),
      child: Column(children: [
        Text(step.emoji, style: const TextStyle(fontSize: 44)),
        const SizedBox(height: 10),
        Text(step.label,
            style: TextStyle(
                color: t.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 18)),
        const SizedBox(height: 6),
        Text(step.description,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: t.textMuted,
                fontWeight: FontWeight.w400,
                fontSize: 13,
                height: 1.5)),
      ]),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final AppThemeProvider t;
  final _Step step;
  final bool done, isActive, isLast;
  final Color activeColor;
  const _TimelineItem(
      {required this.t,
      required this.step,
      required this.done,
      required this.isActive,
      required this.isLast,
      required this.activeColor});

  @override
  Widget build(BuildContext context) {
    final color =
        done ? (isActive ? activeColor : AppThemeProvider.green) : t.border;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? color.withValues(alpha: 0.14) : t.bgSection,
              border: Border.all(color: color, width: done ? 2 : 1)),
          child: Center(
              child: done
                  ? Text(step.emoji, style: const TextStyle(fontSize: 14))
                  : Container(
                      width: 8,
                      height: 8,
                      decoration:
                          BoxDecoration(shape: BoxShape.circle, color: color))),
        ),
        if (!isLast)
          AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: 2,
              height: 42,
              color: (done && !isActive)
                  ? AppThemeProvider.green.withValues(alpha: 0.35)
                  : t.border.withValues(alpha: 0.35)),
      ]),
      const SizedBox(width: 14),
      Expanded(
          child: Padding(
        padding: EdgeInsets.only(top: 4, bottom: isLast ? 0 : 26),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(step.label,
              style: TextStyle(
                  color: isActive
                      ? activeColor
                      : done
                          ? t.textPrimary
                          : t.textMuted,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 14)),
          if (isActive) ...[
            const SizedBox(height: 4),
            Text(step.description,
                style: TextStyle(
                    color: t.textMuted,
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    height: 1.4)),
          ],
        ]),
      )),
    ]);
  }
}

class _InfoRow extends StatelessWidget {
  final AppThemeProvider t;
  final String label, value;
  const _InfoRow({required this.t, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            width: 90,
            child: Text(label,
                style: TextStyle(
                    color: t.textMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 12))),
        Expanded(
            child: Text(value,
                style: TextStyle(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13))),
      ]),
    );
  }
}
