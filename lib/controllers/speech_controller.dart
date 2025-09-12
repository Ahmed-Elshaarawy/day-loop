import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:day_loop/ai/day_loop_service.dart';
import 'package:day_loop/services/language_service.dart';

import '../repositories/task_repository.dart';
import '../task.dart';
import 'journey_controller.dart';

class SpeechController extends ChangeNotifier {
  SpeechController({
    required SpeechToText speech,
    required DayLoopService dayLoop,
    required LanguageService languageService,
    required TaskRepository taskRepository,
    required JourneyController journeyController,
  })  : _speech = speech,
        _dayLoop = dayLoop,
        _languageService = languageService,
        _repo = taskRepository,
        _journey = journeyController;

  final SpeechToText _speech;
  final DayLoopService _dayLoop;
  final LanguageService _languageService;
  final TaskRepository _repo;
  final JourneyController _journey;

  bool _speechReady = false;
  bool get speechReady => _speechReady;
  bool get isListening => _speech.isListening;

  String _lastWords = '';

  /// Flag that becomes true while transcript is being parsed (Gemini call).
  bool _isProcessingTranscript = false;
  bool get processing => _isProcessingTranscript;

  /// Expose one unified flag for UI spinners.
  bool get busy => processing; // or: processing || isListening if you want mic time too

  void _setProcessing(bool v) {
    if (_isProcessingTranscript == v) return;
    _isProcessingTranscript = v;
    notifyListeners();
  }

  Future<void> init() async {
    _speechReady = await _speech.initialize(onStatus: _onStatus);
    notifyListeners();
  }

  Future<void> startListening() async {
    _lastWords = '';
    _setProcessing(false);

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
    _setProcessing(true); // 🔹 show spinner now

    final transcript = _lastWords.trim();
    if (transcript.isEmpty) {
      _setProcessing(false);
      return;
    }

    final mode = DateTime.now().hour < 12 ? 'morning_brief' : 'evening_debrief';
    final locale = _localeFor(_languageService.currentLanguage);

    try {
      final parsed = await _dayLoop.parseTranscript(
        transcript: transcript,
        mode: mode,
        locale: locale,
      );
      debugPrint('DL> Gemini parsed JSON: $parsed');

      await _persistTasks(parsed);
      await _autoCompleteAgainstCurrentTasks(parsed);
      await _journey.fetchFromDb();
    } catch (e, st) {
      debugPrint('DL> Gemini error: $e\n$st');
    } finally {
      _setProcessing(false); // 🔹 hide spinner
    }
  }

  // -------------------- Persistence --------------------

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

  // -------------------- Auto-complete (simplified) --------------------

  Future<void> _autoCompleteAgainstCurrentTasks(Map<String, dynamic> parsed) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final open = _journey.tasks.where((t) => !t.completed).toList();
    if (open.isEmpty) return;

    final phrases = _extractCompletionSignals(parsed);
    final doneEntries = _extractDoneEntries(parsed);

    if (phrases.isEmpty && doneEntries.isEmpty) return;

    Set<String> tokens(String s) {
      s = s.toLowerCase();
      s = s.replaceAll(RegExp(r'[^a-z0-9\u0600-\u06FF\s]'), ' ');
      final stop = {'a','an','the','to','for','of','on','in','at','with','and','or','it','my','our','your','their','then'};
      return s.split(RegExp(r'\s+')).where((w) => w.isNotEmpty && !stop.contains(w)).toSet();
    }

    double jaccard(Set<String> a, Set<String> b) {
      if (a.isEmpty || b.isEmpty) return 0.0;
      final inter = a.intersection(b).length;
      return inter / a.union(b).length;
    }

    bool fuzzyMatches(String a, String b) {
      final sa = tokens(a);
      final sb = tokens(b);
      final jac = jaccard(sa, sb);
      if (jac >= 0.6) return true;
      final inter = sa.intersection(sb).length;
      return inter / sa.length >= 0.6 || inter / sb.length >= 0.6;
    }

    for (final t in open) {
      final title = t.title;
      final titleTokens = tokens(title);
      double best = 0.0;

      for (final e in doneEntries) {
        final lemmas = (e['lemmas'] as List).cast<String>();
        if (lemmas.isNotEmpty) {
          final overlap = jaccard(titleTokens, lemmas.map((w) => w.toLowerCase()).toSet());
          if (overlap > best) best = overlap;
        }
        final items = (e['items'] as List).cast<String>();
        final places = (e['places'] as List).cast<String>();
        if (items.any((it) => title.toLowerCase().contains(it.toLowerCase())) ||
            places.any((pl) => title.toLowerCase().contains(pl.toLowerCase()))) {
          if (best < 0.6) best = 0.6;
        }
        final eText = (e['text'] ?? '').toString();
        if (fuzzyMatches(eText, title) && best < 0.6) {
          best = 0.6;
        }
      }

      for (final p in phrases) {
        if (fuzzyMatches(p, title) && best < 0.6) best = 0.6;
      }

      if (best >= 0.75 || (best >= 0.6 && title.length <= 64)) {
        final row = await _repo.findLatestByTitle(userId: user.uid, title: title.trim());
        final id = row?.id ?? t.id;
        if (id != null) {
          await _repo.setTaskDone(id, true);
        }
      }
    }
  }

  // ---- helpers ----

  List<String> _extractCompletionSignals(Map<String, dynamic> data) {
    final out = <String>[];

    final tasks = (data['tasks'] as List?)?.whereType<Map>() ?? const [];
    for (final t in tasks) {
      if (t['completed'] == true) {
        final text = (t['text'] ?? '').toString().trim();
        if (text.isNotEmpty) out.add(text);
      }
    }

    final entries = (data['entries'] as List?)?.whereType<Map>() ?? const [];
    final doneRegex = RegExp(r'\b(done|finished|completed|checked\s*off)\b', caseSensitive: false);

    bool looksPastTense(String s) {
      final lower = s.toLowerCase();
      if (doneRegex.hasMatch(lower)) return true;
      for (final w in lower.split(RegExp(r'\s+'))) {
        if (w.length > 3 && w.endsWith('ed')) return true;
      }
      return false;
    }

    for (final e in entries) {
      final status = (e['status'] ?? '').toString().toLowerCase();
      final text = (e['text'] ?? '').toString().trim();
      if (text.isEmpty) continue;
      if (status == 'done' || looksPastTense(text)) out.add(text);
    }

    final phrases = (data['completed_phrases'] as List?)?.whereType<String>() ?? const [];
    out.addAll(phrases.map((s) => s.trim()).where((s) => s.isNotEmpty));

    return out.toSet().toList();
  }

  List<Map<String, dynamic>> _extractDoneEntries(Map<String, dynamic> data) {
    final out = <Map<String, dynamic>>[];
    final entries = (data['entries'] as List?)?.whereType<Map>() ?? const [];

    bool isDone(Map e) => ((e['status'] ?? '').toString().toLowerCase() == 'done');

    for (final e in entries) {
      if (!isDone(e)) continue;
      final text = (e['text'] ?? '').toString().trim();
      if (text.isEmpty) continue;
      final lemmas = (e['lemmas'] as List?)?.whereType<String>().toList() ?? const <String>[];
      final entities = (e['entities'] as Map?) ?? const {};
      final items = (entities['items'] as List?)?.whereType<String>().toList() ?? const <String>[];
      final places = (entities['places'] as List?)?.whereType<String>().toList() ?? const <String>[];
      out.add({'text': text, 'lemmas': lemmas, 'items': items, 'places': places});
    }
    return out;
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
