import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/speech_controller.dart';

/// Reusable pulsing mic button.
class RecordButton extends StatefulWidget {
  const RecordButton({
    super.key,
    required this.labelIdle,
    required this.labelActive,
  });

  final String labelIdle;
  final String labelActive;

  @override
  State<RecordButton> createState() => _RecordButtonState();
}

class _RecordButtonState extends State<RecordButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(begin: 1.0, end: 1.2)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SpeechController>(
      builder: (context, ctrl, _) {
        // Start/stop pulse based on listening state.
        if (ctrl.isListening) {
          if (!_controller.isAnimating) _controller.repeat(reverse: true);
        } else {
          if (_controller.isAnimating) _controller.stop();
        }

        return Container(
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: ElevatedButton(
            onPressed: !ctrl.speechReady
                ? null
                : (ctrl.isListening ? ctrl.stopListening : ctrl.startListening),
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
                          if (ctrl.isListening)
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
                            ctrl.isListening ? Icons.mic_off : Icons.mic,
                            color: Colors.white,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      ctrl.isListening ? widget.labelActive : widget.labelIdle,
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
          ),
        );
      },
    );
  }
}
