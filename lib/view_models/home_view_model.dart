import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  })  : _controller = SpeechController(
    speech: SpeechToText(),
    dayLoop: dayLoopService,
    languageService: languageService,
    taskRepository: taskRepository,
  ),
        _taskRepository = taskRepository;

  final SpeechController _controller;
  SpeechController get controller => _controller;

  final TaskRepository _taskRepository;

  VoidCallback? _dataListener;
  String? _lastProcessedSignature;
  bool _processing = false;

  Future<void> init() async {
    // 1) paint immediately with cached "today" if present
    final cached = await JourneyCache.instance.loadToday();
    if (cached != null && JourneyState.instance.data.value == null) {
      JourneyState.instance.data.value = cached;
    }

    // 2) listen to changes -> keep cache; also auto-complete & collapse dupes
    _dataListener = () {
      final data = JourneyState.instance.data.value;
      JourneyCache.instance.saveToday(data);
      _maybeAutoCompleteFromData(data);
    };
    JourneyState.instance.data.addListener(_dataListener!);

    // 3) don't block UI on speech init
    unawaited(_controller.init());

    // 4) hydrate from DB in background; UI already shows cache
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

  // ---------------- Auto-complete & de-dup ----------------

  void _maybeAutoCompleteFromData(Map<String, dynamic>? data) {
    if (_processing || data == null) return;

    final tasks = (data['tasks'] as List?) ?? const [];
    final entries = (data['entries'] as List?) ?? const [];
    final completedPhrases = (data['completed_phrases'] as List?) ?? const [];
    final completedMatches = (data['completed_to_task_matches'] as List?) ?? const [];

    final signature = jsonEncode({
      'tasks_len': tasks.length,
      'entries_len': entries.length,
      'phr_len': completedPhrases.length,
      'mt_len': completedMatches.length,
      'last_task': tasks.isNotEmpty ? (tasks.last as Map)['text'] : null,
    });

    if (signature == _lastProcessedSignature) return;
    _lastProcessedSignature = signature;

    unawaited(_autoCompleteNow(data));
  }

  Future<void> _autoCompleteNow(Map<String, dynamic> data) async {
    _processing = true;
    try {
      final j = JourneyState.instance;

      // A) Completion signals
      final phrases = _extractCompletionSignals(data);

      // B) Current tasks (strong types)
      final current = Map<String, dynamic>.from(j.data.value ?? {});
      final list = (current['tasks'] as List?)
          ?.whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList() ??
          <Map<String, dynamic>>[];

      if (list.isEmpty && phrases.isEmpty) return;

      // C) Fuzzy match & persist
      final changed = await _autoCompleteMatches(list, phrases);

      // D) Collapse duplicates so later recordings don't add a second variant
      final collapsed = _collapseNearDuplicates(list);

      if (changed || collapsed.length != list.length) {
        current['tasks'] = collapsed;
        j.data.value = current;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Auto-complete failed: $e');
    } finally {
      _processing = false;
    }
  }

  // Collects clues that something was finished
  List<String> _extractCompletionSignals(Map<String, dynamic> data) {
    final out = <String>[];

    // 1) tasks[].completed == true
    final tasks = (data['tasks'] as List?)?.whereType<Map>() ?? const [];
    for (final t in tasks) {
      if (t['completed'] == true) {
        final text = (t['text'] ?? '').toString().trim();
        if (text.isNotEmpty) out.add(text);
      }
    }

    // 2) entries[].status == 'done' OR past-tense verbs
    final entries = (data['entries'] as List?)?.whereType<Map>() ?? const [];
    final doneRegex = RegExp(
      r'\b('
      r'done|finished|completed|checked\s*off|'
      r'watched|called|emailed|messaged|texted|sent|replied|'
      r'paid|bought|purchased|ordered|booked|'
      r'went|came|met|visited|attended|'
      r'uploaded|submitted|delivered|returned|renewed|'
      r'fixed|resolved|cleaned|cooked|studied|exercised|worked|read'
      r')\b',
      caseSensitive: false,
    );

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

    // 3) Optional helper fields from prompt
    final phrases = (data['completed_phrases'] as List?)?.whereType<String>() ?? const [];
    out.addAll(phrases.map((s) => s.trim()).where((s) => s.isNotEmpty));

    final matches =
        (data['completed_to_task_matches'] as List?)?.whereType<Map>() ?? const [];
    out.addAll(matches
        .map((m) => (m['task_text_match'] ?? m['task'] ?? '').toString().trim())
        .where((s) => s.isNotEmpty));

    // 4) what_was_said sometimes summarizes completion
    final summary = (data['what_was_said'] ?? '').toString().trim();
    if (summary.isNotEmpty && looksPastTense(summary)) out.add(summary);

    // De-dupe
    final set = <String>{};
    final unique = <String>[];
    for (final s in out) {
      final k = s.toLowerCase().trim();
      if (set.add(k)) unique.add(s);
    }
    return unique;
  }

  // Fuzzy-match completion phrases -> existing tasks; mark complete + persist
  Future<bool> _autoCompleteMatches(
      List<Map<String, dynamic>> tasks, List<String> phrases) async {
    bool anyChanged = false;

    // Minimal stemming + stopword removal; supports Arabic letters too
    String norm(String s) {
      s = s.toLowerCase();
      s = s.replaceAll(RegExp(r'[^a-z0-9\u0600-\u06FF\s]'), ' ');
      s = s.replaceAll(RegExp(r'\s+'), ' ').trim();

      const stop = {
        'a','an','the','to','for','of','on','in','at','with','and','or','it','my','our','your','their'
      };

      String stem(String w) {
        const irr = {
          'went':'go','gone':'go','paid':'pay','bought':'buy','brought':'bring','met':'meet',
          'taught':'teach','caught':'catch','ran':'run','done':'do','did':'do','made':'make',
          'saw':'see','seen':'see','read':'read','sent':'send','built':'build','found':'find',
          'left':'leave','came':'come','became':'become','began':'begin','begun':'begin',
          'watched':'watch','called':'call','emailed':'email','messaged':'message','texted':'text',
          'finished':'finish','completed':'complete','ordered':'order','booked':'book','renewed':'renew',
          'visited':'visit','attended':'attend','returned':'return','delivered':'deliver','submitted':'submit',
        };
        if (irr.containsKey(w)) return irr[w]!;
        if (w.endsWith('ing') && w.length > 5) return w.substring(0, w.length - 3);
        if (w.endsWith('ed') && w.length > 4) return w.substring(0, w.length - 2);
        return w;
      }

      final tokens = <String>[];
      for (final w in s.split(' ')) {
        if (w.isEmpty || stop.contains(w)) continue;
        tokens.add(stem(w));
      }
      return tokens.join(' ');
    }

    double sim(String a, String b) {
      final sa = norm(a).split(' ').where((w) => w.isNotEmpty).toSet();
      final sb = norm(b).split(' ').where((w) => w.isNotEmpty).toSet();
      if (sa.isEmpty || sb.isEmpty) return 0.0;
      final inter = sa.intersection(sb).length;
      final uni = sa.union(sb).length;
      return inter / uni;
    }

    const strong = 0.75; // lowered due to stemming
    const good = 0.60;

    for (final t in tasks) {
      if (t['completed'] == true) continue;
      final display = '${t['emoji'] ?? ''} ${t['text'] ?? ''}'.trim();
      final justText = (t['text'] ?? '').toString();

      double bestScore = 0.0;
      for (final p in phrases) {
        final s1 = sim(display, p);
        final s2 = sim(justText, p);
        final sc = (s1 > s2) ? s1 : s2;
        if (sc > bestScore) bestScore = sc;
      }

      if (bestScore >= strong || (bestScore >= good && justText.length <= 64)) {
        t['completed'] = true;
        anyChanged = true;
        await _persistDone(t);
      }
    }

    return anyChanged;
  }

  Future<void> _persistDone(Map<String, dynamic> task) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String _composeTitle(Map<String, dynamic> t) {
      final text = (t['text'] ?? '').toString().trim();
      final emoji = (t['emoji'] ?? '').toString().trim();
      return emoji.isEmpty ? text : '$emoji $text';
    }

    String? id = task['taskId'] as String?;
    if (id == null || id.isEmpty) {
      final title = _composeTitle(task).trim();
      final all = await _taskRepository.getTasks(user.uid);
      final matches = all
          .where((t) => t.title.trim() == title)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (matches.isNotEmpty) {
        id = matches.first.id;
        task['taskId'] = id;
      }
    }

    if (id != null) {
      await _taskRepository.setTaskDone(id, true);
    }
  }

  // Merge near-duplicate tasks; carry over completion/emoji/id
  List<Map<String, dynamic>> _collapseNearDuplicates(
      List<Map<String, dynamic>> tasks) {
    String norm(String s) {
      s = s.toLowerCase();
      s = s.replaceAll(RegExp(r'[^a-z0-9\u0600-\u06FF\s]'), ' ');
      s = s.replaceAll(RegExp(r'\s+'), ' ').trim();

      const stop = {
        'a','an','the','to','for','of','on','in','at','with','and','or','it','my','our','your','their'
      };

      String stem(String w) {
        const irr = {
          'went':'go','gone':'go','paid':'pay','bought':'buy','brought':'bring','met':'meet',
          'taught':'teach','caught':'catch','ran':'run','done':'do','did':'do','made':'make',
          'saw':'see','seen':'see','read':'read','sent':'send','built':'build','found':'find',
          'left':'leave','came':'come','became':'become','began':'begin','begun':'begin',
          'watched':'watch','called':'call','emailed':'email','messaged':'message','texted':'text',
          'finished':'finish','completed':'complete','ordered':'order','booked':'book','renewed':'renew',
          'visited':'visit','attended':'attend','returned':'return','delivered':'deliver','submitted':'submit',
        };
        if (irr.containsKey(w)) return irr[w]!;
        if (w.endsWith('ing') && w.length > 5) return w.substring(0, w.length - 3);
        if (w.endsWith('ed') && w.length > 4) return w.substring(0, w.length - 2);
        return w;
      }

      final toks = <String>[];
      for (final w in s.split(' ')) {
        if (w.isEmpty || stop.contains(w)) continue;
        toks.add(stem(w));
      }
      return toks.join(' ');
    }

    double sim(String a, String b) {
      final sa = norm(a).split(' ').where((w) => w.isNotEmpty).toSet();
      final sb = norm(b).split(' ').where((w) => w.isNotEmpty).toSet();
      if (sa.isEmpty || sb.isEmpty) return 0.0;
      final inter = sa.intersection(sb).length;
      final uni = sa.union(sb).length;
      return inter / uni;
    }

    String display(Map<String, dynamic> t) =>
        '${(t['emoji'] ?? '').toString()} ${(t['text'] ?? '').toString()}'.trim();

    const dup = 0.75;
    final merged = <Map<String, dynamic>>[];

    for (final raw in tasks) {
      final t = Map<String, dynamic>.from(raw);
      t['text'] = (t['text'] ?? '').toString();
      t['emoji'] = (t['emoji'] ?? '').toString();
      t['completed'] = t['completed'] == true;

      int? matchIdx;
      double best = 0.0;
      for (int i = 0; i < merged.length; i++) {
        final s = sim(display(t), display(merged[i]));
        if (s > best) {
          best = s;
          matchIdx = i;
        }
      }

      if (matchIdx != null && best >= dup) {
        final m = merged[matchIdx];

        m['completed'] = (m['completed'] == true) || (t['completed'] == true);

        if ((m['emoji'] as String).isEmpty && (t['emoji'] as String).isNotEmpty) {
          m['emoji'] = t['emoji'];
        }

        if ((m['taskId'] ?? '').toString().isEmpty &&
            (t['taskId'] ?? '').toString().isNotEmpty) {
          m['taskId'] = t['taskId'];
        }

        final mt = (m['text'] as String);
        final tt = (t['text'] as String);
        if (tt.length > mt.length && tt.length <= mt.length + 20) {
          m['text'] = tt; // prefer slightly more specific title
        }
      } else {
        merged.add(t);
      }
    }

    return merged;
  }
}
