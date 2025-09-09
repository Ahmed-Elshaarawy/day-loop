import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:day_loop/services/language_service.dart';

import '../l10n/app_localizations.dart';

class LanguageSelectionDialog extends StatelessWidget {
  const LanguageSelectionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageService = context.read<LanguageService>();
    final currentLanguage = languageService.currentLanguage;
    final languages = [
      {'name': l10n.languageEnglish, 'code': 'English'},
      {'name': l10n.languageArabic, 'code': 'Arabic'},
    ];

    return Dialog(
      backgroundColor: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.selectLanguage,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...languages.map((lang) {
              final isSelected = currentLanguage == lang['code'];
              return ListTile(
                onTap: () {
                  languageService.setLanguage(lang['code']!);
                  Navigator.of(context).pop();
                },
                leading: Icon(
                  Icons.language,
                  color: isSelected ? const Color(0xFFFF9800) : const Color(0xFF888888),
                ),
                title: Text(
                  lang['name']!,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFFFF9800) : Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Color(0xFFFF9800))
                    : null,
              );
            }).toList(),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.cancelButton, style: const TextStyle(color: Color(0xFFFF9800))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}