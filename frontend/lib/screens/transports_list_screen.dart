// lib/screens/transports_list_screen.dart
//
// ✅ Toutes les fonctionnalités existantes conservées (edit, delete, archive,
//    assign GP, dropdown statut texte libre)
// ✅ NOUVEAU — bouton Suivi → TransportTrackingScreen (tous les rôles)
// ✅ NOUVEAU — dropdown StatutSuivi 7 étapes (admin uniquement)
// ✅ NOUVEAU — couleurs/icônes pour les 7 étapes de suivi
// ✅ Zéro régression sur TransportTile, ModernStatusDropdown existants

import 'package:flutter/material.dart';
import 'package:sama/screens/transports_archives_screen.dart';
import '../models/transport.dart';
import '../services/transport_service.dart';
import '../models/logged_user.dart';
import 'transport_form_screen.dart';
import 'transport_tracking_screen.dart'; // ✅ NOUVEAU
import '../services/gp_service.dart';
import '../models/gp_agent.dart';

// ── Statut texte libre (existant, conservé) ───────────────────────────────────
final Map<String, Color> statutColors = {
  "EN_ATTENTE": Colors.grey,
  "EN_COURS": const Color(0xFFFFB300),
  "LIVRE": const Color(0xFF22C55E),
  "ANNULE": Colors.red,
};

final Map<String, IconData> statutIcons = {
  "EN_ATTENTE": Icons.timelapse,
  "EN_COURS": Icons.sync,
  "LIVRE": Icons.done,
  "ANNULE": Icons.cancel,
};

// ── ✅ Statut suivi structuré (7 étapes TransportStatus.java) ─────────────────
final Map<String, Color> statutSuiviColors = {
  "EN_ATTENTE": Colors.grey,
  "DEPART_CONFIRME": const Color(0xFF2296F3),
  "EN_TRANSIT": const Color(0xFFFFB300),
  "EN_DOUANE": Colors.deepPurple,
  "ARRIVE": const Color(0xFF00D4C8),
  "PRET_RECUPERATION": const Color(0xFF22C55E),
  "LIVRE": const Color(0xFF22C55E),
};

final Map<String, IconData> statutSuiviIcons = {
  "EN_ATTENTE": Icons.hourglass_empty,
  "DEPART_CONFIRME": Icons.check_circle_outline,
  "EN_TRANSIT": Icons.local_shipping_outlined,
  "EN_DOUANE": Icons.gavel_outlined,
  "ARRIVE": Icons.location_on_outlined,
  "PRET_RECUPERATION": Icons.inventory_2_outlined,
  "LIVRE": Icons.celebration_outlined,
};

const List<String> _statutsSuiviOrdonnes = [
  "EN_ATTENTE",
  "DEPART_CONFIRME",
  "EN_TRANSIT",
  "EN_DOUANE",
  "ARRIVE",
  "PRET_RECUPERATION",
  "LIVRE",
];

// ── Couleurs de l'interface ───────────────────────────────────────────────────
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

class TransportListScreen extends StatefulWidget {
  const TransportListScreen({Key? key}) : super(key: key);

  @override
  State<TransportListScreen> createState() => _TransportListScreenState();
}

class _TransportListScreenState extends State<TransportListScreen> {
  final _service = TransportService();
  final _gpService = GpService();

  late LoggedUser logged;
  List<Transport> transports = [];
  List<String> possibleStatuses = [];
  bool _loadingStatuses = false;

  @override
  void initState() {
    super.initState();
    logged = LoggedUser.fromSupabase();
    _init();
  }

  Future<void> _init() async {
    await Future.wait([_loadStatuses(), _loadTransports()]);
  }

  Future<void> _loadStatuses() async {
    setState(() => _loadingStatuses = true);
    try {
      final statuses = await _service.getStatutsTransports();
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
    } finally {
      if (mounted) setState(() => _loadingStatuses = false);
    }
  }

  Future<void> _loadTransports() async {
    final allTs = logged.role == "admin"
        ? await _service.getAllTransports()
        : await _service.getAllTransportsForUser(logged.userId);
    if (!mounted) return;
    setState(() {
      transports = (allTs ?? []).where((t) => t.archived != true).toList();
    });
  }

  Future<void> _refresh() async {
    await Future.wait([_loadStatuses(), _loadTransports()]);
  }

