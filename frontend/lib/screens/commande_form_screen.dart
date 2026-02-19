import 'package:flutter/material.dart';
import '../models/commande.dart';
import '../services/commande_service.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CommandeFormScreen extends StatefulWidget {
  const CommandeFormScreen({Key? key}) : super(key: key);

  @override
  State<CommandeFormScreen> createState() => _CommandeFormScreenState();
}

class _CommandeFormScreenState extends State<CommandeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = CommandeService();
  bool _isLoading = false;

  final nomController = TextEditingController();
  final prenomController = TextEditingController();
  final numeroTelephoneController = TextEditingController();
  final emailController = TextEditingController();
  final paysLivraisonController = TextEditingController();
  final villeLivraisonController = TextEditingController();
  final adresseLivraisonController = TextEditingController();
  final lienProduitController = TextEditingController();
  final descriptionCommandeController = TextEditingController();
  final quantiteController = TextEditingController();
  final prixUnitaireController = TextEditingController();
  final prixTotalController = TextEditingController();
  final notesSpecialesController = TextEditingController();

  String _platformeSelectionnee = 'AMAZON';
  String _deviseSelectionnee = 'USD';

  final List<String> _plateformes = [
    'AMAZON',
    'TEMU',
    'SHEIN',
    'ALIEXPRESS',
    'EBAY',
    'ETSY',
    'AUTRE'
  ];

  final List<String> _devises = ['USD', 'EUR', 'GBP', 'CAD', 'XAF'];

  @override
  void dispose() {
    nomController.dispose();
    prenomController.dispose();
    numeroTelephoneController.dispose();
    emailController.dispose();
    paysLivraisonController.dispose();
    villeLivraisonController.dispose();
    adresseLivraisonController.dispose();
    lienProduitController.dispose();
    descriptionCommandeController.dispose();
    quantiteController.dispose();
    prixUnitaireController.dispose();
    prixTotalController.dispose();
    notesSpecialesController.dispose();
    super.dispose();
  }

  // ✅ Validateur pour le téléphone
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

  // ✅ Validateur pour l'email
  String? _validateEmail(String? value) {
    if (value != null && value.isNotEmpty) {
      final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
      if (!emailRegex.hasMatch(value)) {
        return 'Email invalide';
      }
    }
    return null;
  }

  // ✅ Validateur pour l'adresse (10-500 caractères)
  String? _validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Obligatoire';
    }
    if (value.length < 10) {
      return 'Minimum 10 caractères';
    }
    if (value.length > 500) {
      return 'Maximum 500 caractères';
    }
    return null;
  }

  // ✅ Validateur pour la description (10-1000 caractères)
  String? _validateDescription(String? value) {
    if (value == null || value.isEmpty) {
      return 'Obligatoire';
    }
    if (value.length < 10) {
      return 'Minimum 10 caractères';
    }
    if (value.length > 1000) {
      return 'Maximum 1000 caractères';
    }
    return null;
  }

  // ✅ Validateur pour la quantité (minimum 1)
  String? _validateQuantite(String? value) {
    if (value == null || value.isEmpty) {
      return 'Obligatoire';
    }
    final quantite = int.tryParse(value);
    if (quantite == null || quantite < 1) {
      return 'Minimum 1';
    }
    return null;
  }

  // ✅ Validateur pour les prix (supérieur à 0)
  String? _validatePrice(String? value) {
    if (value == null || value.isEmpty) {
      return 'Obligatoire';
    }
    final price = double.tryParse(value);
    if (price == null || price <= 0) {
      return 'Doit être supérieur à 0';
    }
    return null;
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final commande = Commande(
          nom: nomController.text.trim(),
          prenom: prenomController.text.trim(),
          numeroTelephone: numeroTelephoneController.text.trim(),
          email: emailController.text.trim().isEmpty
              ? null
              : emailController.text.trim(),
          paysLivraison: paysLivraisonController.text.trim(),
          villeLivraison: villeLivraisonController.text.trim(),
          adresseLivraison: adresseLivraisonController.text.trim(),
          plateforme: _platformeSelectionnee,
          lienProduit: lienProduitController.text.trim(),
          descriptionCommande: descriptionCommandeController.text.trim(),
          quantite: int.parse(quantiteController.text),
          prixUnitaire: double.parse(prixUnitaireController.text),
          prixTotal: double.parse(prixTotalController.text),
          devise: _deviseSelectionnee,
          notesSpeciales: notesSpecialesController.text.trim().isEmpty
              ? null
              : notesSpecialesController.text.trim(),
        );

        final result = await _service.createCommande(commande);

        if (result != null) {
          Fluttertoast.showToast(
            msg: '✅ Commande créée!',
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
      appBar: AppBar(title: const Text('Nouvelle Commande')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildSectionTitle('Informations Personnelles'),
              _buildTextField(
                nomController,
                'Nom',
                validator: (v) => v?.isEmpty ?? true ? 'Obligatoire' : null,
              ),
              _buildTextField(
                prenomController,
                'Prénom',
                validator: (v) => v?.isEmpty ?? true ? 'Obligatoire' : null,
              ),
              _buildTextField(
                numeroTelephoneController,
                'Numéro Téléphone',
                validator: _validatePhoneNumber,
                hintText: '+237123456789',
              ),
              _buildTextField(
                emailController,
                'Email (optionnel)',
                validator: _validateEmail,
                hintText: 'example@email.com',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('Livraison'),
              _buildTextField(
                paysLivraisonController,
                'Pays',
                validator: (v) => v?.isEmpty ?? true ? 'Obligatoire' : null,
              ),
              _buildTextField(
                villeLivraisonController,
                'Ville',
                validator: (v) => v?.isEmpty ?? true ? 'Obligatoire' : null,
              ),
              _buildTextField(
                adresseLivraisonController,
                'Adresse',
                validator: _validateAddress,
                maxLines: 2,
                hintText: 'Minimum 10 caractères',
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('Produit'),
              _buildDropdown(
                'Plateforme',
                _platformeSelectionnee,
                _plateformes,
                (value) {
                  setState(() => _platformeSelectionnee = value!);
                },
              ),
              _buildTextField(
                lienProduitController,
                'Lien du produit',
                validator: (v) => v?.isEmpty ?? true ? 'Obligatoire' : null,
                hintText: 'https://...',
              ),
              _buildTextField(
                descriptionCommandeController,
                'Description',
                validator: _validateDescription,
                maxLines: 3,
                hintText: 'Minimum 10 caractères',
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('Détails Financiers'),
              _buildTextField(
                quantiteController,
                'Quantité',
                validator: _validateQuantite,
                keyboardType: TextInputType.number,
              ),
              _buildTextField(
                prixUnitaireController,
                'Prix unitaire',
                validator: _validatePrice,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              _buildTextField(
                prixTotalController,
                'Prix total',
                validator: _validatePrice,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              _buildDropdown(
                'Devise',
                _deviseSelectionnee,
                _devises,
                (value) {
                  setState(() => _deviseSelectionnee = value!);
                },
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('Notes'),
              _buildTextField(
                notesSpecialesController,
                'Notes spéciales (optionnel)',
                maxLines: 2,
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
                      : const Text('Créer la commande'),
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

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
