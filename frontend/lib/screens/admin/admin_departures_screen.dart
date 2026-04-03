// lib/screens/admin/admin_departures_screen.dart
//
// ✅ Liste tous les départs (DRAFT + PUBLISHED + ARCHIVED)
// ✅ Créer un départ (formulaire modal)
// ✅ Modifier un départ
// ✅ Publier / Dépublier / Archiver
// ✅ Supprimer
// ✅ Indicateur visuel par statut

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/departure_model.dart';
import '../../../services/departure_api_service.dart';
import '../../../services/departure_countdown_service.dart';

class AdminDeparturesScreen extends StatefulWidget {
  const AdminDeparturesScreen({Key? key}) : super(key: key);

  @override
  State<AdminDeparturesScreen> createState() => _AdminDeparturesScreenState();
}

class _AdminDeparturesScreenState extends State<AdminDeparturesScreen> {
  static const Color _bg = Color(0xFF0D1B2E);
  static const Color _bgSection = Color(0xFF112236);
  static const Color _bgCard = Color(0xFF1A2E45);
  static const Color _appBlue = Color(0xFF2296F3);
  static const Color _amber = Color(0xFFFFB300);
  static const Color _green = Color(0xFF22C55E);
  static const Color _teal = Color(0xFF00D4C8);
  static const Color _textPrimary = Color(0xFFF0F6FF);
  static const Color _textMuted = Color(0xFF7A94B0);
  static const Color _border = Color(0xFF1E3A55);

  final _service = DepartureApiService();
  List<DepartureModel> _departures = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _service.adminGetAll();
    if (!mounted) return;
    setState(() {
      _departures = list;
      _loading = false;
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'PUBLISHED':
        return _green;
      case 'ARCHIVED':
        return _textMuted;
      default:
        return _amber;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'PUBLISHED':
        return 'Publié';
      case 'ARCHIVED':
        return 'Archivé';
      default:
        return 'Brouillon';
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'PUBLISHED':
        return Icons.public;
      case 'ARCHIVED':
        return Icons.archive_outlined;
      default:
        return Icons.edit_note;
    }
  }

  Future<void> _changeStatus(DepartureModel dep, String newStatus) async {
    if (dep.id == null) return;
    final ok = await _service.adminChangeStatus(dep.id!, newStatus);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? '✅ Statut mis à jour → ${_statusLabel(newStatus)}'
            : '❌ Erreur changement statut')));
    if (ok) {
      _load();
      // ✅ Si le départ est publié ou dépublié, mettre à jour le ticker/compte à rebours immédiatement
      if (newStatus == 'PUBLISHED' || newStatus == 'DRAFT' || newStatus == 'ARCHIVED') {
        context.read<DepartureCountdownService>().reload();
      }
    }
  }

  Future<void> _delete(DepartureModel dep) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer ce départ ?',
            style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w800)),
        content: Text('${dep.flagEmoji} ${dep.route} — ${dep.dateLabel}',
            style: const TextStyle(color: _textMuted)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child:
                  const Text('Annuler', style: TextStyle(color: _textMuted))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            child: const Text('Supprimer',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final ok = await _service.adminDelete(dep.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? '✅ Départ supprimé' : '❌ Erreur suppression')));
    if (ok) _load();
  }

  Future<void> _openForm({DepartureModel? existing}) async {
    final result = await showModalBottomSheet<DepartureModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _DepartureFormSheet(existing: existing),
    );
    if (result == null) return;

    DepartureModel? saved;
    if (existing == null) {
      saved = await _service.adminCreate(result);
    } else {
      saved = await _service.adminUpdate(existing.id!, result);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(saved != null
            ? '✅ Départ ${existing == null ? "créé" : "mis à jour"}'
            : '❌ Erreur enregistrement')));
    if (saved != null) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bgSection,
        elevation: 0,
        iconTheme: const IconThemeData(color: _textPrimary),
        title: const Text('Gestion des départs',
            style: TextStyle(
                color: _textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 16)),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh, color: _textPrimary),
              onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: _appBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nouveau départ',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _appBlue))
          : _departures.isEmpty
              ? const Center(
                  child: Text('Aucun départ',
                      style: TextStyle(color: _textPrimary)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                  itemCount: _departures.length,
                  itemBuilder: (_, i) => _DepartureTile(
                    dep: _departures[i],
                    statusColor: _statusColor(_departures[i].status),
                    statusLabel: _statusLabel(_departures[i].status),
                    statusIcon: _statusIcon(_departures[i].status),
                    onEdit: () => _openForm(existing: _departures[i]),
                    onDelete: () => _delete(_departures[i]),
                    onChangeStatus: (s) => _changeStatus(_departures[i], s),
                    bgCard: _bgCard,
                    textPrimary: _textPrimary,
                    textMuted: _textMuted,
                    border: _border,
                    appBlue: _appBlue,
                    amber: _amber,
                    green: _green,
                    teal: _teal,
                  ),
                ),
    );
  }
}

