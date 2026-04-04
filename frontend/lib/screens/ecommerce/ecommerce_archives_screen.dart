// lib/screens/ecommerce/ecommerce_archives_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/commande_ecommerce.dart';
import '../../providers/app_theme_provider.dart';
import '../../services/auth_service.dart';
import '../../services/ecommerce_service.dart';
import '../../widgets/sama_account_menu.dart';
import 'ecommerce_tracking_screen.dart';

class EcommerceArchivesScreen extends StatefulWidget {
  final String serviceType;
  final String serviceLabel;
  final Color accentColor;
  final bool isAdmin;

  const EcommerceArchivesScreen({
    Key? key,
    required this.serviceType,
    required this.serviceLabel,
    required this.accentColor,
    this.isAdmin = false,
  }) : super(key: key);

  @override
  State<EcommerceArchivesScreen> createState() =>
      _EcommerceArchivesScreenState();
}

class _EcommerceArchivesScreenState
    extends State<EcommerceArchivesScreen> {
  late EcommerceService _service;
  List<CommandeEcommerce> _archives = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _service = EcommerceService(serviceType: widget.serviceType);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _archives = await _service.getMesArchives();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppThemeProvider>();

    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.topBarBg,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('Archives — ${widget.serviceLabel}',
            style: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 16)),
        actions: [
          IconButton(
            tooltip: "Mon espace",
            onPressed: () => SamaAccountMenu.open(context),
            icon: const Icon(Icons.dashboard_outlined),
          ),
          if (AuthService.isLoggedIn())
            IconButton(
              tooltip: "Déconnexion",
              onPressed: () async {
                await AuthService.logout();
                if (!context.mounted) return;
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/', (_) => false);
              },
              icon: const Icon(Icons.logout),
            ),
          IconButton(
              icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                  color: widget.accentColor))
          : _archives.isEmpty
              ? _empty(t)
              : RefreshIndicator(
                  onRefresh: _load,
                  color: widget.accentColor,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _archives.length,
                    itemBuilder: (ctx, i) => _ArchiveTile(
                      commande: _archives[i],
                      accentColor: widget.accentColor,
                      t: t,
                    ),
                  ),
                ),
    );
  }

  Widget _empty(AppThemeProvider t) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('📦', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 16),
          Text('Aucune archive',
              style: TextStyle(
                  color: t.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16)),
        ]),
      );
}

class _ArchiveTile extends StatelessWidget {
  final CommandeEcommerce commande;
  final Color accentColor;
  final AppThemeProvider t;
  const _ArchiveTile(
      {required this.commande,
      required this.accentColor,
      required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
          color: t.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.border)),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EcommerceTrackingScreen(
                commande: commande,
                accentColor: accentColor,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('#${commande.id}',
                      style: TextStyle(
                          color: t.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    '${commande.items.length} article(s) · ${commande.prixTotal.toStringAsFixed(2)} ${commande.devise}',
                    style: TextStyle(color: t.textMuted, fontSize: 12),
                  ),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: AppThemeProvider.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppThemeProvider.green.withValues(alpha: 0.3))),
                child: const Text('Archivée',
                    style: TextStyle(
                        color: AppThemeProvider.green,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
