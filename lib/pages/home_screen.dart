import 'package:day_loop/ai/day_loop_service.dart'; // Gemini service
import 'package:day_loop/services/language_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../l10n/app_localizations.dart';
import '../widgets/journey_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final SpeechToText _speech = SpeechToText();

  bool _speechReady = false;
  String _lastWords = '';
  bool _isProcessingTranscript = false; // Prevent duplicate processing

  // Animation variables
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _initSpeech();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _animation = Tween<double>(begin: 1.0, end: 1.2)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _speech.stop();
    _speech.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    _speechReady = await _speech.initialize(onStatus: _onStatus);
    if (mounted) setState(() {});
  }

  void _onStatus(String status) {
    debugPrint('Speech status: $status');

    // Automatically process transcript when speech recognition finishes
    if (status == 'done' && _lastWords.trim().isNotEmpty && !_isProcessingTranscript) {
      debugPrint('DL> Speech done, auto-calling _stopListening');
      _processTranscript();
    } else if (status == 'notListening') {
      // Stop animation when not listening
      if (mounted) {
        setState(() {});
        _controller.stop();
      }
    }
  }

  Future<void> _startListening() async {
    _lastWords = '';
    _isProcessingTranscript = false;

    debugPrint('DL> Starting to listen...');

    final langSvc = context.read<LanguageService>();
    final localeId = _localeFor(langSvc.currentLanguage);

    await _speech.listen(
      onResult: _onSpeechResult,
      localeId: localeId,
      listenMode: ListenMode.dictation,
      partialResults: true,
      pauseFor: const Duration(seconds: 3), // Auto-stop after 3 seconds of silence
      listenFor: const Duration(seconds: 60), // Maximum 60 seconds
    );

    if (mounted) {
      setState(() {});
      _controller.repeat(reverse: true); // Start the pulsing animation
    }
  }

  /// STOP RECORDING (Manual):
  /// - stop mic + pulse, transcript will be processed via _onStatus callback
  Future<void> _stopListening() async {
    debugPrint('DL> Manual stop listening called');
    await _speech.stop();
    if (mounted) {
      setState(() {});
      _controller.stop();
    }
    // Don't process transcript here - let _onStatus handle it to avoid duplication
  }

  /// PROCESS TRANSCRIPT:
  /// - send _lastWords to Gemini
  /// - publish results to JourneyState so the card updates
  String apiKey = dotenv.env['API_KEY']!;

  Future<void> _processTranscript() async {
    if (_isProcessingTranscript) {
      debugPrint('DL> Already processing transcript, skipping...');
      return;
    }

    _isProcessingTranscript = true;

    final transcript = _lastWords.trim();
    debugPrint('DL> transcript="$transcript"');
    if (transcript.isEmpty) {
      debugPrint('DL> transcript empty, skipping Gemini');
      _isProcessingTranscript = false;
      return;
    }

    final mode = DateTime.now().hour < 12 ? 'morning_brief' : 'evening_debrief';
    final langSvc = context.read<LanguageService>();
    final locale = _localeFor(langSvc.currentLanguage);

    debugPrint('DL> About to call Gemini...');

    final j = JourneyState.instance;
    j.loading.value = true;
    j.error.value = null;

    try {
      debugPrint('DL> calling Gemini… mode=$mode locale=$locale');
      final svc = DayLoopService(apiKey);

      debugPrint('DL> DayLoopService created, calling parseTranscript...');

      final parsed = await svc.parseTranscript(
        transcript: transcript,
        mode: mode,
        locale: locale,
      );
      debugPrint('DL> Gemini parsed JSON: $parsed');

      final currentData = j.data.value;
      if (currentData != null) {
        // Correct append logic: Merge new data with existing data
        final Map<String, dynamic> combinedData = Map.from(currentData);

        parsed.forEach((key, value) {
          if (combinedData.containsKey(key)) {
            // Add a type check to handle cases where the value might not be a List
            if (combinedData[key] is List) {
              final existingTasks = List.from(combinedData[key]);
              final newTasks = List.from(value);
              existingTasks.addAll(newTasks);
              combinedData[key] = existingTasks;
            } else {
              // If the existing data is not a List, replace it with the new List
              combinedData[key] = value;
            }
          } else {
            // If the category is new, add it
            combinedData[key] = value;
          }
        });
        j.data.value = combinedData;
      } else {
        // If no data exists, set the new data
        j.data.value = parsed;
      }
    } catch (e, st) {
      debugPrint('DL> Gemini error: $e\n$st');
      j.error.value = e is FormatException
          ? 'Could not process your recording. Please try again.'
          : 'Something went wrong. Please try again.';
    } finally {
      j.loading.value = false;
      _isProcessingTranscript = false;
      debugPrint('DL> Finally block executed');
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    _lastWords = result.recognizedWords;
    debugPrint('Recognized: $_lastWords');
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final timeOfDayText = (DateTime.now().hour < 12) ? l10n.morning : l10n.evening;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Text(
              l10n.appTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    SizedBox(
                      height: 400, // Fixed height in logical pixels
                      child: JourneyCard(
                        title: '${l10n.todayJourney} - $timeOfDayText',
                        todayDateLabel: l10n.todayDate,
                        dayStreakLabel: l10n.dayStreak,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: AnimatedBuilder(
                              animation: _animation,
                              builder: (context, child) {
                                return ElevatedButton(
                                  onPressed: !_speechReady
                                      ? null
                                      : (_speech.isNotListening
                                      ? _startListening
                                      : _stopListening),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: AnimatedBuilder(
                                    animation: _animation,
                                    builder: (context, child) {
                                      return Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 80,
                                            height: 40,
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                if (_speech.isListening)
                                                  Container(
                                                    width: 24 * 3 + (24 * _animation.value * 2),
                                                    height: 24 * 3 + (24 * _animation.value * 2),
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: Colors.white.withOpacity(
                                                        0.1 + (_animation.value - 1.0) * 0.5,
                                                      ),
                                                    ),
                                                  ),
                                                Icon(
                                                  _speech.isListening
                                                      ? Icons.mic_off
                                                      : Icons.mic,
                                                  color: Colors.white,
                                                  size: 24,
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            _speech.isListening
                                                ? l10n.stopRecordingButton
                                                : l10n.recordJourneyButton,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
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
    );
  }
}

class JourneyState {
  JourneyState._();
  static final instance = JourneyState._();

  final data = ValueNotifier<Map<String, dynamic>?>(null);
  final loading = ValueNotifier<bool>(false);
  final error = ValueNotifier<String?>(null);

  void reset() {
    data.value = null;
    loading.value = false;
    error.value = null;
  }
}