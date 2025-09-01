import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_router.dart';
import 'l10n/app_localizations.dart';
import 'language_service.dart';

void main() => runApp(
  ChangeNotifierProvider(
    create: (context) => LanguageService(),
    child: const DayLoopApp(),
  ),
);

class DayLoopApp extends StatelessWidget {
  const DayLoopApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the current language from the service
    final languageService = Provider.of<LanguageService>(context);

    // Map the language string to a Locale
    final String currentLanguage = languageService.currentLanguage;
    final Locale? selectedLocale = _getLocaleForLanguage(currentLanguage);

    return MaterialApp.router(
      routerConfig: router,
      title: 'Day Loop',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      locale: selectedLocale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }

  Locale? _getLocaleForLanguage(String language) {
    switch (language.toLowerCase()) {
      case 'arabic':
        return const Locale('ar');
      case 'english':
        return const Locale('en');
      default:
        return const Locale('en');
    }
  }
}