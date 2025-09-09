import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:day_loop/ai/day_loop_service.dart';
import 'package:day_loop/services/language_service.dart';

import '../journey_state.dart';
import '../repositories/task_repository.dart';
import '../task.dart';

class SpeechController extends ChangeNotifier {
  SpeechController({
    required SpeechToText speech,
    required DayLoopService dayLoop,
    required LanguageService languageService,
    required TaskRepository taskRepository,
  })  : _speech = speech,
        _dayLoop = dayLoop,
        _languageService = languageService,
        _repo = taskRepository;

  final SpeechToText _speech;
  final DayLoopService _dayLoop;
  final LanguageService _languageService;
  final TaskRepository _repo;

  bool _speechReady = false;
  bool get speechReady => _speechReady;
  bool get isListening => _speech.isListening;

  String _lastWords = '';
  bool _isProcessingTranscript = false;

  Future<void> init() async {
    _speechReady = await _speech.initialize(onStatus: _onStatus);
    notifyListeners();
  }

  Future<void> startListening() async {
    _lastWords = '';
    _isProcessingTranscript = false;

    final localeId = _localeFor(_languageService.currentLanguage);

    await _speech.listen(
      onResult: _onSpeechResult,
      localeId: localeId,
      listenMode: ListenMode.dictation,
      partialResults: true,
      pauseFor: const Duration(seconds: 3),
      listenFor: const Duration(seconds: 60),
    );

    notifyListeners();
  }

  Future<void> stopListening() async {
    await _speech.stop();
    notifyListeners();
  }

  @override
  void dispose() {
    _speech.stop();
    _speech.cancel();
    super.dispose();
  }

  void _onStatus(String status) {
    debugPrint('Speech status: $status');
    if (status == 'done' && _lastWords.trim().isNotEmpty && !_isProcessingTranscript) {
      _processTranscript();
    }
    if (status == 'notListening') notifyListeners();
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    _lastWords = result.recognizedWords;
    debugPrint('Recognized: $_lastWords');
  }

  Future<void> _processTranscript() async {
    if (_isProcessingTranscript) return;
    _isProcessingTranscript = true;

    final transcript = _lastWords.trim();
    if (transcript.isEmpty) {
      _isProcessingTranscript = false;
      return;
    }

    final mode = DateTime.now().hour < 12 ? 'morning_brief' : 'evening_debrief';
    final locale = _localeFor(_languageService.currentLanguage);

    final j = JourneyState.instance;
    j.loading.value = true;
    j.error.value = null;

    try {
      final parsed = await _dayLoop.parseTranscript(
        transcript: transcript,
        mode: mode,
        locale: locale,
      );
      debugPrint('DL> Gemini parsed JSON: $parsed');

      // ---- 1) Update on-screen Journey card state (merge) ----
      final currentData = j.data.value;
      if (currentData != null) {
        final Map<String, dynamic> combinedData = Map.from(currentData);
        parsed.forEach((key, value) {
          if (combinedData.containsKey(key)) {
            if (combinedData[key] is List) {
              final existingList = List.from(combinedData[key]);
              final newList = List.from(value);
              existingList.addAll(newList);
              combinedData[key] = existingList;
            } else {
              combinedData[key] = value;
            }
          } else {
            combinedData[key] = value;
          }
        });
        j.data.value = combinedData;
      } else {
        j.data.value = parsed;
      }

      // ---- 2) Persist parsed tasks for History ----
      await _persistTasks(parsed);

      // (Optional) you could refresh today's tasks from DB here to attach taskIds,
      // but JourneyCard already handles missing ids gracefully via repo lookup.

    } catch (e, st) {
      debugPrint('DL> Gemini error: $e\n$st');
      j.error.value = e is FormatException
          ? 'Could not process your recording. Please try again.'
          : 'Something went wrong. Please try again.';
    } finally {
      j.loading.value = false;
      _isProcessingTranscript = false;
    }
  }

  Future<void> _persistTasks(Map<String, dynamic> parsed) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('DL> skip persist: no user logged in');
      return;
    }

    final tasksJson = (parsed['tasks'] is List)
        ? (parsed['tasks'] as List).whereType<Map>().toList()
        : const <Map<String, dynamic>>[];

    if (tasksJson.isEmpty) return;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    var counter = 0;

    for (final t in tasksJson) {
      final text = (t['text'] ?? '').toString().trim();
      if (text.isEmpty) continue;

      final emoji = (t['emoji'] ?? '').toString().trim();
      final title = emoji.isEmpty ? text : '$emoji $text';
      final dueMs = (t['dueDateMs'] is int) ? t['dueDateMs'] as int : null;

      final task = Task(
        id: 't_${DateTime.now().microsecondsSinceEpoch}_${counter++}',
        userId: user.uid,
        title: title,
        status: 'pending',
        priority: 0,
        dueDate: dueMs,
        createdAt: nowMs,
        updatedAt: nowMs,
        completedAt: null,
        deletedAt: null,
        tags: const [],
        version: 1,
      );

      await _repo.insert(task);
    }
  }

  /// Faster hydration: pulls **only today's** tasks from DB and includes taskId.
  Future<void> hydrateTodayFromDb() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Efficient SQL-side day filter (UTC conversion is inside the repo helper)
    final todays = await _repo.getTasksForToday(
      userId: user.uid,
      orderBy: 'createdAt ASC',
    );

    if (todays.isEmpty) {
      JourneyState.instance.data.value = null;
      return;
    }

    final list = todays.map((Task t) {
      final title = t.title.trim();
      final emoji = _leadingEmoji(title) ?? '';
      final text  = _withoutLeadingEmoji(title);
      return {
        'emoji': emoji,
        'text' : text,
        'completed': t.status == 'done',
        'taskId': t.id,                 // 👈 include DB id for instant persistence
      };
    }).toList();

    JourneyState.instance.data.value = {'tasks': list};
  }

  // ---- emoji helpers (same logic you used elsewhere) ----
  String? _leadingEmoji(String s) {
    final it = s.trimLeft().runes.iterator;
    if (!it.moveNext()) return null;
    final r = it.current;
    final isEmoji = (r >= 0x1F300 && r <= 0x1FAFF) ||
        (r >= 0x1F900 && r <= 0x1F9FF) ||
        (r >= 0x2600 && r <= 0x26FF) ||
        (r >= 0x2700 && r <= 0x27BF);
    return isEmoji ? String.fromCharCode(r) : null;
  }

  String _withoutLeadingEmoji(String s) {
    final trimmed = s.trimLeft();
    if (trimmed.isEmpty) return s;
    final it = trimmed.runes.iterator;
    if (!it.moveNext()) return s;
    final r = it.current;
    final isEmoji = (r >= 0x1F300 && r <= 0x1FAFF) ||
        (r >= 0x1F900 && r <= 0x1F9FF) ||
        (r >= 0x2600 && r <= 0x26FF) ||
        (r >= 0x2700 && r <= 0x27BF);
    if (!isEmoji) return s;
    final emoji = String.fromCharCode(r);
    return trimmed.startsWith(emoji)
        ? trimmed.substring(emoji.length).trimLeft()
        : s;
  }

  String _localeFor(String language) {
    switch (language.toLowerCase()) {
      case 'arabic':
        return 'ar-SA';
      case 'english':
      default:
        return 'en-US';
    }
  }
}
