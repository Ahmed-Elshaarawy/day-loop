import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../controllers/speech_controller.dart';
import '../ai/day_loop_service.dart';
import '../services/language_service.dart';
import '../repositories/task_repository.dart';
import '../journey_state.dart';
import '../services/journey_cache.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    required DayLoopService dayLoopService,
    required LanguageService languageService,
    required TaskRepository taskRepository,
  }) : _controller = SpeechController(
    speech: SpeechToText(),
    dayLoop: dayLoopService,
    languageService: languageService,
    taskRepository: taskRepository,
  );

  final SpeechController _controller;
  SpeechController get controller => _controller;

  VoidCallback? _dataListener;

  Future<void> init() async {
    // 1) Paint immediately with cached "today" if present
    final cached = await JourneyCache.instance.loadToday();
    if (cached != null && JourneyState.instance.data.value == null) {
      JourneyState.instance.data.value = cached;
    }

    // 2) Listen to changes and keep cache up-to-date
    _dataListener = () {
      JourneyCache.instance.saveToday(JourneyState.instance.data.value);
    };
    JourneyState.instance.data.addListener(_dataListener!);

    // 3) Don’t block UI on speech init
    unawaited(_controller.init());

    // 4) Hydrate from DB in background; UI already shows cache
    unawaited(_controller.hydrateTodayFromDb());
  }

  @override
  void dispose() {
    if (_dataListener != null) {
      JourneyState.instance.data.removeListener(_dataListener!);
    }
    _controller.dispose();
    super.dispose();
  }
}