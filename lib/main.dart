import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'language_service.dart';

// GoRouter configuration (provides AppRouter.router)
import 'app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
