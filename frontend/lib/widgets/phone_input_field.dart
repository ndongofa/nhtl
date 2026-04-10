import 'package:flutter/material.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';

/// Widget réutilisable de saisie de numéro de téléphone.
/// Retourne toujours un numéro au format E.164 (ex: +221783042838)
/// via [onChanged], quelle que soit la saisie de l'utilisateur.
///
/// Corrections automatiques appliquées en temps réel :
/// - Suppression des espaces.
/// - Suppression du zéro initial du numéro local.
/// - Détection automatique du pays à partir de l'indicatif saisi
///   (formats +XXX… ou 00XXX…).
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
class PhoneInputField extends StatefulWidget {
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
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  late TextEditingController _controller;
  late String _countryCode;

  /// Incrémenté pour forcer la reconstruction d'[IntlPhoneField]
  /// lors d'un changement de pays automatique.
  int _fieldKey = 0;

  /// Compteur de génération pour éviter les conflits entre microtasks
  /// successifs lors d'une détection internationale rapide.
  int _generation = 0;

  /// Garde contre la récursion lors de la mise à jour du contrôleur.
  bool _isSanitizing = false;

  /// Liste des pays triée du plus long au plus court indicatif,
  /// calculée une seule fois.
  static final List<Country> _sortedCountries = List<Country>.of(countries)
    ..sort((a, b) => b.dialCode.length.compareTo(a.dialCode.length));

  // -----------------------------------------------------------------------
  // Lifecycle
  // -----------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _countryCode = widget.initialCountryCode;
    _controller = TextEditingController(text: widget.initialValue ?? '');
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  // -----------------------------------------------------------------------
  // Helpers
  // -----------------------------------------------------------------------

  /// Supprime espaces et zéro(s) initial(aux) d'un numéro local.
  /// Retourne le texte sanitisé et l'offset de curseur ajusté.
  static ({String text, int cursorOffset}) _sanitizeLocal(
      String text, int cursorPos) {
    // Supprimer les espaces et suivre combien sont supprimés avant le curseur
    final buf = StringBuffer();
    int newCursor = cursorPos;
    for (int i = 0; i < text.length; i++) {
      if (text[i] == ' ') {
        if (i < cursorPos) newCursor--;
      } else {
        buf.write(text[i]);
      }
    }
    final noSpaces = buf.toString();

    // Supprimer les zéros initiaux
    final stripped = noSpaces.replaceFirst(RegExp(r'^0+'), '');
    final zerosRemoved = noSpaces.length - stripped.length;
    newCursor = (newCursor - zerosRemoved).clamp(0, stripped.length);

    return (text: stripped, cursorOffset: newCursor);
  }

  /// Essaie de détecter le pays et d'en extraire le numéro local
  /// lorsque la saisie commence par '+' ou '00'.
  ///
  /// Retourne null si le format n'est pas reconnu.
  static ({String countryCode, String localNumber})? _detectInternational(
      String text) {
    String normalized = text.replaceAll(' ', '');
    if (normalized.startsWith('00')) {
      normalized = '+${normalized.substring(2)}';
    }
    if (!normalized.startsWith('+')) return null;

    final digitsAfterPlus = normalized.substring(1);
    if (digitsAfterPlus.isEmpty) return null;

    for (final country in _sortedCountries) {
      if (digitsAfterPlus.startsWith(country.dialCode)) {
        final local = digitsAfterPlus.substring(country.dialCode.length);
        // Supprimer le zéro initial du numéro local si présent
        final cleanLocal = local.replaceFirst(RegExp(r'^0+'), '');
        return (countryCode: country.code, localNumber: cleanLocal);
      }
    }
    return null;
  }

  // -----------------------------------------------------------------------
  // Listener
  // -----------------------------------------------------------------------

  void _onTextChanged() {
    if (_isSanitizing) return;

    final text = _controller.text;
    final cursorPos = _controller.selection.isValid
        ? _controller.selection.baseOffset
        : text.length;

    // --- Cas 1 : format international (+XXX ou 00XXX) ---
    if (text.startsWith('+') || text.startsWith('00')) {
      final detected = _detectInternational(text);
      if (detected != null) {
        // Capturer la génération courante pour éviter les conflits
        final gen = ++_generation;
        // Planifier le changement après que le listener soit retourné
        Future.microtask(() {
          if (!mounted || gen != _generation) return;
          final newController =
              TextEditingController(text: detected.localNumber);
          _controller.removeListener(_onTextChanged);
          _controller.dispose();
          _controller = newController;
          _controller.addListener(_onTextChanged);
          setState(() {
            _countryCode = detected.countryCode;
            _fieldKey++;
          });
        });
        return;
      }
    }

    // --- Cas 2 : numéro local — supprimer espaces et zéro initial ---
    final result = _sanitizeLocal(text, cursorPos);
    if (result.text != text) {
      _isSanitizing = true;
      _controller.value = TextEditingValue(
        text: result.text,
        selection: TextSelection.collapsed(offset: result.cursorOffset),
      );
      _isSanitizing = false;
    }
  }

  // -----------------------------------------------------------------------
  // Build
  // -----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return IntlPhoneField(
      key: ValueKey('$_fieldKey-$_countryCode'),
      controller: _controller,
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
        counterText: '',
      ),
      initialCountryCode: _countryCode,
      languageCode: 'fr',
      invalidNumberMessage: 'Numéro de téléphone invalide',
      disableLengthCheck: false,
      onChanged: (PhoneNumber phone) {
        try {
          final e164 = phone.completeNumber;
          widget.onChanged(e164.isNotEmpty ? e164 : null);
        } catch (_) {
          widget.onChanged(null);
        }
      },
      onCountryChanged: (_) {
        widget.onChanged(null);
      },
      validator: widget.required
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
