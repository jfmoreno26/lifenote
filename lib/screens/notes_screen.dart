import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'note_editor_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  String _query = '';
  Category? _filter;
  bool _grid = true;

  @override
  Widget build(BuildContext context) {
    final c = context.ln;
    final data = context.watch<DataService>();
    final q = _query.toLowerCase();
    final notes = data.notes
        .where((n) => _filter == null || n.category == _filter)
        .where((n) => q.isEmpty || n.title.toLowerCase().contains(q) || n.body.toLowerCase().contains(q))
        .toList();
    final pinned = data.notes.where((n) => n.pinned).length;

    return SafeArea(
      bottom: false,
      child: CustomScrollView(slivers: [
        SliverToBoxAdapter(
          child: PageHeader(
            title: 'Notes',
            subtitle: '${data.notes.length} notes · $pinned pinned',
            trailing: CircleIconButton(
              icon: _grid ? Icons.view_agenda_outlined : Icons.grid_view_rounded,
              tooltip: _grid ? 'List view' : 'Grid view',
              background: c.surface,
              onTap: () => setState(() => _grid = !_grid),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search notes',
                prefixIcon: Icon(Icons.search_rounded, color: c.muted),
                isDense: true,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: CategoryChips(
            selected: _filter,
            includeAll: true,
            includeNone: false,
            scroll: true,
            onChanged: (v) => setState(() => _filter = v),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 14)),
        if (notes.isEmpty)
          SliverToBoxAdapter(
            child: EmptyState(
              icon: Icons.sticky_note_2_outlined,
              message: data.notes.isEmpty ? 'No notes yet. Tap + to write your first note.' : 'No notes match.',
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
            sliver: SliverToBoxAdapter(child: _grid ? _masonry(notes) : _list(notes)),
          ),
      ]),
    );
  }

  Widget _masonry(List<Note> notes) {
    Widget column(int offset) => Column(children: [
          for (var i = offset; i < notes.length; i += 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: NoteCard(note: notes[i], onTap: () => NoteEditorScreen.open(context, notes[i])),
            ),
        ]);
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: column(0)),
      const SizedBox(width: 10),
      Expanded(child: column(1)),
    ]);
  }

  Widget _list(List<Note> notes) => Column(children: [
        for (final n in notes)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SizedBox(
              width: double.infinity,
              child: NoteCard(note: n, maxLines: 3, onTap: () => NoteEditorScreen.open(context, n)),
            ),
          ),
      ]);
}
