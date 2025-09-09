import 'package:flutter/foundation.dart';
import '../repositories/task_repository.dart';
import '../task.dart';

class HistoryViewModel extends ChangeNotifier {
  HistoryViewModel(this._repo, this._userId) {
    _repoListener = () => refresh();
    _repo.addListener(_repoListener);
  }

  final TaskRepository _repo;
  final String _userId;

  bool _loading = false;
  bool _loadedOnce = false;
  String? _error;
  List<Task> _tasks = [];

  bool get loading => _loading;
  bool get loadedOnce => _loadedOnce;
  String? get error => _error;
  List<Task> get tasks => _tasks;

  Future<void> refresh() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _tasks = await _repo.getTasks(_userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      _loadedOnce = true;
      notifyListeners();
    }
  }

  String _ymd(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Map<String, List<Task>> get groupedByDay {
    final map = <String, List<Task>>{};
    for (final t in _tasks) {
      final created = DateTime.fromMillisecondsSinceEpoch(t.createdAt);
      final key = _ymd(created);
      (map[key] ??= []).add(t);
    }
    return map;
  }

  List<String> get sortedDayKeysDesc {
    final keys = groupedByDay.keys.toList();
    keys.sort((a, b) => b.compareTo(a));
    return keys;
  }

  late final VoidCallback _repoListener;
  @override
  void dispose() {
    _repo.removeListener(_repoListener);
    super.dispose();
  }
}
