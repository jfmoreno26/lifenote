import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'sheets.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final Set<String> _expanded = {};
  bool _initialised = false;

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataService>();
    final projects = data.projects;
    if (!_initialised && projects.isNotEmpty) {
      _expanded.add(projects.first.id);
      _initialised = true;
    }
    final almost = projects.where((p) => p.almostDone).length;

    return SafeArea(
      bottom: false,
      child: ListView(padding: const EdgeInsets.only(bottom: 110), children: [
        PageHeader(
          title: 'Projects',
          subtitle: '${projects.length} projects · $almost almost done',
          trailing: PillButton(label: 'New', icon: Icons.add_rounded, onTap: () => showProjectSheet(context)),
        ),
        if (projects.isEmpty)
          const EmptyState(icon: Icons.folder_open_rounded, message: 'No projects yet. Tap + to start one.'),
        for (final p in projects)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: _ProjectCard(
              project: p,
              expanded: _expanded.contains(p.id),
              onToggle: () => setState(() => _expanded.contains(p.id) ? _expanded.remove(p.id) : _expanded.add(p.id)),
            ),
          ),
      ]),
    );
  }
}

class _ProjectCard extends StatefulWidget {
  const _ProjectCard({required this.project, required this.expanded, required this.onToggle});
  final Project project;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  State<_ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<_ProjectCard> {
  final _newTask = TextEditingController();
  bool _adding = false;

  @override
  void dispose() {
    _newTask.dispose();
    super.dispose();
  }

  Future<void> _submitTask() async {
    final text = _newTask.text.trim();
    if (text.isEmpty) {
      setState(() => _adding = false);
      return;
    }
    _newTask.clear();
    await context.read<DataService>().addTask(widget.project, text);
  }

  Future<void> _menu(String action) async {
    final data = context.read<DataService>();
    final p = widget.project;
    if (action == 'edit') {
      await showProjectSheet(context, existing: p);
    } else if (action == 'delete') {
      final ok = await confirmDialog(context, 'Delete project?', '"${p.title}" and its ${p.tasks.length} tasks will be removed.');
      if (ok) await data.deleteProject(p.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ln;
    final data = context.read<DataService>();
    final p = widget.project;
    final accent = p.category == Category.none ? c.primary : p.category.color;

    return LnCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        InkWell(
          onTap: widget.onToggle,
          borderRadius: BorderRadius.circular(12),
          child: Row(children: [
            CategoryIcon(p.category, size: 38),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                Text('${p.doneCount} of ${p.tasks.length} tasks done', style: TextStyle(color: c.muted, fontSize: 12)),
              ]),
            ),
            if (widget.expanded)
              Text('${(p.progress * 100).round()}%',
                  style: TextStyle(color: accent, fontWeight: FontWeight.w800, fontSize: 16))
            else
              Icon(Icons.keyboard_arrow_down_rounded, color: c.muted),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, color: c.muted, size: 20),
              onSelected: _menu,
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit project')),
                PopupMenuItem(value: 'delete', child: Text('Delete project')),
              ],
            ),
          ]),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: p.progress,
              minHeight: 5,
              color: accent,
              backgroundColor: c.surfaceAlt,
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: !widget.expanded
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 8, right: 8),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    for (final t in p.tasks)
                      InkWell(
                        onTap: () => data.toggleTask(p, t),
                        onLongPress: () async {
                          final title = await textPrompt(context, 'Rename task', initial: t.title);
                          if (title != null && title.isNotEmpty) await data.renameTask(p, t, title);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(children: [
                            CheckCircle(done: t.done, size: 20, color: c.primary, onTap: () => data.toggleTask(p, t)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(t.title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: t.done ? c.muted : c.text,
                                    decoration: t.done ? TextDecoration.lineThrough : null,
                                  )),
                            ),
                            InkResponse(
                              onTap: () => data.deleteTask(p, t),
                              child: Icon(Icons.close_rounded, size: 16, color: c.muted),
                            ),
                          ]),
                        ),
                      ),
                    if (_adding)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: TextField(
                          controller: _newTask,
                          autofocus: true,
                          decoration: const InputDecoration(hintText: 'New task', isDense: true),
                          onSubmitted: (_) => _submitTask(),
                          onTapOutside: (_) => _submitTask(),
                        ),
                      ),
                    TextButton.icon(
                      onPressed: () => _adding ? _submitTask() : setState(() => _adding = true),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(_adding ? 'Save task' : 'Add task'),
                    ),
                  ]),
                ),
        ),
      ]),
    );
  }
}
