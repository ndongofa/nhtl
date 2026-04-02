// lib/screens/achats_list_screen.dart
//
// Liste des achats de l'utilisateur (ou tous les achats pour l'admin).
// Adapté depuis commandes_list_screen.dart.

import 'package:flutter/material.dart';
import '../models/achat.dart';
import '../services/achat_service.dart';
import '../models/logged_user.dart';
import 'achat_form_screen.dart';
import 'achat_tracking_screen.dart';

// ── Statut ADMINISTRATIF ──────────────────────────────────────────────────────
final Map<String, Color> achatStatutAdminColors = {
  "EN_ATTENTE": Colors.grey,
  "EN_COURS": const Color(0xFFFFB300),
  "LIVRE": const Color(0xFF22C55E),
  "ANNULE": Colors.red,
};

final Map<String, IconData> achatStatutAdminIcons = {
  "EN_ATTENTE": Icons.timelapse,
  "EN_COURS": Icons.sync,
  "LIVRE": Icons.done,
  "ANNULE": Icons.cancel,
};

// ── Statut LOGISTIQUE achat (7 étapes) ────────────────────────────────────────
final Map<String, Color> achatStatutSuiviColors = {
  "EN_ATTENTE": Colors.grey,
  "ACHAT_CONFIRME": const Color(0xFF2296F3),
  "ACHAT_EFFECTUE": const Color(0xFFFFB300),
  "EN_TRANSIT": const Color(0xFFFF6F00),
  "ARRIVE": const Color(0xFF00D4C8),
  "PRET_LIVRAISON": const Color(0xFF22C55E),
  "LIVRE": const Color(0xFF22C55E),
};

final Map<String, IconData> achatStatutSuiviIcons = {
  "EN_ATTENTE": Icons.hourglass_empty,
  "ACHAT_CONFIRME": Icons.shopping_cart_outlined,
  "ACHAT_EFFECTUE": Icons.shopping_bag_outlined,
  "EN_TRANSIT": Icons.local_shipping_outlined,
  "ARRIVE": Icons.location_on_outlined,
  "PRET_LIVRAISON": Icons.inventory_2_outlined,
  "LIVRE": Icons.celebration_outlined,
};

const List<String> _statutsSuiviOrdonnes = [
  "EN_ATTENTE",
  "ACHAT_CONFIRME",
  "ACHAT_EFFECTUE",
  "EN_TRANSIT",
  "ARRIVE",
  "PRET_LIVRAISON",
  "LIVRE",
];

String _labelSuivi(String s) {
  switch (s) {
    case "EN_ATTENTE":      return "En attente";
    case "ACHAT_CONFIRME":  return "Achat confirmé";
    case "ACHAT_EFFECTUE":  return "Achat effectué";
    case "EN_TRANSIT":      return "En transit";
    case "ARRIVE":          return "Arrivé";
    case "PRET_LIVRAISON":  return "Prêt à livrer";
    case "LIVRE":           return "Livré";
    default:                return s;
  }
}

// ── Couleurs UI ───────────────────────────────────────────────────────────────
const Color _bg = Color(0xFF0D1B2E);
const Color _bgCard = Color(0xFF1A2E45);
const Color _appBlue = Color(0xFF2296F3);
const Color _amber = Color(0xFFFFB300);
const Color _teal = Color(0xFF00BCD4);
const Color _textPrimary = Color(0xFFF0F6FF);
const Color _textMuted = Color(0xFF7A94B0);
const Color _border = Color(0xFF1E3A55);

// ─────────────────────────────────────────────────────────────────────────────

class AchatsListScreen extends StatefulWidget {
  const AchatsListScreen({Key? key}) : super(key: key);

  @override
  State<AchatsListScreen> createState() => _AchatsListScreenState();
}

