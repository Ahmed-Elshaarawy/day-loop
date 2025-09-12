import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../controllers/speech_controller.dart';
import '../controllers/journey_controller.dart';
import '../ai/day_loop_service.dart';
import '../services/language_service.dart';
import '../repositories/task_repository.dart';
import '../services/journey_cache.dart';

/// ViewModel for the Home screen.
/// - Initializes SpeechController (mic + AI service)
/// - Hydrates JourneyController (via cache first, then DB)
/// - Keeps a lightweight "today" cache in sync with current tasks
class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    required DayLoopService dayLoopService,
    required LanguageService languageService,
    required TaskRepository taskRepository,
    required JourneyController journeyController,
  })  : _controller = SpeechController(
    speech: SpeechToText(),
    dayLoop: dayLoopService,
    languageService: languageService,
    taskRepository: taskRepository, journeyController: journeyController,
  ),
        _taskRepository = taskRepository,
        _journey = journeyController;

  // ----- Dependencies -----
  final SpeechController _controller;
  SpeechController get controller => _controller;

  final TaskRepository _taskRepository;
  final JourneyController _journey;

  // ----- Internals -----
  VoidCallback? _journeyListener;
  bool _initialized = false;

  /// Kick off initialization:
  /// 1) Load cached "today" (if any) into JourneyController for instant paint
  /// 2) Init speech (non-blocking)
  /// 3) Hydrate from DB (controller was already created with fetchFromDb in main.dart,
  ///    but we call it again here if you prefer explicit refresh at screen level)
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // 1) Instant paint from cache (if present)
    try {
      final cached = await JourneyCache.instance.loadToday();
      if (cached != null) {
        final rawTasks = (cached['tasks'] as List?)?.whereType<Map<String, dynamic>>().toList() ?? const [];
        if (rawTasks.isNotEmpty) {
          _journey.loadFromLegacyTasks(rawTasks);
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Journey cache load failed: $e');
    }

    // 2) Keep cache in sync when tasks change
    _journeyListener = () => _saveTodayCacheFromController();
    _journey.addListener(_journeyListener!);

    // 3) Init speech in the background (don’t block UI)
    unawaited(_controller.init());

    // 4) Hydrate from DB in the background (UI already has cache)
    //    If you already call fetchFromDb() in main.dart provider, this is optional.
    unawaited(_refreshFromDb());
  }

  @override
  void dispose() {
    if (_journeyListener != null) {
      _journey.removeListener(_journeyListener!);
    }
    _controller.dispose();
    super.dispose();
  }

  // ---------------- Helpers ----------------

  Future<void> _refreshFromDb() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await _journey.fetchFromDb();
      // cache will auto-update via listener
    } catch (e) {
      if (kDebugMode) debugPrint('DB refresh failed: $e');
    }
  }

  /// Persist a lightweight "today" snapshot to cache from the controller tasks.
  /// We store in the legacy shape that your cache expects:
  /// { tasks: [ { text, emoji, completed, createdAt, taskId } ], entries: [] }
  Future<void> _saveTodayCacheFromController() async {
    try {
      final snapshot = {
        'tasks': _journey.tasks.map((t) {
          // We don’t try to split emoji vs text here; title is kept as text.
          return <String, dynamic>{
            'text': t.title,
            'emoji': '', // not tracked in UiTask; set empty
            'completed': t.completed,
            'createdAt': t.createdAt,
            'taskId': t.id,
          };
        }).toList(),
        // Entries aren’t managed here anymore; keep empty to avoid confusion.
        'entries': const <Map<String, dynamic>>[],
      };
      await JourneyCache.instance.saveToday(snapshot);
    } catch (e) {
      if (kDebugMode) debugPrint('Journey cache save failed: $e');
    }
  }
}
