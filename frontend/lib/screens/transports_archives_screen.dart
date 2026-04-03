import 'package:flutter/material.dart';
import 'package:sama/screens/transports_list_screen.dart';
import '../models/transport.dart';
import '../services/auth_service.dart';
import '../services/transport_service.dart';
import '../widgets/sama_account_menu.dart';

// Réutilise statutColors/statutIcons définis dans transports_list_screen.dart
// (EN_ATTENTE, EN_COURS, LIVRE, ANNULE)
import 'transports_list_screen.dart' show statutColors, statutIcons;

class TransportArchivesScreen extends StatefulWidget {
  final bool isAdmin;
  const TransportArchivesScreen({Key? key, this.isAdmin = false})
      : super(key: key);

  @override
  State<TransportArchivesScreen> createState() =>
      _TransportArchivesScreenState();
}

class _TransportArchivesScreenState extends State<TransportArchivesScreen> {
  final _service = TransportService();
  late Future<List<Transport>?> _futureArchives;

  List<String> _possibleStatuses = [];
  bool _loadingStatuses = false;

  @override
  void initState() {
    super.initState();
    _futureArchives = _fetchArchives();
    _loadStatuses();
  }

  Future<void> _loadStatuses() async {
    setState(() => _loadingStatuses = true);
    try {
      final statuses = await _service.getStatutsTransports();
      if (!mounted) return;
      setState(() {
        _possibleStatuses = (statuses ?? [])
            .map((e) => e.toString())
            .where((s) => s.trim().isNotEmpty)
            .toList();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _possibleStatuses = const ["EN_ATTENTE", "EN_COURS", "LIVRE", "ANNULE"];
      });
    } finally {
      if (mounted) setState(() => _loadingStatuses = false);
    }
  }

  Future<List<Transport>?> _fetchArchives() async {
    if (widget.isAdmin) {
      return await _service.getTransportsArchivesAdmin();
    } else {
      return await _service.getTransportsArchivesUser();
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _futureArchives = _fetchArchives();
    });
    await _loadStatuses();
  }

  // Désarchiver un transport (admin uniquement)
  Future<void> _unarchiveTransport(BuildContext context, int id) async {
    final res = await _service.unarchiveTransportAdmin(id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res ? "Désarchivé" : "Erreur désarchivage")),
    );
    _refresh();
  }

  // Supprimer un transport archivé
  Future<void> _deleteTransport(BuildContext context, int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Supprimer ?"),
        content: const Text("Cette action est irréversible."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final res = await _service.deleteTransport(id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res ? "Supprimé" : "Erreur suppression")),
      );
      _refresh();
    }
  }

  // Changer statut (admin seulement) - statuts dynamiques backend
  Future<void> _changeStatut(
      BuildContext context, int id, String newStatut) async {
    if (!widget.isAdmin) return;

    final res = await _service.changeTransportStatut(id, newStatut);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res ? "Statut changé" : "Erreur statut")),
    );
    if (res) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final titre = widget.isAdmin
        ? "Transports archivés (admin)"
        : "Mes transports archivés";

    return Scaffold(
      appBar: AppBar(
        title: Text(titre, maxLines: 1, overflow: TextOverflow.ellipsis),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          tooltip: "Retour à la liste",
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const TransportListScreen(),
              ),
            );
          },
        ),
        actions: [
          IconButton(
            tooltip: "Mon espace",
            onPressed: () => SamaAccountMenu.open(context),
            icon: const Icon(Icons.dashboard_outlined),
          ),
          IconButton(
            tooltip: "Déconnexion",
            onPressed: () async {
              await AuthService.logout();
              if (!context.mounted) return;
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/', (_) => false);
            },
            icon: const Icon(Icons.logout),
          ),
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<List<Transport>?>(
        future: _futureArchives,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return const Center(child: Text('❌ Erreur'));
          }
          final archives = snapshot.data!;
          if (archives.isEmpty) {
            return const Center(child: Text('Aucune archive'));
          }

          return ListView.builder(
            itemCount: archives.length,
            itemBuilder: (context, index) {
              final t = archives[index];

              final status = t.statut;
              final color = statutAdminColors[status] ?? Colors.grey.shade600;
              final icon = statutAdminIcons[status] ?? Icons.info;

              return Card(
                margin: const EdgeInsets.all(8),
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${t.nom} ${t.prenom}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${t.typesMarchandise} - ${t.valeurEstimee.toStringAsFixed(2)} ${t.devise}',
                      ),
                      Text(
                        'Pays expéditeur : ${t.paysExpediteur}, ville : ${t.villeExpediteur}, adresse : ${t.adresseExpediteur}',
                      ),
                      Text(
                        'Pays destinataire : ${t.paysDestinataire}, ville : ${t.villeDestinataire}, adresse : ${t.adresseDestinataire}',
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(icon, color: Colors.white, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  status,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          if (widget.isAdmin &&
                              !_loadingStatuses &&
                              _possibleStatuses.isNotEmpty)
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.arrow_drop_down),
                              tooltip: "Changer le statut",
                              itemBuilder: (_) => _possibleStatuses
                                  .map((s) => PopupMenuItem<String>(
                                        value: s,
                                        child: Text(s),
                                      ))
                                  .toList(),
                              onSelected: (s) =>
                                  _changeStatut(context, t.id!, s),
                            ),
                          Tooltip(
                            message: "Supprimer définitivement",
                            child: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteTransport(context, t.id!),
                            ),
                          ),
                          if (widget.isAdmin)
                            Tooltip(
                              message: "Désarchiver",
                              child: IconButton(
                                icon: const Icon(Icons.unarchive,
                                    color: Colors.green),
                                onPressed: () =>
                                    _unarchiveTransport(context, t.id!),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
