import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../task.dart';
import '../database/database_helper.dart';

class TaskRepository extends ChangeNotifier {
  Future<Database> get _db async => DatabaseHelper.instance.database;

  // -------------------- Writes --------------------

  Future<void> insert(Task task) async {
    final db = await _db;
    await db.insert(
      'tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    notifyListeners();
  }

  Future<void> update(Task task) async {
    final db = await _db;
    await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
    notifyListeners();
  }

  Future<void> delete(String id) async {
    final db = await _db;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
    notifyListeners();
  }

  Future<void> clearAll(String userId) async {
    final db = await _db;
    await db.delete('tasks', where: 'userId = ?', whereArgs: [userId]);
    notifyListeners();
  }

  Future<void> setTaskDone(String id, bool done) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.update(
      'tasks',
      {
        'status': done ? 'done' : 'pending',
        'completedAt': done ? now : null,
        'updatedAt': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    notifyListeners();
  }

  // -------------------- Reads (generic) --------------------

  Future<List<Task>> getTasks(String userId) async {
    final db = await _db;
    final maps = await db.query(
      'tasks',
      where: 'userId = ? AND deletedAt IS NULL',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
    return maps.map((m) => Task.fromMap(m)).toList();
  }

  /// Efficient range query by createdAt in **UTC millis**.
  Future<List<Task>> getTasksInRange({
    required String userId,
    required int startMillisUtc, // inclusive
    required int endMillisUtc,   // exclusive
    String orderBy = 'createdAt ASC',
  }) async {
    final db = await _db;
    final maps = await db.query(
      'tasks',
      where:
      'userId = ? AND deletedAt IS NULL AND createdAt >= ? AND createdAt < ?',
      whereArgs: [userId, startMillisUtc, endMillisUtc],
      orderBy: orderBy,
    );
    return maps.map((m) => Task.fromMap(m)).toList();
  }

  /// Convenience: fetch tasks for a **local day** quickly (converted to UTC under the hood).
  Future<List<Task>> getTasksForLocalDay({
    required String userId,
    required DateTime localDay, // any time that day in local tz
    String orderBy = 'createdAt ASC',
  }) async {
    final startLocal = DateTime(localDay.year, localDay.month, localDay.day);
    final endLocal = startLocal.add(const Duration(days: 1));

    final startUtc = startLocal.toUtc().millisecondsSinceEpoch;
    final endUtc = endLocal.toUtc().millisecondsSinceEpoch;

    return getTasksInRange(
      userId: userId,
      startMillisUtc: startUtc,
      endMillisUtc: endUtc,
      orderBy: orderBy,
    );
  }

  /// Convenience: today in local timezone.
  Future<List<Task>> getTasksForToday({
    required String userId,
    String orderBy = 'createdAt ASC',
  }) {
    return getTasksForLocalDay(
      userId: userId,
      localDay: DateTime.now(),
      orderBy: orderBy,
    );
  }

  /// Fast lookup: latest task by exact title (trimmed), for this user.
  Future<Task?> findLatestByTitle({
    required String userId,
    required String title,
  }) async {
    final db = await _db;
    final maps = await db.query(
      'tasks',
      where: 'userId = ? AND deletedAt IS NULL AND TRIM(title) = ?',
      whereArgs: [userId, title.trim()],
      orderBy: 'createdAt DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Task.fromMap(maps.first);
  }
}
