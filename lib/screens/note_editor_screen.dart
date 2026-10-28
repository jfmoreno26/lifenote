import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class NoteEditorScreen extends StatefulWidget {
  const NoteEditorScreen({super.key, this.note});

  /// `null` creates a new note.
  final Note? note;

  static Future<void> open(BuildContext context, [Note? note]) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => NoteEditorScreen(note: note)));

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late Note _note = widget.note ?? Note();
  late final _title = TextEditingController(text: _note.title);
  late final _body = TextEditingController(text: _note.body);
  bool _dirty = false;
  bool _closing = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  void _change(Note n) => setState(() {
        _note = n;
        _dirty = true;
      });

  /// Saves (if anything changed and the note isn't blank) and closes.
  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    final data = context.read<DataService>();
    final n = _note.copyWith(title: _title.text.trim(), body: _body.text.trim());
    final blank = n.title.isEmpty && n.body.isEmpty;
    final changed = _dirty || n.title != widget.note?.title || n.body != widget.note?.body;
    Navigator.pop(context);
    if (blank && n.id.isEmpty) return;
    if (changed) {
      try {
        await data.saveNote(n);
      } catch (e) {
        debugPrint('Note save failed: $e');
      }
    }
  }

  Future<void> _delete() async {
    final data = context.read<DataService>();
    if (_note.id.isEmpty) {
      Navigator.pop(context);
      return;
    }
    final ok = await confirmDialog(context, 'Delete note?', 'This note will be permanently removed.');
    if (!ok || !mounted) return;
    _closing = true;
    Navigator.pop(context);
    await data.deleteNote(_note.id);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ln;
    final bg = c.note(_note.color);
    final translucent = Colors.white.withValues(alpha: context.isDark ? 0.08 : 0.55);
    final stamp = sameDay(_note.updatedAt, DateTime.now())
        ? 'Today · ${DateFormat.jm().format(_note.updatedAt)}'
        : DateFormat('MMM d, y · h:mm a').format(_note.updatedAt);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(children: [
                CircleIconButton(icon: Icons.arrow_back_rounded, background: translucent, onTap: _close),
                const Spacer(),
                CircleIconButton(
                  icon: _note.pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                  tooltip: _note.pinned ? 'Unpin' : 'Pin',
                  background: translucent,
                  onTap: () => _change(_note.copyWith(pinned: !_note.pinned)),
                ),
                const SizedBox(width: 8),
                CircleIconButton(
                  icon: Icons.delete_outline_rounded,
                  tooltip: 'Delete',
                  background: translucent,
                  onTap: _delete,
                ),
                const SizedBox(width: 8),
                CircleIconButton(
                  icon: Icons.check_rounded,
                  tooltip: 'Save',
                  background: c.text,
                  color: c.bg,
                  onTap: () {
                    _dirty = true;
                    _close();
                  },
                ),
              ]),
            ),
            Expanded(
              child: ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 20), children: [
                TextField(
                  controller: _title,
                  autofocus: widget.note == null,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: null,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.4),
                  decoration: _bare('Title'),
                ),
                const SizedBox(height: 4),
                Text(stamp, style: TextStyle(color: c.text.withValues(alpha: 0.55), fontSize: 12)),
                const SizedBox(height: 12),
                TextField(
                  controller: _body,
                  maxLines: null,
                  minLines: 8,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(fontSize: 15, height: 1.5),
                  decoration: _bare('Start writing…'),
                ),
              ]),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label(context, 'LINK TO ACTIVITY'),
                CategoryChips(selected: _note.category, onChanged: (v) => _change(_note.copyWith(category: v))),
                const SizedBox(height: 16),
                _label(context, 'NOTE COLOR'),
                Wrap(spacing: 12, children: [
                  for (var i = 0; i < c.notes.length; i++)
                    GestureDetector(
                      onTap: () => _change(_note.copyWith(color: i)),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: c.notes[i],
                          shape: BoxShape.circle,
                          border: Border.all(color: i == _note.color ? c.text : c.border, width: i == _note.color ? 2 : 1),
                        ),
                        child: i == _note.color ? Icon(Icons.check_rounded, size: 16, color: c.text) : null,
                      ),
                    ),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  InputDecoration _bare(String hint) => InputDecoration(
        hintText: hint,
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        isCollapsed: true,
      );

  Widget _label(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: TextStyle(color: context.ln.muted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
      );
}
