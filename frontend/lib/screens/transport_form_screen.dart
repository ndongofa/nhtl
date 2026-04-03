// lib/screens/transport_form_screen.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../models/transport.dart';
import '../services/transport_service.dart';
import '../services/auth_service.dart';
import '../widgets/phone_input_field.dart';

class TransportFormScreen extends StatefulWidget {
  final Transport? transport;
  const TransportFormScreen({Key? key, this.transport}) : super(key: key);

  @override
  State<TransportFormScreen> createState() => _TransportFormScreenState();
}

class _TransportFormScreenState extends State<TransportFormScreen> {
  static const Color _appBlue = Color(0xFF2296F3);
  static const Color _bgLight = Color(0xFFF4F8FF);
  static const Color _surface = Colors.white;
  static const Color _textMain = Color(0xFF0F2040);
  static const Color _textMuted = Color(0xFF6B7A99);
  static const Color _border = Color(0xFFDDE3EF);
  static const Color _amber = Color(0xFFFFB300);
  static const Color _teal = Color(0xFF00BCD4);
  static const Color _green = Color(0xFF22C55E);

  final _formKey = GlobalKey<FormState>();
  final _service = TransportService();
  bool _isLoading = false;

  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _paysExpediteurController = TextEditingController();
  final _villeExpediteurController = TextEditingController();
  final _adresseExpediteurController = TextEditingController();
  final _paysDestController = TextEditingController();
  final _villeDestController = TextEditingController();
  final _adresseDestController = TextEditingController();
  final _typesMarchandiseController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _poidsController = TextEditingController();
  final _valeurEstimeeController = TextEditingController();
  final _deviseController = TextEditingController();

  String? _phoneE164;
  String _statut = "EN_ATTENTE";

  static const List<String> _statuts = [
    "EN_ATTENTE",
    "EN_COURS",
    "LIVRE",
    "ANNULE"
  ];
  static const List<String> _devises = [
    "EUR",
    "USD",
    "GBP",
    "MAD",
    "XOF",
    "CAD"
  ];

