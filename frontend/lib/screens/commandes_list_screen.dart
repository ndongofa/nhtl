import 'package:flutter/material.dart';
import '../models/commande.dart';
import '../services/commande_service.dart';

class CommandesListScreen extends StatefulWidget {
  const CommandesListScreen({Key? key}) : super(key: key);

  @override
  State<CommandesListScreen> createState() => _CommandesListScreenState();
}

class _CommandesListScreenState extends State<CommandesListScreen> {
  final _service = CommandeService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes Commandes')),
      body: FutureBuilder<List<Commande>?>(
        future: _service.getAllCommandes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || snapshot.data == null) {
            return const Center(child: Text('❌ Erreur'));
          }

          if (snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucune commande'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final c = snapshot.data![index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text('${c.nom} ${c.prenom}'),
                  subtitle: Text(
                      '${c.plateforme} - ${c.prixTotal.toStringAsFixed(2)} ${c.devise}'),
                  trailing: Chip(label: Text(c.statut)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
