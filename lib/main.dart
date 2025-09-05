import 'package:day_loop/services/firebase_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


import 'l10n/app_localizations.dart';
import 'services/language_service.dart';

// GoRouter configuration (provides AppRouter.router)
import 'app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initializeFirebase();
  runApp(
    ChangeNotifierProvider<LanguageService>(
      create: (_) => LanguageService(),
      child: const DayLoopApp(),
    ),
  );
}

class DayLoopApp extends StatelessWidget {
  const DayLoopApp({super.key});

  @override
  Widget build(BuildContext context) {
    final languageService = context.watch<LanguageService>();
    final locale = _getLocaleForLanguage(languageService.currentLanguage);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Day Loop',
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: AppRouter.router,
    );
  }

  Locale _getLocaleForLanguage(String language) {
    switch (language.toLowerCase()) {
      case 'arabic':
        return const Locale('ar');
      case 'english':
      default:
        return const Locale('en');
    }
  }
}