  Future<void> _goToArchivesScreen() async {
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                TransportArchivesScreen(isAdmin: logged.role == "admin")));
    _refresh();
  }

  Future<void> _editTransport(Transport transport) async {
    final refresh = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => TransportFormScreen(transport: transport)));
    if (refresh == true) _refresh();
  }

  // ✅ Navigation vers l'écran de suivi (tous les rôles)
  void _openTracking(Transport transport) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => TransportTrackingScreen(transport: transport)));
  }

  Future<void> _deleteTransport(int id) async {
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
      final res = await _service.deleteTransport(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res ? "Supprimé" : "Erreur suppression")));
      _refresh();
    }
  }

  Future<void> _archiveTransport(int id) async {
    if (logged.role != "admin") return;
    final res = await _service.archiveTransport(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res ? "Archivé" : "Erreur archivage")));
    _refresh();
  }

  // Statut texte libre (dropdown existant — conservé)
  Future<void> _changeStatutTransport(int id, String newStatut) async {
    if (logged.role != "admin") return;
    final res = await _service.changeTransportStatut(id, newStatut);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res ? "Statut changé" : "Erreur statut")));
    if (res) {
      setState(() {
        final idx = transports.indexWhere((t) => t.id == id);
        if (idx != -1) {
          transports[idx] = transports[idx].copyWith(statut: newStatut);
        }
      });
    }
  }

  // ✅ NOUVEAU — Statut suivi structuré (7 étapes avec notifications)
  Future<void> _updateStatutSuivi(int id, String newStatus) async {
    if (logged.role != "admin") return;
    final res = await _service.updateStatutSuivi(id, newStatus);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res
            ? "✅ Suivi mis à jour → $newStatus (notifications envoyées)"
            : "❌ Erreur mise à jour suivi")));
    if (res) {
      setState(() {
        final idx = transports.indexWhere((t) => t.id == id);
        if (idx != -1) {
          transports[idx] = transports[idx].copyWith(statutSuivi: newStatus);
        }
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
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

  Future<void> _assignGpToTransport(Transport transport) async {
    final gp = await _pickGpDialog();
    if (gp == null) return;
    try {
      await _gpService.assignGpToTransport(
          transportId: transport.id!, gpId: gp.id, newStatut: "EN_COURS");
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
        logged.role == "admin" ? "Tous les transports" : "Mes Transports";
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
              tooltip: "Transports archivés",
              onPressed: _goToArchivesScreen),
        ],
      ),
      body: transports.isEmpty
          ? Center(
              child: _loadingStatuses
                  ? const CircularProgressIndicator(color: _appBlue)
                  : const Text('Aucun transport',
                      style: TextStyle(color: _textPrimary)))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: transports.length,
              itemBuilder: (context, index) {
                final transport = transports[index];
                return TransportTile(
                  transport: transport,
                  logged: logged,
                  possibleStatuses: possibleStatuses,
                  onEdit: () => _editTransport(transport),
                  onDelete: () => _deleteTransport(transport.id!),
                  onTracking: () => _openTracking(transport), // ✅
                  onArchive: logged.role == "admin"
                      ? () => _archiveTransport(transport.id!)
                      : null,
                  onStatutChanged: logged.role == "admin"
                      ? (s) => _changeStatutTransport(transport.id!, s)
                      : null,
                  onStatutSuiviChanged: logged.role == "admin" // ✅
                      ? (s) => _updateStatutSuivi(transport.id!, s)
                      : null,
                  onAssignGp: logged.role == "admin"
                      ? () => _assignGpToTransport(transport)
                      : null,
                );
              },
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class TransportTile extends StatelessWidget {
  final Transport transport;
  final LoggedUser logged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTracking; // ✅ NOUVEAU
  final VoidCallback? onArchive;
  final void Function(String)? onStatutChanged;
  final void Function(String)? onStatutSuiviChanged; // ✅ NOUVEAU
  final VoidCallback? onAssignGp;
  final List<String> possibleStatuses;

  const TransportTile({
    super.key,
    required this.transport,
    required this.logged,
    required this.onEdit,
    required this.onDelete,
    required this.onTracking,
    required this.possibleStatuses,
    this.onArchive,
    this.onStatutChanged,
    this.onStatutSuiviChanged,
    this.onAssignGp,
  });

  @override
  Widget build(BuildContext context) {
    final color = statutColors[transport.statut] ?? Colors.grey.shade400;
    final icon = statutIcons[transport.statut] ?? Icons.info;
    final gpInfo = _buildGpInfo();

    // Statut suivi courant (null-safe — champ optionnel)
    final currentSuivi = transport.statutSuivi ?? 'EN_ATTENTE';
    final suiviColor = statutSuiviColors[currentSuivi] ?? Colors.grey;
    final suiviIcon = statutSuiviIcons[currentSuivi] ?? Icons.track_changes;

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
        // ── Infos client ────────────────────────────────────────────────────
        Text("${transport.nom} ${transport.prenom}",
            style: const TextStyle(
                color: _textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 15)),
        const SizedBox(height: 2),
        Text(
            "${transport.typesMarchandise} — "
            "${transport.valeurEstimee.toStringAsFixed(2)} ${transport.devise}",
            style: const TextStyle(color: _textMuted, fontSize: 13)),
        Text("${transport.paysExpediteur} → ${transport.paysDestinataire}",
            style: const TextStyle(color: _textMuted, fontSize: 12)),

        // ── GP info ─────────────────────────────────────────────────────────
        if (gpInfo != null) ...[const SizedBox(height: 8), gpInfo],

        // ── ✅ Chip statut suivi ─────────────────────────────────────────────
        const SizedBox(height: 10),
        _SuiviChip(
          currentSuivi: currentSuivi,
          suiviColor: suiviColor,
          suiviIcon: suiviIcon,
          isAdmin: logged.role == "admin",
          onSuiviChanged: onStatutSuiviChanged,
        ),

        const SizedBox(height: 8),

        // ── Actions ─────────────────────────────────────────────────────────
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          // ✅ Bouton Suivi — visible pour tous
          _iconBtn(Icons.track_changes, const Color(0xFF00D4C8),
              "Voir le suivi", onTracking),

          if ((logged.role == "admin") || (transport.userId == logged.userId))
            _iconBtn(Icons.edit, _appBlue, "Modifier", onEdit),

          if ((logged.role == "admin") || (transport.userId == logged.userId))
            _iconBtn(Icons.delete, Colors.red.shade400, "Supprimer", onDelete),

          if (logged.role == "admin" && onArchive != null)
            _iconBtn(Icons.archive, _amber, "Archiver", onArchive!),

          if (logged.role == "admin" && onAssignGp != null)
            _iconBtn(Icons.badge_outlined, Colors.deepPurple.shade300,
                "Assigner GP", onAssignGp!),

          // Dropdown statut texte libre (existant — conservé)
          ModernStatusDropdown(
            current: transport.statut,
            possibleValues: possibleStatuses,
            onChanged: onStatutChanged,
            isAdmin: logged.role == "admin",
            chipColor: color,
            chipIcon: icon,
          ),
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
    final gpPrenom = (transport.gpPrenom ?? '').trim();
    final gpNom = (transport.gpNom ?? '').trim();
    final gpPhone = (transport.gpPhoneNumber ?? '').trim();
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
          'GP: ${name.isEmpty ? "—" : name}'
          '${gpPhone.isNotEmpty ? " • $gpPhone" : ""}',
          style: const TextStyle(
              color: _textPrimary, fontWeight: FontWeight.w600, fontSize: 12),
        )),
      ]),
    );
  }
}

