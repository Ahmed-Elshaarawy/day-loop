import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../ai/day_loop_service.dart';
import '../controllers/journey_controller.dart';
import '../services/language_service.dart';

import '../controllers/speech_controller.dart';
import '../l10n/app_localizations.dart';
import '../widgets/record_button.dart';
import '../widgets/journey_card.dart';
import '../repositories/task_repository.dart';
import '../view_models/home_view_model.dart';
// Note: no JourneyState import needed; JourneyCard reads JourneyController internally.

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _timeOfDayLabel(AppLocalizations l10n) {
    final h = DateTime.now().hour;
    return (h < 12) ? l10n.morning : l10n.evening;
    // If you want a 3-part label (morning/afternoon/evening), adjust here.
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final langSvc = context.read<LanguageService>();
    final repo = context.read<TaskRepository>();
    final dayLoopSvc = DayLoopService(dotenv.env['API_KEY']!);

    return ChangeNotifierProvider<HomeViewModel>(
      create: (ctx) => HomeViewModel(
        dayLoopService: dayLoopSvc,
        languageService: langSvc,
        taskRepository: repo,
        journeyController: ctx.read<JourneyController>(),
      )..init(), // kick off init & hydration (non-JourneyCard concerns)
      builder: (context, _) {
        final vm = context.watch<HomeViewModel>();

        // Expose the SpeechController to children that depend on it
        return ChangeNotifierProvider<SpeechController>.value(
          value: vm.controller,
          child: Scaffold(
            backgroundColor: const Color(0xFF1A1A1A),
            body: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // Header (no add button)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        l10n.appTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          // JourneyCard is a dumb view that subscribes to JourneyController.
                          SizedBox(
                            height: 400,
                            child: JourneyCard(
                              title:
                              '${l10n.todayJourney} - ${_timeOfDayLabel(l10n)}',
                              todayDateLabel: l10n.todayDate,
                              dayStreakLabel: l10n.dayStreak,
                            ),
                          ),
                          const SizedBox(height: 30),
                          Row(
                            children: [
                              Expanded(
                                child: RecordButton(
                                  labelIdle: l10n.recordJourneyButton,
                                  labelActive: l10n.stopRecordingButton,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}