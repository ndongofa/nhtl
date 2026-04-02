// lib/screens/commandes_archives_screen.dart

import 'package:flutter/material.dart';
import '../services/commande_service.dart';
import '../models/commande.dart';
import 'commande_tracking_screen.dart';
import 'commandes_list_screen.dart';

// ✅ Réutilise les maps harmonisées depuis commandes_list_screen.dart :
//    statutAdminColors / statutAdminIcons  (statut administratif)
//    statutSuiviColors / statutSuiviIcons  (statut logistique)

// ── Couleurs UI (miroir commandes_list_screen) ────────────────────────────────
const Color _bg = Color(0xFF0D1B2E);
const Color _bgSection = Color(0xFF112236);
const Color _bgCard = Color(0xFF1A2E45);
const Color _appBlue = Color(0xFF2296F3);
const Color _amber = Color(0xFFFFB300);
const Color _green = Color(0xFF22C55E);
const Color _textPrimary = Color(0xFFF0F6FF);
const Color _textMuted = Color(0xFF7A94B0);
const Color _border = Color(0xFF1E3A55);

// ─────────────────────────────────────────────────────────────────────────────

class CommandesArchivesScreen extends StatefulWidget {
  final bool isAdmin;

  const CommandesArchivesScreen({Key? key, required this.isAdmin})
      : super(key: key);

  @override
  State<CommandesArchivesScreen> createState() =>
      _CommandesArchivesScreenState();
}

class _CommandesArchivesScreenState extends State<CommandesArchivesScreen> {
  final _service = CommandeService();

