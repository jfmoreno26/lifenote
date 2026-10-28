import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

class LnCard extends StatelessWidget {
  const LnCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ln;
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: c.border)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
    );
  }
}

/// Large page title with a muted subtitle and optional trailing action.
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.subtitle, this.trailing, this.overline});

  final String title;
  final String? subtitle;
  final String? overline;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.ln;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (overline != null)
                  Text(overline!, style: TextStyle(color: c.muted, fontSize: 12, fontWeight: FontWeight.w500)),
                Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                if (subtitle != null)
                  Text(subtitle!, style: TextStyle(color: c.muted, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.ln;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
          if (action != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: onAction == null ? c.muted : c.primary,
                visualDensity: VisualDensity.compact,
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              child: Text(action!),
            ),
        ],
      ),
    );
  }
}

/// Small rounded pill button, e.g. "Today" or "+ New".
class PillButton extends StatelessWidget {
  const PillButton({super.key, required this.label, this.icon, this.onTap, this.color, this.background});

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final Color? color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final c = context.ln;
    final fg = color ?? c.primary;
    return Material(
      color: background ?? c.primarySoft,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Icon(icon, size: 15, color: fg), const SizedBox(width: 4)],
            Text(label, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    );
  }
}

/// Round icon button with a soft background (editor toolbar, calendar arrows).
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 38,
    this.background,
    this.color,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color? background;
  final Color? color;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final c = context.ln;
    final btn = Material(
      color: background ?? c.surfaceAlt,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: size, height: size, child: Icon(icon, size: size * 0.5, color: color ?? c.text)),
      ),
    );
    return tooltip == null ? btn : Tooltip(message: tooltip!, child: btn);
  }
}

class CategoryTag extends StatelessWidget {
  const CategoryTag(this.category, {super.key});
  final Category category;

  @override
  Widget build(BuildContext context) {
    if (category == Category.none) return const SizedBox.shrink();
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(category.icon, size: 13, color: category.color),
      const SizedBox(width: 4),
      Text(category.label, style: TextStyle(color: category.color, fontSize: 11, fontWeight: FontWeight.w600)),
    ]);
  }
}

/// Tinted rounded square holding a category icon.
class CategoryIcon extends StatelessWidget {
  const CategoryIcon(this.category, {super.key, this.size = 36});
  final Category category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = category == Category.none ? context.ln.primary : category.color;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: context.isDark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(category == Category.none ? Icons.event_note_rounded : category.icon,
          size: size * 0.5, color: color),
    );
  }
}

/// Selectable category chips used by the editor, activity sheet and filters.
class CategoryChips extends StatelessWidget {
  const CategoryChips({
    super.key,
    required this.selected,
    required this.onChanged,
    this.includeNone = true,
    this.includeAll = false,
    this.scroll = false,
  });

  /// `null` means "All" when [includeAll] is set.
  final Category? selected;
  final ValueChanged<Category?> onChanged;
  final bool includeNone;
  final bool includeAll;
  final bool scroll;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      if (includeAll) _chip(context, null, 'All', null, selected == null),
      for (final cat in Category.values)
        if (cat != Category.none || includeNone) _chip(context, cat, cat.label, cat.icon, selected == cat),
    ];
    if (scroll) {
      return SizedBox(
        height: 34,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: chips.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (_, i) => chips[i],
        ),
      );
    }
    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }

  Widget _chip(BuildContext context, Category? cat, String label, IconData? icon, bool active) {
    final c = context.ln;
    final accent = cat == null || cat == Category.none ? c.primary : cat.color;
    final allStyle = cat == null;
    final bg = active
        ? (allStyle ? c.primary : accent.withValues(alpha: context.isDark ? 0.22 : 0.12))
        : c.surface;
    final fg = active ? (allStyle ? Colors.white : accent) : c.text;
    return Material(
      color: bg,
      shape: StadiumBorder(side: BorderSide(color: active ? accent : c.border)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () => onChanged(cat),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Icon(icon, size: 14, color: active ? accent : (cat?.color ?? c.muted)), const SizedBox(width: 5)],
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
          ]),
        ),
      ),
    );
  }
}

class CheckCircle extends StatelessWidget {
  const CheckCircle({super.key, required this.done, this.onTap, this.size = 24, this.color});
  final bool done;
  final VoidCallback? onTap;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.ln;
    final accent = color ?? c.success;
    return InkResponse(
      onTap: onTap,
      radius: size,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done ? accent : Colors.transparent,
          border: Border.all(color: done ? accent : c.border, width: 1.6),
        ),
        child: done ? Icon(Icons.check_rounded, size: size * 0.65, color: Colors.white) : null,
      ),
    );
  }
}

