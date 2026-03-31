// lib/screens/transport_tracking_screen.dart
//
// ✅ Lit transport.statutSuivi (suivi LOGISTIQUE)
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

import '../models/logged_user.dart';
import '../models/transport.dart';
import '../providers/app_theme_provider.dart';
import '../services/postal_tracking_service.dart';
import '../services/transport_service.dart';
import '../services/postal_cache_service.dart';

class TransportTrackingScreen extends StatefulWidget {
  final Transport transport;
  const TransportTrackingScreen({Key? key, required this.transport})
      : super(key: key);

  @override
  State<TransportTrackingScreen> createState() =>
      _TransportTrackingScreenState();
}

class _TransportTrackingScreenState extends State<TransportTrackingScreen> {
  static const Color _appBlue = AppThemeProvider.appBlue;
  static const Color _green = AppThemeProvider.green;
  static const Color _amber = AppThemeProvider.amber;

  static const List<_Step> _steps = [
    _Step('EN_ATTENTE', '⏳', 'En attente',
        'Votre demande de transport a été reçue.'),
    _Step('DEPART_CONFIRME', '✅', 'Départ confirmé',
        'Confirmé pour le prochain départ SAMA.'),
    _Step('EN_TRANSIT', '🚚', 'En transit',
        'Votre colis est en cours d\'acheminement.'),
    _Step('EN_DOUANE', '🛃', 'En douane', 'Traitement douanier en cours.'),
    _Step('ARRIVE', '📍', 'Arrivé à destination',
        'Votre colis est arrivé. Vous serez contacté.'),
    _Step('PRET_RECUPERATION', '📦', 'Prêt à être récupéré',
        'Présentez-vous muni de votre pièce d\'identité.'),
    _Step('LIVRE', '🎉', 'Livré', 'Votre colis a été remis. Merci !'),
  ];

