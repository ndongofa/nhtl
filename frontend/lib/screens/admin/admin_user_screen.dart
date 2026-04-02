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
  static const Color _bg = Color(0xFF0D1B2E);
  static const Color _bgSection = Color(0xFF112236);
  static const Color _bgCard = Color(0xFF1A2E45);
  static const Color _appBlue = Color(0xFF2296F3);
  static const Color _amber = Color(0xFFFFB300);
  static const Color _teal = Color(0xFF00D4C8);
  static const Color _green = Color(0xFF22C55E);
  static const Color _textPrimary = Color(0xFFF0F6FF);
  static const Color _textMuted = Color(0xFF7A94B0);
  static const Color _border = Color(0xFF1E3A55);

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
    final result =
        await showUserFormDialog(context: context, user: user, isEdit: isEdit);
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
            const SnackBar(content: Text("Modifications enregistrées")));
      } else {
        await adminApi.createUser(
          identifier: result['identifier'],
          password: result['password'],
          prenom: result['prenom'],
          nom: result['nom'],
          role: result['role'],
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Utilisateur créé")));
      }
      await Future.delayed(const Duration(milliseconds: 350));
      await _loadUsers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text("Erreur: ${e.toString().replaceFirst('Exception: ', '')}")));
    }
  }

  Future<void> _deleteUser(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Supprimer ?",
            style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w800)),
        content: const Text("Cette action est irréversible.",
            style: TextStyle(color: _textMuted)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child:
                  const Text("Annuler", style: TextStyle(color: _textMuted))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            child: const Text("Supprimer",
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await adminApi.deleteUser(supabaseUserId: id);
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Supprimé")));
        await Future.delayed(const Duration(milliseconds: 350));
        await _loadUsers();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                "Erreur: ${e.toString().replaceFirst('Exception: ', '')}")));
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
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: _bgCard,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Réinitialiser le mot de passe",
              style:
                  TextStyle(color: _textPrimary, fontWeight: FontWeight.w800)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text("Utilisateur: ${user.displayName}",
                style: const TextStyle(color: _textMuted, fontSize: 13)),
            const SizedBox(height: 12),
            _dialogTextField(controller, "Nouveau mot de passe", obscure1,
                () => setDialogState(() => obscure1 = !obscure1)),
            const SizedBox(height: 10),
            _dialogTextField(confirmController, "Confirmer le mot de passe",
                obscure2, () => setDialogState(() => obscure2 = !obscure2)),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child:
                    const Text("Annuler", style: TextStyle(color: _textMuted))),
            ElevatedButton(
              onPressed: () {
                if (controller.text.length < 8) return;
                if (controller.text != confirmController.text) return;
                Navigator.pop(ctx, true);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: _appBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
              child: const Text("Valider",
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await adminApi.resetPassword(
          supabaseUserId: user.id, newPassword: controller.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Mot de passe réinitialisé")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text("Erreur: ${e.toString().replaceFirst('Exception: ', '')}")));
    }
  }

  Widget _dialogTextField(TextEditingController ctrl, String label,
      bool obscure, VoidCallback toggle) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: const TextStyle(color: _textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _textMuted),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _appBlue, width: 1.8)),
        filled: true,
        fillColor: _bg,
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility,
              color: _textMuted, size: 18),
          onPressed: toggle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logged = LoggedUser.fromSupabase();
    if (logged.role != "admin") {
      return Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
            backgroundColor: _bgSection,
            title: const Text("Sécurité",
                style: TextStyle(
                    color: _textPrimary, fontWeight: FontWeight.w800))),
        body: const Center(
            child:
                Text("Accès refusé.", style: TextStyle(color: _textPrimary))),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bgSection,
        elevation: 0,
        iconTheme: const IconThemeData(color: _textPrimary),
        title: const Text("Gestion Utilisateurs",
            style: TextStyle(
                color: _textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 16)),
        actions: [
          IconButton(
              onPressed: _loadUsers,
              icon: const Icon(Icons.refresh, color: _textPrimary)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditUser(isEdit: false),
        backgroundColor: _appBlue,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _appBlue))
          : users.isEmpty
              ? const Center(
                  child: Text("Aucun utilisateur trouvé",
                      style: TextStyle(color: _textPrimary)))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final u = users[index];
                    final contact =
                        (u.email != null && u.email!.trim().isNotEmpty)
                            ? u.email!
                            : (u.phone ?? '');
                    final isAdmin = u.role == 'admin';

                    return Container(
                      decoration: BoxDecoration(
                        color: _bgCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: isAdmin
                                ? _amber.withValues(alpha: 0.30)
                                : _border),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: (isAdmin ? _amber : _appBlue)
                                .withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                              child: Text(u.role[0].toUpperCase(),
                                  style: TextStyle(
                                      color: isAdmin ? _amber : _appBlue,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(u.displayName,
                                  style: const TextStyle(
                                      color: _textPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14)),
                              Text(contact.isEmpty ? "—" : contact,
                                  style: const TextStyle(
                                      color: _textMuted, fontSize: 12)),
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (isAdmin ? _amber : _teal)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(u.role,
                                    style: TextStyle(
                                        color: isAdmin ? _amber : _teal,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11)),
                              ),
                            ])),
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          _actionIcon(Icons.key, Colors.deepPurple.shade300,
                              "Reset password", () => _resetPassword(u)),
                          _actionIcon(Icons.edit, _appBlue, "Modifier",
                              () => _addOrEditUser(user: u, isEdit: true)),
                          _actionIcon(Icons.delete, Colors.red.shade400,
                              "Supprimer", () => _deleteUser(u.id)),
                        ]),
                      ]),
                    );
                  },
                ),
    );
  }

  Widget _actionIcon(
      IconData icon, Color color, String tooltip, VoidCallback onTap) {
    return IconButton(
      icon: Icon(icon, color: color, size: 20),
      tooltip: tooltip,
      onPressed: onTap,
      splashRadius: 18,
    );
  }
}
