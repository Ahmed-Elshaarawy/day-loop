import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/journey_controller.dart';
import '../controllers/speech_controller.dart';
import '../l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;

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
          // Header with inline spinner during Gemini parsing
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Consumer<SpeechController>(
                builder: (_, sc, __) => AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  transitionBuilder: (child, anim) =>
                      FadeTransition(opacity: anim, child: child),
                  child: sc.busy
                      ? const SizedBox(
                          key: ValueKey('card-busy'),
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFFF5722),
                          ),
                        )
                      : const SizedBox(key: ValueKey('card-idle')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Expanded(
            child: Consumer<JourneyController>(
              builder: (context, c, _) {
                switch (c.status) {
                  case JourneyStatus.loading:
                    return const Center(child: CircularProgressIndicator());
                  case JourneyStatus.error:
                    return Text(
                      'Error: ${c.error}',
                      style: const TextStyle(color: Colors.redAccent),
                    );
                  case JourneyStatus.idle:
                    if (c.tasks.isEmpty) return _EmptyState(l10n: l10n);
                    return const _TaskList();
                }
              },
            ),
          ),

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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mic, size: 48, color: Color(0xFFFF5722)),
            const SizedBox(height: 16),
            Text(
              l10n.emptyStateTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.emptyStateSubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskList extends StatelessWidget {
  const _TaskList();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<JourneyController>();
    final tasks = c.tasks;

    return ReorderableListView.builder(
      padding: EdgeInsets.zero,
      itemCount: tasks.length,
      onReorder: c.reorder,
      proxyDecorator: (child, index, anim) {
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
        final t = tasks[index];
        return Container(
          key: ValueKey('${t.id ?? t.title}-${t.createdAt}'),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Checkbox(
                value: t.completed,
                onChanged: (_) => c.toggleCompleted(index),
                fillColor: MaterialStateProperty.resolveWith(
                  (states) => states.contains(MaterialState.selected)
                      ? const Color(0xFFFF5722)
                      : null,
                ),
                checkColor: Colors.white,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t.title.isEmpty ? '(Untitled task)' : t.title,
                  style: TextStyle(
                    color: t.completed ? const Color(0xFF888888) : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    decoration: t.completed
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Remove',
                icon: const Icon(
                  Icons.delete_outline,
                  color: Color(0xFFAAAAAA),
                ),
                onPressed: () => c.removeAt(index),
              ),
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
}