  List<Commande> _archives = [];
  List<String> _possibleStatuses = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Future.wait([_loadArchives(), _loadStatuses()]);
  }

  Future<void> _loadArchives() async {
    setState(() => _loading = true);
    final data = widget.isAdmin
        ? await _service.getCommandesArchivesAdmin()
        : await _service.getCommandesArchivesUser();
    if (!mounted) return;
    setState(() {
      _archives = data ?? [];
      _loading = false;
    });
  }

  Future<void> _loadStatuses() async {
    final statuses = await _service.getStatutsCommandes();
    if (!mounted) return;
    setState(() {
      _possibleStatuses = (statuses ?? [])
          .map((e) => e.toString())
          .where((s) => s.trim().isNotEmpty)
          .toList();
      if (_possibleStatuses.isEmpty) {
        _possibleStatuses = const ["EN_ATTENTE", "EN_COURS", "LIVRE", "ANNULE"];
      }
    });
  }

  Future<void> _refresh() async {
    await Future.wait([_loadArchives(), _loadStatuses()]);
  }

  // ✅ Désarchiver (admin uniquement)
  Future<void> _unarchiveCommande(int id) async {
    final res = await _service.unarchiveCommandeAdmin(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res ? "Désarchivée" : "Erreur désarchivage")));
    if (res) _refresh();
  }

  // ✅ Supprimer définitivement
  Future<void> _deleteCommande(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Supprimer définitivement ?",
            style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w800)),
        content: const Text("Cette action est irréversible.",
            style: TextStyle(color: _textMuted)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child:
                  const Text("Annuler", style: TextStyle(color: _textMuted))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            child: const Text("Supprimer",
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final res = await _service.deleteCommande(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res ? "Supprimée" : "Erreur suppression")));
      if (res) _refresh();
    }
  }

  // ✅ Changer statut ADMINISTRATIF (admin uniquement, sans notifications)
  Future<void> _changeStatutAdmin(int id, String newStatut) async {
    if (!widget.isAdmin) return;
    final res = await _service.changeStatutCommandeAdmin(id, newStatut);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res ? "Statut mis à jour" : "Erreur statut")));
    if (res) {
      setState(() {
        final idx = _archives.indexWhere((c) => c.id == id);
        if (idx != -1)
          _archives[idx] = _archives[idx].copyWith(statut: newStatut);
      });
    }
  }

  // ✅ Changer statut LOGISTIQUE (admin uniquement, avec notifications)
  Future<void> _updateStatutSuivi(int id, String newStatus) async {
    if (!widget.isAdmin) return;
    final res = await _service.updateStatutSuivi(id, newStatus);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res
            ? "✅ Suivi mis à jour (notifications envoyées)"
            : "❌ Erreur mise à jour suivi")));
    if (res) {
      setState(() {
        final idx = _archives.indexWhere((c) => c.id == id);
        if (idx != -1)
          _archives[idx] = _archives[idx].copyWith(statutSuivi: newStatus);
      });
    }
  }

  void _openTracking(Commande commande) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => CommandeTrackingScreen(commande: commande)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bgSection,
        elevation: 0,
        iconTheme: const IconThemeData(color: _textPrimary),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _textPrimary),
          tooltip: "Retour à la liste",
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const CommandesListScreen()));
            }
          },
        ),
        title: const Text("Commandes archivées",
            style: TextStyle(
                color: _textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 16)),
        actions: [
          IconButton(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh, color: _textPrimary)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _appBlue))
          : _archives.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.archive_outlined, color: _textMuted, size: 48),
                      const SizedBox(height: 12),
                      const Text("Aucune commande archivée",
                          style: TextStyle(color: _textMuted, fontSize: 15)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _archives.length,
                  itemBuilder: (context, index) {
                    final c = _archives[index];
                    return _ArchiveTile(
                      commande: c,
                      isAdmin: widget.isAdmin,
                      possibleStatuses: _possibleStatuses,
                      onUnarchive: () => _unarchiveCommande(c.id!),
                      onDelete: () => _deleteCommande(c.id!),
                      onTracking: () => _openTracking(c),
                      onStatutAdminChanged: widget.isAdmin
                          ? (s) => _changeStatutAdmin(c.id!, s)
                          : null,
                      onStatutSuiviChanged: widget.isAdmin
                          ? (s) => _updateStatutSuivi(c.id!, s)
                          : null,
                    );
                  },
                ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ArchiveTile extends StatelessWidget {
  final Commande commande;
  final bool isAdmin;
  final List<String> possibleStatuses;
  final VoidCallback onUnarchive;
  final VoidCallback onDelete;
  final VoidCallback onTracking;
  final void Function(String)? onStatutAdminChanged;
  final void Function(String)? onStatutSuiviChanged;

  const _ArchiveTile({
    required this.commande,
    required this.isAdmin,
    required this.possibleStatuses,
    required this.onUnarchive,
    required this.onDelete,
    required this.onTracking,
    this.onStatutAdminChanged,
    this.onStatutSuiviChanged,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ Statut ADMINISTRATIF
    final adminColor =
        statutAdminColors[commande.statut] ?? Colors.grey.shade400;
    final adminIcon = statutAdminIcons[commande.statut] ?? Icons.info;

    // ✅ Statut LOGISTIQUE
    final suiviKey = commande.statutSuivi.toUpperCase().trim();
    final suiviColor = statutSuiviColors[suiviKey] ?? Colors.grey;
    final suiviIcon = statutSuiviIcons[suiviKey] ?? Icons.track_changes;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: adminColor.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
              color: adminColor.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── En-tête ────────────────────────────────────────────────────────
        Row(children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text("${commande.nom} ${commande.prenom}",
                    style: const TextStyle(
                        color: _textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 15)),
                const SizedBox(height: 2),
                Text(
                    "${commande.plateforme} — "
                    "${commande.quantite}x "
                    "${commande.prixTotal.toStringAsFixed(2)} ${commande.devise}",
                    style: const TextStyle(color: _textMuted, fontSize: 12)),
                Text("→ ${commande.villeLivraison}, ${commande.paysLivraison}",
                    style: const TextStyle(color: _textMuted, fontSize: 12)),
              ])),
          // Badge archivé
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: _border, borderRadius: BorderRadius.circular(20)),
            child: const Text("ARCHIVÉE",
                style: TextStyle(
                    color: _textMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 9,
                    letterSpacing: 0.8)),
          ),
        ]),

        const SizedBox(height: 10),

        // ── Chip suivi logistique + dropdown ──────────────────────────────
        Row(children: [
          const Text("Suivi : ",
              style: TextStyle(
                  color: _textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: suiviColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: suiviColor.withValues(alpha: 0.35)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(suiviIcon, color: suiviColor, size: 13),
              const SizedBox(width: 5),
              Text(_labelSuivi(suiviKey),
                  style: TextStyle(
                      color: suiviColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 11)),
            ]),
          ),
          if (isAdmin && onStatutSuiviChanged != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.arrow_drop_down,
                  color: _textMuted, size: 20),
              color: _bgCard,
              tooltip: "Changer l'étape de suivi",
              itemBuilder: (_) => _statutsSuiviOrdonnes.map((s) {
                final c = statutSuiviColors[s] ?? Colors.grey;
                final i = statutSuiviIcons[s] ?? Icons.info;
                return PopupMenuItem<String>(
                  value: s,
                  child: Row(children: [
                    Icon(i, size: 16, color: s == suiviKey ? c : _textMuted),
                    const SizedBox(width: 8),
                    Text(_labelSuivi(s),
                        style: TextStyle(
                            color: s == suiviKey ? c : _textMuted,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                    if (s == suiviKey) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.check, size: 14, color: c),
                    ],
                  ]),
                );
              }).toList(),
              onSelected: onStatutSuiviChanged,
            ),
        ]),

        const SizedBox(height: 8),

        // ── Actions + dropdown statut admin ───────────────────────────────
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          // Bouton suivi logistique
          IconButton(
              icon: const Icon(Icons.track_changes,
                  color: Color(0xFF22C55E), size: 20),
              tooltip: "Voir le suivi logistique",
              onPressed: onTracking,
              splashRadius: 18),

          // Désarchiver
          if (isAdmin)
            IconButton(
                icon: const Icon(Icons.unarchive, color: _appBlue, size: 20),
                tooltip: "Désarchiver",
                onPressed: onUnarchive,
                splashRadius: 18),

          // Supprimer
          if (isAdmin)
            IconButton(
                icon: Icon(Icons.delete, color: Colors.red.shade400, size: 20),
                tooltip: "Supprimer définitivement",
                onPressed: onDelete,
                splashRadius: 18),

          // ✅ Dropdown statut ADMINISTRATIF
          Container(
            decoration: BoxDecoration(
                color: adminColor, borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            margin: const EdgeInsets.only(left: 8),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(adminIcon, color: Colors.white, size: 16),
              const SizedBox(width: 5),
              Text(commande.statut,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ]),
          ),
          if (isAdmin && onStatutAdminChanged != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.arrow_drop_down, color: _textMuted),
              color: _bgCard,
              tooltip: "Changer le statut administratif",
              itemBuilder: (_) {
                final safeValues = possibleStatuses.isNotEmpty
                    ? possibleStatuses
                    : ["EN_ATTENTE", "EN_COURS", "LIVRE", "ANNULE"];
                return safeValues
                    .map((s) => PopupMenuItem<String>(
                          value: s,
                          child: Row(children: [
                            Icon(statutAdminIcons[s] ?? Icons.info,
                                size: 16,
                                color: s == commande.statut
                                    ? (statutAdminColors[s] ?? Colors.grey)
                                    : _textMuted),
                            const SizedBox(width: 8),
                            Text(s,
                                style: TextStyle(
                                    color: s == commande.statut
                                        ? (statutAdminColors[s] ?? Colors.grey)
                                        : _textMuted,
                                    fontWeight: FontWeight.w600)),
                          ]),
                        ))
                    .toList();
              },
              onSelected: (v) => onStatutAdminChanged!(v),
            ),
        ]),
      ]),
    );
  }
}

// ── Helpers logistique (miroir commandes_list_screen) ─────────────────────────

const List<String> _statutsSuiviOrdonnes = [
  "EN_ATTENTE",
  "COMMANDE_CONFIRMEE",
  "EN_TRANSIT",
  "EN_DOUANE",
  "ARRIVE",
  "PRET_LIVRAISON",
  "LIVRE",
];

String _labelSuivi(String s) {
  switch (s) {
    case "EN_ATTENTE":
      return "En attente";
    case "COMMANDE_CONFIRMEE":
      return "Commande confirmée";
    case "EN_TRANSIT":
      return "En transit";
    case "EN_DOUANE":
      return "En douane";
    case "ARRIVE":
      return "Arrivé";
    case "PRET_LIVRAISON":
      return "Prêt à livrer";
    case "LIVRE":
      return "Livré";
    default:
      return s;
  }
}
