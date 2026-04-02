// lib/screens/ecommerce/checkout_screen.dart

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import '../../models/commande_ecommerce.dart';
import '../../providers/app_theme_provider.dart';
import '../../providers/panier_provider.dart';
import '../../services/auth_service.dart';
import '../../services/ecommerce_service.dart';
import '../../widgets/phone_input_field.dart';
import 'ecommerce_hub_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final String serviceType;
  final String serviceLabel;
  final Color accentColor;
  final double totalAmount;
  final String devise;

  const CheckoutScreen({
    Key? key,
    required this.serviceType,
    required this.serviceLabel,
    required this.accentColor,
    required this.totalAmount,
    required this.devise,
  }) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _paysController = TextEditingController();
  final _villeController = TextEditingController();
  final _adresseController = TextEditingController();
  final _notesController = TextEditingController();
  String? _phoneE164;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final meta = AuthService.userMetadata;
    final user = AuthService.currentUser;
    _nomController.text = meta?['nom']?.toString().trim() ?? '';
    _prenomController.text = meta?['prenom']?.toString().trim() ?? '';
    _emailController.text = user?.email?.trim() ?? '';
    _phoneE164 = user?.phone != null ? '+${user!.phone}' : null;
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _paysController.dispose();
    _villeController.dispose();
    _adresseController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_phoneE164 == null || _phoneE164!.isEmpty) {
      Fluttertoast.showToast(
          msg: 'Téléphone requis',
          backgroundColor: Colors.red);
      return;
    }
    setState(() => _loading = true);

    try {
      final service = EcommerceService(serviceType: widget.serviceType);
      final commande = CommandeEcommerce(
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        numeroTelephone: _phoneE164!,
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        paysLivraison: _paysController.text.trim(),
        villeLivraison: _villeController.text.trim(),
        adresseLivraison: _adresseController.text.trim(),
        serviceType: widget.serviceType.toUpperCase(),
        prixTotal: widget.totalAmount,
        devise: widget.devise,
        notesSpeciales: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      final result = await service.validerCommande(commande);
      if (result != null) {
        // Vider le panier côté provider
        if (mounted) {
          await context.read<PanierProvider>().vider();
        }
        Fluttertoast.showToast(
            msg: '✅ Commande envoyée ! Référence #${result.id}',
            backgroundColor: Colors.green,
            toastLength: Toast.LENGTH_LONG);
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => EcommerceHubScreen(
                serviceType: widget.serviceType,
                serviceLabel: widget.serviceLabel,
                accentColor: widget.accentColor,
              ),
            ),
            (route) => route.isFirst,
          );
        }
      } else {
        Fluttertoast.showToast(
            msg: '❌ Erreur lors de la validation',
            backgroundColor: Colors.red);
      }
    } catch (e) {
      Fluttertoast.showToast(
          msg: '❌ Erreur : $e', backgroundColor: Colors.red);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
        title: const Text('Finaliser la commande',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(children: [
                // ── Récap montant ───────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                      color: widget.accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: widget.accentColor
                              .withValues(alpha: 0.35))),
                  child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                    Text('Total à régler',
                        style: TextStyle(
                            color: t.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                    Text(
                      '${widget.totalAmount.toStringAsFixed(2)} ${widget.devise}',
                      style: TextStyle(
                          color: widget.accentColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 20),
                    ),
                  ]),
                ),

                // ── Infos contact ───────────────────────────────────────
                _section('Informations de livraison', Icons.person_outline,
                    widget.accentColor, t, [
                  Row(children: [
                    Expanded(child: _field(_nomController, 'Nom', required: true, t: t)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _field(_prenomController, 'Prénom',
                            required: true, t: t)),
                  ]),
                  const SizedBox(height: 12),
                  PhoneInputField(
                    label: 'Téléphone',
                    initialCountryCode: 'SN',
                    initialValue: _phoneE164,
                    onChanged: (e164) =>
                        setState(() => _phoneE164 = e164),
                  ),
                  const SizedBox(height: 12),
                  _field(_emailController, 'Email (optionnel)',
                      required: false, t: t,
                      keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 12),
                  _field(_paysController, 'Pays', required: true, t: t),
                  const SizedBox(height: 12),
                  _field(_villeController, 'Ville', required: true, t: t),
                  const SizedBox(height: 12),
                  _field(_adresseController, 'Adresse complète',
                      required: true, t: t, maxLines: 2, validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Requis';
                    if (v.trim().length < 5) return 'Trop courte';
                    return null;
                  }),
                  const SizedBox(height: 12),
                  _field(_notesController, 'Notes (optionnel)',
                      required: false, t: t, maxLines: 2),
                ]),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle_outline),
                    label: const Text('Confirmer la commande',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: widget.accentColor,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0),
                    onPressed: _loading ? null : _submit,
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(String title, IconData icon, Color color,
          AppThemeProvider t, List<Widget> children) =>
      Container(
        padding: const EdgeInsets.all(18),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
            color: t.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: t.border)),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Row(children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(title,
                style: TextStyle(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14)),
          ]),
          const SizedBox(height: 14),
          ...children,
        ]),
      );

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    required AppThemeProvider t,
  }) =>
      TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: TextStyle(color: t.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: t.textMuted, fontSize: 13),
          filled: true,
          fillColor: t.bg,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: t.border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: t.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: widget.accentColor, width: 1.5)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
        validator: validator ??
            (required
                ? (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requis' : null
                : null),
      );
}
