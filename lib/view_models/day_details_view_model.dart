import 'package:flutter/foundation.dart';
import '../repositories/task_repository.dart';
import '../task.dart';

class DayDetailsViewModel extends ChangeNotifier {
  DayDetailsViewModel({
    required TaskRepository repo,
    required String userId,
    required String dateStr, // yyyy-MM-dd (local)
  })  : _repo = repo,
        _userId = userId,
        _dateStr = dateStr {
    _repoListener = () {
      refresh();
    };
    _repo.addListener(_repoListener);
  }

  final TaskRepository _repo;
  final String _userId;
  final String _dateStr;

  bool _loading = false;
  String? _error;
  List<Task> _tasks = [];

  bool get loading => _loading;
  String? get error => _error;
  List<Task> get tasks => _tasks;

  Future<void> refresh() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final all = await _repo.getTasks(_userId);
      _tasks = all
          .where((t) =>
      _ymd(DateTime.fromMillisecondsSinceEpoch(t.createdAt)) == _dateStr)
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  static String _ymd(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  void dispose() {
    _repo.removeListener(_repoListener);
    super.dispose();
  }

  late final VoidCallback _repoListener;
}
