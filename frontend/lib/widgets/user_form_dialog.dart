import 'package:flutter/material.dart';
import '../models/user.dart';

/// Dialogue formulaire (création/édition utilisateur)
/// Retourne Map<String, dynamic> ou null si annulé.
///
/// Changements:
/// - Remplace "Nom complet" par "Prénom" + "Nom"
/// - Remplace "Email" par "Email ou téléphone" (champ unique "identifier")
/// - En édition: on permet de modifier email/phone séparément (option simple),
///   mais on garde l'UX claire.
Future<Map<String, dynamic>?> showUserFormDialog({
  required BuildContext context,
  User? user,
  bool isEdit = false,
}) {
  final prenomController = TextEditingController(text: user?.prenom ?? '');
  final nomController = TextEditingController(text: user?.nom ?? '');

  // Pour la création: champ unique "identifier"
  final identifierController = TextEditingController(
    text: (user?.email != null && user!.email!.trim().isNotEmpty)
        ? user.email!
        : (user?.phone ?? ''),
  );

  // Pour l'édition: champs séparés (optionnel mais plus clair)
  final emailController = TextEditingController(text: user?.email ?? '');
  final phoneController = TextEditingController(text: user?.phone ?? '');

  final passwordController = TextEditingController();
  String selectedRole = user?.role ?? 'user';

  bool looksLikeEmail(String v) => v.contains('@');
  bool looksLikeE164Phone(String v) => RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(v);

  bool validateIdentifier(String v) {
    final value = v.trim();
    if (value.isEmpty) return false;
    if (looksLikeEmail(value)) return true;
    return looksLikeE164Phone(value);
  }

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
                controller: prenomController,
                decoration: const InputDecoration(labelText: "Prénom"),
              ),
              TextField(
                controller: nomController,
                decoration: const InputDecoration(labelText: "Nom"),
              ),
              const SizedBox(height: 10),
              if (!isEdit) ...[
                TextField(
                  controller: identifierController,
                  decoration: const InputDecoration(
                    labelText: "Email ou téléphone",
                    hintText: "ex: nom@domaine.com ou +221783042838",
                  ),
                  autocorrect: false,
                  enableSuggestions: false,
                ),
                TextField(
                  controller: passwordController,
                  decoration:
                      const InputDecoration(labelText: "Mot de passe initial"),
                  obscureText: true,
                ),
              ] else ...[
                // En édition, on montre séparément email/phone (plus clair pour admin)
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: "Email (optionnel)",
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: "Téléphone E.164 (optionnel)",
                    hintText: "+221783042838",
                  ),
                  keyboardType: TextInputType.phone,
                  autocorrect: false,
                  enableSuggestions: false,
                ),
              ],
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
              final prenom = prenomController.text.trim();
              final nom = nomController.text.trim();

              if (prenom.isEmpty || nom.isEmpty) {
                return;
              }

              if (!isEdit) {
                final identifier = identifierController.text.trim();
                final password = passwordController.text;

                if (!validateIdentifier(identifier) || password.isEmpty) {
                  return;
                }

                Navigator.pop(context, {
                  'prenom': prenom,
                  'nom': nom,
                  'identifier': identifier,
                  'password': password,
                  'role': selectedRole,
                });
              } else {
                // édition
                final email = emailController.text.trim();
                final phone = phoneController.text.trim();

                // Autoriser email/phone vides, mais si fournis, valider:
                if (email.isNotEmpty && !looksLikeEmail(email)) return;
                if (phone.isNotEmpty && !looksLikeE164Phone(phone)) return;

                Navigator.pop(context, {
                  'prenom': prenom,
                  'nom': nom,
                  'email': email.isEmpty ? null : email,
                  'phone': phone.isEmpty ? null : phone,
                  'role': selectedRole,
                });
              }
            },
            child: Text(isEdit ? "Sauvegarder" : "Créer"),
          ),
        ],
      ),
    ),
  );
}
