// lib/screens/achats_archives_screen.dart
//
// Archives des achats (utilisateur ou admin).
// Adapté depuis commandes_archives_screen.dart.

import 'package:flutter/material.dart';
import '../services/achat_service.dart';
import '../models/achat.dart';
import 'achat_tracking_screen.dart';

// ── Couleurs UI ────────────────────────────────────────────────────────────
const Color _bg = Color(0xFF0D1B2E);
const Color _bgCard = Color(0xFF1A2E45);
const Color _teal = Color(0xFF00BCD4);
const Color _amber = Color(0xFFFFB300);
const Color _green = Color(0xFF22C55E);
const Color _textPrimary = Color(0xFFF0F6FF);
const Color _textMuted = Color(0xFF7A94B0);
const Color _border = Color(0xFF1E3A55);

class AchatsArchivesScreen extends StatefulWidget {
  final bool isAdmin;
  const AchatsArchivesScreen({Key? key, required this.isAdmin})
      : super(key: key);

  @override
  State<AchatsArchivesScreen> createState() => _AchatsArchivesScreenState();
}

class _AchatsArchivesScreenState extends State<AchatsArchivesScreen> {
  final _service = AchatService();
  List<Achat> _archives = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadArchives();
  }

  Future<void> _loadArchives() async {
    setState(() => _loading = true);
    final data = widget.isAdmin
        ? await _service.getAchatsArchivesAdmin()
        : await _service.getAchatsArchivesUser();
    if (!mounted) return;
    setState(() {
      _archives = data ?? [];
      _loading = false;
    });
  }

  Future<void> _refresh() => _loadArchives();

  Future<void> _delete(Achat achat) async {
    if (achat.id == null) return;
    final ok = await _service.deleteAchat(achat.id!);
    if (ok) _refresh();
  }

  Future<void> _unarchive(Achat achat) async {
    if (achat.id == null) return;
    if (widget.isAdmin) {
      await _service.unarchiveAchatAdmin(achat.id!);
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1628),
        foregroundColor: _textPrimary,
        elevation: 0,
        title: Text(
            widget.isAdmin
                ? 'Archives — Tous les achats'
                : 'Mes achats archivés',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _teal))
          : _archives.isEmpty
              ? _emptyState()
              : RefreshIndicator(
                  onRefresh: _refresh,
                  color: _teal,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _archives.length,
                    itemBuilder: (ctx, i) => _ArchiveTile(
                      achat: _archives[i],
                      isAdmin: widget.isAdmin,
                      onDelete: () => _delete(_archives[i]),
                      onUnarchive: () => _unarchive(_archives[i]),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                AchatTrackingScreen(achat: _archives[i])),
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _emptyState() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('📦', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text('Aucun achat archivé',
              style: TextStyle(
                  color: _textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16)),
          const SizedBox(height: 8),
          Text('Les achats terminés apparaîtront ici',
              style: TextStyle(color: _textMuted, fontSize: 13)),
        ]),
      );
}

// ── Tuile archive ─────────────────────────────────────────────────────────────

class _ArchiveTile extends StatelessWidget {
  final Achat achat;
  final bool isAdmin;
  final VoidCallback onDelete;
  final VoidCallback onUnarchive;
  final VoidCallback onTap;

  const _ArchiveTile({
    required this.achat,
    required this.isAdmin,
    required this.onDelete,
    required this.onUnarchive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border)),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(
                    '#${achat.id ?? '—'} — ${achat.marche.isNotEmpty ? achat.marche : achat.typeProduit}',
                    style: const TextStyle(
                        color: _textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${achat.quantite}x · ${achat.villeLivraison}, ${achat.paysLivraison}',
                    style: const TextStyle(
                        color: _textMuted, fontSize: 12),
                  ),
                  if (achat.prixTotal > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${achat.prixTotal} ${achat.devise}',
                      style: const TextStyle(
                          color: _amber,
                          fontWeight: FontWeight.w700,
                          fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: _green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _green.withValues(alpha: 0.3))),
                    child: const Text('Archivé',
                        style: TextStyle(
                            color: _green,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
                ]),
              ),
              Column(children: [
                if (isAdmin)
                  IconButton(
                    icon: const Icon(Icons.unarchive_outlined,
                        color: _teal, size: 20),
                    tooltip: 'Désarchiver',
                    onPressed: onUnarchive,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                const SizedBox(height: 8),
                IconButton(
                  icon:
                      const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  tooltip: 'Supprimer',
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: const Color(0xFF1A2E45),
                        title: const Text('Supprimer ?',
                            style: TextStyle(color: _textPrimary)),
                        content: const Text(
                            'Supprimer définitivement cet achat archivé ?',
                            style: TextStyle(color: _textMuted)),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Annuler',
                                  style: TextStyle(color: _textMuted))),
                          TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Supprimer',
                                  style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                    if (confirm == true) onDelete();
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}
