import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/user_service.dart';
import '../../models/logged_user.dart';

class AdminUserScreen extends StatefulWidget {
  const AdminUserScreen({Key? key}) : super(key: key);

  @override
  State<AdminUserScreen> createState() => _AdminUserScreenState();
}

class _AdminUserScreenState extends State<AdminUserScreen> {
  final UserService userService = UserService();
  List<User> users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final data = await userService.getUsers();
    setState(() => users = data ?? []);
  }

  Future<void> _addUserDialog() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String role = 'user';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Ajouter utilisateur"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Nom"),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              TextField(
                controller: passwordController,
                decoration:
                    const InputDecoration(labelText: "Mot de passe initial"),
                obscureText: true,
              ),
              DropdownButton<String>(
                value: role,
                items: ["user", "admin"]
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (value) => setState(() => role = value!),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              final result = await userService.createUserParAdmin(
                name: nameController.text,
                email: emailController.text,
                password: passwordController.text,
                role: role,
              );
              if (result) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Utilisateur ajouté.")),
                );
                Navigator.pop(context);
                _loadUsers();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Erreur lors de l'ajout.")),
                );
              }
            },
            child: const Text("Ajouter"),
          ),
        ],
      ),
    );
  }

  Future<void> _editUserDialog(User user) async {
    final nameController = TextEditingController(text: user.name ?? '');
    final emailController = TextEditingController(text: user.email ?? '');
    String role = user.role;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Éditer utilisateur"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Nom"),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              DropdownButton<String>(
                value: role,
                items: ["user", "admin"]
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (value) => setState(() => role = value!),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              // Pour le backend Spring on force un fallback sur id = 0 si null (ou gérer l'erreur si vraiment absent)
              final updatedUser = User(
                id: user.id ?? 0,
                name: nameController.text,
                email: emailController.text,
                role: role,
              );
              await userService.updateUser(updatedUser);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Utilisateur modifié.")),
              );
              Navigator.pop(context);
              _loadUsers();
            },
            child: const Text("Modifier"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser(int? id) async {
    if (id == null) return;
    final res = await userService.deleteUser(id);
    if (res) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Utilisateur supprimé !")),
      );
      _loadUsers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de la suppression.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final logged = LoggedUser.fromSupabase();
    if (logged.role != "admin") {
      return Scaffold(
        appBar: AppBar(title: const Text("Gestion admin")),
        body: const Center(
          child: Text("Accès réservé aux administrateurs."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Gestion des utilisateurs")),
      body: users.isEmpty
          ? const Center(child: Text("Aucun utilisateur"))
          : ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final u = users[index];
                return ListTile(
                  title: Text(u.name ?? ''),
                  subtitle: Text('${u.email ?? ''} - ${u.role}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editUserDialog(u),
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
        onPressed: _addUserDialog,
        child: const Icon(Icons.add),
        tooltip: 'Ajouter un utilisateur',
      ),
    );
  }
}
