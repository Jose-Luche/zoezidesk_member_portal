import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/sync/sync.dart';
import '../../shared/widgets/app_badge.dart';
import '../../shared/widgets/info_banner.dart';
import '../auth/state/session_controller.dart';

/// Account, other sections of the app, and settings.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final member = session is SignedIn ? session.member : null;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.md),
        children: [
          if (member != null)
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_rounded),
                    title: Text(member.name, style: text.titleMedium),
                    subtitle: Text(
                      [member.memberNumber, member.gymName].whereType<String>().join(' · '),
                      style: text.bodySmall,
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(Routes.profile),
                  ),
                  ListTile(
                    leading: const Icon(Icons.qr_code_2_rounded),
                    title: const Text('Membership card'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(Routes.membershipCard),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpace.md),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.restaurant_rounded),
                  title: const Text('Nutrition'),
                  subtitle: const Text('Food diary and daily goal'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(Routes.nutrition),
                ),
                ListTile(
                  leading: const Icon(Icons.receipt_long_rounded),
                  title: const Text('Payments'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(Routes.payments),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Card(
            child: Column(
              children: [
                if (kDebugMode)
                  ListTile(
                    leading: const Icon(Icons.palette_rounded),
                    title: const Text('Design system'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(Routes.designGallery),
                  ),
                ListTile(
                  leading: const Icon(Icons.settings_rounded),
                  title: const Text('Settings'),
                  subtitle: const Text('Appearance, syncing, notifications'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(Routes.settings),
                ),
                ListTile(
                  leading: const Icon(Icons.logout_rounded),
                  title: const Text('Log out'),
                  onTap: () => confirmLogout(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom-sheet confirmation, then logout. Warns when changes saved on the
/// phone have not reached the server, since logging out deletes them.
Future<void> confirmLogout(BuildContext context, WidgetRef ref) async {
  final unsent = await ref.read(outboxServiceProvider).unsentCount();
  if (!context.mounted) return;
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true, // cover the tab bar too
    builder: (sheetContext) {
      final text = Theme.of(sheetContext).textTheme;
      return Padding(
        padding: const EdgeInsets.fromLTRB(AppSpace.md, 0, AppSpace.md, AppSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Log out?', style: text.headlineSmall),
            const SizedBox(height: AppSpace.sm),
            Text(
              'Data saved on this phone will be removed. '
              'You will need a new code to log in again.',
              style: text.bodyMedium,
            ),
            if (unsent > 0) ...[
              const SizedBox(height: AppSpace.md),
              InfoBanner(
                tone: BadgeTone.warning,
                message: unsent == 1
                    ? '1 change has not been sent yet and will be lost. Connect to the internet first to keep it.'
                    : '$unsent changes have not been sent yet and will be lost. Connect to the internet first to keep them.',
              ),
            ],
            const SizedBox(height: AppSpace.lg),
            FilledButton(
              onPressed: () => Navigator.pop(sheetContext, true),
              child: Text(unsent > 0 ? 'Log out anyway' : 'Log out'),
            ),
            const SizedBox(height: AppSpace.sm),
            OutlinedButton(
              onPressed: () => Navigator.pop(sheetContext, false),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    },
  );
  if (confirmed == true) {
    await ref.read(sessionControllerProvider.notifier).logout();
  }
}
