// lib/screens/ecommerce/ecommerce_tracking_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/commande_ecommerce.dart';
import '../../providers/app_theme_provider.dart';

class _Step {
  final String key;
  final String emoji;
  final String label;
  final String description;
  const _Step(this.key, this.emoji, this.label, this.description);
}

class EcommerceTrackingScreen extends StatelessWidget {
  final CommandeEcommerce commande;
  final Color accentColor;

  const EcommerceTrackingScreen({
    Key? key,
    required this.commande,
    required this.accentColor,
  }) : super(key: key);

  static const List<_Step> _steps = [
    _Step('EN_ATTENTE', '⏳', 'En attente',
        'Commande reçue, en attente de confirmation.'),
    _Step('CONFIRMEE', '✅', 'Confirmée',
        'Votre commande a été confirmée et est en préparation.'),
    _Step('EN_PREPARATION', '📦', 'En préparation',
        'Votre colis est en cours de préparation.'),
    _Step('EN_TRANSIT', '🚚', 'En transit',
        'Votre colis est en acheminement vers vous.'),
    _Step('LIVREE', '🎉', 'Livrée', 'Votre commande a été livrée. Merci !'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppThemeProvider>();
    final currentStatut = commande.statut.toUpperCase().trim();
    final currentIdx = _steps
        .indexWhere((s) => s.key == currentStatut)
        .clamp(0, _steps.length - 1);
    final currentStep = _steps[currentIdx];
    final isFinal = currentIdx == _steps.length - 1;

    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.topBarBg,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Suivi commande',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          Text('#${commande.id} — ${commande.serviceType}',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 12)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // ── Statut actuel ──────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [
                    accentColor.withValues(alpha: isFinal ? 0.2 : 0.15),
                    accentColor.withValues(alpha: isFinal ? 0.08 : 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: accentColor.withValues(alpha: 0.35), width: 1.5),
            ),
            child: Column(children: [
              Text(currentStep.emoji,
                  style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(currentStep.label,
                  style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 20)),
              const SizedBox(height: 8),
              Text(currentStep.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: t.textMuted, fontSize: 13, height: 1.5)),
            ]),
          ),

          const SizedBox(height: 20),

          // ── Timeline ──────────────────────────────────────────────────
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
                  .map((e) => _TimelineRow(
                        t: t,
                        step: e.value,
                        done: e.key <= currentIdx,
                        isActive: e.key == currentIdx,
                        isLast: e.key == _steps.length - 1,
                        accentColor: accentColor,
                      ))
                  .toList(),
            ),
          ),

          const SizedBox(height: 20),

          // ── Détails ───────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                color: t.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: t.border)),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text('Détails de la commande',
                  style: TextStyle(
                      color: t.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 14)),
              const SizedBox(height: 14),
              ...commande.items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(children: [
                      Expanded(
                          child: Text(
                        '${item.produitNom ?? 'Article'} × ${item.quantite}',
                        style: TextStyle(
                            color: t.textPrimary, fontSize: 13),
                      )),
                      Text(
                        '${item.sousTotal.toStringAsFixed(2)} ${item.devise}',
                        style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 13),
                      ),
                    ]),
                  )),
              Divider(color: t.border, height: 24),
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                Text('Total',
                    style: TextStyle(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 15)),
                Text(
                  '${commande.prixTotal.toStringAsFixed(2)} ${commande.devise}',
                  style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 16),
                ),
              ]),
              Divider(color: t.border, height: 24),
              _Row(t: t,
                  label: 'Livraison',
                  value:
                      '${commande.villeLivraison}, ${commande.paysLivraison}'),
              _Row(t: t, label: 'Statut', value: commande.statut),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final AppThemeProvider t;
  final _Step step;
  final bool done;
  final bool isActive;
  final bool isLast;
  final Color accentColor;
  const _TimelineRow(
      {required this.t,
      required this.step,
      required this.done,
      required this.isActive,
      required this.isLast,
      required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? accentColor
        : done
            ? AppThemeProvider.green
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
                    width: isActive ? 2.5 : 1.5)),
            child: Center(
                child: done
                    ? Text(step.emoji,
                        style: const TextStyle(fontSize: 12))
                    : Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                            color: t.border, shape: BoxShape.circle))),
          ),
          if (!isLast)
            Container(
                width: 2,
                height: 40,
                margin: const EdgeInsets.symmetric(vertical: 2),
                color: done
                    ? AppThemeProvider.green.withValues(alpha: 0.35)
                    : t.border),
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

class _Row extends StatelessWidget {
  final AppThemeProvider t;
  final String label;
  final String value;
  const _Row({required this.t, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        SizedBox(
            width: 100,
            child: Text(label,
                style: TextStyle(
                    color: t.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600))),
        Expanded(
            child: Text(value,
                style: TextStyle(
                    color: t.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500))),
      ]),
    );
  }
}
