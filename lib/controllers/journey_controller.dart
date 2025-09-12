import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../repositories/task_repository.dart';

enum JourneyStatus { idle, loading, error }

/// Lean DTO consumed by the card UI.
class UiTask {
  final String? id;     // DB id (nullable until we resolve it)
  final String title;   // composed title (can be plain text)
  final bool completed;
  final int createdAt;  // epoch millis UTC

  const UiTask({
    required this.title,
    required this.completed,
    required this.createdAt,
    this.id,
  });

  UiTask copyWith({String? id, String? title, bool? completed, int? createdAt}) {
    return UiTask(
      id: id ?? this.id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class JourneyController extends ChangeNotifier {
  JourneyController(this._repo);

  final TaskRepository _repo;

  JourneyStatus _status = JourneyStatus.loading;
  JourneyStatus get status => _status;

  String? _error;
  String? get error => _error;

  List<UiTask> _tasks = [];
  List<UiTask> get tasks => List.unmodifiable(_tasks);

  // -------- Bootstrapping --------

  /// Recommended: hydrate from DB
  Future<void> fetchFromDb() async {
    _status = JourneyStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _tasks = [];
        _status = JourneyStatus.idle;
        notifyListeners();
        return;
      }
      final all = await _repo.getTasks(user.uid);
      _tasks = all
          .where((t) => t.deletedAt == null)
          .map((t) => UiTask(
        id: t.id,
        title: t.title,
        completed: t.status == 'done',
        createdAt: t.createdAt,
      ))
          .toList();
      _status = JourneyStatus.idle;
      notifyListeners();
    } catch (e) {
      _status = JourneyStatus.error;
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Back-compat: ingest a legacy blob of maps if some flows still produce it.
  void loadFromLegacyTasks(List<Map<String, dynamic>> items) {
    _tasks = items.map((m) {
      final text = (m['text'] ?? '').toString().trim();
      final emoji = (m['emoji'] ?? '').toString().trim();
      final title = emoji.isEmpty ? text : '$emoji $text';
      final completed = (m['completed'] ?? false) == true;
      final createdAt = (m['createdAt'] is int)
          ? m['createdAt'] as int
          : DateTime.now().millisecondsSinceEpoch;
      final id = (m['taskId'] as String?)?.trim().isEmpty == true
          ? null
          : m['taskId'] as String?;
      return UiTask(id: id, title: title, completed: completed, createdAt: createdAt);
    }).toList();
    _status = JourneyStatus.idle;
    _error = null;
    notifyListeners();
  }

  // -------- Mutations --------

  void reorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = _tasks.removeAt(oldIndex);
    _tasks.insert(newIndex, item);
    notifyListeners();
  }

  Future<void> toggleCompleted(int index) async {
    final before = _tasks[index];
    final after = before.copyWith(completed: !before.completed);
    _tasks[index] = after;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Resolve id if missing (latest by exact title).
      String? id = after.id ?? await _findLatestIdByTitle(user.uid, after.title);
      if (id == null) return;

      _tasks[index] = _tasks[index].copyWith(id: id);
      await _repo.setTaskDone(id, after.completed);
    } catch (e) {
      _tasks[index] = before; // revert
      _error = "Couldn't save status: $e";
      notifyListeners();
    }
  }

  Future<void> removeAt(int index) async {
    final removed = _tasks[index];
    _tasks.removeAt(index);
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final id = removed.id ?? await _findLatestIdByTitle(user.uid, removed.title);
      if (id != null) {
        await _repo.delete(id);
      }
    } catch (e) {
      _error = 'Failed to remove task: $e';
      notifyListeners();
    }
  }

  // -------- Helpers --------

  Future<String?> _findLatestIdByTitle(String userId, String title) async {
    final row = await _repo.findLatestByTitle(userId: userId, title: title.trim());
    return row?.id;
  }
}
