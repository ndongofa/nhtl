import 'package:flutter/material.dart';
import '../models/gp_agent.dart';
import 'phone_input_field.dart';

Future<Map<String, dynamic>?> showGpFormDialog({
  required BuildContext context,
  GpAgent? gp,
  bool isEdit = false,
}) {
  final prenomCtrl = TextEditingController(text: gp?.prenom ?? '');
  final nomCtrl = TextEditingController(text: gp?.nom ?? '');
  String? phoneE164 = gp?.phoneNumber;
  final emailCtrl = TextEditingController(text: gp?.email ?? '');
  bool isActive = gp?.isActive ?? true;

  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(isEdit ? "Modifier GP" : "Ajouter GP"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: prenomCtrl,
                decoration: const InputDecoration(labelText: "Prénom"),
              ),
              TextField(
                controller: nomCtrl,
                decoration: const InputDecoration(labelText: "Nom"),
              ),
              const SizedBox(height: 8),
              PhoneInputField(
                label: 'Téléphone',
                required: false,
                initialValue: gp?.phoneNumber,
                onChanged: (e164) => phoneE164 = e164,
              ),
              TextField(
                controller: emailCtrl,
                decoration:
                    const InputDecoration(labelText: "Email (optionnel)"),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Actif"),
                value: isActive,
                onChanged: (v) => setState(() => isActive = v),
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
              final prenom = prenomCtrl.text.trim();
              final nom = nomCtrl.text.trim();
              if (prenom.isEmpty || nom.isEmpty) return;

              Navigator.pop(context, {
                'prenom': prenom,
                'nom': nom,
                'phoneNumber': (phoneE164?.isEmpty ?? true) ? null : phoneE164,
                'email': emailCtrl.text.trim().isEmpty
                    ? null
                    : emailCtrl.text.trim(),
                'isActive': isActive,
              });
            },
            child: Text(isEdit ? "Sauvegarder" : "Créer"),
          ),
        ],
      ),
    ),
  );
}
