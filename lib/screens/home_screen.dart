import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/alert_service.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'alerts_screen.dart';
import 'note_editor_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'sheets.dart';
import 'water_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onNavigate});

  /// Switches the bottom-nav tab (1 = Notes, 2 = Calendar).
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final c = context.ln;
    final data = context.watch<DataService>();
    final auth = context.watch<AuthService>();
    final alerts = context.watch<AlertService>().count;
    final now = DateTime.now();
    final today = data.activitiesOn(now);
    final pinned = data.pinnedNotes;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          PageHeader(
            overline: DateFormat('EEEE, MMMM d').format(now),
            title: 'Good to see you',
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                tooltip: 'Search',
                icon: const Icon(Icons.search_rounded),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
              ),
              IconButton(
                tooltip: 'Alerts',
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertsScreen())),
                icon: Badge(
                  isLabelVisible: alerts > 0,
                  label: Text('$alerts'),
                  child: const Icon(Icons.notifications_none_rounded),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                child: Avatar(initials: auth.profile?.initials ?? '?', size: 36),
              ),
            ]),
          ),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: WaterCard()),
          SectionHeader(title: 'Pinned notes', action: 'See all', onAction: () => onNavigate(1)),
          if (pinned.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: LnCard(
                child: EmptyState(icon: Icons.push_pin_outlined, message: 'Pin a note to keep it here.'),
              ),
            )
          else
            SizedBox(
              height: 168,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: pinned.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, i) => Align(
                  alignment: Alignment.topCenter,
                  child: NoteCard(
                    note: pinned[i],
                    width: 150,
                    maxLines: 4,
                    onTap: () => NoteEditorScreen.open(context, pinned[i]),
                  ),
                ),
              ),
            ),
          SectionHeader(title: 'Today', action: 'Calendar', onAction: () => onNavigate(2)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: LnCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: today.isEmpty
                  ? EmptyState(icon: Icons.event_available_outlined, message: 'Nothing planned today.\nTap + to add an activity.')
                  : Column(children: [
                      for (var i = 0; i < today.length; i++) ...[
                        if (i > 0) Divider(color: c.border),
                        ActivityTile(
                          activity: today[i],
                          onToggle: () => data.toggleActivity(today[i]),
                          onTap: () => showActivitySheet(context, existing: today[i]),
                        ),
                      ],
                    ]),
            ),
          ),
        ],
      ),
    );
  }
}

/// Blue water-intake summary card from the home screen.
class WaterCard extends StatelessWidget {
  const WaterCard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.ln;
    final data = context.watch<DataService>();
    final profile = context.watch<AuthService>().profile;
    final goal = profile?.waterGoal ?? 8;
    final ml = profile?.glassMl ?? 250;
    final glasses = data.glassesOn(DateTime.now());
    final left = ((goal - glasses).clamp(0, goal) * ml) / 1000;

    return Material(
      color: c.water,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WaterScreen())),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(children: [
            Row(children: [
              ProgressRing(
                value: glasses / goal,
                size: 84,
                stroke: 8,
                color: Colors.white,
                track: Colors.white.withValues(alpha: 0.25),
                child: Text('$glasses/$goal',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('WATER INTAKE',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 10,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('$glasses of $goal glasses',
                      style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
                  Text(left <= 0 ? 'Goal reached today!' : '${_fmtL(left)} L to go today',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
                  const SizedBox(height: 10),
                  Row(children: [
                    CircleIconButton(
                      icon: Icons.remove_rounded,
                      size: 34,
                      tooltip: 'Remove glass',
                      background: Colors.white.withValues(alpha: 0.2),
                      color: Colors.white,
                      onTap: glasses == 0 ? null : () => data.addGlass(-1),
                    ),
                    const SizedBox(width: 8),
                    PillButton(
                      label: 'Add glass',
                      icon: Icons.add_rounded,
                      background: Colors.white,
                      color: LnColors.light.water,
                      onTap: () => data.addGlass(),
                    ),
                  ]),
                ]),
              ),
            ]),
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              for (var i = 0; i < goal.clamp(1, 12); i++)
                Icon(
                  i < glasses ? Icons.water_drop_rounded : Icons.water_drop_outlined,
                  size: 18,
                  color: Colors.white.withValues(alpha: i < glasses ? 1 : 0.45),
                ),
            ]),
          ]),
        ),
      ),
    );
  }
}

String _fmtL(double l) => l == l.roundToDouble() ? l.toStringAsFixed(0) : l.toStringAsFixed(1);
