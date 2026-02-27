import 'package:flutter/material.dart';
import '../models/user.dart';

/// Affiche un dialogue formulaire (création ou édition d'utilisateur)
/// Retourne [Map<String, dynamic>] contenant les champs modifiés ou null si annulé
Future<Map<String, dynamic>?> showUserFormDialog({
  required BuildContext context,
  User? user,
  bool isEdit = false,
}) {
  final nameController = TextEditingController(text: user?.name ?? '');
  final emailController = TextEditingController(text: user?.email ?? '');
  final passwordController = TextEditingController();
  String selectedRole = user?.role ?? 'user';

  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title:
            Text(isEdit ? "Modifier l'utilisateur" : "Ajouter un utilisateur"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Nom complet"),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
                keyboardType: TextInputType.emailAddress,
              ),
              if (!isEdit)
                TextField(
                  controller: passwordController,
                  decoration:
                      const InputDecoration(labelText: "Mot de passe initial"),
                  obscureText: true,
                ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(labelText: "Rôle"),
                items: ["user", "admin"]
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (value) {
                  setDialogState(() => selectedRole = value!);
                },
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
            onPressed: () {
              if (nameController.text.isEmpty || emailController.text.isEmpty) {
                return;
              }
              Navigator.pop(context, {
                'name': nameController.text,
                'email': emailController.text,
                'password': passwordController.text,
                'role': selectedRole,
              });
            },
            child: Text(isEdit ? "Sauvegarder" : "Créer"),
          ),
        ],
      ),
    ),
  );
}
