// lib/screens/transport_tracking_screen.dart
//
// ✅ Suivi structuré des étapes d'un transport (côté client)
// ✅ Extension TransportTracking alignée sur le modèle Flutter existant
//    (champ `statut` String, pas encore `statutSuivi` Enum côté Flutter)
// ✅ Zéro régression : aucun champ ajouté au modèle Transport.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transport.dart';
import '../providers/app_theme_provider.dart';

class TransportTrackingScreen extends StatelessWidget {
  final Transport transport;

  const TransportTrackingScreen({Key? key, required this.transport})
      : super(key: key);

  // ── Étapes — clés alignées sur TransportStatus.java ──────────────────────
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

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppThemeProvider>();

    // ✅ Utilise le champ `statut` String existant du modèle Flutter
    // Quand vous ajouterez `statutSuivi` au modèle, remplacez simplement
    // `transport.statut` par `transport.statutSuivi ?? transport.statut`
    final statut = (transport.statut).toUpperCase().trim();
    final currentIdx =
        _steps.indexWhere((s) => s.key == statut).clamp(0, _steps.length - 1);
    final currentStep = _steps[currentIdx];
    final isFinal = currentIdx == _steps.length - 1;

    // ✅ Référence lisible construite depuis les champs existants
    final refLabel = '#${transport.id ?? '?'} — '
        '${transport.paysExpediteur.isNotEmpty ? transport.paysExpediteur : '?'}'
        ' → '
        '${transport.paysDestinataire.isNotEmpty ? transport.paysDestinataire : '?'}';

    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.topBarBg,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Suivi transport',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          Text(refLabel,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65), fontSize: 12)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // ── Carte statut actuel ────────────────────────────────────────────
          _StatusCard(t: t, step: currentStep, isFinal: isFinal),
          const SizedBox(height: 24),

          // ── Timeline ──────────────────────────────────────────────────────
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

          // ── Infos transport ────────────────────────────────────────────────
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
              Text('Détails du transport',
                  style: TextStyle(
                      color: t.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 14)),
              const SizedBox(height: 14),
              // ✅ Tous ces champs existent dans le modèle Flutter actuel
              _InfoRow(
                  t: t,
                  label: 'Expéditeur',
                  value:
                      '${transport.villeExpediteur}, ${transport.paysExpediteur}'),
              _InfoRow(
                  t: t,
                  label: 'Destinataire',
                  value:
                      '${transport.villeDestinataire}, ${transport.paysDestinataire}'),
              _InfoRow(
                  t: t,
                  label: 'Marchandise',
                  value: transport.typesMarchandise.isNotEmpty
                      ? transport.typesMarchandise
                      : '—'),
              if (transport.poids != null)
                _InfoRow(t: t, label: 'Poids', value: '${transport.poids} kg'),
              if (transport.gpNom != null && transport.gpNom!.isNotEmpty)
                _InfoRow(
                    t: t,
                    label: 'Agent GP',
                    value:
                        '${transport.gpPrenom ?? ''} ${transport.gpNom ?? ''}'
                            .trim()),
              _InfoRow(t: t, label: 'Statut brut', value: transport.statut),
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
    final color = isFinal ? AppThemeProvider.green : AppThemeProvider.appBlue;
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
        Text(step.emoji, style: const TextStyle(fontSize: 42)),
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
  const _TimelineItem({
    required this.t,
    required this.step,
    required this.done,
    required this.isActive,
    required this.isLast,
  });

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
            height: 40,
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
  final String label;
  final String value;
  const _InfoRow({required this.t, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            width: 100,
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
