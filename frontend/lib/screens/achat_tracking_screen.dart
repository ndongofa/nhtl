// lib/screens/achat_tracking_screen.dart
//
// Suivi de statut logistique d'un achat sur mesure.
// Adapté depuis commande_tracking_screen.dart — pipeline AchatStatus 7 étapes.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/achat.dart';
import '../models/logged_user.dart';
import '../providers/app_theme_provider.dart';
import '../services/achat_service.dart';
import '../services/auth_service.dart';
import '../widgets/sama_account_menu.dart';

class _Step {
  final String key;
  final String emoji;
  final String label;
  final String description;
  const _Step(this.key, this.emoji, this.label, this.description);
}

class AchatTrackingScreen extends StatefulWidget {
  final Achat achat;
  const AchatTrackingScreen({Key? key, required this.achat}) : super(key: key);

  @override
  State<AchatTrackingScreen> createState() => _AchatTrackingScreenState();
}

class _AchatTrackingScreenState extends State<AchatTrackingScreen> {
  static const Color _amber = AppThemeProvider.amber;
  static const Color _green = AppThemeProvider.green;
  static const Color _teal = AppThemeProvider.teal;

  static const List<_Step> _steps = [
    _Step('EN_ATTENTE', '⏳', 'En attente',
        'Votre demande d\'achat a été reçue et est en attente de traitement.'),
    _Step('ACHAT_CONFIRME', '✅', 'Achat confirmé',
        'Votre demande a été confirmée. Nos agents vont procéder à l\'achat.'),
    _Step('ACHAT_EFFECTUE', '🛍️', 'Achat effectué',
        'Le produit a été trouvé et acheté pour vous.'),
    _Step('EN_TRANSIT', '🚚', 'En transit',
        'Votre colis est en cours d\'acheminement.'),
    _Step('ARRIVE', '📍', 'Arrivé à destination',
        'Votre colis est arrivé. Vous serez contacté très prochainement.'),
    _Step('PRET_LIVRAISON', '📦', 'Prêt pour livraison',
        'Votre colis est prêt. La livraison est en cours de planification.'),
    _Step('LIVRE', '🎉', 'Livré', 'Votre achat a été livré. Merci !'),
  ];

