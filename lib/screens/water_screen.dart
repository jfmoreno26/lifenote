import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class WaterScreen extends StatelessWidget {
  const WaterScreen({super.key});

  Future<void> _editGoal(BuildContext context, int goal, int ml) async {
    var g = goal;
    var m = ml;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: const Text('Daily goal'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              const Expanded(child: Text('Glasses per day')),
              IconButton(onPressed: g > 1 ? () => set(() => g--) : null, icon: const Icon(Icons.remove_circle_outline)),
              Text('$g', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              IconButton(onPressed: g < 20 ? () => set(() => g++) : null, icon: const Icon(Icons.add_circle_outline)),
            ]),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 200, label: Text('200 ml')),
                ButtonSegment(value: 250, label: Text('250 ml')),
                ButtonSegment(value: 330, label: Text('330 ml')),
              ],
              selected: {m},
              onSelectionChanged: (s) => set(() => m = s.first),
            ),
            const SizedBox(height: 12),
            Text('= ${(g * m / 1000).toStringAsFixed(2)} L per day', style: TextStyle(color: ctx.ln.muted)),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (ok == true && context.mounted) await context.read<AuthService>().updateWaterGoal(g, m);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ln;
    final data = context.watch<DataService>();
    final profile = context.watch<AuthService>().profile;
    final goal = profile?.waterGoal ?? 8;
    final ml = profile?.glassMl ?? 250;
    final now = DateTime.now();
    final glasses = data.glassesOn(now);
    final leftL = (goal - glasses).clamp(0, goal) * ml / 1000;
    final week = data.waterHistory(7);
    final avg = week.reduce((a, b) => a + b) / week.length;
    final labels = [
      for (var i = 6; i >= 0; i--) DateFormat('E').format(DateTime(now.year, now.month, now.day - i)).substring(0, 1)
    ];
    final tiles = goal > glasses ? goal : glasses;

    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), children: [
          Row(children: [
            CircleIconButton(icon: Icons.arrow_back_rounded, background: c.surface, onTap: () => Navigator.pop(context)),
            const SizedBox(width: 12),
            const Expanded(child: Text('Water tracker', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
            PillButton(
              label: 'Goal ${(goal * ml / 1000).toStringAsFixed(goal * ml % 1000 == 0 ? 0 : 1)} L',
              icon: Icons.water_drop_rounded,
              color: c.water,
              background: c.waterSoft,
              onTap: () => _editGoal(context, goal, ml),
            ),
          ]),
          const SizedBox(height: 24),
          Center(
            child: ProgressRing(
              value: glasses / goal,
              size: 200,
              stroke: 18,
              color: c.water,
              track: c.waterSoft,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('$glasses', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w800, height: 1)),
                Text('of $goal glasses', style: TextStyle(color: c.muted, fontSize: 13)),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Text(leftL <= 0 ? 'Goal reached — great job!' : '${leftL.toStringAsFixed(leftL == leftL.roundToDouble() ? 0 : 1)} L to go today',
              textAlign: TextAlign.center, style: TextStyle(color: c.muted, fontSize: 13)),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1,
            children: [
              for (var i = 0; i < tiles; i++)
                _GlassTile(
                  ml: ml,
                  filled: i < glasses,
                  // Tapping a glass fills up to it; tapping the last full one empties it.
                  onTap: () => data.setGlasses(now, i + 1 == glasses ? i : i + 1),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: glasses == 0 ? null : () => data.addGlass(-1),
                child: const Text('Remove'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: FilledButton(onPressed: () => data.addGlass(), child: const Text('Add glass'))),
          ]),
          const SizedBox(height: 20),
          LnCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Expanded(child: Text('Last 7 days', style: TextStyle(fontWeight: FontWeight.w700))),
                Text('Avg ${avg.toStringAsFixed(1)} glasses', style: TextStyle(color: c.muted, fontSize: 12)),
              ]),
              const SizedBox(height: 16),
              BarChart(values: week, labels: labels, color: c.water, track: c.waterSoft, maxValue: goal),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _GlassTile extends StatelessWidget {
  const _GlassTile({required this.ml, required this.filled, required this.onTap});
  final int ml;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ln;
    return Material(
      color: filled ? c.waterSoft : c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: filled ? c.water : c.border, width: filled ? 1.5 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(filled ? Icons.water_drop_rounded : Icons.water_drop_outlined,
              color: filled ? c.water : c.muted, size: 22),
          const SizedBox(height: 4),
          Text('$ml ml',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: filled ? c.water : c.muted)),
        ]),
      ),
    );
  }
}
