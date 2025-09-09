// lib/view_models/settings_view_model.dart
import 'package:flutter/foundation.dart';
import '../repositories/task_repository.dart';
import '../journey_state.dart';
import '../services/journey_cache.dart';

class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel({required this.repo, required this.userId});

  final TaskRepository repo;
  final String userId;

  bool _clearing = false;
  bool get clearing => _clearing;

  Future<void> clearHistory() async {
    _clearing = true;
    notifyListeners();
    try {
      await repo.clearAll(userId);

      JourneyState.instance.reset();

      await JourneyCache.instance.clearToday();
    } finally {
      _clearing = false;
      notifyListeners();
    }
  }
}
