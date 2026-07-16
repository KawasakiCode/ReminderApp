import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/core_providers.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final permissions = ref.watch(permissionOverviewProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          const _SectionLabel('Appearance'),
          _SettingsCard(
            children: [
              ListTile(
                leading: const Icon(Icons.dark_mode_outlined),
                title: const Text('Theme'),
                trailing: SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: ThemeMode.system, label: Text('Auto')),
                    ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                    ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (selection) =>
                      notifier.setThemeMode(selection.first),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.view_week_outlined),
                title: const Text('First day of week'),
                trailing: DropdownButton<FirstDayOfWeek>(
                  value: settings.firstDayOfWeek,
                  underline: const SizedBox.shrink(),
                  items: [
                    for (final day in FirstDayOfWeek.values)
                      DropdownMenuItem(value: day, child: Text(day.label)),
                  ],
                  onChanged: (day) {
                    if (day != null) notifier.setFirstDayOfWeek(day);
                  },
                ),
              ),
            ],
          ),
          const _SectionLabel('Today notification'),
          _SettingsCard(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.push_pin_outlined),
                title: const Text('Show today\'s todos in the status bar'),
                subtitle: const Text(
                  'A permanent notification lists today\'s unfinished todos. '
                  'Check one off right from the notification — no need to '
                  'open the app.',
                ),
                value: settings.persistentNotificationEnabled,
                onChanged: (enabled) async {
                  if (enabled) {
                    // Without POST_NOTIFICATIONS the service would run
                    // invisibly on Android 13+ — ask first.
                    await ref
                        .read(permissionServiceProvider)
                        .requestNotifications();
                    ref.invalidate(permissionOverviewProvider);
                  }
                  await notifier.setPersistentNotificationEnabled(enabled);
                },
              ),
            ],
          ),
          const _SectionLabel('Reminders & permissions'),
          _SettingsCard(
            children: [
              permissions.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => ListTile(
                  leading: const Icon(Icons.error_outline),
                  title: const Text('Could not read permission state'),
                  subtitle: Text('$error'),
                ),
                data: (overview) => Column(
                  children: [
                    _PermissionRow(
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      granted: overview.notificationsGranted,
                      grantedText: 'Allowed',
                      deniedText: 'Required for any reminder to be visible',
                      onRequest: () async {
                        await ref
                            .read(permissionServiceProvider)
                            .requestNotifications();
                        ref.invalidate(permissionOverviewProvider);
                      },
                    ),
                    _PermissionRow(
                      icon: Icons.alarm_on_outlined,
                      title: 'Exact alarms',
                      granted: overview.exactAlarmsGranted,
                      grantedText: 'Reminders fire to the second',
                      deniedText:
                          'Without this, reminders may arrive a few minutes '
                          'late (opens "Alarms & reminders")',
                      onRequest: () async {
                        await ref
                            .read(permissionServiceProvider)
                            .requestExactAlarms();
                        ref.invalidate(permissionOverviewProvider);
                      },
                    ),
                    _PermissionRow(
                      icon: Icons.fullscreen_outlined,
                      title: 'Full-screen reminders',
                      // Not queryable via a public API pre-34; offer the
                      // deep link and describe what it does.
                      granted: null,
                      grantedText: '',
                      deniedText:
                          'Lets reminders wake the screen like an alarm '
                          '(Android 14+ setting)',
                      onRequest: () async {
                        await ref
                            .read(permissionServiceProvider)
                            .requestFullScreenIntent();
                        ref.invalidate(permissionOverviewProvider);
                      },
                    ),
                    _PermissionRow(
                      icon: Icons.battery_saver_outlined,
                      title: 'Battery optimization',
                      granted: overview.batteryUnrestricted,
                      grantedText: 'App is exempt — alarms are reliable',
                      deniedText:
                          'Samsung/aggressive battery savers can delay or '
                          'drop alarms. Exempt this app for reliable '
                          'reminders.',
                      onRequest: () async {
                        await ref
                            .read(permissionServiceProvider)
                            .requestIgnoreBatteryOptimizations();
                        ref.invalidate(permissionOverviewProvider);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const _SectionLabel('About'),
          _SettingsCard(
            children: const [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Everything is stored on this device — the app has no '
                  'internet access, no account and no tracking.\n\n'
                  'Note: Android limits apps to roughly 500 scheduled exact '
                  'alarms on Samsung devices; this app only schedules alarms '
                  'for future reminders and stops safely below that limit.',
                  style: TextStyle(fontSize: 12.5, height: 1.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 18, 12, 8),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Column(children: children),
      );
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.icon,
    required this.title,
    required this.granted,
    required this.grantedText,
    required this.deniedText,
    required this.onRequest,
  });

  final IconData icon;
  final String title;

  /// null = state not queryable; always show the action button.
  final bool? granted;
  final String grantedText;
  final String deniedText;
  final Future<void> Function() onRequest;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isGranted = granted ?? false;
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(
        isGranted ? grantedText : deniedText,
        style: const TextStyle(fontSize: 12),
      ),
      trailing: granted == true
          ? Icon(Icons.check_circle, color: scheme.primary)
          : FilledButton.tonal(
              onPressed: onRequest,
              child: const Text('Allow'),
            ),
    );
  }
}
