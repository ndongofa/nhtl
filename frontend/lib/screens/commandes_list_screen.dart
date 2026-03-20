import 'package:flutter/material.dart';
import 'package:sama/screens/commandes_archives_screen.dart';
import '../models/commande.dart';
import '../services/commande_service.dart';
import '../models/logged_user.dart';
import 'commande_form_screen.dart';
import '../services/gp_service.dart';
import '../models/gp_agent.dart';

final Map<String, Color> statutColors = {
  "EN_ATTENTE": Colors.grey,
  "CONFIRMEE": Color(0xFF22C55E),
  "EN_TRAITEMENT": Color(0xFFFFB300),
  "EXPEDIEE": Color(0xFF42AAFE),
  "LIVREE": Color(0xFF2296F3),
  "ANNULEE": Colors.red,
  "REMBOURSEE": Colors.purple,
  "ARCHIVEE": Colors.grey,
};

final Map<String, IconData> statutIcons = {
  "EN_ATTENTE": Icons.timelapse,
  "CONFIRMEE": Icons.check_circle,
  "EN_TRAITEMENT": Icons.sync,
  "EXPEDIEE": Icons.local_shipping_outlined,
  "LIVREE": Icons.done,
  "ANNULEE": Icons.cancel,
  "REMBOURSEE": Icons.currency_exchange,
  "ARCHIVEE": Icons.archive,
};

// ── Palette ───────────────────────────────────────────────────────────────
const Color _bg = Color(0xFF0D1B2E);
const Color _bgSection = Color(0xFF112236);
const Color _bgCard = Color(0xFF1A2E45);
const Color _appBlue = Color(0xFF2296F3);
const Color _amber = Color(0xFFFFB300);
const Color _textPrimary = Color(0xFFF0F6FF);
const Color _textMuted = Color(0xFF7A94B0);
const Color _border = Color(0xFF1E3A55);

class CommandesListScreen extends StatefulWidget {
  const CommandesListScreen({Key? key}) : super(key: key);

  @override
  State<CommandesListScreen> createState() => _CommandesListScreenState();
}

class _CommandesListScreenState extends State<CommandesListScreen> {
  final _service = CommandeService();
  final _gpService = GpService();

  late LoggedUser logged;
  List<Commande> commandes = [];
  List<String> possibleStatuses = [];
  bool _loadingStatuses = false;

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
    setState(() => _loadingStatuses = true);
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
        possibleStatuses = const [
          "EN_ATTENTE",
          "CONFIRMEE",
          "EN_TRAITEMENT",
          "EXPEDIEE",
          "LIVREE",
          "ANNULEE",
          "REMBOURSEE"
        ];
      });
    } finally {
      if (mounted) setState(() => _loadingStatuses = false);
    }
  }

  Future<void> _loadCommandes() async {
    final allCmds = logged.role == "admin"
        ? await _service.getAllCommandesAdmin()
        : await _service.getAllCommandes();
    if (!mounted) return;
    setState(() {
      commandes = (allCmds ?? []).where((c) => c.archived != true).toList();
    });
  }

  Future<void> _refresh() async {
    await Future.wait([_loadStatuses(), _loadCommandes()]);
  }

  Future<void> _goToArchivesScreen() async {
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                CommandesArchivesScreen(isAdmin: logged.role == "admin")));
    _refresh();
  }

  Future<void> _editCommande(Commande commande) async {
    final refresh = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => CommandeFormScreen(commande: commande)));
    if (refresh == true) _refresh();
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
          SnackBar(content: Text(res ? "Supprimé" : "Erreur suppression")));
      _refresh();
    }
  }

  Future<void> _archiveCommande(int id) async {
    final res = await _service.archiveCommandeAdmin(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res ? "Archivée" : "Erreur archivage")));
    _refresh();
  }

  Future<void> _changeStatutCommande(int id, String newStatut) async {
    final res = await _service.changeStatutCommandeAdmin(id, newStatut);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res ? "Statut changé" : "Erreur statut")));
    if (res) {
      setState(() {
        final idx = commandes.indexWhere((c) => c.id == id);
        if (idx != -1)
          commandes[idx] = commandes[idx].copyWith(statut: newStatut);
      });
    }
  }

  Future<GpAgent?> _pickGpDialog() async {
    try {
      final gps = await _gpService.getActive();
      if (!mounted) return null;
      if (gps.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Aucun GP actif disponible.")));
        return null;
      }
      return showDialog<GpAgent>(
        context: context,
        builder: (_) => SimpleDialog(
          backgroundColor: _bgCard,
          title: const Text("Choisir un GP",
              style:
                  TextStyle(color: _textPrimary, fontWeight: FontWeight.w800)),
          children: gps
              .map((gp) => SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, gp),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(children: [
                        Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                                color: _appBlue.withValues(alpha: 0.15),
                                shape: BoxShape.circle),
                            child: Center(
                                child: Text(
                                    gp.prenom.isNotEmpty
                                        ? gp.prenom[0].toUpperCase()
                                        : 'G',
                                    style: const TextStyle(
                                        color: _appBlue,
                                        fontWeight: FontWeight.w900)))),
                        const SizedBox(width: 10),
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(gp.fullName,
                                  style: const TextStyle(
                                      color: _textPrimary,
                                      fontWeight: FontWeight.w700)),
                              Text(gp.phoneNumber ?? '—',
                                  style: const TextStyle(
                                      color: _textMuted, fontSize: 12)),
                            ]),
                      ]),
                    ),
                  ))
              .toList(),
        ),
      );
    } catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Erreur chargement GP: $e")));
      return null;
    }
  }

  Future<void> _assignGpToCommande(Commande commande) async {
    final gp = await _pickGpDialog();
    if (gp == null) return;
    try {
      await _gpService.assignGpToCommande(
          commandeId: commande.id!, gpId: gp.id, newStatut: "EN_TRAITEMENT");
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("GP assigné: ${gp.fullName}")));
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Erreur assignation GP: $e")));
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
              onPressed: _refresh,
              icon: const Icon(Icons.refresh, color: _textPrimary)),
          IconButton(
              icon: const Icon(Icons.archive, color: _textPrimary),
              tooltip: "Commandes archivées",
              onPressed: _goToArchivesScreen),
        ],
      ),
      body: commandes.isEmpty
          ? Center(
              child: _loadingStatuses
                  ? const CircularProgressIndicator(color: _appBlue)
                  : const Text('Aucune commande',
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
                  onArchive: logged.role == "admin"
                      ? () => _archiveCommande(commande.id!)
                      : null,
                  onStatutChanged: logged.role == "admin"
                      ? (s) => _changeStatutCommande(commande.id!, s)
                      : null,
                  onAssignGp: logged.role == "admin"
                      ? () => _assignGpToCommande(commande)
                      : null,
                );
              },
            ),
    );
  }
}

