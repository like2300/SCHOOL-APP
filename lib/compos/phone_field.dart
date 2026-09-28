import 'package:flutter/material.dart';

/// Indicatifs pays pour la saisie du numéro (récupère le code du pays).
class CountryCode {
  final String iso;
  final String name;
  final String dial;
  const CountryCode(this.iso, this.name, this.dial);
}

const List<CountryCode> kCountryCodes = [
  CountryCode('CG', 'Congo Brazza', '+242'),
  CountryCode('CD', 'Congo Kinshasa', '+243'),
  CountryCode('CM', 'Cameroun', '+237'),
  CountryCode('GA', 'Gabon', '+241'),
  CountryCode('TD', 'Tchad', '+235'),
  CountryCode('CF', 'Centrafrique', '+236'),
  CountryCode('GQ', 'Guinée équat.', '+240'),
  CountryCode('CI', "Côte d'Ivoire", '+225'),
  CountryCode('SN', 'Sénégal', '+221'),
  CountryCode('ML', 'Mali', '+223'),
  CountryCode('BF', 'Burkina Faso', '+226'),
  CountryCode('BJ', 'Bénin', '+229'),
  CountryCode('TG', 'Togo', '+228'),
  CountryCode('NE', 'Niger', '+227'),
  CountryCode('FR', 'France', '+33'),
  CountryCode('US', 'USA / Canada', '+1'),
];

/// Champ téléphone : sélecteur de pays (indicatif) + numéro national.
/// Le parent garde l'indicatif via [onDialCodeChanged] et combine :
/// `full = dial + chiffres(national)` — le 242 n'a plus besoin d'être tapé.
class PhoneField extends StatefulWidget {
  final TextEditingController controller;
  final String initialDialCode;
  final ValueChanged<String> onDialCodeChanged;
  final String? Function(String?)? validator;
  final String labelText;
  final String hintText;

  const PhoneField({
    super.key,
    required this.controller,
    this.initialDialCode = '+242',
    required this.onDialCodeChanged,
    this.validator,
    this.labelText = 'Numéro de téléphone',
    this.hintText = 'Ex : 06 123 45 67',
  });

  @override
  State<PhoneField> createState() => _PhoneFieldState();
}

class _PhoneFieldState extends State<PhoneField> {
  late String _dial;

  @override
  void initState() {
    super.initState();
    _dial = widget.initialDialCode;
  }

  static String digits(String s) => s.replaceAll(RegExp(r'\D'), '');

  /// Numéro complet : indicatif + chiffres du national (0 initial conservé).
  String get fullNumber => '$_dial${digits(widget.controller.text)}';

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 132,
          child: DropdownButtonFormField<String>(
            value: kCountryCodes.any((c) => c.dial == _dial) ? _dial : '+242',
            decoration: const InputDecoration(
              labelText: 'Pays',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            ),
            items: kCountryCodes
                .map((c) => DropdownMenuItem(
                      value: c.dial,
                      child: Text('${c.iso} ${c.dial}',
                          style: const TextStyle(fontSize: 14)),
                    ))
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() => _dial = v);
              widget.onDialCodeChanged(v);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: widget.controller,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: widget.labelText,
              hintText: widget.hintText,
              prefixIcon: const Icon(Icons.phone_outlined),
              border: const OutlineInputBorder(),
            ),
            validator: widget.validator,
          ),
        ),
      ],
    );
  }
}