  late Achat _achat;
  final _achatSvc = AchatService();
  bool _isAdmin = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _achat = widget.achat;
    _isAdmin = LoggedUser.fromSupabase().role == 'admin';
    _refresh();
  }

  Future<void> _refresh() async {
    if (_achat.id == null) return;
    setState(() => _loading = true);

    Achat? fresh;
    if (_isAdmin) {
      fresh = await _achatSvc.getAchatByIdAdmin(_achat.id!);
    } else {
      fresh = await _achatSvc.getAchatById(_achat.id!);
    }

    if (mounted) {
      setState(() {
        if (fresh != null) _achat = fresh!;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppThemeProvider>();

    final currentStatut = _achat.statutSuivi.toUpperCase().trim();
    final currentIdx = _steps
        .indexWhere((s) => s.key == currentStatut)
        .clamp(0, _steps.length - 1);
    final currentStep = _steps[currentIdx];
    final isFinal = currentIdx == _steps.length - 1;

    final refLabel =
        '#${_achat.id ?? '?'} — ${_achat.marche.isNotEmpty ? _achat.marche : "Achat"}';

    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.topBarBg,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Suivi achat',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          Text(refLabel,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65), fontSize: 12)),
        ]),
        actions: [
          IconButton(
            tooltip: "Mon espace",
            onPressed: () => SamaAccountMenu.open(context),
            icon: const Icon(Icons.dashboard_outlined),
          ),
          IconButton(
            tooltip: "Déconnexion",
            onPressed: () async {
              await AuthService.logout();
              if (!context.mounted) return;
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/', (_) => false);
            },
            icon: const Icon(Icons.logout),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                  width: 18,
                  height: 18,
                  child:
                      CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Actualiser',
              onPressed: _refresh,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // ── Carte statut actuel ──────────────────────────────────────
          _buildStatusCard(t, currentStep, isFinal),
          const SizedBox(height: 20),

          // ── Timeline ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: t.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: t.border)),
            child: Column(
              children: _steps
                  .asMap()
                  .entries
                  .map((e) => _buildTimelineItem(
                        t,
                        step: e.value,
                        done: e.key <= currentIdx,
                        isActive: e.key == currentIdx,
                        isLast: e.key == _steps.length - 1,
                      ))
                  .toList(),
            ),
          ),

          const SizedBox(height: 20),

          // ── Infos achat ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                color: t.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: t.border)),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text('Détails de la demande',
                  style: TextStyle(
                      color: t.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 14)),
              const SizedBox(height: 14),
              _InfoRow(t: t, label: 'Type produit', value: _achat.typeProduit),
              _InfoRow(
                  t: t,
                  label: 'Marché / Boutique',
                  value: _achat.marche.isNotEmpty ? _achat.marche : '—'),
              _InfoRow(t: t, label: 'Quantité', value: '${_achat.quantite}'),
              _InfoRow(
                  t: t,
                  label: 'Livraison',
                  value:
                      '${_achat.villeLivraison}, ${_achat.paysLivraison}'),
              if (_achat.prixEstime > 0)
                _InfoRow(
                    t: t,
                    label: 'Prix estimé',
                    value:
                        '${_achat.prixEstime} ${_achat.devise} / unité'),
              if (_achat.prixTotal > 0)
                _InfoRow(
                    t: t,
                    label: 'Total estimé',
                    value: '${_achat.prixTotal} ${_achat.devise}'),
              if (_achat.gpNom != null && _achat.gpNom!.isNotEmpty)
                _InfoRow(
                    t: t,
                    label: 'Agent',
                    value:
                        '${_achat.gpPrenom ?? ''} ${_achat.gpNom ?? ''}'
                            .trim()),
              const Divider(height: 24),
              _InfoRow(t: t, label: 'Suivi', value: currentStep.label),
              _InfoRow(t: t, label: 'Dossier', value: _achat.statut),
            ]),
          ),

          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  Widget _buildStatusCard(AppThemeProvider t, _Step step, bool isFinal) {
    final color = isFinal ? _green : _teal;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: t.isDark ? 0.2 : 0.15),
            color.withValues(alpha: t.isDark ? 0.08 : 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Column(children: [
        Text(step.emoji, style: const TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        Text(step.label,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w900, fontSize: 20)),
        const SizedBox(height: 8),
        Text(step.description,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: t.textMuted, fontSize: 13, height: 1.5)),
      ]),
    );
  }

  Widget _buildTimelineItem(
    AppThemeProvider t, {
    required _Step step,
    required bool done,
    required bool isActive,
    required bool isLast,
  }) {
    final color = isActive
        ? _teal
        : done
            ? _green
            : t.textMuted;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: done
                  ? color.withValues(alpha: 0.15)
                  : t.bg.withValues(alpha: 0.5),
              shape: BoxShape.circle,
              border: Border.all(
                  color: done ? color : t.border,
                  width: isActive ? 2.5 : 1.5),
            ),
            child: Center(
              child: done
                  ? Text(step.emoji,
                      style: const TextStyle(fontSize: 12))
                  : Container(
                      width: 8,
                      height: 8,
                      decoration:
                          BoxDecoration(color: t.border, shape: BoxShape.circle),
                    ),
            ),
          ),
          if (!isLast)
            Container(
                width: 2,
                height: 40,
                margin: const EdgeInsets.symmetric(vertical: 2),
                color: done ? _green.withValues(alpha: 0.35) : t.border),
        ]),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(step.label,
                  style: TextStyle(
                      color: done ? t.textPrimary : t.textMuted,
                      fontWeight: isActive
                          ? FontWeight.w800
                          : FontWeight.w600,
                      fontSize: 14)),
              if (isActive) ...[
                const SizedBox(height: 4),
                Text(step.description,
                    style: TextStyle(
                        color: t.textMuted,
                        fontSize: 12,
                        height: 1.4)),
              ],
            ]),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final AppThemeProvider t;
  final String label;
  final String value;
  const _InfoRow({required this.t, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: TextStyle(
                    color: t.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    color: t.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
