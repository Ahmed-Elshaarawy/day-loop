import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DayLoopService {
  DayLoopService(this.apiKey)
      : _model = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: apiKey,
    generationConfig: GenerationConfig(
      temperature: 0.2,
      responseMimeType: 'application/json',
      maxOutputTokens: 2048, // prevent overly long responses
    ),
  );

  String apiKey = dotenv.env['API_KEY']!;
  final GenerativeModel _model;

  /// Parse transcript with Gemini and return parsed JSON as Map.
  Future<Map<String, dynamic>> parseTranscript({
    required String transcript,
    required String mode, // morning_brief | evening_debrief
    String locale = 'en-US',
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (mode != 'morning_brief' && mode != 'evening_debrief') {
      throw ArgumentError.value(mode, 'mode', 'Must be morning_brief or evening_debrief');
    }
    if (transcript.trim().isEmpty) {
      throw ArgumentError.value(transcript, 'transcript', 'Transcript cannot be empty');
    }

    final prompt = _buildPrompt(transcript: transcript, mode: mode, locale: locale);

    try {
      final resp = await _model.generateContent([Content.text(prompt)]).timeout(timeout);
      debugPrint('DL> Got response from Gemini: ${resp.text?.substring(0, 100)}...');

      if (resp.promptFeedback != null && resp.candidates.isEmpty) {
        final fb = resp.promptFeedback!;
        throw StateError('Gemini blocked the prompt: ${fb.blockReason} ${fb.safetyRatings}');
      }
      if (resp.candidates.isEmpty || resp.text == null) {
        throw StateError('Gemini returned no content');
      }

      final raw = resp.text!.trim();
      if (kDebugMode) debugPrint('Gemini raw response:\n$raw');

      final jsonStr = _extractJson(raw);
      if (kDebugMode) debugPrint('Gemini extracted JSON:\n$jsonStr');

      final decoded = _parseAndValidateJson(jsonStr);

      // Normalize tasks
      decoded['tasks'] = _normalizeTasks(decoded['tasks']);

      // Normalize optional completion helpers
      decoded['completed_phrases'] =
          ((decoded['completed_phrases'] as List?) ?? const [])
              .whereType<String>()
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();

      decoded['completed_to_task_matches'] =
          ((decoded['completed_to_task_matches'] as List?) ?? const [])
              .whereType<Map>()
              .map((m) => {
            'phrase': (m['phrase'] ?? '').toString().trim(),
            'task_text_match':
            (m['task_text_match'] ?? m['task'] ?? '').toString().trim(),
          })
              .where((m) =>
          (m['phrase'] as String).isNotEmpty &&
              (m['task_text_match'] as String).isNotEmpty)
              .toList();

      return decoded;
    } on TimeoutException {
      throw StateError('Request timed out after ${timeout.inSeconds} seconds');
    } catch (e, st) {
      debugPrint('DL> Exception in parseTranscript: $e\n$st');
      if (e is StateError || e is ArgumentError || e is FormatException) rethrow;
      throw StateError('Unexpected error calling Gemini: $e');
    }
  }

  Map<String, dynamic> _parseAndValidateJson(String jsonStr) {
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is! Map<String, dynamic>) {
        throw FormatException('Expected JSON object, got ${decoded.runtimeType}');
      }

      // Required fields
      for (final field in ['headline', 'what_was_said', 'mode', 'intent', 'confidence']) {
        if (!decoded.containsKey(field)) {
          throw FormatException('Missing required field: $field');
        }
      }

      final confidence = decoded['confidence'];
      if (confidence is! num || confidence < 0 || confidence > 1) {
        throw FormatException('Invalid confidence: $confidence (must be 0-1)');
      }

      // Ensure lists exist
      decoded['tasks'] ??= <Map<String, dynamic>>[];
      decoded['entries'] ??= <Map<String, dynamic>>[];

      return decoded;
    } on FormatException {
      rethrow;
    } catch (e) {
      throw FormatException('Failed to parse JSON: $e\n$jsonStr');
    }
  }

  /// Normalize tasks to {text, completed, type, emoji}
  List<Map<String, dynamic>> _normalizeTasks(dynamic tasksRaw) {
    if (tasksRaw is! List) return const [];
    final out = <Map<String, dynamic>>[];
    for (final item in tasksRaw) {
      if (item is Map) {
        final text =
        (item['text'] ?? item['title'] ?? item['task'] ?? '').toString().trim();
        if (text.isEmpty) continue;
        out.add({
          'text': text,
          'completed': (item['completed'] ?? false) == true,
          'type': (item['type'] ?? '').toString(),
          'emoji': (item['emoji'] ?? '').toString().trim(),
        });
      } else if (item is String) {
        final text = item.trim();
        if (text.isEmpty) continue;
        out.add({'text': text, 'completed': false, 'type': '', 'emoji': ''});
      }
    }
    return out;
  }

  String _buildPrompt({
    required String transcript,
    required String mode,
    required String locale,
  }) =>
      '''
Role:
You are the intelligence behind Day Loop. Parse the transcript and output STRICT JSON capturing EVERYTHING (actions, plans, purchases, calls, places, people, ideas, questions, reflections). The app decides MODE; do not infer it. The values of all output keys must be in the same language as the TRANSCRIPT.

Inputs:
- TRANSCRIPT: raw speech-to-text (may be long and rambly).
- MODE: "$mode"
- USER_LOCALE: $locale (currency/number hints)

Output (strict JSON, one object):
{
  "headline": "≤60 chars - short summary",
  "what_was_said": "1–2 sentence summary",
  "mode": "$mode",
  "intent": "Main purpose",

  "entries": [
    {
      "type": "action|call|expense|outing|reminder|note|fact|thought|question|idea|gratitude|habit|memory|follow_up|shopping|plan",
      "text": "Concise restatement",
      "date_phrase": "",
      "time_phrase": "",
      "entities": { "people": [], "places": [], "items": [] },
      "amount": null, "currency": "", "category": "", "priority": "",
      "status": "", // planned|done|said (set 'done' only if user clearly says it's finished)
      "source_phrases": ["short snippet(s) from transcript"]
    }
  ],

  "tasks": [
    { "text": "Actionable item", "completed": false, "type": "action|reminder|call|shopping|expense|follow_up|plan", "emoji": "one emoji" }
  ],

  "reminders": [], "calls": [], "expenses": [], "outings": [], "notes": [],
  "people": [], "places": [], "shopping_list": [], "follow_ups": [],

  // Completion helpers (optional but recommended)
  "completed_phrases": [],                       // e.g., "called Ahmed", "watched the movie"
  "completed_to_task_matches": [                 // map phrase to task text if obvious
    { "phrase": "called Ahmed", "task_text_match": "Call Ahmed" }
  ],

  "unresolved": [],
  "confidence": 0.9
}

Rules:
1) Do NOT invent dates/times; keep as spoken or empty.
2) Use MODE exactly as provided.
3) Record EVERYTHING; prefer recall over precision.
4) Mirror actionable clauses into "tasks". If none, "tasks": [].
5) Mark a task "completed": true ONLY when the user clearly indicates completion — including past-tense statements like "watched the movie", "called Ahmed", "paid the bill". Also add a concise phrase to "completed_phrases". When obvious, add {"phrase": "...", "task_text_match": "..."} to "completed_to_task_matches".
6) Keep strings terse. Include evidence in "source_phrases".
7) No hallucinations; put gaps in "unresolved".
8) Return ONLY valid JSON (no commentary).
9) Confidence is 0–1.
10) All generated text must be in the language of the TRANSCRIPT.
11) Provide one emoji per task in "emoji".

TRANSCRIPT: "${transcript.replaceAll('"', '\\"')}"
''';

  /// Extract JSON from raw model text
  String _extractJson(String s) {
    // Remove ``` fences if present
    final fenced = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```', multiLine: true);
    final fencedMatch = fenced.firstMatch(s);
    if (fencedMatch != null) {
      final content = fencedMatch.group(1)!.trim();
      return _findCompleteJsonObject(content);
    }
    return _findCompleteJsonObject(s);
  }

  /// Finds the first complete JSON object by counting braces
  String _findCompleteJsonObject(String s) {
    final trimmed = s.trim();
    final start = trimmed.indexOf('{');
    if (start == -1) throw const FormatException('No JSON object found in response');

    int braceCount = 0;
    int end = -1;
    bool inString = false;
    bool escaped = false;

    for (int i = start; i < trimmed.length; i++) {
      final char = trimmed[i];

      if (escaped) {
        escaped = false;
        continue;
      }
      if (char == '\\' && inString) {
        escaped = true;
        continue;
      }
      if (char == '"') {
        inString = !inString;
        continue;
      }
      if (!inString) {
        if (char == '{') {
          braceCount++;
        } else if (char == '}') {
          braceCount--;
          if (braceCount == 0) {
            end = i;
            break;
          }
        }
      }
    }

    if (end == -1) throw const FormatException('Incomplete JSON object in response');
    return trimmed.substring(start, end + 1);
  }
}
