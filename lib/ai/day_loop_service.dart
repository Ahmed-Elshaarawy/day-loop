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

      // Validate required fields exist
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

  String _buildPrompt({
    required String transcript,
    required String mode,
    required String locale,
  }) =>
      '''
Role:
You are the intelligence behind Day Loop, an app where users speak freely and the app turns the transcript into structured, actionable data. Day Loop itself detects whether the entry is a morning brief (plans) or an evening debrief (what happened) based on local time.
Your job: parse the transcript and output clean JSON with reminders, tasks, calls, expenses, outings, notes, and ambiguities. Do not create flash cards; do not resolve or insert dates/times.

Inputs provided by the app:
- TRANSCRIPT: raw speech-to-text.
- MODE: "${mode}" (the app decides this; do not infer).
- USER_LOCALE: ${locale} for currency/number parsing hints.

Output (strict JSON only):

{
  "headline": "≤60 chars — short summary of the entry",
  "what_was_said": "1–2 sentences summarizing the transcript",
  "mode": "${mode}",
  "intent": "Main purpose in one sentence",
  "reminders": [
    {"text": "…", "date_phrase": "…", "time_phrase": "…", "assignee": "me|name", "context": "…"}
  ],
  "tasks": [
    {"text": "…", "due_date_phrase": "…", "due_time_phrase": "…", "priority": "low|med|high", "context": "…"}
  ],
  "calls": [
    {"who": "Name/Org", "topic": "…", "date_phrase": "…", "time_phrase": "…"}
  ],
  "expenses": [
    {"amount": 0, "currency": "USD", "category": "groceries|transport|food|…", "merchant": "…", "date_phrase": "…", "time_phrase": "…", "note": "…"}
  ],
  "outings": [
    {"what": "dinner|meeting|…", "with": ["Name"], "where": "…", "date_phrase": "…", "start_time_phrase": "…"}
  ],
  "notes": ["Other brief items not covered above"],
  "unresolved": ["Ambiguities needing confirmation"],
  "confidence": 0.85
}

Rules:
1. Do not resolve or invent dates/times. Keep phrases exactly as spoken (e.g., "tomorrow", "at 7", "next Friday"). If no time was spoken, leave the relevant fields as "".
2. Use the exact MODE value provided: "${mode}".
3. Classify cleanly & atomically. Split compound statements into separate items; keep text terse.
4. Safe normalization only. Fix obvious ASR mistakes; extract numeric amount; infer currency only when clearly indicated by symbol/locale.
5. No hallucinations. If key info (who/when/amount) is missing, add a brief entry in unresolved.
6. Deduplicate within the same entry. Prefer the most complete phrasing.
7. Return ONLY valid JSON - no extra text, explanations, or markdown formatting.
8. Confidence: 0–1 reflecting certainty of extraction and categorization.

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