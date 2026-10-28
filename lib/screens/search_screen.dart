import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'note_editor_screen.dart';
import 'sheets.dart';

/// Searches notes, activities and projects at once.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final c = context.ln;
    final data = context.watch<DataService>();
    final q = _q.trim().toLowerCase();
    bool hit(String s) => s.toLowerCase().contains(q);
    final notes = q.isEmpty ? <Note>[] : data.notes.where((n) => hit(n.title) || hit(n.body)).toList();
    final acts = q.isEmpty ? <Activity>[] : data.activities.where((a) => hit(a.title)).toList().reversed.toList();
    final projects = q.isEmpty ? <Project>[] : data.projects.where((p) => hit(p.title) || p.tasks.any((t) => hit(t.title))).toList();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          autofocus: true,
          onChanged: (v) => setState(() => _q = v),
          decoration: const InputDecoration(hintText: 'Search notes, activities, projects', isDense: true),
        ),
        actions: const [SizedBox(width: 16)],
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 32), children: [
        if (q.isNotEmpty && notes.isEmpty && acts.isEmpty && projects.isEmpty)
          const EmptyState(icon: Icons.search_off_rounded, message: 'No results.'),
        if (notes.isNotEmpty) ...[
          _h(context, 'Notes'),
          for (final n in notes)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                width: double.infinity,
                child: NoteCard(note: n, maxLines: 2, onTap: () => NoteEditorScreen.open(context, n)),
              ),
            ),
        ],
        if (acts.isNotEmpty) ...[
          _h(context, 'Activities'),
          LnCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Column(children: [
              for (final a in acts)
                ActivityTile(
                  activity: a,
                  showDate: true,
                  onToggle: () => data.toggleActivity(a),
                  onTap: () => showActivitySheet(context, existing: a),
                ),
            ]),
          ),
        ],
        if (projects.isNotEmpty) ...[
          _h(context, 'Projects'),
          for (final p in projects)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: LnCard(
                child: Row(children: [
                  CategoryIcon(p.category),
                  const SizedBox(width: 12),
                  Expanded(child: Text(p.title, style: const TextStyle(fontWeight: FontWeight.w600))),
                  Text('${p.doneCount}/${p.tasks.length}', style: TextStyle(color: c.muted)),
                ]),
              ),
            ),
        ],
      ]),
    );
  }

  Widget _h(BuildContext context, String t) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 0, 8),
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.w700)),
      );
}
