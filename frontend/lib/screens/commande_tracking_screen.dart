// lib/screens/commande_tracking_screen.dart
//
// ✅ Lit commande.statutSuivi (suivi LOGISTIQUE CommandeStatus)
// ✅ Ne lit PAS commande.statut (statut ADMINISTRATIF)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/commande.dart';
import '../providers/app_theme_provider.dart';

class CommandeTrackingScreen extends StatelessWidget {
  final Commande commande;

  const CommandeTrackingScreen({Key? key, required this.commande})
      : super(key: key);

  static const List<_Step> _steps = [
    _Step('EN_ATTENTE', '⏳', 'En attente',
        'Votre commande a été reçue, en attente de traitement.'),
    _Step('COMMANDE_CONFIRMEE', '🛒', 'Commande confirmée',
        'Votre commande a été passée sur la plateforme.'),
    _Step('EN_TRANSIT', '🚚', 'En transit',
        'Votre colis est en cours d\'acheminement.'),
    _Step('EN_DOUANE', '🛃', 'En douane', 'Traitement douanier en cours.'),
    _Step('ARRIVE', '📍', 'Arrivé à l\'entrepôt',
        'Votre colis est arrivé. La livraison est en cours d\'organisation.'),
    _Step('PRET_LIVRAISON', '📦', 'Prêt à être livré',
        'Vous serez contacté très prochainement pour la livraison.'),
    _Step('LIVRE', '🎉', 'Livré',
        'Votre commande a été livrée. Merci pour votre confiance !'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppThemeProvider>();

    // ✅ Lit statutSuivi (logistique) — jamais statut (administratif)
    final currentStatut = commande.statutSuivi.toUpperCase().trim();
    final currentIdx = _steps
        .indexWhere((s) => s.key == currentStatut)
        .clamp(0, _steps.length - 1);
    final currentStep = _steps[currentIdx];
    final isFinal = currentIdx == _steps.length - 1;

    final refLabel = '#${commande.id ?? '?'} — '
        '${commande.plateforme} → ${commande.paysLivraison}';

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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // ── Carte statut actuel ──────────────────────────────────────────
          _StatusCard(t: t, step: currentStep, isFinal: isFinal),
          const SizedBox(height: 24),

          // ── Timeline ─────────────────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: t.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: t.border),
            ),
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

          // ── Infos commande ────────────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: t.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: t.border),
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Détails de la commande',
                  style: TextStyle(
                      color: t.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 14)),
              const SizedBox(height: 14),
              _InfoRow(t: t, label: 'Plateforme', value: commande.plateforme),
              _InfoRow(
                  t: t,
                  label: 'Livraison',
                  value:
                      '${commande.villeLivraison}, ${commande.paysLivraison}'),
              _InfoRow(t: t, label: 'Quantité', value: '${commande.quantite}'),
              _InfoRow(
                  t: t,
                  label: 'Total',
                  value:
                      '${commande.prixTotal.toStringAsFixed(2)} ${commande.devise}'),
              if (commande.gpNom != null && commande.gpNom!.isNotEmpty)
                _InfoRow(
                    t: t,
                    label: 'Agent GP',
                    value: '${commande.gpPrenom ?? ''} ${commande.gpNom ?? ''}'
                        .trim()),
              const Divider(height: 24),
              _InfoRow(t: t, label: 'Suivi', value: currentStep.label),
              _InfoRow(t: t, label: 'Dossier', value: commande.statut),
            ]),
          ),

          const SizedBox(height: 32),
        ]),
      ),
    );
  }
}

// ── Widgets internes ──────────────────────────────────────────────────────────

class _Step {
  final String key;
  final String emoji;
  final String label;
  final String description;
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
    final color = isFinal ? AppThemeProvider.green : AppThemeProvider.amber;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
      ),
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
  final bool done;
  final bool isActive;
  final bool isLast;
  const _TimelineItem(
      {required this.t,
      required this.step,
      required this.done,
      required this.isActive,
      required this.isLast});

  @override
  Widget build(BuildContext context) {
    final color = done
        ? (isActive ? AppThemeProvider.amber : AppThemeProvider.green)
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
            border: Border.all(color: color, width: done ? 2 : 1),
          ),
          child: Center(
            child: done
                ? Text(step.emoji, style: const TextStyle(fontSize: 14))
                : Container(
                    width: 8,
                    height: 8,
                    decoration:
                        BoxDecoration(shape: BoxShape.circle, color: color)),
          ),
        ),
        if (!isLast)
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 2,
            height: 42,
            color: (done && !isActive)
                ? AppThemeProvider.green.withValues(alpha: 0.35)
                : t.border.withValues(alpha: 0.35),
          ),
      ]),
      const SizedBox(width: 14),
      Expanded(
          child: Padding(
        padding: EdgeInsets.only(top: 4, bottom: isLast ? 0 : 26),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(step.label,
              style: TextStyle(
                  color: isActive
                      ? AppThemeProvider.amber
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
  final String label;
  final String value;
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
