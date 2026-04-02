import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';

/// Widget réutilisable de saisie de numéro de téléphone.
/// Retourne toujours un numéro au format E.164 (ex: +221783042838)
/// via [onChanged], quelle que soit la saisie de l'utilisateur.
///
/// Utilisation :
/// ```dart
/// String? _phoneE164;
///
/// PhoneInputField(
///   initialCountryCode: 'SN',
///   onChanged: (e164) => _phoneE164 = e164,
/// )
/// ```
class PhoneInputField extends StatelessWidget {
  /// Callback appelé à chaque changement — reçoit le numéro E.164 complet
  /// (ex: +221783042838) ou null si le numéro est invalide.
  final void Function(String? e164) onChanged;

  /// Code pays ISO 3166-1 alpha-2 par défaut (ex: 'SN' pour Sénégal)
  final String initialCountryCode;

  /// Valeur initiale du numéro (sans indicatif, juste la partie locale)
  final String? initialValue;

  /// Label du champ
  final String label;

  /// Si true, le champ est obligatoire
  final bool required;

  const PhoneInputField({
    super.key,
    required this.onChanged,
    this.initialCountryCode = 'SN',
    this.initialValue,
    this.label = 'Téléphone',
    this.required = true,
  });

  @override
  Widget build(BuildContext context) {
    return IntlPhoneField(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        counterText: '',
      ),
      initialCountryCode: initialCountryCode,
      initialValue: initialValue,
      languageCode: 'fr',
      invalidNumberMessage: 'Numéro de téléphone invalide',
      disableLengthCheck: false,
      onChanged: (PhoneNumber phone) {
        try {
          // completeNumber retourne le numéro E.164 complet avec "+"
          final e164 = phone.completeNumber;
          onChanged(e164.isNotEmpty ? e164 : null);
        } catch (_) {
          onChanged(null);
        }
      },
      onCountryChanged: (_) {
        // Reset à null lors du changement de pays
        onChanged(null);
      },
      validator: required
          ? (phone) {
              if (phone == null || phone.number.trim().isEmpty) {
                return 'Téléphone requis';
              }
              return null;
            }
          : null,
    );
  }
}