// ── Tile d'un départ ──────────────────────────────────────────────────────────

class _DepartureTile extends StatelessWidget {
  final DepartureModel dep;
  final Color statusColor;
  final String statusLabel;
  final IconData statusIcon;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final void Function(String) onChangeStatus;
  final Color bgCard,
      textPrimary,
      textMuted,
      border,
      appBlue,
      amber,
      green,
      teal;

  const _DepartureTile({
    required this.dep,
    required this.statusColor,
    required this.statusLabel,
    required this.statusIcon,
    required this.onEdit,
    required this.onDelete,
    required this.onChangeStatus,
    required this.bgCard,
    required this.textPrimary,
    required this.textMuted,
    required this.border,
    required this.appBlue,
    required this.amber,
    required this.green,
    required this.teal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withValues(alpha: 0.30)),
        boxShadow: [
          BoxShadow(
              color: statusColor.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── En-tête : flag + route + statut ───────────────────────────────
        Row(children: [
          Text(dep.flagEmoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(dep.route,
                    style: TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 15)),
                Text('${dep.dateLabel}  ·  ${dep.timeLabel}',
                    style: TextStyle(color: textMuted, fontSize: 12)),
              ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withValues(alpha: 0.35)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(statusIcon, color: statusColor, size: 12),
              const SizedBox(width: 4),
              Text(statusLabel,
                  style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 11)),
            ]),
          ),
        ]),

        const SizedBox(height: 10),

        // ── Info trajet ────────────────────────────────────────────────────
        Row(children: [
          Icon(Icons.flight_takeoff, color: textMuted, size: 14),
          const SizedBox(width: 6),
          Text('${dep.pointDepart} → ${dep.pointArrivee}',
              style: TextStyle(color: textMuted, fontSize: 12)),
          const Spacer(),
          dep.isPast
              ? Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: border, borderRadius: BorderRadius.circular(10)),
                  child: Text('PASSÉ',
                      style: TextStyle(
                          color: textMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8)))
              : const SizedBox.shrink(),
        ]),

        const SizedBox(height: 10),

        // ── Actions ────────────────────────────────────────────────────────
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          // Modifier
          _iconBtn(Icons.edit_outlined, appBlue, 'Modifier', onEdit),

          // Actions statut
          if (dep.status != 'PUBLISHED')
            _textBtn(Icons.public, green, 'Publier',
                () => onChangeStatus('PUBLISHED')),
          if (dep.status == 'PUBLISHED')
            _textBtn(Icons.public_off, textMuted, 'Dépublier',
                () => onChangeStatus('DRAFT')),
          if (dep.status != 'ARCHIVED')
            _textBtn(Icons.archive_outlined, amber, 'Archiver',
                () => onChangeStatus('ARCHIVED')),
          if (dep.status == 'ARCHIVED')
            _textBtn(Icons.unarchive_outlined, teal, 'Désarchiver',
                () => onChangeStatus('DRAFT')),

          // Supprimer
          _iconBtn(
              Icons.delete_outline, Colors.red.shade400, 'Supprimer', onDelete),
        ]),
      ]),
    );
  }

  Widget _iconBtn(
          IconData icon, Color color, String tooltip, VoidCallback onTap) =>
      IconButton(
          icon: Icon(icon, color: color, size: 20),
          tooltip: tooltip,
          onPressed: onTap,
          splashRadius: 18);

  Widget _textBtn(
          IconData icon, Color color, String label, VoidCallback onTap) =>
      TextButton.icon(
        icon: Icon(icon, size: 14, color: color),
        label: Text(label,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w700, fontSize: 11)),
        style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 6)),
        onPressed: onTap,
      );
}

