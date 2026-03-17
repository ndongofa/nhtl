import 'package:flutter/material.dart';
import '../models/transport.dart';
import '../services/transport_service.dart';
import 'package:fluttertoast/fluttertoast.dart';

class TransportFormScreen extends StatefulWidget {
  final Transport? transport; // null = création, non null = édition

  const TransportFormScreen({Key? key, this.transport}) : super(key: key);

  @override
  State<TransportFormScreen> createState() => _TransportFormScreenState();
}

class _TransportFormScreenState extends State<TransportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = TransportService();
  bool _isLoading = false;

  // Contrôleurs pour chaque champ
  final nomController = TextEditingController();
  final prenomController = TextEditingController();
  final numeroTelephoneController = TextEditingController();
  final emailController = TextEditingController();
  final paysExpediteurController = TextEditingController();
  final villeExpediteurController = TextEditingController();
  final adresseExpediteurController = TextEditingController();
  final paysDestinataireController = TextEditingController();
  final villeDestinataireController = TextEditingController();
  final adresseDestinataireController = TextEditingController();
  final typesMarchandiseController = TextEditingController();
  final descriptionController = TextEditingController();
  final poidsController = TextEditingController();
  final valeurEstimeeController = TextEditingController();
  final deviseController = TextEditingController();

  String _statutSelectionne = "EN_ATTENTE";
  final List<String> _statuts = ["EN_ATTENTE", "EN_COURS", "LIVRE", "ANNULE"];
  final List<String> _devises = ['USD', 'EUR', 'GBP', 'CAD', 'XAF'];

  @override
  void initState() {
    super.initState();
    final t = widget.transport;
    if (t != null) {
      nomController.text = t.nom;
      prenomController.text = t.prenom;
      numeroTelephoneController.text = t.numeroTelephone;
      emailController.text = t.email ?? '';
      paysExpediteurController.text = t.paysExpediteur;
      villeExpediteurController.text = t.villeExpediteur;
      adresseExpediteurController.text = t.adresseExpediteur;
      paysDestinataireController.text = t.paysDestinataire;
      villeDestinataireController.text = t.villeDestinataire;
      adresseDestinataireController.text = t.adresseDestinataire;
      typesMarchandiseController.text = t.typesMarchandise;
      descriptionController.text = t.description;
      poidsController.text = t.poids?.toString() ?? '';
      valeurEstimeeController.text = t.valeurEstimee.toString();
      deviseController.text = t.devise;
      _statutSelectionne = t.statut;
    }
  }

  @override
  void dispose() {
    nomController.dispose();
    prenomController.dispose();
    numeroTelephoneController.dispose();
    emailController.dispose();
    paysExpediteurController.dispose();
    villeExpediteurController.dispose();
    adresseExpediteurController.dispose();
    paysDestinataireController.dispose();
    villeDestinataireController.dispose();
    adresseDestinataireController.dispose();
    typesMarchandiseController.dispose();
    descriptionController.dispose();
    poidsController.dispose();
    valeurEstimeeController.dispose();
    deviseController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final transportData = Transport(
          id: widget.transport?.id,
          nom: nomController.text.trim(),
          prenom: prenomController.text.trim(),
          numeroTelephone: numeroTelephoneController.text.trim(),
          email: emailController.text.trim().isEmpty
              ? null
              : emailController.text.trim(),
          paysExpediteur: paysExpediteurController.text.trim(),
          villeExpediteur: villeExpediteurController.text.trim(),
          adresseExpediteur: adresseExpediteurController.text.trim(),
          paysDestinataire: paysDestinataireController.text.trim(),
          villeDestinataire: villeDestinataireController.text.trim(),
          adresseDestinataire: adresseDestinataireController.text.trim(),
          typesMarchandise: typesMarchandiseController.text.trim(),
          description: descriptionController.text.trim(),
          poids: poidsController.text.trim().isEmpty
              ? null
              : double.tryParse(poidsController.text.trim()),
          valeurEstimee: double.parse(valeurEstimeeController.text.trim()),
          devise: deviseController.text.trim().isEmpty
              ? 'USD'
              : deviseController.text.trim(),
          statut: _statutSelectionne,
        );

        final result = widget.transport == null
            ? await _service.createTransport(transportData)
            : await _service.updateTransport(transportData.id!, transportData);

        if (result != null) {
          Fluttertoast.showToast(
            msg: widget.transport == null
                ? '✅ Transport créé!'
                : '✅ Transport modifié!',
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.green,
          );
          Navigator.pop(context, true); // Pour rafraîchir la liste
        } else {
          Fluttertoast.showToast(
            msg:
                '❌ Erreur lors de la ${widget.transport == null ? "création" : "modification"}',
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
          );
        }
      } catch (e) {
        Fluttertoast.showToast(
          msg: '❌ Erreur: $e',
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transport == null
            ? 'Nouveau Transport'
            : 'Modifier Transport'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildSectionTitle('Expéditeur'),
              _buildTextField(nomController, 'Nom', true),
              _buildTextField(prenomController, 'Prénom', true),
              _buildTextField(numeroTelephoneController, 'N° Téléphone', true),
              _buildTextField(emailController, 'Email (optionnel)', false),
              _buildTextField(paysExpediteurController, 'Pays', true),
              _buildTextField(villeExpediteurController, 'Ville', true),
              _buildTextField(adresseExpediteurController, 'Adresse', true),
              _buildSectionTitle('Destinataire'),
              _buildTextField(paysDestinataireController, 'Pays', true),
              _buildTextField(villeDestinataireController, 'Ville', true),
              _buildTextField(adresseDestinataireController, 'Adresse', true),
              _buildSectionTitle('Marchandise'),
              _buildTextField(typesMarchandiseController, 'Type', true),
              _buildTextField(descriptionController, 'Description', true),
              _buildTextField(poidsController, 'Poids (kg)', false),
              _buildTextField(valeurEstimeeController, 'Valeur estimée', true,
                  keyboardType: TextInputType.number),
              _buildTextField(deviseController, 'Devise', true),
              DropdownButtonFormField<String>(
                value: _statutSelectionne,
                items: _statuts.map((s) {
                  return DropdownMenuItem(value: s, child: Text(s));
                }).toList(),
                decoration: InputDecoration(
                    labelText: 'Statut', border: OutlineInputBorder()),
                onChanged: (val) => setState(() => _statutSelectionne = val!),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.transport == null
                          ? 'Créer le transport'
                          : 'Modifier le transport'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, bool required,
      {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        keyboardType: keyboardType,
        validator: required
            ? (v) => v == null || v.isEmpty ? 'Obligatoire' : null
            : null,
      ),
    );
  }
}
