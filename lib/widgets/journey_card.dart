// journey_card.dart
import 'package:flutter/material.dart';

import '../pages/home_screen.dart';

class JourneyCard extends StatelessWidget {
  const JourneyCard({
    super.key,
    required this.title,
    required this.todayDateLabel,
    required this.dayStreakLabel,
  });

  final String title;
  final String todayDateLabel;
  final String dayStreakLabel;

  @override
  Widget build(BuildContext context) {
    final j = JourneyState.instance;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // This section is part of the non-scrollable header
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),

          // The scrollable content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ValueListenableBuilder<bool>(
                    valueListenable: j.loading,
                    builder: (context, loading, _) {
                      if (loading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return ValueListenableBuilder<String?>(
                        valueListenable: j.error,
                        builder: (context, error, __) {
                          if (error != null) {
                            return Text('Error: $error',
                                style: const TextStyle(color: Colors.redAccent));
                          }
                          return ValueListenableBuilder<Map<String, dynamic>?>(
                            valueListenable: j.data,
                            builder: (context, data, ___) {
                              if (data == null) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.mic, size: 48, color: Color(0xFFFF5722)),
                                        SizedBox(height: 16),
                                        Text(
                                          "Your journey starts here!",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          "Tap the microphone below and start talking to add your first task.",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Color(0xFFAAAAAA),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              return _EntriesSection(data: data); // Pass the data to the stateful widget
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // The fixed bottom section
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.only(top: 20),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFF333333), width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  todayDateLabel,
                  style: const TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 14,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5722),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    dayStreakLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskItem extends StatelessWidget {
  const _TaskItem(this.emoji, this.text);

  final String emoji;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _EntriesSection extends StatefulWidget {
  const _EntriesSection({required this.data});
  final Map<String, dynamic> data;

  @override
  State<_EntriesSection> createState() => _EntriesSectionState();
}

class _EntriesSectionState extends State<_EntriesSection> {
  late List<Map<String, dynamic>> _entries;
  late List<Map<String, dynamic>> _tasks;

  @override
  void initState() {
    super.initState();
    _entries = (widget.data['entries'] is List)
        ? (widget.data['entries'] as List)
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList()
        : const <Map<String, dynamic>>[];

    _tasks = (widget.data['tasks'] is List)
        ? (widget.data['tasks'] as List)
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList()
        : const <Map<String, dynamic>>[];
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _tasks.removeAt(oldIndex);
      _tasks.insert(newIndex, item);
    });
  }

  void _toggleTaskCompletion(int index) {
    setState(() {
      final task = _tasks[index];
      task['completed'] = !(task['completed'] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Check if there are tasks to display
    if (_tasks.isNotEmpty) {
      return ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _tasks.length,
        onReorder: _onReorder,
        proxyDecorator: (Widget child, int index, Animation<double> anim) {
          return AnimatedBuilder(
            animation: anim,
            builder: (context, _) {
              final t = Curves.easeInOut.transform(anim.value);
              return Transform.scale(
                scale: 1.0 + 0.02 * t,
                child: Material(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                  elevation: 8,
                  child: child,
                ),
              );
            },
          );
        },
        itemBuilder: (context, index) {
          final task = _tasks[index];
          final bool isCompleted = task['completed'] ?? false;
          final text = (task['text'] ?? '').toString();

          return Container(
            key: ValueKey(task), // required for ReorderableListView
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1) Checkbox
                Checkbox(
                  value: isCompleted,
                  onChanged: (_) => _toggleTaskCompletion(index),
                  fillColor: MaterialStateProperty.resolveWith<Color?>(
                        (states) {
                      if (states.contains(MaterialState.selected)) {
                        return const Color(0xFFFF5722); // orange when checked
                      }
                      return null; // use default (theme) when unchecked
                    },
                  ),
                  checkColor: Colors.white, // color of the check icon
                ),

                // 2) Emoji (fixed width so things don't jump)
                SizedBox(
                  width: 24,
                  child: Text(
                    _emojiFor((task['type'] ?? 'action').toString(), text),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(width: 8),

                // 3) Task text
                Expanded(
                  child: Text(
                    text.isEmpty ? '(Untitled task)' : text,
                    style: TextStyle(
                      color: isCompleted ? const Color(0xFF888888) : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                    ),
                  ),
                ),

                // 4) Drag handle (keeps drag separate from checkbox/text taps)
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.drag_handle, color: Color(0xFFAAAAAA)),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    // If no tasks, check for entries
    if (_entries.isNotEmpty) {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _entries.length,
        separatorBuilder: (_, __) => const Divider(color: Color(0xFF333333), height: 20),
        itemBuilder: (_, i) => _entryTile(_entries[i]),
      );
    }

    // Fallback if neither tasks nor entries exist
    return const SizedBox.shrink();
  }

  static Widget _entryTile(Map<String, dynamic> e) {
    final type = (e['type'] ?? 'note').toString();
    final text = (e['text'] ?? '').toString();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2, right: 8),
          child: Text(
            _emojiFor(type, text),
            style: const TextStyle(fontSize: 18),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text.isEmpty ? '—' : text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _emojiFor(String type, String text) {
    final s = (text).toLowerCase().trim();

    final place = _placeEmojiFor(s);
    if (place != null) return place;

    if (_hasAny(s, ['call', 'phone', 'dial', 'ring'])) return '📞';
    if (_hasAny(s, ['email', 'e-mail', 'mail', 'inbox'])) return '📧';
    if (_hasAny(s, ['text ', 'dm ', 'message', 'whatsapp', 'im '])) return '💬';

    if (_hasAny(s, ['meet', 'meeting', 'catch up', 'appointment'])) return '🤝';
    if (_hasAny(s, ['remind', 'reminder', 'nudge'])) return '⏰';
    if (_hasAny(s, ['calendar', 'schedule', 'book', 'reserve'])) return '📅';

    if (_hasAny(s, ['buy', 'purchase', 'order', 'shop', 'checkout'])) return '🛒';
    if (_hasAny(s, ['pay', 'bill', 'invoice', 'rent', 'subscription'])) return '💳';
    if (_hasAny(s, ['\$', '€', '£', '₹'])) return '💸';

    if (_hasAny(s, ['coffee', 'latte', 'espresso', 'cappuccino'])) return '☕';
    if (_hasAny(s, ['tea', 'matcha', 'chai'])) return '🫖';
    if (_hasAny(s, ['breakfast', 'lunch', 'dinner', 'eat', 'meal'])) return '🍽️';
    if (_hasAny(s, ['grocer', 'supermarket'])) return '🧺';
    if (_hasAny(s, ['water', 'juice', 'soda', 'drink'])) return '🥤';

    if (_hasAny(s, ['run', 'jog', 'workout', 'gym', 'weights'])) return '🏋️';
    if (_hasAny(s, ['walk', 'steps', 'hike'])) return '🚶';
    if (_hasAny(s, ['yoga', 'meditate', 'stretch'])) return '🧘';

    if (_hasAny(s, ['doctor', 'dentist', 'clinic', 'hospital'])) return '🩺';
    if (_hasAny(s, ['medicine', 'pill', 'vitamin'])) return '💊';
    if (_hasAny(s, ['sleep', 'nap', 'rest'])) return '🛌';

    if (_hasAny(s, ['travel', 'trip', 'vacation', 'holiday'])) return '✈️';
    if (_hasAny(s, ['flight', 'airport'])) return '🛫';
    if (_hasAny(s, ['train', 'metro', 'subway'])) return '🚆';
    if (_hasAny(s, ['bus'])) return '🚌';
    if (_hasAny(s, ['drive', 'car', 'uber', 'lyft'])) return '🚗';
    if (_hasAny(s, ['bike', 'bicycle'])) return '🚲';

    if (_hasAny(s, ['work', 'project', 'deadline', 'presentation'])) return '💼';
    if (_hasAny(s, ['study', 'course', 'class', 'homework', 'lecture'])) return '📚';
    if (_hasAny(s, ['code', 'bug', 'deploy', 'commit'])) return '💻';

    if (_hasAny(s, ['book', 'read'])) return '📖';
    if (_hasAny(s, ['music', 'song', 'playlist'])) return '🎵';
    if (_hasAny(s, ['movie', 'film', 'cinema'])) return '🎬';
    if (_hasAny(s, ['photo', 'camera', 'shoot'])) return '📸';

    if (_hasAny(s, ['birthday', 'anniversary', 'party', 'celebrate'])) return '🥳';
    if (_hasAny(s, ['gift', 'present'])) return '🎁';

    if (_hasAny(s, ['friend', 'mom', 'dad', 'wife', 'husband', 'team'])) return '👥';

    if (_hasAny(s, ['dog', 'puppy'])) return '🐶';
    if (_hasAny(s, ['cat', 'kitten'])) return '🐱';

    if (_hasAny(s, ['weather', 'sunny', 'rain', 'storm', 'snow'])) return '🌦️';

    if (_hasAny(s, ['think', 'thought', 'reflect'])) return '🤔';
    if (_hasAny(s, ['grateful', 'thanks', 'gratitude'])) return '🙏';
    if (_hasAny(s, ['question', '?'])) return '❓';
    if (_hasAny(s, ['warning', 'issue', 'problem', 'risk'])) return '⚠️';

    return _iconFor(type);
  }

  static String? _placeEmojiFor(String s) {
    if (_hasAny(s, ['home', 'house', 'apartment', 'flat'])) return '🏠';
    if (_hasAny(s, ['office', 'workplace', 'hq', 'headquarters'])) return '🏢';

    if (_hasAny(s, ['school', 'college', 'university', 'campus', 'classroom'])) return '🏫';
    if (_hasAny(s, ['library'])) return '📚';

    if (_hasAny(s, ['hospital', 'clinic', 'er', 'emergency'])) return '🏥';
    if (_hasAny(s, ['pharmacy', 'drugstore'])) return '💊';
    if (_hasAny(s, ['dentist', 'dental'])) return '🦷';

    if (_hasAny(s, ['bank', 'atm'])) return '🏦';
    if (_hasAny(s, ['post office', 'post-office', 'shipping center'])) return '📮';

    if (_hasAny(s, ['cafe', 'coffee shop', 'starbucks'])) return '☕';
    if (_hasAny(s, ['restaurant', 'diner', 'bistro', 'pizzeria', 'sushi'])) return '🍽️';
    if (_hasAny(s, ['bar', 'pub', 'tavern'])) return '🍺';
    if (_hasAny(s, ['bakery'])) return '🥐';

    if (_hasAny(s, ['supermarket', 'grocery', 'market'])) return '🛒';
    if (_hasAny(s, ['mall', 'shopping mall'])) return '🏬';
    if (_hasAny(s, ['convenience store', 'corner shop', 'bodega'])) return '🏪';

    if (_hasAny(s, ['airport', 'terminal'])) return '🛫';
    if (_hasAny(s, ['station', 'train station'])) return '🚉';
    if (_hasAny(s, ['subway', 'metro', 'underground'])) return '🚇';
    if (_hasAny(s, ['bus station', 'bus stop'])) return '🚌';
    if (_hasAny(s, ['gas station', 'petrol station'])) return '⛽';
    if (_hasAny(s, ['parking', 'car park', 'garage'])) return '🅿️';

    if (_hasAny(s, ['park', 'playground'])) return '🌳';
    if (_hasAny(s, ['beach', 'seaside'])) return '🏖️';
    if (_hasAny(s, ['museum', 'gallery'])) return '🖼️';
    if (_hasAny(s, ['theatre', 'theater'])) return '🎭';
    if (_hasAny(s, ['stadium', 'arena'])) return '🏟️';
    if (_hasAny(s, ['hotel'])) return '🏨';
    if (_hasAny(s, ['gym', 'fitness center'])) return '🏋️';
    if (_hasAny(s, ['spa', 'salon', 'barbershop', 'barber'])) return '💇‍♂️';

    if (_hasAny(s, ['mosque'])) return '🕌';
    if (_hasAny(s, ['church', 'cathedral'])) return '⛪';
    if (_hasAny(s, ['temple'])) return '🛕';
    if (_hasAny(s, ['synagogue'])) return '🕍';
    if (_hasAny(s, ['courthouse', 'court'])) return '⚖️';
    if (_hasAny(s, ['police', 'station police'])) return '🚓';
    if (_hasAny(s, ['embassy', 'consulate'])) return '🏛️';

    if (_hasAny(s, ['mountain', 'trail'])) return '⛰️';
    if (_hasAny(s, ['river', 'lake'])) return '🏞️';
    if (_hasAny(s, ['zoo'])) return '🦁';

    return null;
  }

  static bool _hasAny(String s, List<String> kws) {
    for (final k in kws) {
      if (s.contains(k)) return true;
    }
    return false;
  }

  static String _iconFor(String type) {
    switch (type) {
      case 'call':
        return '📞';
      case 'shopping':
        return '🛒';
      case 'expense':
        return '💸';
      case 'outing':
        return '📍';
      case 'reminder':
        return '⏰';
      case 'plan':
      case 'action':
        return '✅';
      case 'idea':
        return '💡';
      case 'question':
        return '❓';
      case 'gratitude':
        return '🙏';
      case 'habit':
        return '🔁';
      case 'memory':
        return '🧠';
      case 'follow_up':
        return '📩';
      case 'note':
        return '📝';
      case 'fact':
        return 'ℹ️';
      case 'thought':
        return '🤔';
      case 'event':
        return '🎉';
      case 'appointment':
        return '📅';
      case 'travel':
        return '✈️';
      case 'work':
        return '💼';
      case 'study':
        return '📚';
      case 'exercise':
        return '🏋️';
      case 'food':
        return '🍽️';
      case 'drink':
        return '☕';
      case 'health':
        return '❤️';
      case 'sleep':
        return '🛌';
      case 'music':
        return '🎵';
      case 'movie':
        return '🎬';
      case 'book':
        return '📖';
      case 'gift':
        return '🎁';
      case 'celebration':
        return '🥳';
      case 'meeting':
        return '🤝';
      case 'cleaning':
        return '🧹';
      case 'shopping_list':
        return '🛍️';
      case 'transport':
        return '🚗';
      case 'home':
        return '🏠';
      case 'tech':
        return '💻';
      case 'finance':
        return '💰';
      case 'unresolved':
        return '⚠️';
      default:
        return '•';
    }
  }
}