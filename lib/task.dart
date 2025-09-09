import 'dart:convert';

class Task {
  final String id;         // UUID v4
  final String userId;
  final String title;

  final String status;     // 'pending' | 'done' | 'archived'
  final int priority;      // 0..3

  final int? dueDate;      // epoch millis UTC
  final int createdAt;
  final int updatedAt;
  final int? completedAt;
  final int? deletedAt;

  final List<String> tags;

  final int version;       // for conflict resolution later if needed

  Task({
    required this.id,
    required this.userId,
    required this.title,
    this.status = 'pending',
    this.priority = 0,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.deletedAt,
    this.tags = const [],
    this.version = 1,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'title': title,
    'status': status,
    'priority': priority,
    'dueDate': dueDate,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'completedAt': completedAt,
    'deletedAt': deletedAt,
    'tags_json': tags,
    'version': version,
  };

  factory Task.fromMap(Map<String, dynamic> m) => Task(
    id: m['id'],
    userId: m['userId'],
    title: m['title'],
    status: m['status'] ?? 'pending',
    priority: (m['priority'] ?? 0) as int,
    dueDate: m['dueDate'],
    createdAt: m['createdAt'],
    updatedAt: m['updatedAt'],
    completedAt: m['completedAt'],
    deletedAt: m['deletedAt'],
    tags: _decodeTags(m['tags_json']),
    version: (m['version'] ?? 1) as int,
  );

  static List<String> _decodeTags(dynamic v) {
    if (v == null) return const [];
    if (v is List) return v.cast<String>();
    try { return (jsonDecode(v as String) as List).cast<String>(); }
    catch (_) { return const []; }
  }
}
