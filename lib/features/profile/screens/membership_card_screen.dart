import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/brightness.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/info_banner.dart';
import '../../../shared/widgets/state_message.dart';
import '../../auth/state/session_controller.dart';
import '../../dashboard/state/dashboard_providers.dart';
import '../../dashboard/state/membership_status.dart';
import '../../dashboard/widgets/membership_card.dart';

/// Full-screen membership card to show at the front desk. Reads only from
/// the cache, so it works offline once the dashboard has loaded.
class MembershipCardScreen extends ConsumerWidget {
  const MembershipCardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = ref.watch(memberCardProvider).value?.data;
    final dashboard = ref.watch(dashboardCacheProvider).value?.data;
    final session = ref.watch(sessionControllerProvider);
    final signedIn = session is SignedIn ? session.member : null;

    final name = dashboard?.member.name ?? card?.name ?? signedIn?.name;

    return BrightnessBoost(
      child: Scaffold(
        appBar: const AppTopBar(title: 'Membership card'),
        body: card == null || name == null
            ? StateMessage.offline(
                title: 'Card not saved yet',
                message:
                    'Open the app once with an internet connection to save your '
                    'card. After that it works offline.',
                actionLabel: 'Back',
                onAction: () => Navigator.of(context).maybePop(),
              )
            : SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.sm, AppSpace.gutter, AppSpace.lg),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          MembershipCard(
                            expanded: true,
                            name: name,
                            memberNumber:
                                dashboard?.member.memberNumber ??
                                card.memberNumber,
                            gymName: dashboard?.member.gymName ?? card.gymName,
                            status: MembershipStatus.from(
                              dashboard?.membership,
                            ),
                            qrCode: card.qrCode,
                          ),
                          const SizedBox(height: AppSpace.md),
                          const InfoBanner(
                            icon: AppIcons.scanLine,
                            message: 'Show this code at the front desk to check in.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
