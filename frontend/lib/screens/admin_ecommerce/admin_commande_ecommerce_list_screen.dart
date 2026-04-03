// lib/screens/admin_ecommerce/admin_commande_ecommerce_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/commande_ecommerce.dart';
import '../../providers/app_theme_provider.dart';
import '../../services/ecommerce_service.dart';

const List<String> _kStatuts = [
  'EN_ATTENTE',
  'CONFIRMEE',
  'EN_PREPARATION',
  'EN_TRANSIT',
  'LIVREE',
];

class AdminCommandeEcommerceListScreen extends StatefulWidget {
  final String serviceType;
  final String serviceLabel;
  final Color accentColor;

  const AdminCommandeEcommerceListScreen({
    Key? key,
    required this.serviceType,
    required this.serviceLabel,
    required this.accentColor,
  }) : super(key: key);

  @override
  State<AdminCommandeEcommerceListScreen> createState() =>
      _AdminCommandeEcommerceListScreenState();
}

class _AdminCommandeEcommerceListScreenState
    extends State<AdminCommandeEcommerceListScreen> {
  late EcommerceService _service;
  List<CommandeEcommerce> _commandes = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _service = EcommerceService(serviceType: widget.serviceType);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _commandes = await _service.getCommandesAdmin();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _updateStatut(CommandeEcommerce commande, String newStatut) async {
    if (commande.id == null) return;
    final ok = await _service.updateStatutAdmin(commande.id!, newStatut);
    if (ok && mounted) _load();
  }

  Future<void> _showUpdateDialog(CommandeEcommerce commande) async {
    final t = context.read<AppThemeProvider>();
    String selected = commande.statut;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: t.bgCard,
          title: Text(
            'Modifier le statut',
            style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Commande #${commande.id} — ${commande.nom} ${commande.prenom}',
                style: TextStyle(color: t.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ..._kStatuts.map((statut) => RadioListTile<String>(
                    value: statut,
                    groupValue: selected,
                    title: Text(statut,
                        style: TextStyle(
                            color: t.textPrimary, fontSize: 13)),
                    activeColor: widget.accentColor,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) {
                      if (v != null) setDialogState(() => selected = v);
                    },
                  )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Annuler',
                  style: TextStyle(color: t.textMuted)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _updateStatut(commande, selected);
              },
              child: Text('Enregistrer',
                  style: TextStyle(
                      color: widget.accentColor,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppThemeProvider>();

    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.topBarBg,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Commandes — ${widget.serviceLabel}',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: widget.accentColor))
          : _commandes.isEmpty
              ? _emptyState(t)
              : RefreshIndicator(
                  onRefresh: _load,
                  color: widget.accentColor,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _commandes.length,
                    itemBuilder: (ctx, i) => _CommandeAdminTile(
                      commande: _commandes[i],
                      accentColor: widget.accentColor,
                      t: t,
                      onUpdateStatut: () => _showUpdateDialog(_commandes[i]),
                    ),
                  ),
                ),
    );
  }

  Widget _emptyState(AppThemeProvider t) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🛍️', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('Aucune commande',
              style: TextStyle(
                  color: t.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16)),
        ]),
      );
}

// ── Tuile commande admin ───────────────────────────────────────────────────────

class _CommandeAdminTile extends StatelessWidget {
  final CommandeEcommerce commande;
  final Color accentColor;
  final AppThemeProvider t;
  final VoidCallback onUpdateStatut;

  const _CommandeAdminTile({
    required this.commande,
    required this.accentColor,
    required this.t,
    required this.onUpdateStatut,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: t.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(
              '#${commande.id} — ${commande.nom} ${commande.prenom}',
              style: TextStyle(
                  color: t.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 14),
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: accentColor.withValues(alpha: 0.3))),
            child: Text(commande.statut,
                style: TextStyle(
                    color: accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 6),
        Text(
          '${commande.items.length} article(s) · ${commande.prixTotal.toStringAsFixed(2)} ${commande.devise}',
          style: TextStyle(color: t.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(
          '📍 ${commande.villeLivraison}, ${commande.paysLivraison}',
          style: TextStyle(color: t.textMuted, fontSize: 12),
        ),
        if (commande.numeroTelephone.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            '📞 ${commande.numeroTelephone}',
            style: TextStyle(color: t.textMuted, fontSize: 12),
          ),
        ],
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            icon: Icon(Icons.edit_outlined, size: 16, color: accentColor),
            label: Text('Modifier le statut',
                style: TextStyle(
                    color: accentColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
            style: TextButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              backgroundColor: accentColor.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: onUpdateStatut,
          ),
        ),
      ]),
    );
  }
}
