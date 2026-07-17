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
                  borderRadius: BorderRadius.circular(18),
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
                    // Each toggle = "app-level feature flag AND OS grant".
                    // Toggling OFF only flips the flag — the OS permission
                    // stays granted, so toggling back ON never re-prompts
                    // (unless the permission was never granted, in which
                    // case ON triggers the system request).
                    _FeatureToggle(
                      icon: Icons.notifications_outlined,
                      title: 'Reminders',
                      value: settings.remindersEnabled &&
                          overview.notificationsGranted,
                      subtitle: settings.remindersEnabled &&
                              overview.notificationsGranted
                          ? 'Alarm notifications for todos with reminders'
                          : settings.remindersEnabled
                              ? 'Notifications blocked by Android — switch '
                                  'on to grant'
                              : 'Off — reminder alarms won\'t ring',
                      onChanged: (enabled) async {
                        await ref
                            .read(settingsProvider.notifier)
                            .setRemindersEnabled(enabled);
                        ref.invalidate(permissionOverviewProvider);
                      },
                    ),
                    _FeatureToggle(
                      icon: Icons.alarm_on_outlined,
                      title: 'Exact timing',
                      value: settings.exactAlarmsEnabled &&
                          overview.exactAlarmsGranted,
                      subtitle: settings.exactAlarmsEnabled &&
                              overview.exactAlarmsGranted
                          ? 'Reminders fire to the second'
                          : settings.exactAlarmsEnabled
                              ? 'Needs "Alarms & reminders" — switch on to '
                                  'open the system setting'
                              : 'Off — reminders may arrive a few minutes '
                                  'late',
                      onChanged: (enabled) async {
                        await ref
                            .read(settingsProvider.notifier)
                            .setExactAlarmsEnabled(enabled);
                        ref.invalidate(permissionOverviewProvider);
                      },
                    ),
                    _FeatureToggle(
                      icon: Icons.fullscreen_outlined,
                      title: 'Full-screen reminders',
                      value: settings.fullScreenEnabled &&
                          overview.fullScreenGranted,
                      subtitle: settings.fullScreenEnabled &&
                              overview.fullScreenGranted
                          ? 'Reminders wake the screen like an alarm'
                          : settings.fullScreenEnabled
                              ? 'Revoked by Android — switch on to grant'
                              : 'Off — a heads-up banner is shown instead',
                      onChanged: (enabled) async {
                        await ref
                            .read(settingsProvider.notifier)
                            .setFullScreenEnabled(enabled);
                        ref.invalidate(permissionOverviewProvider);
                      },
                    ),
                    _FeatureToggle(
                      icon: Icons.battery_saver_outlined,
                      title: 'Ignore battery optimization',
                      // Pure OS state — there is no app-side flag to keep:
                      // the exemption itself IS the feature.
                      value: overview.batteryUnrestricted,
                      subtitle: overview.batteryUnrestricted
                          ? 'App is exempt — alarms are reliable'
                          : 'Optimized — Samsung may delay alarms in deep '
                              'sleep. Switch on to exempt this app.',
                      onChanged: (enabled) async {
                        final messenger = ScaffoldMessenger.of(context);
                        if (enabled) {
                          await ref
                              .read(permissionServiceProvider)
                              .requestIgnoreBatteryOptimizations();
                        } else {
                          // Android has no API to re-optimize an app; send
                          // the user to the system list instead.
                          await ref
                              .read(persistentNotificationControllerProvider)
                              .openBatteryOptimizationSettings();
                          messenger.showSnackBar(const SnackBar(
                            content: Text(
                              'Android manages this setting — find '
                              '"Reminder" in the list to re-enable '
                              'optimization.',
                            ),
                          ));
                        }
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

class _FeatureToggle extends StatelessWidget {
  const _FeatureToggle({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool value;
  final String subtitle;
  final Future<void> Function(bool enabled) onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: value,
      onChanged: (enabled) => onChanged(enabled),
    );
  }
}
