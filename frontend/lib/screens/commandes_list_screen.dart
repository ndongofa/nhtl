// lib/screens/commandes_list_screen.dart
//
// ✅ Dropdown statut ADMINISTRATIF (statut String : EN_ATTENTE, EN_COURS…)
// ✅ Dropdown statut LOGISTIQUE (statutSuivi : 7 étapes CommandeStatus)
// ✅ Bouton suivi → CommandeTrackingScreen
// ✅ Structure miroir de TransportListScreen

import 'package:flutter/material.dart';
import '../models/commande.dart';
import '../services/auth_service.dart';
import '../services/commande_service.dart';
import '../models/logged_user.dart';
import '../widgets/sama_account_menu.dart';
import 'commande_form_screen.dart';
import 'commande_tracking_screen.dart';

// ── Statut ADMINISTRATIF ──────────────────────────────────────────────────────
final Map<String, Color> statutAdminColors = {
  "EN_ATTENTE": Colors.grey,
  "EN_COURS": const Color(0xFFFFB300),
  "LIVRE": const Color(0xFF22C55E),
  "ANNULE": Colors.red,
};

final Map<String, IconData> statutAdminIcons = {
  "EN_ATTENTE": Icons.timelapse,
  "EN_COURS": Icons.sync,
  "LIVRE": Icons.done,
  "ANNULE": Icons.cancel,
};

// ── Statut LOGISTIQUE commande (7 étapes) ─────────────────────────────────────
final Map<String, Color> statutSuiviColors = {
  "EN_ATTENTE": Colors.grey,
  "COMMANDE_CONFIRMEE": const Color(0xFF2296F3),
  "EN_TRANSIT": const Color(0xFFFFB300),
  "EN_DOUANE": Colors.deepPurple,
  "ARRIVE": const Color(0xFF00D4C8),
  "PRET_LIVRAISON": const Color(0xFF22C55E),
  "LIVRE": const Color(0xFF22C55E),
};

final Map<String, IconData> statutSuiviIcons = {
  "EN_ATTENTE": Icons.hourglass_empty,
  "COMMANDE_CONFIRMEE": Icons.shopping_cart_outlined,
  "EN_TRANSIT": Icons.local_shipping_outlined,
  "EN_DOUANE": Icons.gavel_outlined,
  "ARRIVE": Icons.location_on_outlined,
  "PRET_LIVRAISON": Icons.inventory_2_outlined,
  "LIVRE": Icons.celebration_outlined,
};

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

// ── Couleurs UI ───────────────────────────────────────────────────────────────
const Color _bg = Color(0xFF0D1B2E);
const Color _bgSection = Color(0xFF112236);
const Color _bgCard = Color(0xFF1A2E45);
const Color _appBlue = Color(0xFF2296F3);
const Color _amber = Color(0xFFFFB300);
const Color _textPrimary = Color(0xFFF0F6FF);
const Color _textMuted = Color(0xFF7A94B0);
const Color _border = Color(0xFF1E3A55);

// ─────────────────────────────────────────────────────────────────────────────

class CommandesListScreen extends StatefulWidget {
  const CommandesListScreen({Key? key}) : super(key: key);

  @override
  State<CommandesListScreen> createState() => _CommandesListScreenState();
}

class _CommandesListScreenState extends State<CommandesListScreen> {
  final _service = CommandeService();

