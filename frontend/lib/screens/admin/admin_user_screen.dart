import 'package:flutter/material.dart';
import 'package:nhtl_mobile/services/user_service.dart';
import 'package:nhtl_mobile/widgets/user_form_dialog.dart';
import '../../models/user.dart';
import '../../models/logged_user.dart';

class AdminUserScreen extends StatefulWidget {
  const AdminUserScreen({Key? key}) : super(key: key);

  @override
  State<AdminUserScreen> createState() => _AdminUserScreenState();
}

class _AdminUserScreenState extends State<AdminUserScreen> {
  final UserService userService = UserService();
  List<User> users = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final data = await userService.getUsers();
    if (mounted) {
      setState(() {
        users = data ?? [];
        _isLoading = false;
      });
    }
  }

  Future<void> _addOrEditUser({User? user, bool isEdit = false}) async {
    final result = await showUserFormDialog(
      context: context,
      user: user,
      isEdit: isEdit,
    );
    if (result == null) return;

    if (isEdit && user != null) {
      // Edition d’un utilisateur
      final updated = User(
        id: user.id!,
        name: result['name'],
        email: result['email'],
        role: result['role'],
      );
      final res = await userService.updateUser(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(res != null
                ? "Modifications enregistrées"
                : "Erreur modification")),
      );
    } else {
      // Création par admin
      final res = await userService.createUserParAdmin(
        name: result['name'],
        email: result['email'],
        password: result['password'],
        role: result['role'],
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(res ? "Utilisateur créé" : "Erreur lors de la création")),
      );
    }
    // Rafraîchir après action
    _loadUsers();
  }

  Future<void> _deleteUser(int? id) async {
    if (id == null) return;
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
      final res = await userService.deleteUser(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(res ? "Supprimé" : "Erreur lors de la suppression")),
        );
        _loadUsers();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final logged = LoggedUser.fromSupabase();

    if (logged.role != "admin") {
      return Scaffold(
        appBar: AppBar(title: const Text("Sécurité")),
        body: const Center(child: Text("Accès refusé.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestion Utilisateurs"),
        actions: [
          IconButton(onPressed: _loadUsers, icon: const Icon(Icons.refresh))
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : users.isEmpty
              ? const Center(child: Text("Aucun utilisateur trouvé"))
              : ListView.separated(
                  itemCount: users.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final u = users[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(u.role[0].toUpperCase()),
                        backgroundColor:
                            u.role == 'admin' ? Colors.orange : Colors.blueGrey,
                      ),
                      title: Text(u.name ?? 'Sans nom'),
                      subtitle: Text('${u.email}\nRôle: ${u.role}'),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () =>
                                _addOrEditUser(user: u, isEdit: true),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteUser(u.id),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditUser(isEdit: false),
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
