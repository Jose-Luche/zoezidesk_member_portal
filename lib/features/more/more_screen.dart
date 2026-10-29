import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/sync/sync.dart';
import '../../shared/widgets/app_badge.dart';
import '../../shared/widgets/app_sheet.dart';
import '../../shared/widgets/app_top_bar.dart';
import '../../shared/widgets/info_banner.dart';
import '../../shared/widgets/surfaces.dart';
import '../auth/state/session_controller.dart';

/// Account, other sections of the app, and settings.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final member = session is SignedIn ? session.member : null;

    return Scaffold(
      appBar: const AppTopBar(title: 'More', back: false),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.sm, AppSpace.gutter, AppSpace.lg),
        children: [
          if (member != null) ...[
            ListCard(
              children: [
                ListRow(
                  icon: AppIcons.circleUser,
                  title: member.name,
                  subtitle: [member.memberNumber, member.gymName].whereType<String>().join(' · '),
                  onTap: () => context.push(Routes.profile),
                ),
                ListRow(
                  icon: AppIcons.qrCode,
                  title: 'Membership card',
                  onTap: () => context.push(Routes.membershipCard),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.lg),
          ],
          ListCard(
            children: [
              ListRow(
                icon: AppIcons.utensils,
                title: 'Nutrition',
                subtitle: 'Food diary and daily goal',
                onTap: () => context.push(Routes.nutrition),
              ),
              ListRow(
                icon: AppIcons.receipt,
                title: 'Payments',
                subtitle: 'History, receipts and renewal',
                onTap: () => context.push(Routes.payments),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          ListCard(
            children: [
              if (kDebugMode)
                ListRow(
                  icon: AppIcons.palette,
                  title: 'Design system',
                  onTap: () => context.push(Routes.designGallery),
                ),
              ListRow(
                icon: AppIcons.slidersHorizontal,
                title: 'Settings',
                subtitle: 'Appearance, syncing, notifications',
                onTap: () => context.push(Routes.settings),
              ),
              ListRow(
                icon: AppIcons.logOut,
                title: 'Log out',
                chevron: false,
                onTap: () => confirmLogout(context, ref),
              ),
            ],
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
  final confirmed = await showAppSheet<bool>(
    context,
    builder: (sheetContext) => SheetLayout(
      title: 'Log out?',
      body: [
        Text(
          'Data saved on this phone will be removed. '
          'You will need a new code to log in again.',
          style: Theme.of(sheetContext).textTheme.bodyLarge,
        ),
        if (unsent > 0) ...[
          const SizedBox(height: AppSpace.md),
          InfoBanner(
            tone: BadgeTone.warning,
            icon: AppIcons.cloudOff,
            message: unsent == 1
                ? '1 change has not been sent yet and will be lost. Connect to the internet first to keep it.'
                : '$unsent changes have not been sent yet and will be lost. Connect to the internet first to keep them.',
          ),
        ],
      ],
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(sheetContext, true),
          child: Text(unsent > 0 ? 'Log out anyway' : 'Log out'),
        ),
        OutlinedButton(
          onPressed: () => Navigator.pop(sheetContext, false),
          child: const Text('Cancel'),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    await ref.read(sessionControllerProvider.notifier).logout();
  }
}