  late LoggedUser logged;
  List<Commande> commandes = [];
  List<String> possibleStatuses = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    logged = LoggedUser.fromSupabase();
    _init();
  }

  Future<void> _init() async {
    await Future.wait([_loadStatuses(), _loadCommandes()]);
  }

  Future<void> _loadStatuses() async {
    try {
      final statuses = await _service.getStatutsCommandes();
      if (!mounted) return;
      setState(() {
        possibleStatuses = (statuses ?? [])
            .map((e) => e.toString())
            .where((s) => s.trim().isNotEmpty)
            .toList();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        possibleStatuses = const ["EN_ATTENTE", "EN_COURS", "LIVRE", "ANNULE"];
      });
    }
  }

  Future<void> _loadCommandes() async {
    setState(() => _loading = true);
    final all = await _service.getAllCommandes();
    if (!mounted) return;
    setState(() {
      commandes = (all ?? []).where((c) => c.archived != true).toList();
      _loading = false;
    });
  }

  Future<void> _refresh() async {
    await Future.wait([_loadStatuses(), _loadCommandes()]);
  }

  Future<void> _editCommande(Commande commande) async {
    final refresh = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => CommandeFormScreen(commande: commande)));
    if (refresh == true) _refresh();
  }

  void _openTracking(Commande commande) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => CommandeTrackingScreen(commande: commande)));
  }

  Future<void> _deleteCommande(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Supprimer ?",
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
      _refresh();
    }
  }

  Future<void> _archiveCommande(int id) async {
    if (logged.role != "admin") return;
    final res = await _service.archiveCommande(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res ? "Archivée" : "Erreur archivage")));
    _refresh();
  }

  // ✅ Statut ADMINISTRATIF — sans notifications
  Future<void> _changeStatutAdmin(int id, String newStatut) async {
    if (logged.role != "admin") return;
    final res = await _service.changeCommandeStatut(id, newStatut);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res ? "Statut mis à jour" : "Erreur statut")));
    if (res) {
      setState(() {
        final idx = commandes.indexWhere((c) => c.id == id);
        if (idx != -1)
          commandes[idx] = commandes[idx].copyWith(statut: newStatut);
      });
    }
  }

  // ✅ Statut LOGISTIQUE — avec notifications
  Future<void> _updateStatutSuivi(int id, String newStatus) async {
    if (logged.role != "admin") return;
    final res = await _service.updateStatutSuivi(id, newStatus);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res
            ? "✅ Suivi mis à jour → ${_labelSuivi(newStatus)} (notifications envoyées)"
            : "❌ Erreur mise à jour suivi")));
    if (res) {
      setState(() {
        final idx = commandes.indexWhere((c) => c.id == id);
        if (idx != -1)
          commandes[idx] = commandes[idx].copyWith(statutSuivi: newStatus);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final titre =
        logged.role == "admin" ? "Toutes les commandes" : "Mes Commandes";
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bgSection,
        elevation: 0,
        iconTheme: const IconThemeData(color: _textPrimary),
        title: Text(titre,
            style: const TextStyle(
                color: _textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 16)),
        actions: [
          IconButton(
              tooltip: "Mon espace",
              onPressed: () => SamaAccountMenu.open(context),
              icon: const Icon(Icons.dashboard_outlined, color: _textPrimary)),
          IconButton(
              tooltip: "Déconnexion",
              onPressed: () async {
                await AuthService.logout();
                if (!context.mounted) return;
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/', (_) => false);
              },
              icon: const Icon(Icons.logout, color: _textPrimary)),
          IconButton(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh, color: _textPrimary)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _appBlue))
          : commandes.isEmpty
              ? const Center(
                  child: Text('Aucune commande',
                      style: TextStyle(color: _textPrimary)))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: commandes.length,
                  itemBuilder: (context, index) {
                    final commande = commandes[index];
                    return CommandeTile(
                      commande: commande,
                      logged: logged,
                      possibleStatuses: possibleStatuses,
                      onEdit: () => _editCommande(commande),
                      onDelete: () => _deleteCommande(commande.id!),
                      onTracking: () => _openTracking(commande),
                      onArchive: logged.role == "admin"
                          ? () => _archiveCommande(commande.id!)
                          : null,
                      onStatutAdminChanged: logged.role == "admin"
                          ? (s) => _changeStatutAdmin(commande.id!, s)
                          : null,
                      onStatutSuiviChanged: logged.role == "admin"
                          ? (s) => _updateStatutSuivi(commande.id!, s)
                          : null,
                    );
                  },
                ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class CommandeTile extends StatelessWidget {
  final Commande commande;
  final LoggedUser logged;
  final List<String> possibleStatuses;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTracking;
  final VoidCallback? onArchive;
  final void Function(String)? onStatutAdminChanged;
  final void Function(String)? onStatutSuiviChanged;

  const CommandeTile({
    super.key,
    required this.commande,
    required this.logged,
    required this.possibleStatuses,
    required this.onEdit,
    required this.onDelete,
    required this.onTracking,
    this.onArchive,
    this.onStatutAdminChanged,
    this.onStatutSuiviChanged,
  });

  @override
  Widget build(BuildContext context) {
    final adminColor =
        statutAdminColors[commande.statut] ?? Colors.grey.shade400;
    final adminIcon = statutAdminIcons[commande.statut] ?? Icons.info;

    final suiviKey = commande.statutSuivi.toUpperCase().trim();
    final suiviColor = statutSuiviColors[suiviKey] ?? Colors.grey;
    final suiviIcon = statutSuiviIcons[suiviKey] ?? Icons.track_changes;

    // ✅ Tap sur la carte → ouvre directement l'écran de suivi
    return GestureDetector(
      onTap: onTracking,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: adminColor.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
                color: adminColor.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Infos client ─────────────────────────────────────────────────
          Text("${commande.nom} ${commande.prenom}",
              style: const TextStyle(
                  color: _textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 15)),
          const SizedBox(height: 2),
          Text(
              "${commande.plateforme} — ${commande.quantite}x "
              "${commande.prixTotal.toStringAsFixed(2)} ${commande.devise}",
              style: const TextStyle(color: _textMuted, fontSize: 13)),
          Text("→ ${commande.villeLivraison}, ${commande.paysLivraison}",
              style: const TextStyle(color: _textMuted, fontSize: 12)),

          const SizedBox(height: 10),

          // ── Statut logistique (chip + dropdown) ──────────────────────────
          _SuiviChip(
            currentSuivi: suiviKey,
            suiviColor: suiviColor,
            suiviIcon: suiviIcon,
            isAdmin: logged.role == "admin",
            onSuiviChanged: onStatutSuiviChanged,
          ),

          const SizedBox(height: 8),

          // ── Actions ──────────────────────────────────────────────────────
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            // Bouton suivi logistique
            IconButton(
                icon: const Icon(Icons.track_changes,
                    color: Color(0xFF22C55E), size: 20),
                tooltip: "Voir le suivi logistique",
                onPressed: onTracking,
                splashRadius: 18),

            if ((logged.role == "admin") || (commande.userId == logged.userId))
              _iconBtn(Icons.edit, _appBlue, "Modifier", onEdit),

            if ((logged.role == "admin") || (commande.userId == logged.userId))
              _iconBtn(
                  Icons.delete, Colors.red.shade400, "Supprimer", onDelete),

            if (logged.role == "admin" && onArchive != null)
              _iconBtn(Icons.archive, _amber, "Archiver", onArchive!),

            // ✅ Dropdown statut ADMINISTRATIF
            _AdminStatusDropdown(
              current: commande.statut,
              possibleValues: possibleStatuses,
              onChanged: onStatutAdminChanged,
              isAdmin: logged.role == "admin",
              chipColor: adminColor,
              chipIcon: adminIcon,
            ),
          ]),
        ]),
      ), // ✅ fermeture GestureDetector
    );
  }

  Widget _iconBtn(
          IconData icon, Color color, String tooltip, VoidCallback onTap) =>
      IconButton(
          icon: Icon(icon, color: color, size: 20),
          tooltip: tooltip,
          onPressed: onTap,
          splashRadius: 18);
}

