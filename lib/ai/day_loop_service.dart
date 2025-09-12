import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class DayLoopService {
  DayLoopService(this.apiKey)
      : _model = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: apiKey,
    generationConfig:  GenerationConfig(
      temperature: 0.2,
      responseMimeType: 'application/json',
      maxOutputTokens: 2048,
    ),
  );

  final String apiKey;
  final GenerativeModel _model;

  Future<Map<String, dynamic>> parseTranscript({
    required String transcript,
    required String mode,
    String locale = 'en-US',
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final prompt = _buildPrompt(
      transcript: transcript,
      mode: mode,
      locale: locale,
    );

    try {
      final resp = await _model.generateContent([Content.text(prompt)]).timeout(timeout);
      debugPrint('DL> Got response from Gemini: ${resp.text?.substring(0, 100)}...');

      if (resp.promptFeedback != null && resp.candidates.isEmpty) {
        throw StateError('Gemini blocked the prompt: ${resp.promptFeedback}');
      }
      if (resp.candidates.isEmpty || resp.text == null) {
        throw StateError('Gemini returned no content');
      }

      final raw = resp.text!.trim();
      if (kDebugMode) debugPrint('Gemini raw response:\n$raw');

      final jsonStr = _extractJson(raw);
      if (kDebugMode) debugPrint('Gemini extracted JSON:\n$jsonStr');

      final decoded = jsonDecode(jsonStr);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid JSON');
      }
      return decoded;
    } on TimeoutException {
      throw StateError('Request timed out after ${timeout.inSeconds} seconds');
    }
  }

  String _buildPrompt({
    required String transcript,
    required String mode,
    required String locale,
  }) =>
      '''
Role:
You are the intelligence behind Day Loop. Parse the transcript and output STRICT JSON capturing EVERYTHING (actions, plans, purchases, calls, places, people, ideas, questions, reflections).

Inputs:
- TRANSCRIPT: raw speech-to-text (may be long and rambly).
- MODE: "$mode"
- USER_LOCALE: $locale (currency/number hints)

Output (strict JSON):
{
  "headline": "≤60 chars - short summary",
  "what_was_said": "1–2 sentence summary",
  "mode": "$mode",
  "intent": "Main purpose",
  "entries": [
    {
      "type": "plan|outing|action|...",
      "text": "Concise restatement",
      "lemmas": ["eat","lunch"],   // ✅ NEW: base forms of important words
      "date_phrase": "",
      "time_phrase": "",
      "entities": { "people": [], "places": [], "items": [] },
      "status": "planned|done|said",
      "source_phrases": ["snippet(s)"]
    }
  ],
  "tasks": [
    { "text": "Actionable item", "completed": false, "type": "plan", "emoji": "🏫" }
  ],
  "completed_phrases": [],
  "completed_to_task_matches": [],
  "unresolved": [],
  "confidence": 0.9
}

Rules:
1) ALWAYS fill "lemmas" with the base/dictionary forms of the important words from "text".
2) Do NOT invent dates/times; keep as spoken or empty.
3) Use MODE exactly as provided.
4) Record EVERYTHING; prefer recall over precision.
5) Mirror actionable clauses into "tasks". If none, "tasks": [].
6) Mark a task "completed": true ONLY when the user clearly indicates completion — including past-tense statements like "watched the movie", "called Ahmed", "paid the bill". Also add a concise phrase to "completed_phrases". When obvious, add {"phrase": "...", "task_text_match": "..."} to "completed_to_task_matches".
7) Keep strings terse. Include evidence in "source_phrases".
8) No hallucinations; put gaps in "unresolved".
9) Return ONLY valid JSON (no commentary).
10) Confidence is 0–1.
11) All generated text must be in the language of the TRANSCRIPT.
12) Provide one emoji per task in "emoji".

TRANSCRIPT: "${transcript.replaceAll('"', '\\"')}"
''';

  String _extractJson(String s) {
    final fenced = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```', multiLine: true);
    final match = fenced.firstMatch(s);
    return match != null ? _findCompleteJsonObject(match.group(1)!.trim()) : _findCompleteJsonObject(s);
  }

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
