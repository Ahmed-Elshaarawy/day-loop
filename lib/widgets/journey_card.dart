import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../journey_state.dart';
import '../l10n/app_localizations.dart';

import '../repositories/task_repository.dart';

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
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),

          // scrollable content
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
                            return Text(
                              'Error: $error',
                              style: const TextStyle(color: Colors.redAccent),
                            );
                          }
                          return ValueListenableBuilder<Map<String, dynamic>?>(
                            valueListenable: j.data,
                            builder: (context, data, ___) {
                              final tasks = _extractTasks(data);
                              if (data == null || tasks.isEmpty) {
                                return _emptyState(l10n);
                              }
                              return _EntriesSection(data: data);
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
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

  static List<Map<String, dynamic>> _extractTasks(Map<String, dynamic>? data) {
    if (data == null) return const [];
    final raw = data['tasks'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Widget _emptyState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
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
              style: const TextStyle(
                color: Color(0xFFAAAAAA),
                fontSize: 14,
              ),
            ),
          ],
        ),
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
  late List<Map<String, dynamic>> _tasks;

  @override
  void initState() {
    super.initState();
    _tasks = _extractTasks(widget.data);
  }

  @override
  void didUpdateWidget(covariant _EntriesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.data, widget.data)) {
      setState(() {
        _tasks = _extractTasks(widget.data);
      });
    }
  }

  List<Map<String, dynamic>> _extractTasks(Map<String, dynamic> data) {
    final raw = data['tasks'];
    if (raw is! List) return <Map<String, dynamic>>[];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _tasks.removeAt(oldIndex);
      _tasks.insert(newIndex, item);
      _syncJourneyState();
    });
  }

  // ✅ Persist completion by DB id (taskId). Attach id once if missing.
  Future<void> _toggleTaskCompletion(int index) async {
    setState(() {
      final task = _tasks[index];
      task['completed'] = !(task['completed'] ?? false);
      _syncJourneyState();
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final repo = context.read<TaskRepository>();

      String? id = _tasks[index]['taskId'] as String?;
      if (id == null || id.isEmpty) {
        id = await _attachTaskIdIfMissing(index);
        if (id == null) return;
      }

      final isDone = (_tasks[index]['completed'] == true);
      await repo.setTaskDone(id, isDone);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Couldn’t save status: $e')),
      );
    }
  }

  Future<void> _removeTask(int index) async {
    final removed = Map<String, dynamic>.from(_tasks[index]);

    setState(() {
      _tasks.removeAt(index);
      _syncJourneyState();
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final repo = context.read<TaskRepository>();

      String? id = removed['taskId'] as String?;
      if (id == null || id.isEmpty) {
        id = await _findLatestTaskIdByTitle(_composeTitle(removed).trim());
      }

      if (id != null) {
        await repo.delete(id);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task removed')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove task: $e')),
      );
    }
  }

  // ——— helpers for attaching/locating the DB id ———

  /// Attach the DB id to the in-memory entry if it's missing.
  /// We locate the latest DB row whose title equals the composed title.
  Future<String?> _attachTaskIdIfMissing(int index) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final repo = context.read<TaskRepository>();
    final all = await repo.getTasks(user.uid);

    final title = _composeTitle(_tasks[index]).trim();
    final matches = all
        .where((t) => t.title.trim() == title)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (matches.isEmpty) return null;

    final id = matches.first.id;
    setState(() {
      _tasks[index]['taskId'] = id;
      _syncJourneyState();
    });
    return id;
  }

  Future<String?> _findLatestTaskIdByTitle(String title) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final repo = context.read<TaskRepository>();
    final all = await repo.getTasks(user.uid);

    final matches = all
        .where((t) => t.title.trim() == title)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return matches.isEmpty ? null : matches.first.id;
  }

  void _syncJourneyState() {
    final j = JourneyState.instance;

    if (_tasks.isEmpty) {
      j.data.value = null; // revert to empty/mic state
      return;
    }

    final data = Map<String, dynamic>.from(j.data.value ?? {});
    data['tasks'] = _tasks.map((e) => Map<String, dynamic>.from(e)).toList();
    data.remove('entries');
    j.data.value = data;
  }

  String _composeTitle(Map<String, dynamic> t) {
    final text = (t['text'] ?? '').toString().trim();
    final emoji = (t['emoji'] ?? '').toString().trim();
    return emoji.isEmpty ? text : '$emoji $text';
  }

  @override
  Widget build(BuildContext context) {
    if (_tasks.isEmpty) return const SizedBox.shrink();

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
        final emoji = (task['emoji'] ?? '').toString();

        return Container(
          key: ValueKey(task),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Checkbox(
                value: isCompleted,
                onChanged: (_) {
                  _toggleTaskCompletion(index);
                },
                fillColor: MaterialStateProperty.resolveWith<Color?>(
                      (states) => states.contains(MaterialState.selected)
                      ? const Color(0xFFFF5722)
                      : null,
                ),
                checkColor: Colors.white,
              ),
              SizedBox(
                width: 24,
                child: Text(
                  emoji,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text.isEmpty ? '(Untitled task)' : text,
                  style: TextStyle(
                    color: isCompleted ? const Color(0xFF888888) : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    decoration: isCompleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Remove',
                icon:
                const Icon(Icons.delete_outline, color: Color(0xFFAAAAAA)),
                onPressed: () => _removeTask(index),
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
