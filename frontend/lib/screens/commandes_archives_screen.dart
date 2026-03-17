import 'package:flutter/material.dart';
import '../services/commande_service.dart';
import '../models/commande.dart';
import 'commandes_list_screen.dart';

// Réutilise les maps harmonisées (sans accents) depuis commandes_list_screen.dart
// statutColors / statutIcons doivent correspondre à:
// EN_ATTENTE, CONFIRMEE, EN_TRAITEMENT, EXPEDIEE, LIVREE, ANNULEE, REMBOURSEE, ARCHIVEE

class CommandesArchivesScreen extends StatefulWidget {
  final bool isAdmin;

  const CommandesArchivesScreen({Key? key, required this.isAdmin})
      : super(key: key);

  @override
  State<CommandesArchivesScreen> createState() =>
      _CommandesArchivesScreenState();
}

class _CommandesArchivesScreenState extends State<CommandesArchivesScreen> {
  final CommandeService _service = CommandeService();

  late Future<List<Commande>?> _futureArchives;
  List<String> _possibleStatuses = [];

  @override
  void initState() {
    super.initState();
    _futureArchives = _fetchArchives();
    _loadStatuses();
  }

  Future<void> _loadStatuses() async {
    final statuses = await _service.getStatutsCommandes();
    if (!mounted) return;
    setState(() {
      _possibleStatuses = (statuses ?? [])
          .map((e) => e.toString())
          .where((s) => s.trim().isNotEmpty)
          .toList();
    });
  }

  Future<List<Commande>?> _fetchArchives() {
    return widget.isAdmin
        ? _service.getCommandesArchivesAdmin()
        : _service.getCommandesArchivesUser();
  }

  Future<void> _refresh() async {
    setState(() {
      _futureArchives = _fetchArchives();
    });
    await _loadStatuses();
  }

  // Désarchiver une commande (admin seulement)
  Future<void> _unarchiveCommande(BuildContext context, int id) async {
    final res = await _service.unarchiveCommandeAdmin(id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res ? "Désarchivée" : "Erreur désarchivage")),
    );
    _refresh();
  }

  // Supprimer une commande archivée
  Future<void> _deleteCommande(BuildContext context, int id) async {
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
      final res = await _service.deleteCommande(id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res ? "Supprimée" : "Erreur suppression")),
      );
      _refresh();
    }
  }

  // Changer statut (admin seulement) - harmonisé avec backend
  Future<void> _changeStatut(
      BuildContext context, int id, String newStatut) async {
    if (!widget.isAdmin) return;
    final res = await _service.changeStatutCommandeAdmin(id, newStatut);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res ? "Statut changé" : "Erreur statut")),
    );
    if (res) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Commandes archivées'),
        leading: IconButton(
          icon: const Icon(Icons.list_alt, color: Colors.white),
          tooltip: "Retour à la liste",
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const CommandesListScreen()),
            );
          },
        ),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<List<Commande>?>(
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
            return const Center(child: Text('Aucune commande archivée'));
          }

          return ListView.builder(
            itemCount: archives.length,
            itemBuilder: (context, index) {
              final c = archives[index];

              final status = c.statut;
              final color = statutColors[status] ?? Colors.grey.shade600;
              final icon = statutIcons[status] ?? Icons.info;

              return Card(
                margin: const EdgeInsets.all(8),
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${c.nom} ${c.prenom}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        '${c.plateforme} - ${c.prixTotal.toStringAsFixed(2)} ${c.devise}',
                        style: TextStyle(color: Colors.grey.shade800),
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
                          if (widget.isAdmin && _possibleStatuses.isNotEmpty)
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
                                  _changeStatut(context, c.id!, s),
                            ),
                          if (widget.isAdmin)
                            Tooltip(
                              message: "Rendre disponible",
                              child: IconButton(
                                icon: const Icon(Icons.unarchive,
                                    color: Colors.blue),
                                onPressed: () =>
                                    _unarchiveCommande(context, c.id!),
                              ),
                            ),
                          if (widget.isAdmin)
                            Tooltip(
                              message: "Supprimer définitivement",
                              child: IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () =>
                                    _deleteCommande(context, c.id!),
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