// ── Chip + dropdown statut LOGISTIQUE ────────────────────────────────────────

class _SuiviChip extends StatelessWidget {
  final String currentSuivi;
  final Color suiviColor;
  final IconData suiviIcon;
  final bool isAdmin;
  final void Function(String)? onSuiviChanged;

  const _SuiviChip({
    required this.currentSuivi,
    required this.suiviColor,
    required this.suiviIcon,
    required this.isAdmin,
    required this.onSuiviChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const Text("Suivi : ",
          style: TextStyle(
              color: _textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
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
          Text(_labelSuivi(currentSuivi),
              style: TextStyle(
                  color: suiviColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 11)),
        ]),
      ),
      if (isAdmin && onSuiviChanged != null)
        PopupMenuButton<String>(
          icon: const Icon(Icons.arrow_drop_down, color: _textMuted, size: 20),
          color: _bgCard,
          tooltip: "Changer l'étape de suivi",
          itemBuilder: (_) => _statutsSuiviOrdonnes.map((s) {
            final c = statutSuiviColors[s] ?? Colors.grey;
            final i = statutSuiviIcons[s] ?? Icons.info;
            return PopupMenuItem<String>(
              value: s,
              child: Row(children: [
                Icon(i, size: 16, color: s == currentSuivi ? c : _textMuted),
                const SizedBox(width: 8),
                Text(_labelSuivi(s),
                    style: TextStyle(
                        color: s == currentSuivi ? c : _textMuted,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                if (s == currentSuivi) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.check, size: 14, color: c),
                ],
              ]),
            );
          }).toList(),
          onSelected: onSuiviChanged,
        ),
    ]);
  }
}

// ── Dropdown statut ADMINISTRATIF ────────────────────────────────────────────

class _AdminStatusDropdown extends StatelessWidget {
  final String current;
  final List<String> possibleValues;
  final Function(String)? onChanged;
  final bool isAdmin;
  final Color chipColor;
  final IconData chipIcon;

  const _AdminStatusDropdown({
    required this.current,
    required this.possibleValues,
    required this.onChanged,
    required this.isAdmin,
    required this.chipColor,
    required this.chipIcon,
  });

  @override
  Widget build(BuildContext context) {
    final safeValues = possibleValues.isNotEmpty
        ? possibleValues
        : ["EN_ATTENTE", "EN_COURS", "LIVRE", "ANNULE"];
    final safeValue = safeValues.contains(current) ? current : safeValues.first;

    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        decoration: BoxDecoration(
            color: chipColor, borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        margin: const EdgeInsets.only(left: 8),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(chipIcon, color: Colors.white, size: 16),
          const SizedBox(width: 5),
          Text(safeValue,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
        ]),
      ),
      if (isAdmin && onChanged != null)
        PopupMenuButton<String>(
          icon: const Icon(Icons.arrow_drop_down, color: _textMuted),
          color: _bgCard,
          tooltip: "Changer le statut administratif",
          itemBuilder: (_) => safeValues
              .map((s) => PopupMenuItem<String>(
                    value: s,
                    child: Row(children: [
                      Icon(statutAdminIcons[s] ?? Icons.info,
                          size: 16,
                          color: s == current
                              ? (statutAdminColors[s] ?? Colors.grey)
                              : _textMuted),
                      const SizedBox(width: 8),
                      Text(s,
                          style: TextStyle(
                              color: s == current
                                  ? (statutAdminColors[s] ?? Colors.grey)
                                  : _textMuted,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ))
              .toList(),
          onSelected: (v) => onChanged!(v),
        ),
    ]);
  }
}
