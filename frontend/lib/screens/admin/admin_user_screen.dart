import 'package:flutter/material.dart';
import 'package:sama/services/user_service.dart';
import 'package:sama/widgets/user_form_dialog.dart';
import 'package:sama/services/admin_user_api_service.dart';
import '../../models/user.dart' as appUser;
import '../../models/logged_user.dart';

class AdminUserScreen extends StatefulWidget {
  const AdminUserScreen({Key? key}) : super(key: key);

  @override
  State<AdminUserScreen> createState() => _AdminUserScreenState();
}

class _AdminUserScreenState extends State<AdminUserScreen> {
  final UserService userService = UserService();
  final AdminUserApiService adminApi = AdminUserApiService();

  List<appUser.User> users = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final data = await userService.getUsers();
    if (!mounted) return;
    setState(() {
      users = data ?? <appUser.User>[];
      _isLoading = false;
    });
  }

  Future<void> _addOrEditUser({appUser.User? user, bool isEdit = false}) async {
    final result = await showUserFormDialog(
      context: context,
      user: user,
      isEdit: isEdit,
    );
    if (result == null) return;

    try {
      if (isEdit && user != null) {
        await adminApi.updateUser(
          supabaseUserId: user.id,
          email: result['email'],
          phone: result['phone'],
          prenom: result['prenom'],
          nom: result['nom'],
          role: result['role'],
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Modifications enregistrées")),
        );
      } else {
        await adminApi.createUser(
          identifier: result['identifier'],
          password: result['password'],
          prenom: result['prenom'],
          nom: result['nom'],
          role: result['role'],
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Utilisateur créé")),
        );
      }

      await Future.delayed(const Duration(milliseconds: 350));
      await _loadUsers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Erreur: ${e.toString().replaceFirst('Exception: ', '')}",
          ),
        ),
      );
    }
  }

  Future<void> _deleteUser(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Supprimer ?"),
        content: const Text("Cette action est irréversible."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await adminApi.deleteUser(supabaseUserId: id);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Supprimé")),
        );

        await Future.delayed(const Duration(milliseconds: 350));
        await _loadUsers();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Erreur: ${e.toString().replaceFirst('Exception: ', '')}",
            ),
          ),
        );
      }
    }
  }

  Future<void> _resetPassword(appUser.User user) async {
    final controller = TextEditingController();
    final confirmController = TextEditingController();
    bool obscure1 = true;
    bool obscure2 = true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Réinitialiser le mot de passe"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Utilisateur: ${user.displayName}",
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                obscureText: obscure1,
                decoration: InputDecoration(
                  labelText: "Nouveau mot de passe",
                  helperText: "Minimum 8 caractères",
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscure1 ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setDialogState(() => obscure1 = !obscure1),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: confirmController,
                obscureText: obscure2,
                decoration: InputDecoration(
                  labelText: "Confirmer le mot de passe",
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscure2 ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setDialogState(() => obscure2 = !obscure2),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () {
                final p1 = controller.text;
                final p2 = confirmController.text;
                if (p1.length < 8) return;
                if (p1 != p2) return;
                Navigator.pop(context, true);
              },
              child: const Text("Valider"),
            ),
          ],
        ),
      ),
    );

    if (ok != true) return;

    try {
      await adminApi.resetPassword(
        supabaseUserId: user.id,
        newPassword: controller.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mot de passe réinitialisé")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Erreur reset password: ${e.toString().replaceFirst('Exception: ', '')}",
          ),
        ),
      );
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
          IconButton(onPressed: _loadUsers, icon: const Icon(Icons.refresh)),
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
                    final contact =
                        (u.email != null && u.email!.trim().isNotEmpty)
                            ? u.email!
                            : (u.phone ?? '');

                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(u.role[0].toUpperCase()),
                        backgroundColor:
                            u.role == 'admin' ? Colors.orange : Colors.blueGrey,
                      ),
                      title: Text(u.displayName),
                      subtitle: Text(
                        '${contact.isEmpty ? "—" : contact}\nRôle: ${u.role}',
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Reset password',
                            icon:
                                const Icon(Icons.key, color: Colors.deepPurple),
                            onPressed: () => _resetPassword(u),
                          ),
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
