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
    extends State<AdminCommandeEcommerceListScreen>
    with SingleTickerProviderStateMixin {
  late EcommerceService _service;
  late TabController _tabController;
  List<CommandeEcommerce> _actives = [];
  List<CommandeEcommerce> _archives = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _service = EcommerceService(serviceType: widget.serviceType);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _service.getCommandesAdmin(),
      _service.getCommandesArchivedAdmin(),
    ]);
    if (mounted) {
      setState(() {
        _actives = results[0];
        _archives = results[1];
        _loading = false;
      });
    }
  }

  Future<void> _updateStatut(CommandeEcommerce commande, String newStatut) async {
    if (commande.id == null) return;
    final ok = await _service.updateStatutAdmin(commande.id!, newStatut);
    if (ok && mounted) _load();
  }

  Future<void> _archiver(CommandeEcommerce commande) async {
    if (commande.id == null) return;
    final ok = await _service.archiverCommandeAdmin(commande.id!);
    if (ok && mounted) _load();
  }

  Future<void> _desarchiver(CommandeEcommerce commande) async {
    if (commande.id == null) return;
    final ok = await _service.desarchiverCommandeAdmin(commande.id!);
    if (ok && mounted) _load();
  }

  Future<void> _delete(CommandeEcommerce commande) async {
    if (commande.id == null) return;
    final ok = await _service.deleteCommandeAdmin(commande.id!);
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

  Future<void> _confirmDelete(CommandeEcommerce commande) async {
    final t = context.read<AppThemeProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.bgCard,
        title: Text('Supprimer la commande ?',
            style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w800)),
        content: Text(
          'Supprimer définitivement la commande #${commande.id} de ${commande.nom} ${commande.prenom} ?',
          style: TextStyle(color: t.textMuted, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler', style: TextStyle(color: t.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) _delete(commande);
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: widget.accentColor,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: [
            Tab(text: 'Actives (${_actives.length})'),
            Tab(text: 'Archivées (${_archives.length})'),
          ],
        ),
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: widget.accentColor))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(_actives, archived: false, t: t),
                _buildList(_archives, archived: true, t: t),
              ],
            ),
    );
  }

  Widget _buildList(List<CommandeEcommerce> commandes,
      {required bool archived, required AppThemeProvider t}) {
    if (commandes.isEmpty) return _emptyState(t);
    return RefreshIndicator(
      onRefresh: _load,
      color: widget.accentColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: commandes.length,
        itemBuilder: (ctx, i) => _CommandeAdminTile(
          commande: commandes[i],
          accentColor: widget.accentColor,
          t: t,
          isArchived: archived,
          onUpdateStatut: () => _showUpdateDialog(commandes[i]),
          onArchive: () => _archiver(commandes[i]),
          onUnarchive: () => _desarchiver(commandes[i]),
          onDelete: () => _confirmDelete(commandes[i]),
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

class _CommandeAdminTile extends StatefulWidget {
  final CommandeEcommerce commande;
  final Color accentColor;
  final AppThemeProvider t;
  final bool isArchived;
  final VoidCallback onUpdateStatut;
  final VoidCallback onArchive;
  final VoidCallback onUnarchive;
  final VoidCallback onDelete;

  const _CommandeAdminTile({
    required this.commande,
    required this.accentColor,
    required this.t,
    required this.isArchived,
    required this.onUpdateStatut,
    required this.onArchive,
    required this.onUnarchive,
    required this.onDelete,
  });

  @override
  State<_CommandeAdminTile> createState() => _CommandeAdminTileState();
}

class _CommandeAdminTileState extends State<_CommandeAdminTile> {
  bool _expanded = false;

  String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final commande = widget.commande;
    final t = widget.t;
    final accent = widget.accentColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
          color: t.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header ──────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(14),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: accent.withValues(alpha: 0.3))),
                child: Text(commande.statut,
                    style: TextStyle(
                        color: accent,
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

            // ── Détails expandables ──────────────────────────────────────
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Row(children: [
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: accent,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  _expanded ? 'Masquer les détails' : 'Voir les détails',
                  style: TextStyle(
                      color: accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ),
              ]),
            ),

            if (_expanded) ...[
              const SizedBox(height: 10),
              Divider(color: t.border, height: 1),
              const SizedBox(height: 10),

              // Date commande
              if (commande.dateCommande != null) ...[
                _detailRow(t, '📅 Date commande',
                    _formatDate(commande.dateCommande)),
              ],
              if (commande.dateModification != null) ...[
                _detailRow(t, '🔄 Dernière modif.',
                    _formatDate(commande.dateModification)),
              ],

              // Adresse complète
              _detailRow(t, '🏠 Adresse', commande.adresseLivraison),

              // Email
              if (commande.email != null && commande.email!.isNotEmpty)
                _detailRow(t, '✉️ Email', commande.email!),

              // Notes spéciales
              if (commande.notesSpeciales != null &&
                  commande.notesSpeciales!.isNotEmpty)
                _detailRow(t, '📝 Notes', commande.notesSpeciales!),

              // Articles
              if (commande.items.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('🛒 Articles',
                    style: TextStyle(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
                const SizedBox(height: 6),
                ...commande.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(children: [
                        Expanded(
                          child: Text(
                            '• ${item.produitNom ?? 'Produit #${item.produitId}'} × ${item.quantite}',
                            style:
                                TextStyle(color: t.textMuted, fontSize: 12),
                          ),
                        ),
                        Text(
                          '${item.sousTotal.toStringAsFixed(2)} ${item.devise}',
                          style: TextStyle(
                              color: t.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ]),
                    )),
                Divider(color: t.border, height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Total',
                      style: TextStyle(
                          color: t.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13)),
                  Text(
                    '${commande.prixTotal.toStringAsFixed(2)} ${commande.devise}',
                    style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w900,
                        fontSize: 14),
                  ),
                ]),
              ],
            ],

            // ── Actions ──────────────────────────────────────────────────
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                // Modifier le statut (only for non-archived)
                if (!widget.isArchived)
                  _actionButton(
                    icon: Icons.edit_outlined,
                    label: 'Statut',
                    color: accent,
                    onPressed: widget.onUpdateStatut,
                  ),

                // Archiver / Désarchiver
                if (!widget.isArchived)
                  _actionButton(
                    icon: Icons.archive_outlined,
                    label: 'Archiver',
                    color: Colors.orange,
                    onPressed: widget.onArchive,
                  )
                else
                  _actionButton(
                    icon: Icons.unarchive_outlined,
                    label: 'Désarchiver',
                    color: Colors.blue,
                    onPressed: widget.onUnarchive,
                  ),

                // Supprimer
                _actionButton(
                  icon: Icons.delete_outline,
                  label: 'Supprimer',
                  color: Colors.red,
                  onPressed: widget.onDelete,
                ),
              ],
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _detailRow(AppThemeProvider t, String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: TextStyle(
                    color: t.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(color: widget.t.textPrimary, fontSize: 12)),
          ),
        ]),
      );

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) =>
      TextButton.icon(
        icon: Icon(icon, size: 14, color: color),
        label: Text(label,
            style:
                TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          backgroundColor: color.withValues(alpha: 0.08),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: onPressed,
      );
}
