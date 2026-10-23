import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_tokens.dart';
import '../auth/state/session_controller.dart';

/// Account and app options. Settings (theme, notifications) join this tab
/// in the Settings feature.
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
                if (kDebugMode)
                  ListTile(
                    leading: const Icon(Icons.palette_rounded),
                    title: const Text('Design system'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(Routes.designGallery),
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

/// Bottom-sheet confirmation, then logout.
Future<void> confirmLogout(BuildContext context, WidgetRef ref) async {
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
            const SizedBox(height: AppSpace.lg),
            FilledButton(
              onPressed: () => Navigator.pop(sheetContext, true),
              child: const Text('Log out'),
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
