import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import '../repositories/task_repository.dart';
import '../services/journey_cache.dart';
import '../controllers/journey_controller.dart';

class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel({
    required this.repo,
    required this.userId,
    required this.journeyController,
  });

  final TaskRepository repo;
  final String userId;
  final JourneyController journeyController;

  bool _clearing = false;
  bool get clearing => _clearing;

  Future<void> clearHistory() async {
    _clearing = true;
    notifyListeners();

    try {
      // 1) Clear all tasks for this user
      await repo.clearAll(userId);

      // 2) Clear local cache
      await JourneyCache.instance.clearToday();

      // 3) Tell the controller to reset tasks so UI updates immediately
      journeyController.loadFromLegacyTasks(const []); // empty list -> empty state
    } finally {
      _clearing = false;
      notifyListeners();
    }
  }
}
