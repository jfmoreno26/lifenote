import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Admin-only user management. Access is enforced by Firestore rules; the
/// screen is only reachable when the signed-in profile has the admin role.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  late final Stream<List<AppUser>> _users = context.read<AuthService>().allUsers();
  String _query = '';

  Future<void> _setRole(AppUser u, Role role) async {
    if (role == u.role) return;
    final ok = await confirmDialog(context, 'Change role?', 'Make ${u.name.isEmpty ? u.email : u.name} ${role.label.toLowerCase()}?',
        action: 'Change');
    if (!ok || !mounted) return;
    try {
      await context.read<AuthService>().setRole(u.uid, role);
      if (mounted) showMessage(context, 'Role updated');
    } catch (e) {
      if (mounted) showMessage(context, 'Could not update role: $e', error: true);
    }
  }

  Future<void> _details(AppUser u) async {
    final counts = context.read<AuthService>().userCounts(u.uid);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(u.name.isEmpty ? u.email : u.name),
        content: FutureBuilder<Map<String, int>>(
          future: counts,
          builder: (ctx, snap) {
            if (snap.hasError) return Text('Could not load: ${snap.error}');
            if (!snap.hasData) return const SizedBox(height: 60, child: Center(child: CircularProgressIndicator()));
            final m = snap.data!;
            return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(u.email),
              const SizedBox(height: 10),
              Text('Role: ${u.role.label}'),
              Text('Notes: ${m['notes']}'),
              Text('Activities: ${m['activities']}'),
              Text('Projects: ${m['projects']}'),
            ]);
          },
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ln;
    final me = context.watch<AuthService>();
    if (!me.isAdmin) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(icon: Icons.lock_outline_rounded, message: 'Administrator access required.'),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('User management', style: TextStyle(fontWeight: FontWeight.w700))),
      body: StreamBuilder<List<AppUser>>(
        stream: _users,
        builder: (context, snap) {
          if (snap.hasError) {
            return EmptyState(icon: Icons.error_outline_rounded, message: 'Could not load users.\n${snap.error}');
          }
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final q = _query.toLowerCase();
          final all = snap.data!;
          final users =
              all.where((u) => q.isEmpty || u.name.toLowerCase().contains(q) || u.email.toLowerCase().contains(q)).toList();
          final admins = all.where((u) => u.isAdmin).length;

          return ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 32), children: [
            Row(children: [
              Expanded(child: _count(context, '${all.length}', 'Users', Icons.people_outline_rounded)),
              const SizedBox(width: 10),
              Expanded(child: _count(context, '$admins', 'Admins', Icons.shield_outlined)),
            ]),
            const SizedBox(height: 12),
            TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search users',
                isDense: true,
                prefixIcon: Icon(Icons.search_rounded, color: c.muted),
              ),
            ),
            const SizedBox(height: 12),
            LnCard(
              padding: EdgeInsets.zero,
              child: Column(children: [
                for (var i = 0; i < users.length; i++) ...[
                  if (i > 0) const Divider(indent: 68),
                  ListTile(
                    onTap: () => _details(users[i]),
                    leading: Avatar(initials: users[i].initials),
                    title: Text(users[i].name.isEmpty ? '(no name)' : users[i].name,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text(users[i].email, style: TextStyle(color: c.muted, fontSize: 12)),
                    trailing: users[i].uid == me.user?.uid
                        ? const PillButton(label: 'You')
                        : DropdownButton<Role>(
                            value: users[i].role,
                            underline: const SizedBox.shrink(),
                            borderRadius: BorderRadius.circular(12),
                            items: [for (final r in Role.values) DropdownMenuItem(value: r, child: Text(r.label))],
                            onChanged: (r) => r == null ? null : _setRole(users[i], r),
                          ),
                  ),
                ],
              ]),
            ),
          ]);
        },
      ),
    );
  }

  Widget _count(BuildContext context, String value, String label, IconData icon) => LnCard(
        child: Row(children: [
          Icon(icon, color: context.ln.primary),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            Text(label, style: TextStyle(color: context.ln.muted, fontSize: 12)),
          ]),
        ]),
      );
}