class ActivityTile extends StatelessWidget {
  const ActivityTile({super.key, required this.activity, this.onToggle, this.onTap, this.showDate = false});
  final Activity activity;
  final VoidCallback? onToggle;
  final VoidCallback? onTap;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final c = context.ln;
    final a = activity;
    final parts = [
      if (showDate) DateFormat('MMM d').format(a.date),
      if (a.hasTime) DateFormat.jm().format(a.date) else if (!showDate) 'Any time',
      if (a.category != Category.none) a.category.label,
    ];
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          CategoryIcon(a.category),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: a.done ? c.muted : c.text,
                    decoration: a.done ? TextDecoration.lineThrough : null,
                  )),
              const SizedBox(height: 2),
              Text(parts.join(' · '), style: TextStyle(color: c.muted, fontSize: 12)),
            ]),
          ),
          CheckCircle(done: a.done, onTap: onToggle),
        ]),
      ),
    );
  }
}

class NoteCard extends StatelessWidget {
  const NoteCard({super.key, required this.note, this.onTap, this.maxLines = 6, this.width});
  final Note note;
  final VoidCallback? onTap;
  final int maxLines;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final c = context.ln;
    return SizedBox(
      width: width,
      child: Material(
        color: c.note(note.color),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Text(note.title.isEmpty ? 'Untitled' : note.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                ),
                if (note.pinned) Icon(Icons.push_pin_rounded, size: 14, color: c.text.withValues(alpha: 0.7)),
              ]),
              if (note.body.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(note.body,
                    maxLines: maxLines,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, height: 1.35, color: c.text.withValues(alpha: 0.7))),
              ],
              if (note.category != Category.none) ...[const SizedBox(height: 10), CategoryTag(note.category)],
            ]),
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.ln;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(children: [
        Icon(icon, size: 32, color: c.muted.withValues(alpha: 0.6)),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center, style: TextStyle(color: c.muted, fontSize: 13)),
      ]),
    );
  }
}

class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.initials, this.size = 38});
  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.ln;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: c.primarySoft, shape: BoxShape.circle),
      child: Text(initials, style: TextStyle(color: c.primary, fontWeight: FontWeight.w700, fontSize: size * 0.36)),
    );
  }
}

/// Circular progress ring with arbitrary center content.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    required this.size,
    required this.color,
    required this.track,
    this.stroke = 10,
    this.child,
  });

  final double value;
  final double size;
  final Color color;
  final Color track;
  final double stroke;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.clamp(0, 1)),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (_, v, _) => CustomPaint(
        size: Size.square(size),
        painter: _RingPainter(v, color, track, stroke),
        child: SizedBox.square(dimension: size, child: Center(child: child)),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.color, this.track, this.stroke);
  final double value;
  final Color color;
  final Color track;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = rect.deflate(stroke / 2);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(r, 0, math.pi * 2, false, p..color = track);
    if (value > 0) canvas.drawArc(r, -math.pi / 2, math.pi * 2 * value, false, p..color = color);
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.value != value || o.color != color || o.track != track;
}

/// Simple vertical bar chart; the last bar is emphasised as "today".
class BarChart extends StatelessWidget {
  const BarChart({
    super.key,
    required this.values,
    required this.labels,
    required this.color,
    required this.track,
    this.height = 120,
    this.maxValue,
    this.labelEvery = 1,
  });

  final List<int> values;
  final List<String> labels;
  final Color color;
  final Color track;
  final double height;
  final int? maxValue;
  final int labelEvery;

  @override
  Widget build(BuildContext context) {
    final c = context.ln;
    final top = math.max(1, maxValue ?? values.fold<int>(1, math.max)).toDouble();
    final gap = values.length > 14 ? 2.0 : 6.0;
    return Column(children: [
      SizedBox(
        height: height,
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Tooltip(
                message: '${labels[i]}: ${values[i]}',
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: gap / 2),
                  child: Stack(alignment: Alignment.bottomCenter, children: [
                    Container(decoration: BoxDecoration(color: track, borderRadius: BorderRadius.circular(6))),
                    FractionallySizedBox(
                      heightFactor: (values[i] / top).clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: i == values.length - 1 ? color : color.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
        ]),
      ),
      const SizedBox(height: 6),
      Row(children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: Text(
              i % labelEvery == 0 || i == labels.length - 1 ? labels[i] : '',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: i == labels.length - 1 ? c.text : c.muted,
                fontWeight: i == labels.length - 1 ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
      ]),
    ]);
  }
}

Future<bool> confirmDialog(BuildContext context, String title, String message, {String action = 'Delete'}) async {
  final c = context.ln;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: c.danger),
          child: Text(action),
        ),
      ],
    ),
  );
  return ok ?? false;
}

Future<String?> textPrompt(BuildContext context, String title,
    {String initial = '', String hint = '', String action = 'Save'}) {
  final ctrl = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        decoration: InputDecoration(hintText: hint),
        onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: Text(action)),
      ],
    ),
  );
}

void showMessage(BuildContext context, String message, {bool error = false}) {
  final c = context.ln;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), backgroundColor: error ? c.danger : null));
}