// ── ✅ Widget chip statut suivi + dropdown 7 étapes ───────────────────────────

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
      // Label "Suivi :"
      const Text("Suivi : ",
          style: TextStyle(
              color: _textMuted, fontSize: 11, fontWeight: FontWeight.w600)),

      // Chip étape actuelle
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
          Text(
            _label(currentSuivi),
            style: TextStyle(
                color: suiviColor, fontWeight: FontWeight.w700, fontSize: 11),
          ),
        ]),
      ),

      // Dropdown pour changer l'étape (admin uniquement)
      if (isAdmin && onSuiviChanged != null)
        PopupMenuButton<String>(
          icon: const Icon(Icons.arrow_drop_down, color: _textMuted, size: 20),
          color: _bgCard,
          tooltip: "Changer l'étape de suivi",
          itemBuilder: (_) => _statutsSuiviOrdonnes.map((status) {
            final c = statutSuiviColors[status] ?? Colors.grey;
            final i = statutSuiviIcons[status] ?? Icons.info;
            return PopupMenuItem<String>(
              value: status,
              child: Row(children: [
                Icon(i,
                    size: 16, color: status == currentSuivi ? c : _textMuted),
                const SizedBox(width: 8),
                Text(_label(status),
                    style: TextStyle(
                        color: status == currentSuivi ? c : _textMuted,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                if (status == currentSuivi) ...[
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

  String _label(String status) {
    const labels = {
      "EN_ATTENTE": "En attente",
      "DEPART_CONFIRME": "Départ confirmé",
      "EN_TRANSIT": "En transit",
      "EN_DOUANE": "En douane",
      "ARRIVE": "Arrivé",
      "PRET_RECUPERATION": "Prêt à récupérer",
      "LIVRE": "Livré",
    };
    return labels[status] ?? status;
  }
}

// ── Dropdown statut texte libre (existant — inchangé) ────────────────────────

class ModernStatusDropdown extends StatelessWidget {
  final String current;
  final List<String> possibleValues;
  final Function(String)? onChanged;
  final bool isAdmin;
  final Color chipColor;
  final IconData chipIcon;

  const ModernStatusDropdown({
    Key? key,
    required this.current,
    required this.possibleValues,
    required this.onChanged,
    required this.isAdmin,
    required this.chipColor,
    required this.chipIcon,
  }) : super(key: key);

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
