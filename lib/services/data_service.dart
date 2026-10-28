import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/models.dart';

/// Live, in-memory view of the signed-in user's notes, activities, projects and
/// water log, plus CRUD operations. Bound to a uid by the provider tree.
class DataService extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;
  final List<StreamSubscription<dynamic>> _subs = [];
  String? _uid;

  List<Note> notes = [];
  List<Activity> activities = [];
  List<Project> projects = [];
  Map<String, WaterDay> water = {};
  bool loaded = false;

  void bind(String? uid) {
    if (uid == _uid) return;
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    _uid = uid;
    notes = [];
    activities = [];
    projects = [];
    water = {};
    loaded = false;
    if (uid == null) return;

    var pending = 4;
    void ready() {
      if (!loaded && --pending <= 0) loaded = true;
      notifyListeners();
    }

    void onError(Object e) => debugPrint('Data stream error: $e');

    _subs
      ..add(_col('notes').snapshots().listen((s) {
        notes = s.docs.map(Note.fromDoc).toList()..sort(_noteOrder);
        ready();
      }, onError: onError))
      ..add(_col('activities').orderBy('date').snapshots().listen((s) {
        activities = s.docs.map(Activity.fromDoc).toList();
        ready();
      }, onError: onError))
      ..add(_col('projects').orderBy('createdAt').snapshots().listen((s) {
        projects = s.docs.map(Project.fromDoc).toList();
        ready();
      }, onError: onError))
      ..add(_col('water').snapshots().listen((s) {
        water = {for (final d in s.docs) d.id: WaterDay.fromDoc(d)};
        ready();
      }, onError: onError));
  }

  static int _noteOrder(Note a, Note b) {
    if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
    return b.updatedAt.compareTo(a.updatedAt);
  }

  CollectionReference<Map<String, dynamic>> _col(String name) =>
      _db.collection('users').doc(_uid).collection(name);

  // ---- Notes ----
  List<Note> get pinnedNotes => notes.where((n) => n.pinned).toList();

  Future<String> saveNote(Note n) async {
    if (n.id.isEmpty) return (await _col('notes').add(n.toMap())).id;
    await _col('notes').doc(n.id).set(n.toMap());
    return n.id;
  }

  Future<void> deleteNote(String id) => _col('notes').doc(id).delete();

  Future<void> togglePin(Note n) => _col('notes').doc(n.id).update({'pinned': !n.pinned});

  // ---- Activities ----
  List<Activity> activitiesOn(DateTime day) {
    final list = activities.where((a) => sameDay(a.date, day)).toList()
      ..sort((a, b) {
        if (a.hasTime != b.hasTime) return a.hasTime ? -1 : 1;
        return a.date.compareTo(b.date);
      });
    return list;
  }

  Future<void> saveActivity(Activity a) async {
    if (a.id.isEmpty) {
      await _col('activities').add(a.toMap());
    } else {
      await _col('activities').doc(a.id).set(a.toMap());
    }
  }

  Future<void> toggleActivity(Activity a) => _col('activities').doc(a.id).update({'done': !a.done});

  Future<void> deleteActivity(String id) => _col('activities').doc(id).delete();

  // ---- Projects ----
  Future<void> saveProject(Project p) async {
    if (p.id.isEmpty) {
      await _col('projects').add(p.toMap());
    } else {
      await _col('projects').doc(p.id).set(p.toMap());
    }
  }

  Future<void> deleteProject(String id) => _col('projects').doc(id).delete();

  Future<void> addTask(Project p, String title) => saveProject(p.copyWith(tasks: [
        ...p.tasks,
        TaskItem(id: DateTime.now().microsecondsSinceEpoch.toString(), title: title.trim()),
      ]));

  Future<void> toggleTask(Project p, TaskItem t) => saveProject(
      p.copyWith(tasks: [for (final x in p.tasks) x.id == t.id ? x.copyWith(done: !x.done) : x]));

  Future<void> renameTask(Project p, TaskItem t, String title) => saveProject(
      p.copyWith(tasks: [for (final x in p.tasks) x.id == t.id ? x.copyWith(title: title.trim()) : x]));

  Future<void> deleteTask(Project p, TaskItem t) =>
      saveProject(p.copyWith(tasks: p.tasks.where((x) => x.id != t.id).toList()));

  // ---- Water ----
  int glassesOn(DateTime day) => water[dayKey(day)]?.glasses ?? 0;

  Future<void> setGlasses(DateTime day, int glasses) => _col('water').doc(dayKey(day)).set({
        'date': Timestamp.fromDate(dayOnly(day)),
        'glasses': glasses < 0 ? 0 : glasses,
      });

  Future<void> addGlass([int delta = 1]) {
    final today = DateTime.now();
    return setGlasses(today, glassesOn(today) + delta);
  }

  /// Glasses per day for the [days] days ending today (oldest first).
  List<int> waterHistory(int days) {
    final t = DateTime.now();
    return [for (var i = days - 1; i >= 0; i--) glassesOn(DateTime(t.year, t.month, t.day - i))];
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }
}
