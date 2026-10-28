import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/alert_service.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';
import 'alerts_screen.dart';
import 'calendar_screen.dart';
import 'home_screen.dart';
import 'note_editor_screen.dart';
import 'notes_screen.dart';
import 'projects_screen.dart';
import 'sheets.dart';

/// Bottom-nav shell: Home, Notes, [+], Calendar, Projects.
class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tab = 0;
  final _calendarDay = ValueNotifier(dayOnly(DateTime.now()));
  StreamSubscription<AppAlert>? _alertSub;

  @override
  void initState() {
    super.initState();
    _alertSub = context.read<AlertService>().onNewAlert.listen(_toast);
  }

  @override
  void dispose() {
    _alertSub?.cancel();
    _calendarDay.dispose();
    super.dispose();
  }

  void _toast(AppAlert a) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Row(children: [
          Icon(a.icon, color: levelColor(context, a.level), size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(a.title)),
        ]),
        action: SnackBarAction(
          label: 'View',
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertsScreen())),
        ),
      ));
  }

  void _add() {
    switch (_tab) {
      case 1:
        NoteEditorScreen.open(context);
      case 2:
        showActivitySheet(context, date: _calendarDay.value);
      case 3:
        showProjectSheet(context);
      default:
        _quickAdd();
    }
  }

  void _quickAdd() {
    final data = context.read<DataService>();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _quick(ctx, Icons.sticky_note_2_outlined, 'New note', () => NoteEditorScreen.open(context)),
          _quick(ctx, Icons.event_outlined, 'New activity', () => showActivitySheet(context)),
          _quick(ctx, Icons.folder_outlined, 'New project', () => showProjectSheet(context)),
          _quick(ctx, Icons.water_drop_outlined, 'Log a glass of water', () => data.addGlass()),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Widget _quick(BuildContext ctx, IconData icon, String label, VoidCallback action) => ListTile(
        leading: Icon(icon, color: ctx.ln.primary),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        onTap: () {
          Navigator.pop(ctx);
          action();
        },
      );

  @override
  Widget build(BuildContext context) {
    final c = context.ln;
    final loaded = context.select<DataService, bool>((d) => d.loaded);
    final pages = [
      HomeScreen(onNavigate: (i) => setState(() => _tab = i)),
      const NotesScreen(),
      CalendarScreen(selected: _calendarDay),
      const ProjectsScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: loaded ? IndexedStack(index: _tab, children: pages) : const Center(child: CircularProgressIndicator()),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: c.surface, border: Border(top: BorderSide(color: c.border))),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(children: [
              _nav(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
              _nav(1, Icons.sticky_note_2_outlined, Icons.sticky_note_2_rounded, 'Notes'),
              Expanded(
                child: Center(
                  child: Material(
                    color: c.primary,
                    shape: const CircleBorder(),
                    elevation: 4,
                    shadowColor: c.primary.withValues(alpha: 0.5),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _add,
                      child: const SizedBox(width: 50, height: 50, child: Icon(Icons.add_rounded, color: Colors.white, size: 28)),
                    ),
                  ),
                ),
              ),
              _nav(2, Icons.calendar_today_outlined, Icons.calendar_today_rounded, 'Calendar'),
              _nav(3, Icons.folder_copy_outlined, Icons.folder_copy_rounded, 'Projects'),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _nav(int index, IconData icon, IconData active, String label) {
    final c = context.ln;
    final sel = _tab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tab = index),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(color: sel ? c.primarySoft : null, borderRadius: BorderRadius.circular(12)),
            child: Icon(sel ? active : icon, size: 22, color: sel ? c.primary : c.muted),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(fontSize: 11, fontWeight: sel ? FontWeight.w700 : FontWeight.w500, color: sel ? c.primary : c.muted)),
        ]),
      ),
    );
  }
}
