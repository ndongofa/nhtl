import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/logged_user.dart';
import '../../providers/app_theme_provider.dart';
import '../../services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppThemeProvider>();
    final user = LoggedUser.fromSupabase();

    final identifier = (user.email != null && user.email!.trim().isNotEmpty)
        ? user.email!.trim()
        : ((user.phone ?? '').trim().isNotEmpty ? user.phone!.trim() : '—');

    final fullName =
        (user.fullName ?? '').trim().isEmpty ? '—' : user.fullName!.trim();
    final username =
        (user.username ?? '').trim().isEmpty ? '—' : user.username!.trim();

    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.topBarBg,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Mon profil",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: t.isDark ? "Thème clair" : "Thème sombre",
            onPressed: () => context.read<AppThemeProvider>().toggleTheme(),
            icon: Icon(
              t.isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round,
            ),
          ),
          IconButton(
            tooltip: "Déconnexion",
            onPressed: () async {
              await AuthService.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: user.userId.isEmpty
                ? _emptyState(t)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _headerCard(t,
                          fullName: fullName, identifier: identifier),
                      const SizedBox(height: 14),
                      _infoCard(t, title: "Informations", rows: [
                        ("Identifiant", identifier),
                        ("Nom complet", fullName),
                        ("Nom d'utilisateur", username),
                        ("Email", user.email ?? '—'),
                        ("Téléphone", user.phone ?? '—'),
                      ]),
                      const SizedBox(height: 14),
                      _infoCard(t, title: "Sécurité", rows: [
                        ("ID utilisateur", user.userId),
                      ]),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState(AppThemeProvider t) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: t.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppThemeProvider.appBlue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.person_off_outlined,
                  color: AppThemeProvider.appBlue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Aucun utilisateur connecté.",
                style: TextStyle(
                    color: t.textPrimary, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );

  Widget _headerCard(
    AppThemeProvider t, {
    required String fullName,
    required String identifier,
  }) {
    final initials = _initials(fullName == '—' ? identifier : fullName);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: t.isDark
              ? [const Color(0xFF0A1628), const Color(0xFF0D3060)]
              : [AppThemeProvider.appBlue, const Color(0xFF0D5BBF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppThemeProvider.appBlue.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  identifier,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(
    AppThemeProvider t, {
    required String title,
    required List<(String, String)> rows,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  TextStyle(color: t.textPrimary, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          ...rows.map((r) => _row(t, r.$1, r.$2)),
        ],
      ),
    );
  }

  Widget _row(AppThemeProvider t, String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            SizedBox(
              width: 140,
              child: Text(
                k,
                style:
                    TextStyle(color: t.textMuted, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                v,
                style: TextStyle(
                    color: t.textPrimary, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );

  String _initials(String s) {
    final text = s.trim();
    if (text.isEmpty) return "U";
    final parts =
        text.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.length == 1) {
      final p = parts.first;
      return (p.length >= 2 ? p.substring(0, 2) : p.substring(0, 1))
          .toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}
