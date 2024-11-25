import 'package:flutter/material.dart';

class LanguageSelector extends StatelessWidget {
  final Locale currentLocale;
  final Function(Locale) onLocaleChange;

  const LanguageSelector({
    super.key,
    required this.currentLocale,
    required this.onLocaleChange,
  });

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
      ],
      onChanged: (String? languageCode) {
        if (languageCode != null) {
          onLocaleChange(Locale(languageCode));
        }
      },
    );
  }
}