class _AchatsListScreenState extends State<AchatsListScreen> {
  final _service = AchatService();
  List<Achat> _achats = [];
  bool _loading = false;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _isAdmin = LoggedUser.fromSupabase().role == 'admin';
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _service.getAllAchats();
    if (!mounted) return;
    setState(() {
      _achats = data ?? [];
      _loading = false;
    });
  }

  Future<void> _refresh() => _load();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1628),
        foregroundColor: _textPrimary,
        elevation: 0,
        title: const Text('Mes achats',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: 'Actualiser',
          ),
          if (!_isAdmin)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                final ok = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AchatFormScreen()),
                );
                if (ok == true) _refresh();
              },
              tooltip: 'Nouvelle demande',
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _teal))
          : _achats.isEmpty
              ? _emptyState()
              : RefreshIndicator(
                  onRefresh: _refresh,
                  color: _teal,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _achats.length,
                    itemBuilder: (ctx, i) => _AchatTile(
                      achat: _achats[i],
                      isAdmin: _isAdmin,
                      service: _service,
                      onRefresh: _refresh,
                    ),
                  ),
                ),
    );
  }

  Widget _emptyState() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🏪', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text('Aucun achat en cours',
              style: TextStyle(
                  color: _textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16)),
          const SizedBox(height: 8),
          Text('Créez votre première demande d\'achat sur mesure',
              style: TextStyle(color: _textMuted, fontSize: 13)),
          const SizedBox(height: 24),
          if (!_isAdmin)
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nouvelle demande',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12)),
              onPressed: () async {
                final ok = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const AchatFormScreen()),
                );
                if (ok == true) _refresh();
              },
            ),
        ]),
      );
}

// ── Tuile achat ──────────────────────────────────────────────────────────────

class _AchatTile extends StatelessWidget {
  final Achat achat;
  final bool isAdmin;
  final AchatService service;
  final VoidCallback onRefresh;

  const _AchatTile({
    required this.achat,
    required this.isAdmin,
    required this.service,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final statut = achat.statut.toUpperCase();
    final suivi = achat.statutSuivi.toUpperCase();
    final statusColor = achatStatutAdminColors[statut] ?? Colors.grey;
    final suivisColor = achatStatutSuiviColors[suivi] ?? Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border)),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => AchatTrackingScreen(achat: achat)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Row(children: [
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(
                      '#${achat.id ?? '—'} — ${achat.marche.isNotEmpty ? achat.marche : achat.typeProduit}',
                      style: const TextStyle(
                          color: _textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${achat.quantite}x ${achat.typeProduit} · ${achat.villeLivraison}',
                      style: const TextStyle(
                          color: _textMuted, fontSize: 12),
                    ),
                  ]),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  _badge(statut, statusColor),
                  const SizedBox(height: 4),
                  _badge(_labelSuivi(suivi), suivisColor, small: true),
                ]),
              ]),
              if (achat.prixTotal > 0) ...[
                const SizedBox(height: 8),
                Text(
                  '${achat.prixTotal} ${achat.devise}',
                  style: const TextStyle(
                      color: _amber,
                      fontWeight: FontWeight.w700,
                      fontSize: 14),
                ),
              ],
              if (isAdmin) ...[
                const Divider(color: _border, height: 20),
                Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                  TextButton.icon(
                    icon: const Icon(Icons.archive_outlined,
                        size: 16, color: _textMuted),
                    label: const Text('Archiver',
                        style: TextStyle(
                            color: _textMuted, fontSize: 12)),
                    style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4)),
                    onPressed: () async {
                      if (achat.id == null) return;
                      await service.archiveAchat(achat.id!);
                      onRefresh();
                    },
                  ),
                ]),
              ],
            ]),
          ),
        ),
      ),
    );
  }

  Widget _badge(String label, Color color, {bool small = false}) => Container(
        padding: EdgeInsets.symmetric(
            horizontal: small ? 6 : 8, vertical: small ? 2 : 4),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.35))),
        child: Text(label,
            style: TextStyle(
                color: color,
                fontSize: small ? 10 : 11,
                fontWeight: FontWeight.w700)),
      );
}
