import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/theme_mode_controller.dart';
import '../../data/sync/sync.dart';
import '../../shared/widgets/app_badge.dart';
import '../../shared/widgets/app_top_bar.dart';
import '../../shared/widgets/info_banner.dart';
import '../../shared/widgets/surfaces.dart';
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
      appBar: const AppTopBar(title: 'Settings'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.sm, AppSpace.gutter, AppSpace.lg),
        children: [
          const SectionHeader('Appearance'),
          RadioGroup<ThemeMode>(
            groupValue: mode,
            onChanged: (m) => m == null ? null : ref.read(themeModeProvider.notifier).set(m),
            child: const ListCard(
              children: [
                _ThemeOption(value: ThemeMode.light, icon: AppIcons.sun, title: 'Light'),
                _ThemeOption(value: ThemeMode.dark, icon: AppIcons.moon, title: 'Dark'),
                _ThemeOption(
                  value: ThemeMode.system,
                  icon: AppIcons.smartphone,
                  title: 'Match my phone',
                  subtitle: 'Follows the phone\'s dark or light setting.',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          const SectionHeader('Saving and syncing'),
          if (unsent == 0)
            ListCard(
              children: [
                ListRow(
                  icon: AppIcons.circleCheck,
                  iconColor: context.palette.rowIcon,
                  title: 'Everything is saved to your account',
                  subtitle: 'Workouts, food and bookings you log offline are sent when you are back online.',
                ),
              ],
            )
          else
            InfoBanner(
              tone: BadgeTone.warning,
              icon: AppIcons.cloudUpload,
              message: '${_changes(unsent)}. They are sent when the phone is online.',
              actionLabel: 'Send now',
              onAction: () => ref.read(outboxServiceProvider).drain(),
            ),
          const SizedBox(height: AppSpace.lg),
          const SectionHeader('Notifications'),
          const _NotificationsSection(),
          const SizedBox(height: AppSpace.lg),
          const SectionHeader('Account'),
          ListCard(
            children: [
              ListRow(
                icon: AppIcons.logOut,
                title: 'Log out',
                subtitle: 'Removes your data from this phone.',
                chevron: false,
                onTap: () => confirmLogout(context, ref),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Text('ZoeziDesk members app', style: text.bodySmall),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({required this.value, required this.icon, required this.title, this.subtitle});

  final ThemeMode value;
  final LucideIcon icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final group = RadioGroup.maybeOf<ThemeMode>(context);
    return ListRow(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: () => group?.onChanged(value),
      trailing: Radio<ThemeMode>(value: value),
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
        icon: AppIcons.bellOff,
        message: 'Notifications are not available on this phone. Your gym still sends booking '
            'and payment messages by WhatsApp.',
      );
    }
    final on = status != NotificationStatus.off;
    void set(bool v) => ref.read(notificationsControllerProvider.notifier).setEnabled(v);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListCard(
          children: [
            ListRow(
              icon: AppIcons.bell,
              title: 'App notifications',
              subtitle: 'Class bookings, payments and membership reminders',
              onTap: () => set(!on),
              trailing: Switch(value: on, onChanged: set),
            ),
          ],
        ),
        if (status == NotificationStatus.blocked) ...[
          const SizedBox(height: AppSpace.sm),
          const InfoBanner(
            tone: BadgeTone.warning,
            icon: AppIcons.bellOff,
            message: 'Your phone is blocking notifications from ZoeziDesk. Allow them in the '
                "phone's Settings, under Apps > ZoeziDesk > Notifications.",
          ),
        ],
      ],
    );
  }
}

String _changes(int n) => n == 1 ? '1 change is waiting to be sent' : '$n changes are waiting to be sent';
