import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/user_service.dart';

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final UserService userService = UserService();
  List<User> users = [];

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    final data = await userService.getUsers();
    setState(() => users = data ?? []);
  }

  Future<void> showUserDialog({User? user}) async {
    final nameController = TextEditingController(text: user?.name ?? "");
    final emailController = TextEditingController(text: user?.email ?? "");
    String role = user?.role ?? "user";

    final isEditing = user != null;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? "Modifier utilisateur" : "Ajouter utilisateur"),
        content: Column(
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
              onChanged: (value) => role = value!,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newUser = User(
                id: isEditing ? user!.id : 0,
                name: nameController.text,
                email: emailController.text,
                role: role,
              );
              try {
                if (isEditing) {
                  await userService.updateUser(newUser);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Utilisateur modifié avec succès")),
                  );
                } else {
                  await userService.addUser(newUser);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Utilisateur ajouté avec succès")),
                  );
                }
                Navigator.pop(context);
                loadUsers();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Erreur : $e")),
                );
              }
            },
            child: Text(isEditing ? "Modifier" : "Ajouter"),
          ),
        ],
      ),
    );
  }

  Future<void> deleteUser(int id) async {
    try {
      await userService.deleteUser(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Utilisateur supprimé")),
      );
      loadUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gestion des utilisateurs")),
      body: users.isEmpty
          ? const Center(child: Text("Aucun utilisateur trouvé"))
          : ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final u = users[index];
                return ListTile(
                  title: Text(u.name),
                  subtitle: Text("${u.email} - ${u.role}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => showUserDialog(user: u),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => deleteUser(u.id),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showUserDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
