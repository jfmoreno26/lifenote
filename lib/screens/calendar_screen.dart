import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'sheets.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, required this.selected});

  /// Shared with the shell so the + button adds to the selected day.
  final ValueNotifier<DateTime> selected;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _month = DateTime(widget.selected.value.year, widget.selected.value.month);

  void _select(DateTime d) {
    widget.selected.value = dayOnly(d);
    setState(() => _month = DateTime(d.year, d.month));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ln;
    final data = context.watch<DataService>();
    final now = DateTime.now();
    final todayCount = data.activitiesOn(now).length;

    return ValueListenableBuilder<DateTime>(
      valueListenable: widget.selected,
      builder: (context, selected, _) {
        final dayList = data.activitiesOn(selected);
        return SafeArea(
          bottom: false,
          child: ListView(padding: const EdgeInsets.only(bottom: 110), children: [
            PageHeader(
              title: 'Calendar',
              subtitle: '$todayCount ${todayCount == 1 ? 'activity' : 'activities'} today',
              trailing: PillButton(label: 'Today', onTap: () => _select(now)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: LnCard(child: _monthGrid(context, data, selected)),
            ),
            SectionHeader(
              title: sameDay(selected, now) ? 'Today, ${DateFormat('MMM d').format(selected)}' : DateFormat('EEEE, MMM d').format(selected),
              action: '${dayList.length} ${dayList.length == 1 ? 'activity' : 'activities'}',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: LnCard(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 4),
                child: Column(children: [
                  if (dayList.isEmpty)
                    const EmptyState(icon: Icons.event_available_outlined, message: 'No activities on this day.'),
                  for (var i = 0; i < dayList.length; i++) ...[
                    if (i > 0) Divider(color: c.border),
                    ActivityTile(
                      activity: dayList[i],
                      onToggle: () => data.toggleActivity(dayList[i]),
                      onTap: () => showActivitySheet(context, existing: dayList[i]),
                    ),
                  ],
                  TextButton.icon(
                    onPressed: () => showActivitySheet(context, date: selected),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add activity'),
                  ),
                ]),
              ),
            ),
          ]),
        );
      },
    );
  }

  Widget _monthGrid(BuildContext context, DataService data, DateTime selected) {
    final c = context.ln;
    final now = DateTime.now();
    // Sunday-first grid covering the whole month.
    final first = DateTime(_month.year, _month.month, 1);
    final start = DateTime(first.year, first.month, 1 - first.weekday % 7);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final cells = ((first.weekday % 7 + daysInMonth) / 7).ceil() * 7;

    final byDay = <String, List<Activity>>{};
    for (final a in data.activities) {
      byDay.putIfAbsent(dayKey(a.date), () => []).add(a);
    }

    return Column(children: [
      Row(children: [
        CircleIconButton(
          icon: Icons.chevron_left_rounded,
          size: 34,
          onTap: () => setState(() => _month = DateTime(_month.year, _month.month - 1)),
        ),
        Expanded(
          child: Text(DateFormat('MMMM y').format(_month),
              textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        ),
        CircleIconButton(
          icon: Icons.chevron_right_rounded,
          size: 34,
          onTap: () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
        ),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        for (final d in ['S', 'M', 'T', 'W', 'T', 'F', 'S'])
          Expanded(
            child: Text(d,
                textAlign: TextAlign.center,
                style: TextStyle(color: c.muted, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
      ]),
      const SizedBox(height: 6),
      for (var row = 0; row < cells / 7; row++)
        Row(children: [
          for (var col = 0; col < 7; col++)
            Expanded(child: _dayCell(context, DateTime(start.year, start.month, start.day + row * 7 + col), selected, now, byDay)),
        ]),
    ]);
  }

  Widget _dayCell(BuildContext context, DateTime day, DateTime selected, DateTime now, Map<String, List<Activity>> byDay) {
    final c = context.ln;
    final inMonth = day.month == _month.month;
    final isSel = sameDay(day, selected);
    final isToday = sameDay(day, now);
    final acts = byDay[dayKey(day)] ?? const [];
    final dotColors = acts.take(3).map((a) => a.category == Category.none ? c.primary : a.category.color).toList();

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _select(day),
      child: SizedBox(
        height: 44,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: isSel ? c.primary : null, shape: BoxShape.circle),
            child: Text('${day.day}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSel || isToday ? FontWeight.w700 : FontWeight.w500,
                  color: isSel
                      ? Colors.white
                      : isToday
                          ? c.primary
                          : inMonth
                              ? c.text
                              : c.muted.withValues(alpha: 0.5),
                )),
          ),
          SizedBox(
            height: 6,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (final dc in dotColors)
                Container(
                  width: 4,
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
                  decoration: BoxDecoration(color: dc, shape: BoxShape.circle),
                ),
            ]),
          ),
        ]),
      ),
    );
  }
}
