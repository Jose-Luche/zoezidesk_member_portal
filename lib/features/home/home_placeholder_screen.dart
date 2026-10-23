import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_tokens.dart';
import '../auth/state/session_controller.dart';

/// Temporary signed-in screen until the dashboard feature replaces it.
class HomePlaceholderScreen extends ConsumerWidget {
  const HomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    if (session is! SignedIn) return const SizedBox.shrink();
    final member = session.member;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('ZoeziDesk')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.md),
        children: [
          Text('Welcome, ${member.name.split(' ').first}', style: text.headlineLarge),
          if (member.gymName != null)
            Text(member.gymName!, style: text.bodySmall),
          const SizedBox(height: AppSpace.lg),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.md),
              child: Text(
                'Your dashboard arrives in the next feature.',
                style: text.bodyMedium,
              ),
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          if (kDebugMode) ...[
            OutlinedButton(
              onPressed: () => context.push(Routes.designGallery),
              child: const Text('Design system'),
            ),
            const SizedBox(height: AppSpace.sm),
          ],
          OutlinedButton.icon(
            onPressed: () => confirmLogout(context, ref),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Log out'),
          ),
        ],
      ),
    );
  }
}

/// Bottom-sheet confirmation, then logout. Reused by Settings later.
Future<void> confirmLogout(BuildContext context, WidgetRef ref) async {
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
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
