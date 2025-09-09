import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class JourneyCache {
  JourneyCache._();
  static final instance = JourneyCache._();

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _keyFor(DateTime localDay) => 'journey_cache_${_ymd(localDay)}';

  Future<Map<String, dynamic>?> loadToday() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(DateTime.now()));
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveToday(Map<String, dynamic>? data) async {
    final prefs = await SharedPreferences.getInstance();
    if (data == null) {
      await prefs.remove(_keyFor(DateTime.now()));
      return;
    }
    await prefs.setString(_keyFor(DateTime.now()), jsonEncode(data));
  }

  /// Optional: clear old day cache (call on new day rollover if you want).
  Future<void> clearToday() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFor(DateTime.now()));
  }
}