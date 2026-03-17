import 'package:flutter/material.dart';
import 'package:sama/screens/transports_archives_screen.dart';
import '../models/transport.dart';
import '../services/transport_service.dart';
import '../models/logged_user.dart';
import 'transport_form_screen.dart';
import '../services/gp_service.dart';
import '../models/gp_agent.dart';

// Couleurs/icônes (alignées sur StatutTransport côté backend)
final Map<String, Color> statutColors = {
  "EN_ATTENTE": Colors.grey,
  "EN_COURS": Colors.orange,
  "LIVRE": Colors.green,
  "ANNULE": Colors.red,
};

final Map<String, IconData> statutIcons = {
  "EN_ATTENTE": Icons.timelapse,
  "EN_COURS": Icons.sync,
  "LIVRE": Icons.done,
  "ANNULE": Icons.cancel,
};

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
    await Future.wait([
      _loadStatuses(),
      _loadTransports(),
    ]);
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
            TransportArchivesScreen(isAdmin: logged.role == "admin"),
      ),
    );
    _refresh();
  }

  Future<void> _editTransport(Transport transport) async {
    final refresh = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransportFormScreen(transport: transport),
      ),
    );
    if (refresh == true) {
      _refresh();
    }
  }

  Future<void> _deleteTransport(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Supprimer ?"),
        content: const Text("Cette action est irréversible."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Annuler")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text("Supprimer", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      final res = await _service.deleteTransport(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res ? "Supprimé" : "Erreur suppression")),
      );
      _refresh();
    }
  }

  Future<void> _archiveTransport(int id) async {
    if (logged.role != "admin") return;
    final res = await _service.archiveTransport(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res ? "Archivé" : "Erreur archivage")),
    );
    _refresh();
  }

  Future<void> _changeStatutTransport(int id, String newStatut) async {
    if (logged.role != "admin") return;
    final res = await _service.changeTransportStatut(id, newStatut);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res ? "Statut changé" : "Erreur statut")),
    );

    if (res) {
      setState(() {
        final idx = transports.indexWhere((t) => t.id == id);
        if (idx != -1) {
          transports[idx] = transports[idx].copyWith(statut: newStatut);
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
          const SnackBar(content: Text("Aucun GP actif disponible.")),
        );
        return null;
      }

      return showDialog<GpAgent>(
        context: context,
        builder: (_) => SimpleDialog(
          title: const Text("Choisir un GP"),
          children: gps
              .map(
                (gp) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, gp),
                  child: ListTile(
                    dense: true,
                    title: Text(gp.fullName),
                    subtitle: Text(gp.phoneNumber ?? '—'),
                  ),
                ),
              )
              .toList(),
        ),
      );
    } catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur chargement GP: $e")),
      );
      return null;
    }
  }

  Future<void> _assignGpToTransport(Transport transport) async {
    final gp = await _pickGpDialog();
    if (gp == null) return;

    try {
      await _gpService.assignGpToTransport(
        transportId: transport.id!,
        gpId: gp.id,
        newStatut: "EN_COURS",
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("GP assigné: ${gp.fullName}")),
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur assignation GP: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final titre =
        logged.role == "admin" ? "Tous les transports" : "Mes Transports";

    return Scaffold(
      appBar: AppBar(
        title: Text(titre),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
          IconButton(
            icon: const Icon(Icons.archive),
            tooltip: "Transports archivés",
            onPressed: _goToArchivesScreen,
          ),
        ],
      ),
      body: transports.isEmpty
          ? Center(
              child: _loadingStatuses
                  ? const CircularProgressIndicator()
                  : const Text('Aucun transport'),
            )
          : ListView.builder(
              itemCount: transports.length,
              itemBuilder: (context, index) {
                final transport = transports[index];
                return TransportTile(
                  transport: transport,
                  logged: logged,
                  possibleStatuses: possibleStatuses,
                  onEdit: () => _editTransport(transport),
                  onDelete: () => _deleteTransport(transport.id!),
                  onArchive: logged.role == "admin"
                      ? () => _archiveTransport(transport.id!)
                      : null,
                  onStatutChanged: logged.role == "admin"
                      ? (newStatut) =>
                          _changeStatutTransport(transport.id!, newStatut)
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

class TransportTile extends StatelessWidget {
  final Transport transport;
  final LoggedUser logged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onArchive;
  final void Function(String)? onStatutChanged;
  final VoidCallback? onAssignGp;

  final List<String> possibleStatuses;

  const TransportTile({
    super.key,
    required this.transport,
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
    final color = statutColors[transport.statut] ?? Colors.grey.shade400;
    final icon = statutIcons[transport.statut] ?? Icons.info;

    final gpInfo = _buildGpInfo();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${transport.nom} ${transport.prenom}",
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 2),
            Text(
              "${transport.typesMarchandise} - ${transport.valeurEstimee.toStringAsFixed(2)} ${transport.devise}",
              style: TextStyle(color: Colors.grey.shade800),
            ),
            Text(
              "Pays expéditeur : ${transport.paysExpediteur}, ville : ${transport.villeExpediteur}, adresse : ${transport.adresseExpediteur}",
            ),
            Text(
              "Pays destinataire : ${transport.paysDestinataire}, ville : ${transport.villeDestinataire}, adresse : ${transport.adresseDestinataire}",
            ),
            if (gpInfo != null) ...[
              const SizedBox(height: 8),
              gpInfo,
            ],
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if ((logged.role == "admin") ||
                    (transport.userId == logged.userId))
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    tooltip: "Modifier",
                    onPressed: onEdit,
                    splashRadius: 20,
                  ),
                if ((logged.role == "admin") ||
                    (transport.userId == logged.userId))
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: "Supprimer",
                    onPressed: onDelete,
                    splashRadius: 20,
                  ),
                if (logged.role == "admin" && onArchive != null)
                  IconButton(
                    icon: const Icon(Icons.archive, color: Colors.orange),
                    tooltip: "Archiver",
                    onPressed: onArchive,
                    splashRadius: 20,
                  ),
                if (logged.role == "admin" && onAssignGp != null)
                  IconButton(
                    icon: const Icon(Icons.badge_outlined,
                        color: Colors.deepPurple),
                    tooltip: "Assigner un GP",
                    onPressed: onAssignGp,
                    splashRadius: 20,
                  ),
                ModernStatusDropdown(
                  current: transport.statut,
                  possibleValues: possibleStatuses,
                  onChanged: onStatutChanged,
                  isAdmin: logged.role == "admin",
                  chipColor: color,
                  chipIcon: icon,
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
        color: Colors.deepPurple.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user, color: Colors.deepPurple),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Pris en charge par: ${name.isEmpty ? "GP" : name}${gpPhone.isNotEmpty ? " • $gpPhone" : ""}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: chipColor,
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          margin: const EdgeInsets.only(left: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(chipIcon, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(
                current,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        if (isAdmin && onChanged != null)
          PopupMenuButton<String>(
            icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
            itemBuilder: (_) => possibleValues
                .map((status) => PopupMenuItem<String>(
                      value: status,
                      child: Row(
                        children: [
                          Icon(
                            statutIcons[status] ?? Icons.info,
                            size: 18,
                            color: status == current
                                ? (statutColors[status] ?? Colors.grey)
                                : Colors.grey,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            status,
                            style: TextStyle(
                              color: status == current
                                  ? (statutColors[status] ?? Colors.grey)
                                  : Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
            onSelected: onChanged,
          ),
      ],
    );
  }
}
