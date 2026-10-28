import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'admin_screen.dart';
import 'alerts_screen.dart';
import 'reports_screen.dart';
import 'water_screen.dart';

/// Account management, appearance and navigation to reports/admin.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _run(BuildContext context, Future<void> Function() fn, String success) async {
    try {
      await fn();
      if (context.mounted) showMessage(context, success);
    } on AuthFailure catch (e) {
      if (context.mounted) showMessage(context, e.message, error: true);
    }
  }

  Future<void> _changePassword(BuildContext context) async {
    final current = TextEditingController();
    final next = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change password'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: current, obscureText: true, decoration: const InputDecoration(hintText: 'Current password')),
          const SizedBox(height: 10),
          TextField(controller: next, obscureText: true, decoration: const InputDecoration(hintText: 'New password (6+ chars)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Update')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    if (next.text.length < 6) return showMessage(context, 'New password must be at least 6 characters.', error: true);
    await _run(context, () => context.read<AuthService>().changePassword(current.text, next.text), 'Password updated');
  }

  Future<void> _changeEmail(BuildContext context) async {
    final email = TextEditingController();
    final password = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change email'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(hintText: 'New email')),
          const SizedBox(height: 10),
          TextField(controller: password, obscureText: true, decoration: const InputDecoration(hintText: 'Current password')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Send link')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await _run(context, () => context.read<AuthService>().changeEmail(password.text, email.text),
        'Verification link sent to ${email.text.trim()}');
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final password = TextEditingController();
    final c = context.ln;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('All notes, activities, projects and water logs will be permanently deleted.'),
          const SizedBox(height: 12),
          TextField(controller: password, obscureText: true, decoration: const InputDecoration(hintText: 'Confirm with your password')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: c.danger),
            child: const Text('Delete forever'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final auth = context.read<AuthService>();
    final nav = Navigator.of(context);
    try {
      await auth.deleteAccount(password.text);
      nav.popUntil((r) => r.isFirst);
    } on AuthFailure catch (e) {
      if (context.mounted) showMessage(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ln;
    final auth = context.watch<AuthService>();
    final settings = context.watch<SettingsService>();
    final p = auth.profile;

    return Scaffold(
      appBar: AppBar(title: const Text('Account', style: TextStyle(fontWeight: FontWeight.w700))),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 32), children: [
        LnCard(
          child: Row(children: [
            Avatar(initials: p?.initials ?? '?', size: 56),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p?.name.isNotEmpty == true ? p!.name : 'Unnamed',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                Text(auth.user?.email ?? '', style: TextStyle(color: c.muted, fontSize: 13)),
                const SizedBox(height: 6),
                Row(children: [
                  PillButton(
                    label: p?.role.label ?? 'User',
                    icon: p?.isAdmin == true ? Icons.shield_rounded : Icons.person_rounded,
                  ),
                  const SizedBox(width: 8),
                  if (p != null)
                    Text('Since ${DateFormat.yMMM().format(p.createdAt)}', style: TextStyle(color: c.muted, fontSize: 11)),
                ]),
              ]),
            ),
          ]),
        ),
        _section(context, 'PROFILE'),
        _group(context, [
          _tile(context, Icons.badge_outlined, 'Display name', subtitle: p?.name, onTap: () async {
            final name = await textPrompt(context, 'Display name', initial: p?.name ?? '');
            if (name != null && name.isNotEmpty && context.mounted) {
              await _run(context, () => auth.updateName(name), 'Name updated');
            }
          }),
          _tile(context, Icons.alternate_email_rounded, 'Change email', onTap: () => _changeEmail(context)),
          _tile(context, Icons.lock_outline_rounded, 'Change password', onTap: () => _changePassword(context)),
          _tile(context, Icons.water_drop_outlined, 'Water goal',
              subtitle: '${p?.waterGoal ?? 8} glasses × ${p?.glassMl ?? 250} ml',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WaterScreen()))),
        ]),
        _section(context, 'APPEARANCE'),
        LnCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Theme', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto_outlined), label: Text('System')),
                  ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_outlined), label: Text('Light')),
                  ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_outlined), label: Text('Dark')),
                ],
                selected: {settings.themeMode},
                onSelectionChanged: (s) => settings.setThemeMode(s.first),
              ),
            ),
          ]),
        ),
        _section(context, 'INSIGHTS'),
        _group(context, [
          _tile(context, Icons.insights_rounded, 'Reports & export',
              subtitle: 'Analytics, CSV / JSON export',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()))),
          _tile(context, Icons.notifications_none_rounded, 'Alerts',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertsScreen())),
              trailing: Switch(value: settings.alertsEnabled, onChanged: settings.setAlertsEnabled)),
        ]),
        if (auth.isAdmin) ...[
          _section(context, 'ADMINISTRATION'),
          _group(context, [
            _tile(context, Icons.admin_panel_settings_outlined, 'User management',
                subtitle: 'View users and assign roles',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen()))),
          ]),
        ],
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () async {
            Navigator.of(context).popUntil((r) => r.isFirst);
            await auth.signOut();
          },
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Sign out'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => _deleteAccount(context),
          style: TextButton.styleFrom(foregroundColor: c.danger),
          child: const Text('Delete account'),
        ),
      ]),
    );
  }

  Widget _section(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 22, 0, 8),
        child: Text(text,
            style: TextStyle(color: context.ln.muted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
      );

  Widget _group(BuildContext context, List<Widget> tiles) => LnCard(
        padding: EdgeInsets.zero,
        child: Column(children: [
          for (var i = 0; i < tiles.length; i++) ...[if (i > 0) const Divider(indent: 56), tiles[i]],
        ]),
      );

  Widget _tile(BuildContext context, IconData icon, String title,
          {String? subtitle, VoidCallback? onTap, Widget? trailing}) =>
      ListTile(
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: subtitle == null ? null : Text(subtitle, style: TextStyle(color: context.ln.muted, fontSize: 12)),
        trailing: trailing ?? Icon(Icons.chevron_right_rounded, color: context.ln.muted),
        onTap: onTap,
      );
}
