import 'package:flutter_test/flutter_test.dart';

import 'package:lifenote/models/models.dart';
import 'package:lifenote/services/report_service.dart';

void main() {
  test('project progress', () {
    final p = Project(title: 'Getting started', tasks: [
      TaskItem(id: '1', title: 'a', done: true),
      TaskItem(id: '2', title: 'b', done: true),
      TaskItem(id: '3', title: 'c'),
    ]);
    expect(p.doneCount, 2);
    expect(p.progress, closeTo(0.67, 0.01));
    expect(p.almostDone, isTrue);
    expect(p.isComplete, isFalse);
  });

  test('day key is zero padded', () {
    expect(dayKey(DateTime(2026, 9, 2)), '2026-09-02');
  });

  test('category parse falls back to none', () {
    expect(Category.parse('workout'), Category.workout);
    expect(Category.parse('bogus'), Category.none);
  });

  test('export service is importable', () {
    expect(ExportService.shareFile, isNotNull);
  });
}
