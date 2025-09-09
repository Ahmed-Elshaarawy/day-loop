import 'package:day_loop/services/firebase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/rendering.dart'
    show
    debugPaintSizeEnabled,
    debugPaintBaselinesEnabled,
    debugPaintPointersEnabled,
    debugRepaintRainbowEnabled;
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'services/language_service.dart';
import 'app_router.dart';

import 'repositories/task_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initializeFirebase();
  await dotenv.load(fileName: ".env");

  // 🔧 HARD-OFF all debug paints/overlays (sometimes toggled in Inspector)
  debugPaintSizeEnabled = false;
  debugPaintBaselinesEnabled = false;
  debugPaintPointersEnabled = false;
  debugRepaintRainbowEnabled = false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<LanguageService>(
          create: (_) => LanguageService(),
        ),
        // ⬅️ Important: use ChangeNotifierProvider so HistoryScreen rebuilds
        ChangeNotifierProvider<TaskRepository>(
          create: (_) => TaskRepository(),
        ),
      ],
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
      // Explicitly keep ALL debug/overlay stuff OFF:
      debugShowMaterialGrid: false,
      showPerformanceOverlay: false,
      checkerboardRasterCacheImages: false,
      checkerboardOffscreenLayers: false,
      showSemanticsDebugger: false,

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