// ── Formulaire création / modification ────────────────────────────────────────

class _DepartureFormSheet extends StatefulWidget {
  final DepartureModel? existing;
  const _DepartureFormSheet({this.existing});

  @override
  State<_DepartureFormSheet> createState() => _DepartureFormSheetState();
}

class _DepartureFormSheetState extends State<_DepartureFormSheet> {
  static const Color _bgCard = Color(0xFF1A2E45);
  static const Color _bg = Color(0xFF0D1B2E);
  static const Color _appBlue = Color(0xFF2296F3);
  static const Color _textPrimary = Color(0xFFF0F6FF);
  static const Color _textMuted = Color(0xFF7A94B0);
  static const Color _border = Color(0xFF1E3A55);

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _route;
  late final TextEditingController _pointDepart;
  late final TextEditingController _pointArrivee;
  late final TextEditingController _flagEmoji;
  DateTime? _selectedDateTime;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _route = TextEditingController(text: e?.route ?? '');
    _pointDepart = TextEditingController(text: e?.pointDepart ?? '');
    _pointArrivee = TextEditingController(text: e?.pointArrivee ?? '');
    _flagEmoji = TextEditingController(text: e?.flagEmoji ?? '');
    _selectedDateTime = e?.departureDateTime;
  }

  @override
  void dispose() {
    _route.dispose();
    _pointDepart.dispose();
    _pointArrivee.dispose();
    _flagEmoji.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          _selectedDateTime ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark()
            .copyWith(colorScheme: const ColorScheme.dark(primary: _appBlue)),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime ?? DateTime.now()),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark()
            .copyWith(colorScheme: const ColorScheme.dark(primary: _appBlue)),
        child: child!,
      ),
    );
    if (time == null || !mounted) return;

    setState(() {
      _selectedDateTime =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Veuillez sélectionner une date et heure.')));
      return;
    }

    final result = DepartureModel(
      route: _route.text.trim(),
      pointDepart: _pointDepart.text.trim(),
      pointArrivee: _pointArrivee.text.trim(),
      flagEmoji: _flagEmoji.text.trim().isEmpty ? '🌍' : _flagEmoji.text.trim(),
      departureDateTime: _selectedDateTime!,
    );
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: Form(
        key: _formKey,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Poignée
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: _border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),

          Text(isEdit ? 'Modifier le départ' : 'Nouveau départ',
              style: const TextStyle(
                  color: _textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 17)),
          const SizedBox(height: 20),

          _field(_route, 'Route (ex: Paris → Dakar)', required: true),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: _field(_pointDepart, 'Ville départ', required: true)),
            const SizedBox(width: 10),
            Expanded(
                child: _field(_pointArrivee, 'Ville arrivée', required: true)),
          ]),
          const SizedBox(height: 12),
          _field(_flagEmoji, 'Emoji drapeaux (ex: 🇫🇷🇸🇳)', required: false),
          const SizedBox(height: 12),

          // Sélecteur date/heure
          GestureDetector(
            onTap: _pickDateTime,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _selectedDateTime != null
                        ? _appBlue.withValues(alpha: 0.60)
                        : _border),
              ),
              child: Row(children: [
                Icon(Icons.calendar_today,
                    color: _selectedDateTime != null ? _appBlue : _textMuted,
                    size: 18),
                const SizedBox(width: 10),
                Text(
                  _selectedDateTime != null
                      ? DateFormat('dd/MM/yyyy  HH:mm')
                          .format(_selectedDateTime!)
                      : 'Date et heure du départ',
                  style: TextStyle(
                      color:
                          _selectedDateTime != null ? _textPrimary : _textMuted,
                      fontSize: 14),
                ),
              ]),
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                  backgroundColor: _appBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: Text(isEdit ? 'Enregistrer' : 'Créer le départ',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label,
      {bool required = true}) {
    return TextFormField(
      controller: ctrl,
      style: const TextStyle(color: _textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _textMuted, fontSize: 13),
        filled: true,
        fillColor: _bg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _appBlue, width: 1.8)),
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null
          : null,
    );
  }
}