  @override
  void initState() {
    super.initState();
    final t = widget.transport;
    if (t != null) {
      // ── Mode édition : remplir depuis l'objet existant ──────────────
      _nomController.text = t.nom;
      _prenomController.text = t.prenom;
      _phoneE164 = t.numeroTelephone;
      _emailController.text = t.email ?? '';
      _paysExpediteurController.text = t.paysExpediteur;
      _villeExpediteurController.text = t.villeExpediteur;
      _adresseExpediteurController.text = t.adresseExpediteur;
      _paysDestController.text = t.paysDestinataire;
      _villeDestController.text = t.villeDestinataire;
      _adresseDestController.text = t.adresseDestinataire;
      _typesMarchandiseController.text = t.typesMarchandise;
      _descriptionController.text = t.description;
      _poidsController.text = t.poids?.toString() ?? '';
      _valeurEstimeeController.text = t.valeurEstimee.toString();
      _deviseController.text = t.devise;
      _statut = t.statut;
    } else {
      // ── Nouveau formulaire : auto-remplissage depuis le profil connecté ──
      _deviseController.text = 'EUR';
      final meta = AuthService.userMetadata;
      final user = AuthService.currentUser;
      if (meta != null || user != null) {
        _nomController.text = meta?['nom']?.toString().trim() ?? '';
        _prenomController.text = meta?['prenom']?.toString().trim() ?? '';
        _emailController.text = user?.email?.trim() ?? '';
        _phoneE164 = user?.phone != null ? '+${user!.phone}' : null;
      }
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _paysExpediteurController.dispose();
    _villeExpediteurController.dispose();
    _adresseExpediteurController.dispose();
    _paysDestController.dispose();
    _villeDestController.dispose();
    _adresseDestController.dispose();
    _typesMarchandiseController.dispose();
    _descriptionController.dispose();
    _poidsController.dispose();
    _valeurEstimeeController.dispose();
    _deviseController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_phoneE164 == null || _phoneE164!.isEmpty) {
      Fluttertoast.showToast(
          msg: 'Veuillez entrer un numéro de téléphone valide.',
          backgroundColor: Colors.red,
          toastLength: Toast.LENGTH_LONG);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final data = Transport(
        id: widget.transport?.id,
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        numeroTelephone: _phoneE164!,
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        paysExpediteur: _paysExpediteurController.text.trim(),
        villeExpediteur: _villeExpediteurController.text.trim(),
        adresseExpediteur: _adresseExpediteurController.text.trim(),
        paysDestinataire: _paysDestController.text.trim(),
        villeDestinataire: _villeDestController.text.trim(),
        adresseDestinataire: _adresseDestController.text.trim(),
        typesMarchandise: _typesMarchandiseController.text.trim(),
        description: _descriptionController.text.trim(),
        poids: _poidsController.text.trim().isEmpty
            ? null
            : double.tryParse(
                _poidsController.text.trim().replaceAll(',', '.')),
        valeurEstimee: double.parse(
            _valeurEstimeeController.text.trim().replaceAll(',', '.')),
        devise: _deviseController.text.trim().isEmpty
            ? 'EUR'
            : _deviseController.text.trim(),
        statut: _statut,
      );
      final result = widget.transport == null
          ? await _service.createTransport(data)
          : await _service.updateTransport(data.id!, data);
      if (result != null) {
        Fluttertoast.showToast(
            msg: widget.transport == null
                ? '✅ Transport créé !'
                : '✅ Transport modifié !',
            backgroundColor: Colors.green);
        Navigator.pop(context, true);
      } else {
        Fluttertoast.showToast(
            msg: '❌ Une erreur est survenue.', backgroundColor: Colors.red);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: '❌ Erreur : $e', backgroundColor: Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.transport != null;
    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        backgroundColor: _appBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(isEdit ? 'Modifier le transport par GP' : 'Nouveau transport par GP',
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Form(
              key: _formKey,
              child: Column(children: [
                // ── Section 1 : Expéditeur ──────────────────────────────────
                _card(children: [
                  _sectionHeader(Icons.person_outline, _appBlue, "Expéditeur",
                      "Informations de la personne qui envoie"),
                  const SizedBox(height: 20),
                  Row(children: [
                    Expanded(
                        child: _field(
                            _nomController, "Nom", Icons.badge_outlined,
                            hint: "Ex : Diallo", required: true)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _field(
                            _prenomController, "Prénom", Icons.person_outline,
                            hint: "Ex : Mamadou", required: true)),
                  ]),
                  const SizedBox(height: 14),
                  // ✅ PhoneInputField avec initialValue depuis le profil
                  PhoneInputField(
                    label: 'Téléphone',
                    initialCountryCode: 'SN',
                    initialValue: _phoneE164,
                    onChanged: (e164) => setState(() => _phoneE164 = e164),
                  ),
                  const SizedBox(height: 14),
                  _field(_emailController, "Email (optionnel)",
                      Icons.alternate_email,
                      hint: "votre@email.com",
                      keyboardType: TextInputType.emailAddress,
                      required: false, validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final regex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                    return regex.hasMatch(v.trim()) ? null : 'Email invalide';
                  }),
                  const SizedBox(height: 14),
                  _field(_paysExpediteurController, "Pays d'expédition",
                      Icons.flag_outlined,
                      hint: "Ex : France, Sénégal, Maroc", required: true),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(
                        child: _field(_villeExpediteurController, "Ville",
                            Icons.location_city_outlined,
                            hint: "Ex : Paris", required: true)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _field(_adresseExpediteurController,
                            "Adresse complète", Icons.home_outlined,
                            hint: "N°, rue, quartier...",
                            required: true,
                            maxLines: 2)),
                  ]),
                ]),

                const SizedBox(height: 16),

                // ── Section 2 : Destinataire ────────────────────────────────
                _card(children: [
                  _sectionHeader(Icons.place_outlined, _teal, "Destinataire",
                      "Informations de livraison"),
                  const SizedBox(height: 20),
                  _field(_paysDestController, "Pays de destination",
                      Icons.flag_outlined,
                      hint: "Ex : Sénégal, France, Maroc", required: true),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(
                        child: _field(_villeDestController, "Ville",
                            Icons.location_city_outlined,
                            hint: "Ex : Dakar", required: true)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _field(_adresseDestController,
                            "Adresse complète", Icons.home_outlined,
                            hint: "N°, rue, quartier...",
                            required: true,
                            maxLines: 2)),
                  ]),
                ]),

                const SizedBox(height: 16),

                // ── Section 3 : Marchandise ─────────────────────────────────
                _card(children: [
                  _sectionHeader(
                      Icons.inventory_2_outlined,
                      _amber,
                      "Marchandise",
                      "Détails du colis ou produit à transporter"),
                  const SizedBox(height: 20),
                  _field(_typesMarchandiseController, "Type de marchandise",
                      Icons.category_outlined,
                      hint: "Ex : Vêtements, électronique, alimentaire...",
                      required: true),
                  const SizedBox(height: 14),
                  _field(_descriptionController, "Description détaillée",
                      Icons.description_outlined,
                      hint: "Décrivez précisément le contenu du colis",
                      required: true,
                      maxLines: 3, validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Requis';
                    if (v.trim().length < 10) return 'Minimum 10 caractères';
                    return null;
                  }),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(
                        child: _field(_poidsController, "Poids estimé (kg)",
                            Icons.scale_outlined,
                            hint: "Ex : 5,5",
                            required: false,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _field(_valeurEstimeeController,
                            "Valeur estimée", Icons.payments_outlined,
                            hint: "Ex : 150",
                            required: true,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true), validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Requis';
                      final val =
                          double.tryParse(v.trim().replaceAll(',', '.'));
                      return (val == null || val <= 0)
                          ? 'Valeur invalide'
                          : null;
                    })),
                  ]),
                  const SizedBox(height: 14),
                  _dropdown(
                      "Devise",
                      _deviseController.text.isEmpty
                          ? 'EUR'
                          : _deviseController.text,
                      _devises,
                      Icons.currency_exchange, (v) {
                    setState(() => _deviseController.text = v!);
                  }),
                ]),

                const SizedBox(height: 16),

                // ── Section 4 : Statut (édition uniquement) ─────────────────
                if (isEdit)
                  _card(children: [
                    _sectionHeader(Icons.track_changes_outlined, _green,
                        "Statut", "État actuel du transport"),
                    const SizedBox(height: 16),
                    _dropdown("Statut du transport", _statut, _statuts,
                        Icons.local_shipping_outlined, (v) {
                      setState(() => _statut = v!);
                    }),
                  ]),

                if (isEdit) const SizedBox(height: 16),

                // ── Bouton soumettre ────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Icon(
                            isEdit ? Icons.save_outlined : Icons.send_outlined,
                            size: 18),
                    label: Text(
                      _isLoading
                          ? "Envoi en cours..."
                          : isEdit
                              ? "Enregistrer les modifications"
                              : "Envoyer la demande de transport par GP",
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _appBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _isLoading ? null : _submit,
                  ),
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers UI ─────────────────────────────────────────────────────────────

  Widget _card({required List<Widget> children}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );

  Widget _sectionHeader(
          IconData icon, Color color, String title, String subtitle) =>
      Row(children: [
        Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  color: _textMain, fontWeight: FontWeight.w800, fontSize: 15)),
          Text(subtitle,
              style: const TextStyle(
                  color: _textMuted,
                  fontWeight: FontWeight.w400,
                  fontSize: 12)),
        ]),
      ]);

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    String? hint,
    bool required = true,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(
          color: _textMain, fontWeight: FontWeight.w500, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(
            color: _textMuted, fontWeight: FontWeight.w500, fontSize: 14),
        hintStyle: const TextStyle(color: Color(0xFFB0BBCC), fontSize: 13),
        prefixIcon: Icon(icon, color: _appBlue, size: 18),
        filled: true,
        fillColor: _bgLight,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _appBlue, width: 1.8)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red)),
      ),
      validator: validator ??
          (required
              ? (v) =>
                  (v == null || v.trim().isEmpty) ? 'Ce champ est requis' : null
              : null),
    );
  }

  Widget _dropdown(String label, String value, List<String> items,
      IconData icon, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: items.contains(value) ? value : items.first,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
            color: _textMuted, fontWeight: FontWeight.w500, fontSize: 14),
        prefixIcon: Icon(icon, color: _appBlue, size: 18),
        filled: true,
        fillColor: _bgLight,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      style: const TextStyle(
          color: _textMain, fontWeight: FontWeight.w500, fontSize: 14),
      dropdownColor: _surface,
      borderRadius: BorderRadius.circular(12),
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(item, style: const TextStyle(color: _textMain)),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}
