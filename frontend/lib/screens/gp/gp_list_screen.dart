import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sama/services/gp_service.dart';
import 'package:sama/widgets/gp_form_dialog.dart';
import '../../models/gp_agent.dart';
import '../../models/logged_user.dart';

class GpListScreen extends StatefulWidget {
  const GpListScreen({Key? key}) : super(key: key);

  @override
  State<GpListScreen> createState() => _GpListScreenState();
}

class _GpListScreenState extends State<GpListScreen> {
  final GpService gpService = GpService();
  List<GpAgent> gps = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await gpService.getAll();
      if (!mounted) return;
      setState(() => gps = data);
    } catch (e) {
      if (!mounted) return;
      Fluttertoast.showToast(msg: e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _add() async {
    final logged = LoggedUser.fromSupabase();
    if (logged.role != 'admin') return;

    final result = await showGpFormDialog(context: context, isEdit: false);
    if (result == null) return;

    try {
      await gpService.create(
        prenom: result['prenom'],
        nom: result['nom'],
        phoneNumber: result['phoneNumber'],
        email: result['email'],
        isActive: result['isActive'] ?? true,
      );
      await _load();
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _edit(GpAgent gp) async {
    final result =
        await showGpFormDialog(context: context, gp: gp, isEdit: true);
    if (result == null) return;

    try {
      await gpService.update(
        id: gp.id,
        prenom: result['prenom'],
        nom: result['nom'],
        phoneNumber: result['phoneNumber'],
        email: result['email'],
        isActive: result['isActive'] ?? gp.isActive,
      );
      await _load();
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _delete(GpAgent gp) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Supprimer GP ?"),
        content: Text("Supprimer ${gp.fullName} ?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Annuler")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await gpService.delete(gp.id);
      await _load();
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final logged = LoggedUser.fromSupabase();
    if (logged.role != 'admin') {
      return Scaffold(
        appBar: AppBar(title: const Text("Sécurité")),
        body: const Center(child: Text("Accès refusé.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("GP (Agents de transport)"),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : gps.isEmpty
              ? const Center(child: Text("Aucun GP"))
              : ListView.separated(
                  itemCount: gps.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final gp = gps[i];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(gp.prenom.isNotEmpty
                            ? gp.prenom[0].toUpperCase()
                            : 'G'),
                      ),
                      title: Text(gp.fullName),
                      subtitle: Text(
                        '${gp.phoneNumber ?? "—"}\n${gp.email ?? "—"}',
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            gp.isActive ? Icons.check_circle : Icons.block,
                            color: gp.isActive ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _edit(gp),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _delete(gp),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        child: const Icon(Icons.add),
      ),
    );
  }
}
