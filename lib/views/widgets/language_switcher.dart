import 'package:flutter/material.dart';
import '../../main.dart'; // Import MyApp for setLocale

class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return DropdownButton<Locale>(
      value: locale,
      icon: const Icon(Icons.language),
      onChanged: (Locale? newLocale) {
        if (newLocale != null && newLocale != locale) {
          MyApp.setLocale(context, newLocale);
        }
      },
      items: const [
        DropdownMenuItem(
          value: Locale('en'),
          child: Text('English'),
        ),
        DropdownMenuItem(
          value: Locale('ar'),
          child: Text('العربية'),
        ),
        DropdownMenuItem(
          value: Locale('so'),
          child: Text('Somali'),
        ),
      ],
    );
  }
}
