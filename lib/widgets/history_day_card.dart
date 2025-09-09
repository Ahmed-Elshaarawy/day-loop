import 'package:flutter/material.dart';
import '../task.dart';
import '../l10n/app_localizations.dart';

class HistoryDayCard extends StatelessWidget {
  const HistoryDayCard({
    super.key,
    required this.day,   // local date at midnight
    required this.tasks, // all tasks for that day
    this.onTap,          // open details page
  });

  final DateTime day;
  final List<Task> tasks;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = MaterialLocalizations.of(context);
    final l10n = AppLocalizations.of(context)!;

    final isToday = _sameDay(day, DateTime.now());
    final fullDate = l.formatFullDate(day);
    final title = isToday ? l10n.todayWithDate(fullDate) : fullDate;

    // show only first two tasks in the card
    final preview = tasks.length <= 2 ? tasks : tasks.take(2).toList();
    final moreCount = tasks.length > 2 ? (tasks.length - 2) : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Material(
        color: Colors.transparent,
        elevation: 10,
        shadowColor: Colors.black.withOpacity(.55),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              constraints: const BoxConstraints(minHeight: 96),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF232323), Color(0xFF151515)],
                ),
                border: Border.all(color: Colors.white.withOpacity(.06), width: 1),
              ),
              child: Stack(
                children: [
                  // Subtle glossy highlight
                  Positioned(
                    top: -36,
                    left: -30,
                    child: IgnorePointer(
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withOpacity(.06),
                              Colors.transparent
                            ],
                            radius: .9,
                          ),
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title = date
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .2,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // hairline divider
                        Opacity(
                          opacity: .6,
                          child: Container(
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(.06),
                                  Colors.white.withOpacity(.02),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // First two tasks — emoji + text (no background, no handle)
                        ...preview.map((t) => _taskRowJournalStyle(context, t)).toList(),

                        if (moreCount > 0) ...[
                          const SizedBox(height: 10),
                          InkWell(
                            onTap: onTap, // make "View all" tappable
                            borderRadius: BorderRadius.circular(8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  l10n.viewAllCount(tasks.length),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(.85),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.chevron_right,
                                  size: 18,
                                  color: Colors.white.withOpacity(.85),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Journal-style row: plain emoji + text (no checkbox, no time, no handle) ---
  Widget _taskRowJournalStyle(BuildContext context, Task t) {
    final l10n = AppLocalizations.of(context)!;

    final title = t.title.trim();
    final emoji = _leadingEmojiFromTitle(title) ?? '•';
    final text = _titleWithoutLeadingEmoji(title);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Plain emoji (no background)
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),

          // Task text (single line)
          Expanded(
            child: Text(
              text.isEmpty ? l10n.untitledTask : text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- emoji helpers (no guessing) ---

  String? _leadingEmojiFromTitle(String s) {
    final trimmed = s.trimLeft();
    if (trimmed.isEmpty) return null;

    final it = trimmed.runes.iterator;
    if (!it.moveNext()) return null;
    final firstRune = it.current;

    return _isEmojiRune(firstRune) ? String.fromCharCode(firstRune) : null;
  }

  String _titleWithoutLeadingEmoji(String s) {
    final trimmed = s.trimLeft();
    if (trimmed.isEmpty) return s;

    final it = trimmed.runes.iterator;
    if (!it.moveNext()) return s;

    final firstRune = it.current;
    if (_isEmojiRune(firstRune)) {
      final emojiChar = String.fromCharCode(firstRune);
      if (trimmed.startsWith(emojiChar)) {
        return trimmed.substring(emojiChar.length).trimLeft();
      }
    }
    return s;
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isEmojiRune(int r) {
    // Common emoji blocks
    return (r >= 0x1F300 && r <= 0x1FAFF) || // Symbols & pictographs
        (r >= 0x1F900 && r <= 0x1F9FF) || // Supplemental symbols
        (r >= 0x2600  && r <= 0x26FF)  || // Misc symbols
        (r >= 0x2700  && r <= 0x27BF);    // Dingbats
  }
}
