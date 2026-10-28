import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../models/models.dart';
import 'data_service.dart';

/// Aggregated analytics for a period ending today.
class Report {
  Report._({
    required this.days,
    required this.from,
    required this.to,
    required this.notesCreated,
    required this.activities,
    required this.water,
    required this.waterGoal,
    required this.projects,
  });

  factory Report.build(DataService data, {required int days, required int waterGoal}) {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day - days + 1);
    final to = DateTime(now.year, now.month, now.day + 1);
    bool inRange(DateTime d) => !d.isBefore(from) && d.isBefore(to);
    return Report._(
      days: days,
      from: from,
      to: to,
      notesCreated: data.notes.where((n) => inRange(n.createdAt)).length,
      activities: data.activities.where((a) => inRange(a.date)).toList(),
      water: data.waterHistory(days),
      waterGoal: waterGoal,
      projects: data.projects,
    );
  }

  final int days;
  final DateTime from;
  final DateTime to;
  final int notesCreated;
  final List<Activity> activities;
  final List<int> water;
  final int waterGoal;
  final List<Project> projects;

  int get activitiesDone => activities.where((a) => a.done).length;
  double get activityRate => activities.isEmpty ? 0 : activitiesDone / activities.length;
  int get tasksTotal => projects.fold(0, (s, p) => s + p.tasks.length);
  int get tasksDone => projects.fold(0, (s, p) => s + p.doneCount);
  double get avgWater => water.isEmpty ? 0 : water.reduce((a, b) => a + b) / water.length;
  int get waterGoalDays => water.where((g) => g >= waterGoal).length;

  Map<Category, int> get activitiesByCategory {
    final m = {for (final c in Category.values) c: 0};
    for (final a in activities) {
      m[a.category] = m[a.category]! + 1;
    }
    return m;
  }

  List<String> get insights {
    final out = <String>[];
    out.add('Water goal met on $waterGoalDays of $days days (avg ${avgWater.toStringAsFixed(1)} glasses).');
    if (activities.isNotEmpty) {
      final top = activitiesByCategory.entries.where((e) => e.key != Category.none && e.value > 0).toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      if (top.isNotEmpty) out.add('Most planned category: ${top.first.key.label} (${top.first.value}).');
      final byWeekday = <int, int>{};
      for (final a in activities.where((a) => a.done)) {
        byWeekday[a.date.weekday] = (byWeekday[a.date.weekday] ?? 0) + 1;
      }
      if (byWeekday.isNotEmpty) {
        final best = byWeekday.entries.reduce((a, b) => b.value > a.value ? b : a);
        out.add('Most productive day: ${DateFormat('EEEE').format(DateTime(2024, 1, best.key))}.');
      }
      out.add('Completed ${(activityRate * 100).round()}% of planned activities.');
    } else {
      out.add('No activities planned in this period yet.');
    }
    final almost = projects.where((p) => p.almostDone).length;
    if (almost > 0) out.add('$almost project${almost == 1 ? ' is' : 's are'} almost done.');
    return out;
  }

  String get periodLabel => '${DateFormat.yMMMd().format(from)} – ${DateFormat.yMMMd().format(to.subtract(const Duration(days: 1)))}';

  String toText() {
    final b = StringBuffer()
      ..writeln('LifeNote report')
      ..writeln(periodLabel)
      ..writeln('')
      ..writeln('Notes created: $notesCreated')
      ..writeln('Activities: $activitiesDone of ${activities.length} done (${(activityRate * 100).round()}%)')
      ..writeln('Project tasks: $tasksDone of $tasksTotal done')
      ..writeln('Average water: ${avgWater.toStringAsFixed(1)} glasses/day (goal $waterGoal)')
      ..writeln('')
      ..writeln('Insights');
    for (final i in insights) {
      b.writeln('• $i');
    }
    b
      ..writeln('')
      ..writeln('Projects');
    for (final p in projects) {
      b.writeln('• ${p.title}: ${p.doneCount}/${p.tasks.length} tasks (${(p.progress * 100).round()}%)');
    }
    return b.toString();
  }
}

/// Builds full-data exports and hands them to the platform share sheet.
class ExportService {
  static String _csvCell(Object? v) {
    final s = '${v ?? ''}';
    return s.contains(RegExp(r'[",\n]')) ? '"${s.replaceAll('"', '""')}"' : s;
  }

  static String _row(List<Object?> cells) => cells.map(_csvCell).join(',');

  static String toCsv(DataService data) {
    final iso = DateFormat('yyyy-MM-dd HH:mm');
    final b = StringBuffer()
      ..writeln('# Notes')
      ..writeln(_row(['title', 'body', 'category', 'pinned', 'created', 'updated']));
    for (final n in data.notes) {
      b.writeln(_row([n.title, n.body, n.category.label, n.pinned, iso.format(n.createdAt), iso.format(n.updatedAt)]));
    }
    b
      ..writeln()
      ..writeln('# Activities')
      ..writeln(_row(['title', 'date', 'has_time', 'category', 'done']));
    for (final a in data.activities) {
      b.writeln(_row([a.title, iso.format(a.date), a.hasTime, a.category.label, a.done]));
    }
    b
      ..writeln()
      ..writeln('# Project tasks')
      ..writeln(_row(['project', 'category', 'task', 'done']));
    for (final p in data.projects) {
      for (final t in p.tasks) {
        b.writeln(_row([p.title, p.category.label, t.title, t.done]));
      }
    }
    b
      ..writeln()
      ..writeln('# Water')
      ..writeln(_row(['date', 'glasses']));
    final days = data.water.keys.toList()..sort();
    for (final k in days) {
      b.writeln(_row([k, data.water[k]!.glasses]));
    }
    return b.toString();
  }

  static String toJson(DataService data) {
    String iso(DateTime d) => d.toIso8601String();
    return const JsonEncoder.withIndent('  ').convert({
      'exportedAt': iso(DateTime.now()),
      'notes': [
        for (final n in data.notes)
          {
            'title': n.title,
            'body': n.body,
            'category': n.category.name,
            'pinned': n.pinned,
            'color': n.color,
            'createdAt': iso(n.createdAt),
            'updatedAt': iso(n.updatedAt),
          }
      ],
      'activities': [
        for (final a in data.activities)
          {'title': a.title, 'date': iso(a.date), 'hasTime': a.hasTime, 'category': a.category.name, 'done': a.done}
      ],
      'projects': [
        for (final p in data.projects)
          {
            'title': p.title,
            'category': p.category.name,
            'tasks': [for (final t in p.tasks) t.toMap()..remove('id')],
          }
      ],
      'water': {for (final e in data.water.entries) e.key: e.value.glasses},
    });
  }

  /// Shares [content] as `<baseName>_<yyyyMMdd>.<extension>`.
  static Future<void> shareFile(String content, String baseName, String extension, String mimeType) async {
    final name = '${baseName}_${DateFormat('yyyyMMdd').format(DateTime.now())}.$extension';
    await SharePlus.instance.share(ShareParams(
      subject: 'LifeNote export',
      files: [XFile.fromData(utf8.encode(content), mimeType: mimeType, name: name)],
      fileNameOverrides: [name],
    ));
  }
}
