import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

Future<void> showActivitySheet(BuildContext context, {Activity? existing, DateTime? date}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ActivitySheet(existing: existing, date: date ?? DateTime.now()),
  );
}

class _ActivitySheet extends StatefulWidget {
  const _ActivitySheet({this.existing, required this.date});
  final Activity? existing;
  final DateTime date;

  @override
  State<_ActivitySheet> createState() => _ActivitySheetState();
}

class _ActivitySheetState extends State<_ActivitySheet> {
  late final _title = TextEditingController(text: widget.existing?.title);
  late DateTime _day = dayOnly(widget.existing?.date ?? widget.date);
  late TimeOfDay? _time = widget.existing?.hasTime == true ? TimeOfDay.fromDateTime(widget.existing!.date) : null;
  late Category _category = widget.existing?.category ?? Category.none;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      setState(() => _error = 'Give your activity a name');
      return;
    }
    final date = _time == null ? _day : DateTime(_day.year, _day.month, _day.day, _time!.hour, _time!.minute);
    final base = widget.existing ?? Activity(title: '', date: date);
    final data = context.read<DataService>();
    Navigator.pop(context);
    await data.saveActivity(
        base.copyWith(title: _title.text.trim(), date: date, hasTime: _time != null, category: _category));
  }

  Future<void> _delete() async {
    final data = context.read<DataService>();
    final ok = await confirmDialog(context, 'Delete activity?', '"${widget.existing!.title}" will be removed.');
    if (!ok || !mounted) return;
    Navigator.pop(context);
    await data.deleteActivity(widget.existing!.id);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ln;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
            child: Text(widget.existing == null ? 'New activity' : 'Edit activity',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          if (widget.existing != null)
            IconButton(onPressed: _delete, icon: Icon(Icons.delete_outline_rounded, color: c.danger)),
        ]),
        const SizedBox(height: 12),
        TextField(
          controller: _title,
          autofocus: widget.existing == null,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(hintText: 'e.g. Morning run, Read 20 pages', errorText: _error),
          onChanged: (_) => _error == null ? null : setState(() => _error = null),
          onSubmitted: (_) => _save(),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _day,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _day = picked);
              },
              icon: const Icon(Icons.calendar_today_outlined, size: 16),
              label: Text(DateFormat('MMM d, y').format(_day)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                final picked = await showTimePicker(context: context, initialTime: _time ?? TimeOfDay.now());
                if (picked != null) setState(() => _time = picked);
              },
              onLongPress: () => setState(() => _time = null),
              icon: const Icon(Icons.schedule_rounded, size: 16),
              label: Text(_time == null ? 'Add time' : _time!.format(context)),
            ),
          ),
          if (_time != null)
            IconButton(
              tooltip: 'Clear time',
              onPressed: () => setState(() => _time = null),
              icon: Icon(Icons.close_rounded, size: 18, color: c.muted),
            ),
        ]),
        const SizedBox(height: 14),
        CategoryChips(selected: _category, onChanged: (v) => setState(() => _category = v ?? Category.none)),
        const SizedBox(height: 20),
        FilledButton(onPressed: _save, child: const Text('Save activity')),
      ]),
    );
  }
}

Future<void> showProjectSheet(BuildContext context, {Project? existing}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ProjectSheet(existing: existing),
  );
}

class _ProjectSheet extends StatefulWidget {
  const _ProjectSheet({this.existing});
  final Project? existing;

  @override
  State<_ProjectSheet> createState() => _ProjectSheetState();
}

class _ProjectSheetState extends State<_ProjectSheet> {
  late final _title = TextEditingController(text: widget.existing?.title);
  late Category _category = widget.existing?.category ?? Category.none;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      setState(() => _error = 'Give your project a name');
      return;
    }
    final data = context.read<DataService>();
    final base = widget.existing ?? Project(title: '');
    Navigator.pop(context);
    await data.saveProject(base.copyWith(title: _title.text.trim(), category: _category));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(widget.existing == null ? 'New project' : 'Edit project',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        TextField(
          controller: _title,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(hintText: 'e.g. Fitness plan, Work sprint', errorText: _error),
          onSubmitted: (_) => _save(),
        ),
        const SizedBox(height: 14),
        CategoryChips(selected: _category, onChanged: (v) => setState(() => _category = v ?? Category.none)),
        const SizedBox(height: 20),
        FilledButton(onPressed: _save, child: const Text('Save project')),
      ]),
    );
  }
}
