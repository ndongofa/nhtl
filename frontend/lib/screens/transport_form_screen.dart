import 'package:flutter/material.dart';
import '../models/transport.dart';
import '../services/transport_service.dart';
import 'package:fluttertoast/fluttertoast.dart';

class TransportFormScreen extends StatefulWidget {
  const TransportFormScreen({Key? key}) : super(key: key);

  @override
  State<TransportFormScreen> createState() => _TransportFormScreenState();
}

class _TransportFormScreenState extends State<TransportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = TransportService();
  bool _isLoading = false;

  final nomController = TextEditingController();
  final prenomController = TextEditingController();
  final numeroTelephoneController = TextEditingController();
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
  final typeTransportController = TextEditingController();
  final pointDepartController = TextEditingController();
  final pointArriveeController = TextEditingController();

  String statutValue = "EN_ATTENTE";

  @override
  void dispose() {
    nomController.dispose();
    prenomController.dispose();
    numeroTelephoneController.dispose();
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
    typeTransportController.dispose();
    pointDepartController.dispose();
    pointArriveeController.dispose();
    super.dispose();
  }

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) return 'Obligatoire';
    final phoneRegex = RegExp(r'^[+]?[0-9]{9,15}$');
    if (!phoneRegex.hasMatch(value)) return 'Format invalide';
    return null;
  }

  String? _validateDescription(String? value) {
    if (value == null || value.isEmpty) return 'Obligatoire';
    if (value.length < 10) return 'Minimum 10 caractères';
    if (value.length > 1000) return 'Maximum 1000 caractères';
    return null;
  }

  String? _validateAddress(String? value) {
    if (value == null || value.isEmpty) return 'Obligatoire';
    if (value.length < 10) return 'Minimum 10 caractères';
    return null;
  }

  String? _validateDouble(String? value) {
    if (value == null || value.isEmpty) return 'Obligatoire';
    final v = double.tryParse(value);
    if (v == null) return 'Doit être un nombre';
    if (v < 0) return 'Doit être positif';
    return null;
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final transport = Transport(
          nom: nomController.text.trim(),
          prenom: prenomController.text.trim(),
          numeroTelephone: numeroTelephoneController.text.trim(),
          paysExpediteur: paysExpediteurController.text.trim(),
          villeExpediteur: villeExpediteurController.text.trim(),
          adresseExpediteur: adresseExpediteurController.text.trim(),
          paysDestinataire: paysDestinataireController.text.trim(),
          villeDestinataire: villeDestinataireController.text.trim(),
          adresseDestinataire: adresseDestinataireController.text.trim(),
          typesMarchandise: typesMarchandiseController.text.trim(),
          description: descriptionController.text.trim(),
          poids: double.parse(poidsController.text.trim()),
          valeurEstimee: double.parse(valeurEstimeeController.text.trim()),
          typeTransport: typeTransportController.text.trim(),
          pointDepart: pointDepartController.text.trim(),
          pointArrivee: pointArriveeController.text.trim(),
          statut: statutValue,
        );
        print('JSON envoyé : ${transport.toJson()}');
        final result = await _service.createTransport(transport);

        if (result != null) {
          Fluttertoast.showToast(
            msg: '✅ Transport créé !',
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.green,
          );
          Navigator.pop(context);
        } else {
          Fluttertoast.showToast(
            msg: '❌ Erreur lors de la création',
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
      appBar: AppBar(title: const Text('Nouveau Transport')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildSectionTitle('Infos Personnelles'),
              _buildTextField(nomController, 'Nom'),
              _buildTextField(prenomController, 'Prénom'),
              _buildTextField(numeroTelephoneController, 'Numéro Téléphone',
                  validator: _validatePhoneNumber, hintText: '+221771234567'),
              _buildSectionTitle('Expéditeur'),
              _buildTextField(paysExpediteurController, 'Pays'),
              _buildTextField(villeExpediteurController, 'Ville'),
              _buildTextField(adresseExpediteurController, 'Adresse',
                  validator: _validateAddress, maxLines: 2),
              _buildSectionTitle('Destinataire'),
              _buildTextField(paysDestinataireController, 'Pays'),
              _buildTextField(villeDestinataireController, 'Ville'),
              _buildTextField(adresseDestinataireController, 'Adresse',
                  validator: _validateAddress, maxLines: 2),
              _buildSectionTitle('Marchandise'),
              _buildTextField(typesMarchandiseController, 'Type'),
              _buildTextField(descriptionController, 'Description',
                  validator: _validateDescription,
                  maxLines: 3,
                  hintText: 'Au moins 10 caractères'),
              _buildTextField(poidsController, 'Poids (kg)',
                  keyboardType: TextInputType.number,
                  validator: _validateDouble),
              _buildTextField(valeurEstimeeController, 'Valeur estimée',
                  keyboardType: TextInputType.number,
                  validator: _validateDouble),
              _buildSectionTitle('Transport'),
              _buildTextField(typeTransportController, 'Type de transport'),
              _buildTextField(pointDepartController, 'Point de départ'),
              _buildTextField(pointArriveeController, 'Point d\'arrivée'),
              _buildSectionTitle('Statut'),
              DropdownButtonFormField<String>(
                value: statutValue,
                decoration: InputDecoration(
                  labelText: "Statut",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      statutValue = newValue;
                    });
                  }
                },
                items: const [
                  DropdownMenuItem(
                      value: "EN_ATTENTE", child: Text("En attente")),
                  DropdownMenuItem(value: "EN_COURS", child: Text("En cours")),
                  DropdownMenuItem(value: "TERMINE", child: Text("Terminé")),
                ],
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
                      : const Text('Envoyer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? hintText,
    String? Function(String?)? validator,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            hintText: hintText,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator:
              validator ?? (v) => v?.isEmpty ?? true ? 'Obligatoire' : null,
        ),
      );
}
