// lib/widgets/language_selector.dart
import 'package:flutter/material.dart';

class LanguageSelector extends StatelessWidget {
  final Locale currentLocale;
  final Function(Locale) onLocaleChange;

  const LanguageSelector({
    Key? key,
    required this.currentLocale,
    required this.onLocaleChange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: currentLocale.languageCode,
      items: const [
        DropdownMenuItem(
          value: 'en',
          child: Text('English'),
        ),
        DropdownMenuItem(
          value: 'es',
          child: Text('Español'),
        ),
        // Add more languages as needed
      ],
      onChanged: (String? languageCode) {
        if (languageCode != null) {
          onLocaleChange(Locale(languageCode));
        }
      },
    );
  }
}