import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/theme_mode_controller.dart';
import '../../data/sync/sync.dart';
import '../../shared/widgets/app_badge.dart';
import '../../shared/widgets/info_banner.dart';
import '../more/more_screen.dart' show confirmLogout;
import '../notifications/notifications_controller.dart';

/// Changes saved on this phone that have not reached the server yet.
final unsentChangesProvider = StreamProvider.autoDispose<int>(
  (ref) => ref.watch(outboxServiceProvider).watchPendingCount(),
);

/// Appearance, what is waiting to be sent, notifications, and logout.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final mode = ref.watch(themeModeProvider);
    final unsent = ref.watch(unsentChangesProvider).value ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.md),
        children: [
          Text('Appearance', style: text.titleMedium),
          const SizedBox(height: AppSpace.sm),
          Card(
            child: RadioGroup<ThemeMode>(
              groupValue: mode,
              onChanged: (m) => m == null ? null : ref.read(themeModeProvider.notifier).set(m),
              child: const Column(
                children: [
                  RadioListTile(value: ThemeMode.dark, title: Text('Dark')),
                  RadioListTile(value: ThemeMode.light, title: Text('Light')),
                  RadioListTile(
                    value: ThemeMode.system,
                    title: Text('Match my phone'),
                    subtitle: Text('Follows the phone\'s dark or light setting.'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          Text('Saving and syncing', style: text.titleMedium),
          const SizedBox(height: AppSpace.sm),
          Card(
            child: ListTile(
              leading: Icon(unsent == 0 ? Icons.cloud_done_outlined : Icons.cloud_upload_outlined),
              title: Text(unsent == 0 ? 'Everything is saved to your account' : _changes(unsent)),
              subtitle: Text(
                unsent == 0
                    ? 'Workouts, food and bookings you log offline are sent when you are back online.'
                    : 'They are sent when the phone is online.',
              ),
              trailing: unsent == 0
                  ? null
                  : TextButton(onPressed: () => ref.read(outboxServiceProvider).drain(), child: const Text('Send now')),
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          Text('Notifications', style: text.titleMedium),
          const SizedBox(height: AppSpace.sm),
          const _NotificationsSection(),
          const SizedBox(height: AppSpace.lg),
          Text('Account', style: text.titleMedium),
          const SizedBox(height: AppSpace.sm),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: const Text('Log out'),
              subtitle: const Text('Removes your data from this phone.'),
              onTap: () => confirmLogout(context, ref),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationsSection extends ConsumerWidget {
  const _NotificationsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(notificationsControllerProvider);
    if (status == NotificationStatus.unavailable) {
      return const InfoBanner(
        icon: Icons.notifications_off_rounded,
        message: 'Notifications are not available on this phone. Your gym still sends booking '
            'and payment messages by WhatsApp.',
      );
    }
    final on = status != NotificationStatus.off;
    return Column(
      children: [
        Card(
          child: SwitchListTile(
            secondary: const Icon(Icons.notifications_rounded),
            title: const Text('App notifications'),
            subtitle: const Text('Class bookings, payments and membership reminders'),
            value: on,
            onChanged: (v) => ref.read(notificationsControllerProvider.notifier).setEnabled(v),
          ),
        ),
        if (status == NotificationStatus.blocked) ...[
          const SizedBox(height: AppSpace.sm),
          const InfoBanner(
            tone: BadgeTone.warning,
            icon: Icons.notifications_paused_rounded,
            message: 'Your phone is blocking notifications from ZoeziDesk. Allow them in the '
                "phone's Settings, under Apps > ZoeziDesk > Notifications.",
          ),
        ],
      ],
    );
  }
}

String _changes(int n) => n == 1 ? '1 change waiting to send' : '$n changes waiting to send';
