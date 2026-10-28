import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import 'auth_service.dart';
import 'data_service.dart';
import 'settings_service.dart';

enum AlertLevel { info, warning, success }

class AppAlert {
  AppAlert({required this.id, required this.title, required this.message, required this.icon, required this.level});

  /// Stable per day, so the same alert isn't raised twice.
  final String id;
  final String title;
  final String message;
  final IconData icon;
  final AlertLevel level;
}

/// Evaluates rules against the user's data every minute (and on every data
/// change) and raises automated alerts: water pace, upcoming and overdue
/// activities, and projects that are close to completion.
class AlertService extends ChangeNotifier {
  AlertService(this._data, this._auth, this._settings) {
    _data.addListener(_evaluate);
    _auth.addListener(_evaluate);
    _settings.addListener(_evaluate);
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _evaluate());
    _evaluate();
  }

  final DataService _data;
  final AuthService _auth;
  final SettingsService _settings;
  late final Timer _timer;

  final _fresh = StreamController<AppAlert>.broadcast();
  final Set<String> _seen = {};
  final Set<String> _dismissed = {};

  List<AppAlert> alerts = [];

  /// Emits alerts the first time they become active (for in-app toasts).
  Stream<AppAlert> get onNewAlert => _fresh.stream;

  int get count => alerts.length;

  void dismiss(String id) {
    _dismissed.add(id);
    _evaluate();
  }

  void dismissAll() {
    _dismissed.addAll(alerts.map((a) => a.id));
    _evaluate();
  }

  void _evaluate() {
    if (!_settings.alertsEnabled || _auth.user == null || !_data.loaded) {
      if (alerts.isNotEmpty) {
        alerts = [];
        notifyListeners();
      }
      return;
    }
    final now = DateTime.now();
    final today = dayKey(now);
    final time = DateFormat.jm();
    final out = <AppAlert>[];

    // Water: expect the goal to be spread evenly between 8 AM and 8 PM.
    final goal = _auth.profile?.waterGoal ?? 8;
    final glasses = _data.glassesOn(now);
    final hoursIn = (now.hour + now.minute / 60 - 8).clamp(0, 12);
    final expected = (goal * hoursIn / 12).floor();
    if (glasses >= goal) {
      out.add(AppAlert(
        id: 'water-goal-$today',
        title: 'Water goal reached',
        message: 'You drank $glasses of $goal glasses today. Nice work!',
        icon: Icons.water_drop_rounded,
        level: AlertLevel.success,
      ));
    } else if (expected - glasses >= 2) {
      out.add(AppAlert(
        id: 'water-pace-$today-$expected',
        title: 'Time for some water',
        message: "You're at $glasses of $goal glasses — about ${expected - glasses} behind pace.",
        icon: Icons.local_drink_rounded,
        level: AlertLevel.warning,
      ));
    }

    for (final a in _data.activities) {
      if (a.done) continue;
      if (a.hasTime) {
        final mins = a.date.difference(now).inMinutes;
        if (mins >= 0 && mins <= 60) {
          out.add(AppAlert(
            id: 'soon-${a.id}',
            title: 'Coming up: ${a.title}',
            message: 'Starts at ${time.format(a.date)} (in $mins min).',
            icon: Icons.schedule_rounded,
            level: AlertLevel.info,
          ));
          continue;
        }
      }
      final end = a.hasTime ? a.date : DateTime(a.date.year, a.date.month, a.date.day + 1);
      if (end.isBefore(now) && now.difference(end).inDays < 7) {
        out.add(AppAlert(
          id: 'overdue-${a.id}',
          title: 'Overdue: ${a.title}',
          message: 'Planned for ${DateFormat('EEE, MMM d').format(a.date)}. Mark it done or reschedule.',
          icon: Icons.event_busy_rounded,
          level: AlertLevel.warning,
        ));
      }
    }

    for (final p in _data.projects) {
      if (p.almostDone) {
        final left = p.tasks.length - p.doneCount;
        out.add(AppAlert(
          id: 'almost-${p.id}-${p.doneCount}',
          title: 'Almost done: ${p.title}',
          message: '$left task${left == 1 ? '' : 's'} left — ${(p.progress * 100).round()}% complete.',
          icon: Icons.flag_rounded,
          level: AlertLevel.success,
        ));
      }
    }

    alerts = out.where((a) => !_dismissed.contains(a.id)).toList();
    for (final a in alerts) {
      if (_seen.add(a.id)) _fresh.add(a);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _timer.cancel();
    _data.removeListener(_evaluate);
    _auth.removeListener(_evaluate);
    _settings.removeListener(_evaluate);
    _fresh.close();
    super.dispose();
  }
}
