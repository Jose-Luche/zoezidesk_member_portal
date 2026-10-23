import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/db/encrypted_cache.dart';
import '../../../data/dto/dashboard_dto.dart';
import '../../../shared/widgets/app_badge.dart';
import '../../../shared/widgets/info_banner.dart';
import '../../../shared/widgets/state_message.dart';
import '../../../shared/widgets/sync_status.dart';
import '../state/dashboard_providers.dart';
import '../state/membership_status.dart';
import '../widgets/dashboard_sections.dart';
import '../widgets/membership_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Render from cache immediately, refresh in the background.
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() =>
      ref.read(dashboardRefreshProvider.notifier).refresh();

  @override
  Widget build(BuildContext context) {
    final cache = ref.watch(dashboardCacheProvider);
    final card = ref.watch(memberCardProvider).value;
    final refresh = ref.watch(dashboardRefreshProvider);
    final now = ref.watch(clockProvider)();

    final cached = cache.value;
    final Widget body;
    if (cached != null) {
      body = _DashboardContent(
        cached: cached,
        card: card?.data,
        now: now,
        refreshing: refresh.isLoading,
        refreshError: refresh.error,
        onRefresh: _refresh,
      );
    } else if (refresh.hasError) {
      // Nothing cached and the first load failed.
      body = refresh.error is NetworkFailure
          ? StateMessage.offline(
              message:
                  'Connect to the internet once to load your membership. '
                  'After that it is available offline.',
              onAction: _refresh,
            )
          : StateMessage.error(onAction: _refresh);
    } else {
      body = const DashboardSkeleton();
    }

    final firstName = cached?.data.member.name.split(' ').first;
    return Scaffold(
      appBar: AppBar(
        title: Text(firstName == null ? 'Home' : 'Hi, $firstName'),
      ),
      body: body,
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.cached,
    required this.card,
    required this.now,
    required this.refreshing,
    required this.refreshError,
    required this.onRefresh,
  });

  final Cached<DashboardDto> cached;
  final MemberCardDto? card;
  final DateTime now;
  final bool refreshing;
  final Object? refreshError;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final data = cached.data;
    final status = MembershipStatus.from(data.membership);
    final text = Theme.of(context).textTheme;

    final notice = switch (status.state) {
      MembershipState.expired => const InfoBanner(
        tone: BadgeTone.danger,
        message: 'Your membership has expired. Visit the front desk or contact us to renew.',
      ),
      MembershipState.expiring => InfoBanner(
        tone: BadgeTone.warning,
        message:
            '${status.label}. Visit the front desk or contact us to renew.',
      ),
      _ => null,
    };

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpace.md),
        children: [
          SyncStatus(
            fetchedAt: cached.fetchedAt,
            now: now,
            refreshing: refreshing,
            refreshError: refreshError,
            onRetry: onRefresh,
          ),
          const SizedBox(height: AppSpace.md),
          MembershipCard(
            name: data.member.name,
            memberNumber: data.member.memberNumber,
            gymName: data.member.gymName,
            status: status,
            qrCode: card?.qrCode,
            onTap: () => context.push(Routes.membershipCard),
          ),
          if (notice != null) ...[const SizedBox(height: AppSpace.md), notice],
          const SizedBox(height: AppSpace.md),
          // Equal-height tiles even when a label wraps.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: StatTile(
                    icon: Icons.event_available_rounded,
                    value: '${data.attendanceMonth}',
                    label: 'Visits this month',
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: StatTile(
                    icon: Icons.hourglass_bottom_rounded,
                    value: status.state == MembershipState.none
                        ? '–'
                        : '${status.daysRemaining}',
                    label: 'Days left',
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: StatTile(
                    icon: Icons.account_balance_wallet_rounded,
                    value: data.totalPaid == null
                        ? '–'
                        : formatKes(data.totalPaid!),
                    label: 'Total paid',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          Text('Quick actions', style: text.titleLarge),
          const SizedBox(height: AppSpace.sm),
          QuickActionsGrid(
            actions: [
              QuickAction(
                label: 'My card',
                icon: Icons.qr_code_2_rounded,
                onTap: () => context.push(Routes.membershipCard),
              ),
              QuickAction(
                label: 'Classes',
                icon: Icons.calendar_month_rounded,
                onTap: () => context.push(Routes.classes),
              ),
              QuickAction(
                label: 'Check-in',
                icon: Icons.how_to_reg_rounded,
                onTap: () => context.push(Routes.checkIn),
              ),
              QuickAction(
                label: 'Payments',
                icon: Icons.receipt_long_rounded,
                onTap: () => context.push(Routes.payments),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          RecentPaymentsCard(
            payments: data.recentPayments,
            onSeeAll: () => context.push(Routes.payments),
          ),
          const SizedBox(height: AppSpace.lg),
        ],
      ),
    );
  }
}
