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
  final paysDestinataiireController = TextEditingController();
  final villeDestinataiireController = TextEditingController();
  final adresseDestinataiireController = TextEditingController();
  final typesMarchandiseController = TextEditingController();
  final descriptionController = TextEditingController();
  final poidsController = TextEditingController();
  final valeurEstimeeController = TextEditingController();

  // Champs obligatoires ajoutés :
  final typeTransportController = TextEditingController();
  final pointDepartController = TextEditingController();
  final pointArriveeController = TextEditingController();

  @override
  void dispose() {
    nomController.dispose();
    prenomController.dispose();
    numeroTelephoneController.dispose();
    paysExpediteurController.dispose();
    villeExpediteurController.dispose();
    adresseExpediteurController.dispose();
    paysDestinataiireController.dispose();
    villeDestinataiireController.dispose();
    adresseDestinataiireController.dispose();
    typesMarchandiseController.dispose();
    descriptionController.dispose();
    poidsController.dispose();
    valeurEstimeeController.dispose();
    // Dispose des nouveaux contrôleurs
    typeTransportController.dispose();
    pointDepartController.dispose();
    pointArriveeController.dispose();
    super.dispose();
  }

  // Validators comme avant...

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Obligatoire';
    }
    final phoneRegex = RegExp(r'^[+]?[0-9]{9,15}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Format invalide (ex: +237123456789)';
    }
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
              _buildSectionTitle('Informations Personnelles'),
              _buildTextField(nomController, 'Nom',
                  validator: (v) => v?.isEmpty ?? true ? 'Obligatoire' : null),
              _buildTextField(prenomController, 'Prénom',
                  validator: (v) => v?.isEmpty ?? true ? 'Obligatoire' : null),
              _buildTextField(
                numeroTelephoneController,
                'Numéro Téléphone',
                validator: _validatePhoneNumber,
                hintText: '+237123456789',
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('Expéditeur'),
              _buildTextField(paysExpediteurController, 'Pays',
                  validator: (v) => v?.isEmpty ?? true ? 'Obligatoire' : null),
              _buildTextField(villeExpediteurController, 'Ville',
                  validator: (v) => v?.isEmpty ?? true ? 'Obligatoire' : null),
              _buildTextField(
                adresseExpediteurController,
                'Adresse',
                validator: _validateAddress,
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('Destinataire'),
              _buildTextField(paysDestinataiireController, 'Pays',
                  validator: (v) => v?.isEmpty ?? true ? 'Obligatoire' : null),
              _buildTextField(villeDestinataiireController, 'Ville',
                  validator: (v) => v?.isEmpty ?? true ? 'Obligatoire' : null),
              _buildTextField(
                adresseDestinataiireController,
                'Adresse',
                validator: _validateAddress,
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('Marchandise'),
              _buildTextField(typesMarchandiseController, 'Type',
                  validator: (v) => v?.isEmpty ?? true ? 'Obligatoire' : null),
              _buildTextField(
                descriptionController,
                'Description',
                validator: _validateDescription,
                maxLines: 3,
                hintText: 'Minimum 10 caractères',
              ),
              _buildTextField(
                poidsController,
                'Poids (kg)',
                keyboardType: TextInputType.number,
                validator: (v) => v?.isEmpty ?? true ? 'Obligatoire' : null,
              ),
              _buildTextField(
                valeurEstimeeController,
                'Valeur estimée',
                keyboardType: TextInputType.number,
                validator: (v) => v?.isEmpty ?? true ? 'Obligatoire' : null,
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('Informations Transport'),
              _buildTextField(typeTransportController, 'Type de transport',
                  validator: (v) => v?.isEmpty ?? true ? 'Obligatoire' : null),
              _buildTextField(pointDepartController, 'Point de départ',
                  validator: (v) => v?.isEmpty ?? true ? 'Obligatoire' : null),
              _buildTextField(pointArriveeController, 'Point d\'arrivée',
                  validator: (v) => v?.isEmpty ?? true ? 'Obligatoire' : null),
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
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? hintText,
    String? Function(String?)? validator,
  }) {
    return Padding(
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
          paysDestinataire: paysDestinataiireController.text.trim(),
          villeDestinataire: villeDestinataiireController.text.trim(),
          adresseDestinataire: adresseDestinataiireController.text.trim(),
          typesMarchandise: typesMarchandiseController.text.trim(),
          description: descriptionController.text.trim(),
          poids: double.tryParse(poidsController.text) ?? 0.0,
          valeurEstimee: double.tryParse(valeurEstimeeController.text) ?? 0.0,
          typeTransport: typeTransportController.text.trim(),
          pointDepart: pointDepartController.text.trim(),
          pointArrivee: pointArriveeController.text.trim(),
          // statut volontairement non modifiable ici : par défaut à EN_ATTENTE
        );

        final result = await _service.createTransport(transport);

        if (result != null) {
          Fluttertoast.showToast(
            msg: '✅ Transport créé!',
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
}
