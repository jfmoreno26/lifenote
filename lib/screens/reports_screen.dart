import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../services/report_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _days = 7;

  Future<void> _export(Future<void> Function() fn) async {
    try {
      await fn();
    } catch (e) {
      if (mounted) showMessage(context, 'Export failed: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ln;
    final data = context.watch<DataService>();
    final goal = context.watch<AuthService>().profile?.waterGoal ?? 8;
    final r = Report.build(data, days: _days, waterGoal: goal);
    final now = DateTime.now();
    final labels = [
      for (var i = _days - 1; i >= 0; i--)
        _days == 7
            ? DateFormat('E').format(DateTime(now.year, now.month, now.day - i)).substring(0, 1)
            : DateFormat('d').format(DateTime(now.year, now.month, now.day - i)),
    ];
    final byCat = r.activitiesByCategory;
    final maxCat = byCat.values.fold<int>(1, (a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(title: const Text('Reports & analytics', style: TextStyle(fontWeight: FontWeight.w700))),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 32), children: [
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 7, label: Text('7 days')),
            ButtonSegment(value: 30, label: Text('30 days')),
            ButtonSegment(value: 90, label: Text('90 days')),
          ],
          selected: {_days},
          onSelectionChanged: (s) => setState(() => _days = s.first),
        ),
        const SizedBox(height: 6),
        Text(r.periodLabel, textAlign: TextAlign.center, style: TextStyle(color: c.muted, fontSize: 12)),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.6,
          children: [
            _Stat(icon: Icons.sticky_note_2_outlined, color: c.primary, value: '${r.notesCreated}', label: 'Notes created'),
            _Stat(
              icon: Icons.task_alt_rounded,
              color: c.success,
              value: '${(r.activityRate * 100).round()}%',
              label: '${r.activitiesDone}/${r.activities.length} activities done',
            ),
            _Stat(
              icon: Icons.folder_outlined,
              color: Category.work.color,
              value: '${r.tasksDone}/${r.tasksTotal}',
              label: 'Project tasks done',
            ),
            _Stat(
              icon: Icons.water_drop_outlined,
              color: c.water,
              value: r.avgWater.toStringAsFixed(1),
              label: 'Avg glasses / day',
            ),
          ],
        ),
        const SizedBox(height: 12),
        LnCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Expanded(child: Text('Water intake', style: TextStyle(fontWeight: FontWeight.w700))),
              Text('Goal met ${r.waterGoalDays}/$_days days', style: TextStyle(color: c.muted, fontSize: 12)),
            ]),
            const SizedBox(height: 14),
            BarChart(
              values: r.water,
              labels: labels,
              color: c.water,
              track: c.waterSoft,
              maxValue: goal,
              labelEvery: _days == 7 ? 1 : (_days == 30 ? 5 : 15),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        LnCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Activities by category', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            for (final cat in Category.values)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(children: [
                  SizedBox(width: 92, child: Text(cat.label, style: const TextStyle(fontSize: 12))),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: byCat[cat]! / maxCat,
                        minHeight: 8,
                        color: cat == Category.none ? c.primary : cat.color,
                        backgroundColor: c.surfaceAlt,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 32,
                    child: Text('${byCat[cat]}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
          ]),
        ),
        const SizedBox(height: 12),
        LnCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Insights', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            for (final i in r.insights)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.auto_awesome_rounded, size: 15, color: c.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(i, style: const TextStyle(fontSize: 13))),
                ]),
              ),
          ]),
        ),
        const SizedBox(height: 12),
        LnCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('Generate & export', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Reports cover the selected period. CSV and JSON exports include all of your data.',
                style: TextStyle(color: c.muted, fontSize: 12)),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _showReport(context, r),
              icon: const Icon(Icons.description_outlined),
              label: const Text('Generate report'),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _export(() => ExportService.shareFile(ExportService.toCsv(data), 'lifenote', 'csv', 'text/csv')),
                  icon: const Icon(Icons.table_chart_outlined, size: 18),
                  label: const Text('CSV'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _export(() => ExportService.shareFile(ExportService.toJson(data), 'lifenote', 'json', 'application/json')),
                  icon: const Icon(Icons.data_object_rounded, size: 18),
                  label: const Text('JSON'),
                ),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }

  void _showReport(BuildContext context, Report r) {
    final text = r.toText();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (ctx, scroll) => Column(children: [
          Expanded(
            child: SingleChildScrollView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: SelectableText(text, style: const TextStyle(fontSize: 13, height: 1.5)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: text));
                    if (ctx.mounted) showMessage(ctx, 'Report copied');
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copy'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _export(() => ExportService.shareFile(text, 'lifenote_report', 'txt', 'text/plain')),
                  icon: const Icon(Icons.ios_share_rounded, size: 18),
                  label: const Text('Share'),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.color, required this.value, required this.label});
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return LnCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Icon(icon, color: color, size: 20),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: context.ln.muted, fontSize: 11)),
        ]),
      ]),
    );
  }
}
