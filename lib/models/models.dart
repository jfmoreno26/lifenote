import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Tag shared by notes, activities and projects ("Link to activity" in the UI).
enum Category {
  none('None', Icons.check_rounded, Color(0xFF8A8FA3)),
  reading('Reading', Icons.menu_book_rounded, Color(0xFF3E7BFA)),
  workout('Workout', Icons.fitness_center_rounded, Color(0xFFE5484D)),
  work('Work', Icons.work_outline_rounded, Color(0xFF7C5CFA)),
  journaling('Journaling', Icons.star_outline_rounded, Color(0xFFE0A100));

  const Category(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;

  static Category parse(Object? value) =>
      Category.values.firstWhere((c) => c.name == value, orElse: () => Category.none);
}

enum Role {
  user('User'),
  admin('Admin');

  const Role(this.label);
  final String label;

  static Role parse(Object? value) => value == 'admin' ? Role.admin : Role.user;
}

DateTime _date(Object? v) => v is Timestamp ? v.toDate() : DateTime.now();

class AppUser {
  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.waterGoal,
    required this.glassMl,
    required this.createdAt,
  });

  final String uid;
  final String name;
  final String email;
  final Role role;
  final int waterGoal;
  final int glassMl;
  final DateTime createdAt;

  bool get isAdmin => role == Role.admin;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return email.isEmpty ? '?' : email[0].toUpperCase();
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return AppUser(
      uid: doc.id,
      name: d['name'] as String? ?? '',
      email: d['email'] as String? ?? '',
      role: Role.parse(d['role']),
      waterGoal: (d['waterGoal'] as num?)?.toInt() ?? 8,
      glassMl: (d['glassMl'] as num?)?.toInt() ?? 250,
      createdAt: _date(d['createdAt']),
    );
  }
}

class Note {
  Note({
    this.id = '',
    this.title = '',
    this.body = '',
    this.category = Category.none,
    this.color = 0,
    this.pinned = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String title;
  final String body;
  final Category category;
  final int color;
  final bool pinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note copyWith({String? title, String? body, Category? category, int? color, bool? pinned}) => Note(
        id: id,
        title: title ?? this.title,
        body: body ?? this.body,
        category: category ?? this.category,
        color: color ?? this.color,
        pinned: pinned ?? this.pinned,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'body': body,
        'category': category.name,
        'color': color,
        'pinned': pinned,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  factory Note.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Note(
      id: doc.id,
      title: d['title'] as String? ?? '',
      body: d['body'] as String? ?? '',
      category: Category.parse(d['category']),
      color: (d['color'] as num?)?.toInt() ?? 0,
      pinned: d['pinned'] as bool? ?? false,
      createdAt: _date(d['createdAt']),
      updatedAt: _date(d['updatedAt']),
    );
  }
}

class Activity {
  Activity({
    this.id = '',
    required this.title,
    required this.date,
    this.hasTime = false,
    this.category = Category.none,
    this.done = false,
  });

  final String id;
  final String title;

  /// Day of the activity; also carries the time of day when [hasTime] is set.
  final DateTime date;
  final bool hasTime;
  final Category category;
  final bool done;

  Activity copyWith({String? title, DateTime? date, bool? hasTime, Category? category, bool? done}) => Activity(
        id: id,
        title: title ?? this.title,
        date: date ?? this.date,
        hasTime: hasTime ?? this.hasTime,
        category: category ?? this.category,
        done: done ?? this.done,
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'date': Timestamp.fromDate(date),
        'hasTime': hasTime,
        'category': category.name,
        'done': done,
      };

  factory Activity.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Activity(
      id: doc.id,
      title: d['title'] as String? ?? '',
      date: _date(d['date']),
      hasTime: d['hasTime'] as bool? ?? false,
      category: Category.parse(d['category']),
      done: d['done'] as bool? ?? false,
    );
  }
}

class TaskItem {
  TaskItem({required this.id, required this.title, this.done = false});

  final String id;
  final String title;
  final bool done;

  TaskItem copyWith({String? title, bool? done}) =>
      TaskItem(id: id, title: title ?? this.title, done: done ?? this.done);

  Map<String, dynamic> toMap() => {'id': id, 'title': title, 'done': done};

  factory TaskItem.fromMap(Map<String, dynamic> m) =>
      TaskItem(id: m['id'] as String? ?? '', title: m['title'] as String? ?? '', done: m['done'] as bool? ?? false);
}

class Project {
  Project({
    this.id = '',
    required this.title,
    this.category = Category.none,
    this.tasks = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String title;
  final Category category;
  final List<TaskItem> tasks;
  final DateTime createdAt;

  int get doneCount => tasks.where((t) => t.done).length;
  double get progress => tasks.isEmpty ? 0 : doneCount / tasks.length;
  bool get isComplete => tasks.isNotEmpty && doneCount == tasks.length;
  bool get almostDone => tasks.isNotEmpty && progress >= 0.6 && !isComplete;

  Project copyWith({String? title, Category? category, List<TaskItem>? tasks}) => Project(
        id: id,
        title: title ?? this.title,
        category: category ?? this.category,
        tasks: tasks ?? this.tasks,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'category': category.name,
        'tasks': tasks.map((t) => t.toMap()).toList(),
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory Project.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Project(
      id: doc.id,
      title: d['title'] as String? ?? '',
      category: Category.parse(d['category']),
      tasks: ((d['tasks'] as List?) ?? [])
          .whereType<Map>()
          .map((m) => TaskItem.fromMap(Map<String, dynamic>.from(m)))
          .toList(),
      createdAt: _date(d['createdAt']),
    );
  }
}

/// One day of water intake; the document id is the `yyyy-MM-dd` day key.
class WaterDay {
  WaterDay({required this.day, required this.glasses});

  final DateTime day;
  final int glasses;

  factory WaterDay.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return WaterDay(day: _date(d['date']), glasses: (d['glasses'] as num?)?.toInt() ?? 0);
  }
}

DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
