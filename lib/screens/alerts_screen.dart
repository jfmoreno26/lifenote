import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/alert_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.ln;
    final service = context.watch<AlertService>();
    final settings = context.watch<SettingsService>();
    final alerts = service.alerts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          if (alerts.isNotEmpty) TextButton(onPressed: service.dismissAll, child: const Text('Clear all')),
        ],
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 32), children: [
        LnCard(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: SwitchListTile(
            value: settings.alertsEnabled,
            onChanged: settings.setAlertsEnabled,
            title: const Text('Automated alerts', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text('Water pace, upcoming & overdue activities, projects near completion',
                style: TextStyle(color: c.muted, fontSize: 12)),
          ),
        ),
        const SizedBox(height: 16),
        if (!settings.alertsEnabled)
          const EmptyState(icon: Icons.notifications_off_outlined, message: 'Alerts are turned off.')
        else if (alerts.isEmpty)
          const EmptyState(icon: Icons.notifications_none_rounded, message: "You're all caught up.")
        else
          for (final a in alerts)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Dismissible(
                key: ValueKey(a.id),
                onDismissed: (_) => service.dismiss(a.id),
                child: LnCard(
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: levelColor(context, a.level).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(a.icon, size: 19, color: levelColor(context, a.level)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(a.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text(a.message, style: TextStyle(color: c.muted, fontSize: 12)),
                      ]),
                    ),
                    InkResponse(onTap: () => service.dismiss(a.id), child: Icon(Icons.close_rounded, size: 18, color: c.muted)),
                  ]),
                ),
              ),
            ),
      ]),
    );
  }
}

Color levelColor(BuildContext context, AlertLevel level) => switch (level) {
      AlertLevel.info => context.ln.primary,
      AlertLevel.warning => const Color(0xFFE08A00),
      AlertLevel.success => context.ln.success,
    };
