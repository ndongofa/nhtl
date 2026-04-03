import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sama/services/auth_service.dart';
import 'package:sama/services/gp_service.dart';
import 'package:sama/widgets/gp_form_dialog.dart';
import 'package:sama/widgets/sama_account_menu.dart';
import '../../models/gp_agent.dart';
import '../../models/logged_user.dart';

class GpListScreen extends StatefulWidget {
  const GpListScreen({Key? key}) : super(key: key);

  @override
  State<GpListScreen> createState() => _GpListScreenState();
}

class _GpListScreenState extends State<GpListScreen> {
  static const Color _bg = Color(0xFF0D1B2E);
  static const Color _bgSection = Color(0xFF112236);
  static const Color _bgCard = Color(0xFF1A2E45);
  static const Color _appBlue = Color(0xFF2296F3);
  static const Color _amber = Color(0xFFFFB300);
  static const Color _green = Color(0xFF22C55E);
  static const Color _textPrimary = Color(0xFFF0F6FF);
  static const Color _textMuted = Color(0xFF7A94B0);
  static const Color _border = Color(0xFF1E3A55);

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
      builder: (ctx) => AlertDialog(
        backgroundColor: _bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Supprimer GP ?",
            style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w800)),
        content: Text("Supprimer ${gp.fullName} ?",
            style: const TextStyle(color: _textMuted)),
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
        backgroundColor: _bg,
        appBar: AppBar(
            backgroundColor: _bgSection,
            title:
                const Text("Sécurité", style: TextStyle(color: _textPrimary))),
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
        title: const Text("GP — Agents de transport",
            style: TextStyle(
                color: _textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 16)),
        actions: [
          IconButton(
            tooltip: "Mon espace",
            onPressed: () => SamaAccountMenu.open(context),
            icon: const Icon(Icons.dashboard_outlined, color: _textPrimary),
          ),
          IconButton(
            tooltip: "Déconnexion",
            onPressed: () async {
              await AuthService.logout();
              if (!context.mounted) return;
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/', (_) => false);
            },
            icon: const Icon(Icons.logout, color: _textPrimary),
          ),
          IconButton(
              onPressed: _load,
              icon: const Icon(Icons.refresh, color: _textPrimary)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        backgroundColor: _appBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _appBlue))
          : gps.isEmpty
              ? const Center(
                  child:
                      Text("Aucun GP", style: TextStyle(color: _textPrimary)))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: gps.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final gp = gps[i];
                    return Container(
                      decoration: BoxDecoration(
                        color: _bgCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: gp.isActive
                                ? _green.withValues(alpha: 0.25)
                                : _border),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: _appBlue.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                              child: Text(
                                  gp.prenom.isNotEmpty
                                      ? gp.prenom[0].toUpperCase()
                                      : 'G',
                                  style: const TextStyle(
                                      color: _appBlue,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(gp.fullName,
                                  style: const TextStyle(
                                      color: _textPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14)),
                              Text(gp.phoneNumber ?? "—",
                                  style: const TextStyle(
                                      color: _textMuted, fontSize: 12)),
                              if (gp.email != null)
                                Text(gp.email!,
                                    style: const TextStyle(
                                        color: _textMuted, fontSize: 12)),
                            ])),
                        Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                  gp.isActive
                                      ? Icons.check_circle
                                      : Icons.block,
                                  color: gp.isActive
                                      ? _green
                                      : Colors.red.shade400,
                                  size: 18),
                              const SizedBox(height: 2),
                              Text(gp.isActive ? "Actif" : "Inactif",
                                  style: TextStyle(
                                      color: gp.isActive
                                          ? _green
                                          : Colors.red.shade400,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600)),
                            ]),
                        const SizedBox(width: 8),
                        IconButton(
                            icon: const Icon(Icons.edit,
                                color: _appBlue, size: 20),
                            onPressed: () => _edit(gp),
                            splashRadius: 18),
                        IconButton(
                            icon: Icon(Icons.delete,
                                color: Colors.red.shade400, size: 20),
                            onPressed: () => _delete(gp),
                            splashRadius: 18),
                      ]),
                    );
                  },
                ),
    );
  }
}