  late Transport _transport;
  final _postalSvc = PostalTrackingService();
  final _transportSvc = TransportService();
  bool _isAdmin = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _transport = widget.transport;
    _isAdmin = LoggedUser.fromSupabase().role == 'admin';
    // ✅ Toujours recharger depuis l'API pour avoir les données fraîches
    // (photos postales, statutSuivi, etc.)
    _refresh();
  }

  Future<void> _refresh() async {
    if (_transport.id == null) return;
    setState(() => _loading = true);

    // 1. Charger depuis l'API
    Transport? fresh;
    if (_isAdmin) {
      fresh = await _transportSvc.getTransportByIdAdmin(_transport.id!);
    } else {
      fresh = await _transportSvc.getTransportById(_transport.id!);
    }
    if (fresh != null && mounted) {
      setState(() => _transport = fresh!);
    }

    // 2. Si les champs postaux sont absents dans la réponse API,
    //    les compléter depuis le cache local (SharedPreferences)
    if (_transport.id != null && !_transport.isDeposePoste) {
      final cached = await PostalCacheService.getTransport(_transport.id!);
      if (cached != null && mounted) {
        setState(() {
          _transport = _transport.copyWith(
            photoColisUrl: cached['photoColisUrl'] as String?,
            photoBordereauUrl: cached['photoBordereauUrl'] as String?,
            numeroBordereau: cached['numeroBordereau'] as String?,
            deposePosteAt:
                DateTime.tryParse(cached['deposePosteAt']?.toString() ?? ''),
            statutSuivi: 'PRET_RECUPERATION',
          );
        });
      }
    }

    if (mounted) setState(() => _loading = false);
  }

  // ── Bottom sheet upload postal ─────────────────────────────────────────────
  void _showPostalUploadSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PostalUploadSheet(
        transport: _transport,
        service: _postalSvc,
        onSuccess: (updated) {
          if (mounted) setState(() => _transport = updated);
          // ✅ Sauvegarder dans le cache local pour survivre aux rechargements
          if (updated.id != null && updated.deposePosteAt != null) {
            PostalCacheService.saveTransport(
              id: updated.id!,
              photoColisUrl: updated.photoColisUrl ?? '',
              photoBordereauUrl: updated.photoBordereauUrl ?? '',
              numeroBordereau: updated.numeroBordereau ?? '',
              deposePosteAt: updated.deposePosteAt!,
            );
          }
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('✅ Dépôt postal enregistré — client notifié')));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppThemeProvider>();

    final currentStatut = _transport.statutSuivi.toUpperCase().trim();
    final currentIdx = _steps
        .indexWhere((s) => s.key == currentStatut)
        .clamp(0, _steps.length - 1);
    final currentStep = _steps[currentIdx];
    final isFinal = currentIdx == _steps.length - 1;

    final refLabel = '#${_transport.id ?? '?'} — '
        '${_transport.paysExpediteur} → ${_transport.paysDestinataire}';

    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.topBarBg,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Suivi logistique',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          Text(refLabel,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65), fontSize: 12)),
        ]),
        // ✅ Bouton admin visible uniquement pour l'admin
        actions: [
          if (_isAdmin && !_transport.isDeposePoste)
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
          _StatusCard(t: t, step: currentStep, isFinal: isFinal),
          const SizedBox(height: 20),

          // ── ✅ Section suivi postal (si déposé) ──────────────────────
          if (_transport.isDeposePoste) ...[
            _PostalSection(t: t, transport: _transport),
            const SizedBox(height: 20),
          ],

          // ── Bouton admin déposer à la poste (dans le body aussi) ─────
          if (_isAdmin && !_transport.isDeposePoste) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Text('📬', style: TextStyle(fontSize: 18)),
                label: const Text('Enregistrer dépôt à la poste',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                    foregroundColor: _appBlue,
                    side: BorderSide(color: _appBlue.withValues(alpha: 0.5)),
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
                      ))
                  .toList(),
            ),
          ),

          const SizedBox(height: 20),

          // ── Infos transport ──────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                color: t.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: t.border)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Détails du transport',
                  style: TextStyle(
                      color: t.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 14)),
              const SizedBox(height: 14),
              _InfoRow(
                  t: t,
                  label: 'Expéditeur',
                  value: '${_transport.villeExpediteur}, '
                      '${_transport.paysExpediteur}'),
              _InfoRow(
                  t: t,
                  label: 'Destinataire',
                  value: '${_transport.villeDestinataire}, '
                      '${_transport.paysDestinataire}'),
              _InfoRow(
                  t: t,
                  label: 'Marchandise',
                  value: _transport.typesMarchandise.isNotEmpty
                      ? _transport.typesMarchandise
                      : '—'),
              if (_transport.poids != null)
                _InfoRow(t: t, label: 'Poids', value: '${_transport.poids} kg'),
              if (_transport.gpNom != null && _transport.gpNom!.isNotEmpty)
                _InfoRow(
                    t: t,
                    label: 'Agent GP',
                    value: '${_transport.gpPrenom ?? ''} '
                            '${_transport.gpNom ?? ''}'
                        .trim()),
              const Divider(height: 24),
              _InfoRow(t: t, label: 'Suivi', value: currentStep.label),
              _InfoRow(t: t, label: 'Dossier', value: _transport.statut),
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
  final Transport transport;
  const _PostalSection({required this.t, required this.transport});

  @override
  Widget build(BuildContext context) {
    final date = transport.deposePosteAt != null
        ? DateFormat('dd/MM/yyyy à HH:mm').format(transport.deposePosteAt!)
        : '';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppThemeProvider.appBlue.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppThemeProvider.appBlue.withValues(alpha: 0.35),
            width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── En-tête ────────────────────────────────────────────────────
        Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                color: AppThemeProvider.appBlue.withValues(alpha: 0.12),
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
        if (transport.numeroBordereau != null &&
            transport.numeroBordereau!.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
                color: t.bgCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: t.border)),
            child: Row(children: [
              Icon(Icons.local_post_office_outlined,
                  color: AppThemeProvider.appBlue, size: 18),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Numéro de suivi postal',
                    style: TextStyle(
                        color: t.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
                Text(transport.numeroBordereau!,
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
        if (transport.photoColisUrl != null ||
            transport.photoBordereauUrl != null) ...[
          const SizedBox(height: 16),
          Text('Photos',
              style: TextStyle(
                  color: t.textMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 1)),
          const SizedBox(height: 10),
          Row(children: [
            if (transport.photoColisUrl != null)
              Expanded(
                  child: _PhotoCard(
                      t: t, url: transport.photoColisUrl!, label: '📦 Colis')),
            if (transport.photoColisUrl != null &&
                transport.photoBordereauUrl != null)
              const SizedBox(width: 10),
            if (transport.photoBordereauUrl != null)
              Expanded(
                  child: _PhotoCard(
                      t: t,
                      url: transport.photoBordereauUrl!,
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

  void _showFullscreen(BuildContext context) {
    final t = context.read<AppThemeProvider>();
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
                decoration: BoxDecoration(
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
}

// ── Bottom Sheet Upload Postal ─────────────────────────────────────────────────

class _PostalUploadSheet extends StatefulWidget {
  final Transport transport;
  final PostalTrackingService service;
  final void Function(Transport) onSuccess;
  const _PostalUploadSheet({
    required this.transport,
    required this.service,
    required this.onSuccess,
  });

  @override
  State<_PostalUploadSheet> createState() => _PostalUploadSheetState();
}

class _PostalUploadSheetState extends State<_PostalUploadSheet> {
  static const Color _appBlue = AppThemeProvider.appBlue;

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
    if (file != null) {
      setState(() {
        if (isColis)
          _photoColis = file;
        else
          _photoBordereau = file;
      });
    }
  }

  Future<void> _pickFromCamera(bool isColis) async {
    final file = await widget.service.pickImage(fromCamera: true);
    if (file != null) {
      setState(() {
        if (isColis)
          _photoColis = file;
        else
          _photoBordereau = file;
      });
    }
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
      folder: 'transports',
      entityId: widget.transport.id!,
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
      folder: 'transports',
      entityId: widget.transport.id!,
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
    final ok = await widget.service.savePostalTransport(
      id: widget.transport.id!,
      photoColisUrl: colisUrl,
      photoBordereauUrl: bordereauUrl,
      numeroBordereau: _bordereauCtrl.text.trim(),
    );

    setState(() => _uploading = false);

    if (ok) {
      final updated = widget.transport.copyWith(
        photoColisUrl: colisUrl,
        photoBordereauUrl: bordereauUrl,
        numeroBordereau: _bordereauCtrl.text.trim(),
        deposePosteAt: DateTime.now(),
        statutSuivi: 'PRET_RECUPERATION',
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
          // Poignée
          Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: t.border,
                      borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),

          // Titre
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
                  Text('Transport #${widget.transport.id}',
                      style: TextStyle(color: t.textMuted, fontSize: 13)),
                ])),
          ]),

          const SizedBox(height: 20),

          // ── Photo colis ──────────────────────────────────────────────
          _PhotoPicker(
            t: t,
            label: '📦 Photo du colis *',
            file: _photoColis,
            onGallery: () => _pickImage(true),
            onCamera: () => _pickFromCamera(true),
          ),

          const SizedBox(height: 14),

          // ── Photo bordereau ──────────────────────────────────────────
          _PhotoPicker(
            t: t,
            label: '🏷️ Photo du bordereau *',
            file: _photoBordereau,
            onGallery: () => _pickImage(false),
            onCamera: () => _pickFromCamera(false),
          ),

          const SizedBox(height: 14),

          // ── Numéro de bordereau ──────────────────────────────────────
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
                  color: _appBlue, size: 20),
              filled: true,
              fillColor: t.bg,
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: t.border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _appBlue, width: 1.5)),
            ),
          ),

          // ── Statut ───────────────────────────────────────────────────
          if (_status.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                  color: _status.startsWith('❌')
                      ? Colors.red.withValues(alpha: 0.08)
                      : _status.startsWith('⚠️')
                          ? AppThemeProvider.amber.withValues(alpha: 0.08)
                          : _appBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: _status.startsWith('❌')
                          ? Colors.red.withValues(alpha: 0.3)
                          : _status.startsWith('⚠️')
                              ? AppThemeProvider.amber.withValues(alpha: 0.3)
                              : _appBlue.withValues(alpha: 0.3))),
              child: Row(children: [
                if (_uploading) ...[
                  SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _appBlue)),
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

          // ── Bouton valider ───────────────────────────────────────────
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
                  backgroundColor: _appBlue,
                  foregroundColor: Colors.white,
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
                decoration: BoxDecoration(
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
                  color: AppThemeProvider.appBlue,
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
  const _StatusCard(
      {required this.t, required this.step, required this.isFinal});

  @override
  Widget build(BuildContext context) {
    final color = isFinal ? AppThemeProvider.green : AppThemeProvider.appBlue;
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
  const _TimelineItem(
      {required this.t,
      required this.step,
      required this.done,
      required this.isActive,
      required this.isLast});

  @override
  Widget build(BuildContext context) {
    final color = done
        ? (isActive ? AppThemeProvider.appBlue : AppThemeProvider.green)
        : t.border;
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
                      ? AppThemeProvider.appBlue
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
