import 'package:flutter/material.dart';
import '../models/transport.dart';
import '../services/transport_service.dart';

class TransportsListScreen extends StatefulWidget {
  const TransportsListScreen({Key? key}) : super(key: key);

  @override
  State<TransportsListScreen> createState() => _TransportsListScreenState();
}

class _TransportsListScreenState extends State<TransportsListScreen> {
  final _service = TransportService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes Transports')),
      body: FutureBuilder<List<Transport>?>(
        future: _service.getAllTransports(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || snapshot.data == null) {
            return const Center(child: Text('❌ Erreur'));
          }

          if (snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucun transport'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final t = snapshot.data![index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text('${t.nom} ${t.prenom}'),
                  subtitle: Text('${t.paysExpediteur} → ${t.paysDestinataire}'),
                  trailing: Chip(label: Text(t.statut)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