class CommandeTile extends StatelessWidget {
  final Commande commande;
  final LoggedUser logged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onArchive;
  final void Function(String)? onStatutChanged;
  final VoidCallback? onAssignGp;
  final List<String> possibleStatuses;

  const CommandeTile({
    super.key,
    required this.commande,
    required this.logged,
    required this.onEdit,
    required this.onDelete,
    this.onArchive,
    this.onStatutChanged,
    this.onAssignGp,
    required this.possibleStatuses,
  });

  @override
  Widget build(BuildContext context) {
    final color = statutColors[commande.statut] ?? Colors.grey.shade400;
    final icon = statutIcons[commande.statut] ?? Icons.info;
    final gpInfo = _buildGpInfo();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("${commande.nom} ${commande.prenom}",
            style: const TextStyle(
                color: _textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 15)),
        const SizedBox(height: 2),
        Text(
            "${commande.plateforme} — ${commande.prixTotal.toStringAsFixed(2)} ${commande.devise}",
            style: const TextStyle(color: _textMuted, fontSize: 13)),
        if (gpInfo != null) ...[const SizedBox(height: 8), gpInfo],
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          if ((logged.role == "admin") || (commande.userId == logged.userId))
            _iconBtn(Icons.edit, _appBlue, "Modifier", onEdit),
          if ((logged.role == "admin") || (commande.userId == logged.userId))
            _iconBtn(Icons.delete, Colors.red.shade400, "Supprimer", onDelete),
          if (logged.role == "admin" && onArchive != null)
            _iconBtn(Icons.archive, _amber, "Archiver", onArchive!),
          if (logged.role == "admin" && onAssignGp != null)
            _iconBtn(Icons.badge_outlined, Colors.deepPurple.shade300,
                "Assigner GP", onAssignGp!),
          ModernStatusDropdown(
              current: commande.statut,
              possibleValues: possibleStatuses,
              onChanged: onStatutChanged,
              isAdmin: logged.role == "admin",
              chipColor: color,
              chipIcon: icon),
        ]),
      ]),
    );
  }

  Widget _iconBtn(
      IconData icon, Color color, String tooltip, VoidCallback onTap) {
    return IconButton(
        icon: Icon(icon, color: color, size: 20),
        tooltip: tooltip,
        onPressed: onTap,
        splashRadius: 18);
  }

  Widget? _buildGpInfo() {
    final gpPrenom = (commande.gpPrenom ?? '').trim();
    final gpNom = (commande.gpNom ?? '').trim();
    final gpPhone = (commande.gpPhoneNumber ?? '').trim();
    if (gpPrenom.isEmpty && gpNom.isEmpty && gpPhone.isEmpty) return null;
    final name = ('$gpPrenom $gpNom').trim();
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.20)),
      ),
      child: Row(children: [
        const Icon(Icons.verified_user, color: Colors.deepPurple, size: 16),
        const SizedBox(width: 8),
        Expanded(
            child: Text(
          'GP: ${name.isEmpty ? "—" : name}${gpPhone.isNotEmpty ? " • $gpPhone" : ""}',
          style: const TextStyle(
              color: _textPrimary, fontWeight: FontWeight.w600, fontSize: 12),
        )),
      ]),
    );
  }
}

class ModernStatusDropdown extends StatelessWidget {
  final String current;
  final List<String> possibleValues;
  final Function(String)? onChanged;
  final bool isAdmin;
  final Color chipColor;
  final IconData chipIcon;

  const ModernStatusDropdown(
      {Key? key,
      required this.current,
      required this.possibleValues,
      required this.onChanged,
      required this.isAdmin,
      required this.chipColor,
      required this.chipIcon})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        decoration: BoxDecoration(
            color: chipColor, borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        margin: const EdgeInsets.only(left: 8),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(chipIcon, color: Colors.white, size: 16),
          const SizedBox(width: 5),
          Text(current,
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
          itemBuilder: (_) => possibleValues
              .map((status) => PopupMenuItem<String>(
                    value: status,
                    child: Row(children: [
                      Icon(statutIcons[status] ?? Icons.info,
                          size: 16,
                          color: status == current
                              ? (statutColors[status] ?? Colors.grey)
                              : _textMuted),
                      const SizedBox(width: 8),
                      Text(status,
                          style: TextStyle(
                              color: status == current
                                  ? (statutColors[status] ?? Colors.grey)
                                  : _textMuted,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ))
              .toList(),
          onSelected: onChanged,
        ),
    ]);
  }
}
