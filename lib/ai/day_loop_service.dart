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
      maxOutputTokens: 2048, // Prevent overly long responses
    ),
  );

  String apiKey = dotenv.env['API_KEY']!;
  final GenerativeModel _model;

  /// Sends the transcript + mode to Gemini and returns the parsed JSON Map.
  /// Throws a readable exception if the response is blocked or not JSON.
  Future<Map<String, dynamic>> parseTranscript({
    required String transcript,
    required String mode,
    String locale = 'en-US',
    Duration timeout = const Duration(seconds: 30),
  }) async {
    // Guard bad mode early
    if (mode != 'morning_brief' && mode != 'evening_debrief') {
      throw ArgumentError.value(mode, 'mode', 'Must be morning_brief or evening_debrief');
    }

    // Guard empty transcript
    if (transcript.trim().isEmpty) {
      throw ArgumentError.value(transcript, 'transcript', 'Transcript cannot be empty');
    }

    final prompt = _buildPrompt(transcript: transcript, mode: mode, locale: locale);

    try {
      final resp = await _model.generateContent([Content.text(prompt)]).timeout(timeout);
      debugPrint('DL> Got response from Gemini: ${resp.text?.substring(0, 100)}...');

      // Check if content was blocked
      if (resp.promptFeedback != null && resp.candidates.isEmpty) {
        final fb = resp.promptFeedback!;
        throw StateError('Gemini blocked the prompt: ${fb.blockReason} ${fb.safetyRatings}');
      }

      // Check if we got a response
      if (resp.candidates.isEmpty || resp.text == null) {
        throw StateError('Gemini returned no content');
      }

      final raw = resp.text!.trim();
      if (kDebugMode) {
        debugPrint('Gemini raw response:\n$raw');
      }

      // Extract and parse JSON
      final jsonStr = _extractJson(raw);
      if (kDebugMode) {
        debugPrint('Gemini extracted JSON:\n$jsonStr');
      }

      final decoded = _parseAndValidateJson(jsonStr);

      // Safety net: ensure a top-level tasks array exists
      if (decoded['tasks'] is! List) {
        decoded['tasks'] = <Map<String, dynamic>>[];
      }

      // Optional: Light normalization of tasks structure (keep super-simple)
      decoded['tasks'] = _normalizeTasks(decoded['tasks']);

      return decoded;
    } on TimeoutException {
      throw StateError('Request timed out after ${timeout.inSeconds} seconds');
    } catch (e, st) {
      debugPrint('DL> Exception in parseTranscript: $e');
      debugPrint('DL> Stack trace: $st');
      // Re-throw our custom exceptions as-is
      if (e is StateError || e is ArgumentError || e is FormatException) {
        rethrow;
      }
      // Wrap unexpected errors
      throw StateError('Unexpected error calling Gemini: $e');
    }
  }

  Map<String, dynamic> _parseAndValidateJson(String jsonStr) {
    try {
      final decoded = jsonDecode(jsonStr);

      if (decoded is! Map<String, dynamic>) {
        throw FormatException('Expected JSON object, got ${decoded.runtimeType}');
      }

      // Validate required fields exist (tasks is encouraged below, but not required here)
      final required = ['headline', 'what_was_said', 'mode', 'intent', 'confidence'];
      for (final field in required) {
        if (!decoded.containsKey(field)) {
          throw FormatException('Missing required field: $field');
        }
      }

      // Validate confidence is a number between 0-1
      final confidence = decoded['confidence'];
      if (confidence is! num || confidence < 0 || confidence > 1) {
        throw FormatException('Invalid confidence value: $confidence (must be 0-1)');
      }

      return decoded;
    } on FormatException {
      rethrow;
    } catch (e) {
      throw FormatException('Failed to parse JSON: $e\n$jsonStr');
    }
  }

  /// Normalizes the "tasks" array to a simple list of {text, completed, type}
  List<Map<String, dynamic>> _normalizeTasks(dynamic tasksRaw) {
    if (tasksRaw is! List) return const [];
    final out = <Map<String, dynamic>>[];
    for (final item in tasksRaw) {
      if (item is Map) {
        final text = (item['text'] ?? item['title'] ?? item['task'] ?? '').toString().trim();
        if (text.isEmpty) continue;
        final completed = (item['completed'] ?? false) == true;
        final type = (item['type'] ?? '').toString();
        out.add({'text': text, 'completed': completed, 'type': type});
      } else if (item is String) {
        final text = item.trim();
        if (text.isEmpty) continue;
        out.add({'text': text, 'completed': false, 'type': ''});
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
You are the intelligence behind Day Loop, where users speak freely and the app turns the transcript into structured data. The app decides MODE (morning_brief vs evening_debrief). Your job: parse the transcript and output JSON that records EVERYTHING the user says—actions, plans, purchases, calls, places, people, ideas, questions, reflections—without resolving dates/times.

Inputs provided by the app:
- TRANSCRIPT: raw speech-to-text (may be long and rambly).
- MODE: "${mode}" (the app decides this; do not infer).
- USER_LOCALE: ${locale} for currency/number parsing hints.

Output (STRICT JSON only; one object):
{
  "headline": "≤60 chars — short summary of the entry",
  "what_was_said": "1–2 sentences summarizing the transcript",
  "mode": "${mode}",
  "intent": "Main purpose in one sentence",

  // EVERYTHING goes here as a flat stream, preserving order.
  "entries": [
    {
      "type": "action|call|expense|outing|reminder|note|fact|thought|question|idea|gratitude|habit|memory|follow_up|shopping|plan",
      "text": "Concise restatement of the user’s clause",
      "date_phrase": "",
      "time_phrase": "",
      "entities": {
        "people": ["..."],
        "places": ["..."],
        "items": ["..."]
      },
      "amount": null,           // number if expense
      "currency": "",           // e.g., USD if symbol/locale implies
      "category": "",           // e.g., groceries|transport|food|personal|work
      "priority": "",           // low|med|high when implied
      "status": "",             // planned|done|said (do not infer completion unless stated)
      "source_phrases": ["Verbatim or near-verbatim snippet(s)"]
    }
  ],

  // 👉 PRIMARY for our app:
  "tasks": [
    {
      "text": "Concise actionable item",
      "completed": false,             // true only if user explicitly said it's done
      "type": "action|reminder|call|shopping|expense|follow_up|plan"
    }
  ],

  // Optional grouped views (populate if naturally fits; otherwise []):
  "reminders": [],
  "calls": [],
  "expenses": [],
  "outings": [],
  "notes": [],
  "people": ["Distinct proper names mentioned"],
  "places": ["Distinct places/venues mentioned"],
  "shopping_list": ["Items to buy if no price/amount given"],
  "follow_ups": ["Non-call follow-ups (email/text/check-in)"],

  "unresolved": ["Ambiguities needing confirmation"],
  "confidence": 0.9
}

Coverage-first extraction for long transcripts (1+ minute):
- PASS 1 — Segment by sentences/clauses; ignore fillers (um, like, you know) but DO NOT drop meaningful content.
- PASS 2 — Harvest EVERYTHING: plans (do/buy/go/call/meet/book/check/send/pay/renew/return), facts (“I finished …”), thoughts/feelings, questions, ideas, places, people, amounts.
- PASS 3 — For each clause, create one entry in "entries" with an appropriate "type". Keep it even if non-actionable (use "note", "thought", "fact", or "question").
- PASS 4 — Categorize (optional arrays): If a clause clearly matches a category (call/expense/outing/reminder), also mirror it into that array. Prefer recall over precision.
- PASS 5 — Normalize safely: fix obvious ASR errors; extract numeric amounts; infer currency only when clearly indicated by symbol/locale; Title Case proper names.
- PASS 6 — Evidence: include a short "source_phrases" array with the snippet(s) that justify each entry.
- PASS 7 — Deduplicate but preserve: merge near-duplicates while keeping all snippets in "source_phrases".
- PASS 8 — Order: keep "entries" in the order mentioned by the user.

Rules:
1) Do NOT resolve or invent dates/times. Keep phrases exactly as spoken; if none, use "" for date/time fields.
2) Do NOT infer MODE. Use "${mode}" exactly as provided.
3) RECORD EVERYTHING said (actionable or not). Prefer more entries over fewer.
4) Mirror actionable clauses into the top-level "tasks" array. If none are actionable, set "tasks": [].
5) Do not invent completion; set "completed": true only if the user explicitly said it's done.
6) Keep strings terse and scannable; "what_was_said" may use 1–2 sentences.
7) No hallucinations. Missing key info → add a brief item in "unresolved".
8) Return ONLY valid JSON (no markdown or commentary).
9) Confidence 0–1 reflects certainty of extraction and categorization.

TRANSCRIPT: "${transcript.replaceAll('"', '\\"')}"
''';

  /// Improved JSON extraction that handles nested braces properly
  String _extractJson(String s) {
    // Remove triple backtick fences if present
    final fenced = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```', multiLine: true);
    final fencedMatch = fenced.firstMatch(s);
    if (fencedMatch != null) {
      final content = fencedMatch.group(1)!.trim();
      return _findCompleteJsonObject(content);
    }

    // Try to find a complete JSON object
    return _findCompleteJsonObject(s);
  }

  /// Finds the first complete JSON object by counting braces
  String _findCompleteJsonObject(String s) {
    final trimmed = s.trim();

    // Find the first opening brace
    final start = trimmed.indexOf('{');
    if (start == -1) {
      throw FormatException('No JSON object found in response');
    }

    // Count braces to find the matching closing brace
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

    if (end == -1) {
      throw FormatException('Incomplete JSON object in response');
    }

    return trimmed.substring(start, end + 1);
  }
}
