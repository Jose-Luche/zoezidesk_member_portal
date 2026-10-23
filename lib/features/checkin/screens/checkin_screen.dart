import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/brightness.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/db/app_database.dart';
import '../../../shared/widgets/app_badge.dart';
import '../../../shared/widgets/info_banner.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/state_message.dart';
import '../../../shared/widgets/sync_status.dart';
import '../../auth/state/session_controller.dart';
import '../../dashboard/state/dashboard_providers.dart';
import '../../dashboard/state/membership_status.dart';
import '../../dashboard/widgets/membership_card.dart';
import '../state/checkin_providers.dart';

/// Check-in: the front desk scans the member's QR. The screen shows the code
/// at full brightness (works offline from the cache), confirms the scan when
/// it lands, and lists past check-ins.
class CheckInScreen extends ConsumerStatefulWidget {
  const CheckInScreen({super.key});

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_maybeLoadMore);
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.start());
  }

  late final CheckInController _controller = ref.read(checkInControllerProvider.notifier);

  @override
  void dispose() {
    // Stop looking for a scan as soon as the screen closes.
    _controller.stop();
    _scroll.dispose();
    super.dispose();
  }

  void _maybeLoadMore() {
    if (_scroll.position.extentAfter < 400) {
      ref.read(checkInControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(checkInControllerProvider.select((s) => s.confirmedAt), (_, at) {
      if (at != null) HapticFeedback.lightImpact();
    });

    final state = ref.watch(checkInControllerProvider);
    final card = ref.watch(memberCardProvider).value?.data;
    final dashboard = ref.watch(dashboardCacheProvider).value?.data;
    final session = ref.watch(sessionControllerProvider);
    final history = ref.watch(attendanceProvider).value;
    final summary = ref.watch(attendanceSummaryProvider).value;
    final fetchedAt = ref.watch(attendanceFetchedAtProvider).value;
    final now = ref.watch(clockProvider)();
    final text = Theme.of(context).textTheme;

    final name =
        dashboard?.member.name ??
        card?.name ??
        (session is SignedIn ? session.member.name : null);
    final status = MembershipStatus.from(dashboard?.membership);
    final canCheckIn =
        status.state == MembershipState.active ||
        status.state == MembershipState.expiring;
    final controller = ref.read(checkInControllerProvider.notifier);

    return BrightnessBoost(
      child: Scaffold(
        appBar: AppBar(title: const Text('Check-in')),
        body: RefreshIndicator(
          onRefresh: controller.refresh,
          child: CustomScrollView(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(AppSpace.md),
                sliver: SliverList.list(
                  children: [
                    if (card == null || name == null)
                      const StateMessage(
                        icon: Icons.qr_code_2_rounded,
                        title: 'Code not saved yet',
                        message:
                            'Open the app once with an internet connection to save your '
                            'membership code. After that it works offline.',
                      )
                    else
                      MembershipCard(
                        expanded: true,
                        name: name,
                        memberNumber:
                            dashboard?.member.memberNumber ?? card.memberNumber,
                        gymName: dashboard?.member.gymName ?? card.gymName,
                        status: status,
                        qrCode: card.qrCode,
                      ),
                    const SizedBox(height: AppSpace.md),
                    if (state.confirmedAt != null)
                      InfoBanner(
                        tone: BadgeTone.success,
                        icon: Icons.check_circle_rounded,
                        message:
                            'Checked in at ${DateFormat('h:mm a').format(state.confirmedAt!.toLocal())}. '
                            'Have a great session!',
                      )
                    else if (dashboard != null && !canCheckIn)
                      const InfoBanner(
                        tone: BadgeTone.danger,
                        message:
                            'Your membership is not active, so the front desk cannot check you in. '
                            'Visit the front desk to renew.',
                      )
                    else
                      InfoBanner(
                        icon: Icons.qr_code_scanner_rounded,
                        message:
                            'Show this code at the front desk. You will see a confirmation here '
                            'when they scan it.',
                      ),
                    const SizedBox(height: AppSpace.lg),
                    Row(
                      children: [
                        Expanded(
                          child: Text('Your visits', style: text.titleLarge),
                        ),
                        if (summary != null)
                          AppBadge(
                            label: '${summary.thisMonth} this month',
                            tone: BadgeTone.highlight,
                            icon: Icons.event_available_rounded,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.sm),
                    if (fetchedAt != null)
                      SyncStatus(
                        fetchedAt: fetchedAt,
                        now: now,
                        refreshing: state.refresh.isLoading,
                        refreshError: state.refresh.error,
                        onRetry: controller.refresh,
                      ),
                    const SizedBox(height: AppSpace.sm),
                  ],
                ),
              ),
              ..._history(context, history, fetchedAt, state),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _history(
    BuildContext context,
    List<Attendance>? rows,
    DateTime? fetchedAt,
    CheckInState state,
  ) {
    const pad = EdgeInsets.symmetric(horizontal: AppSpace.md);
    if (rows == null ||
        (rows.isEmpty && fetchedAt == null && !state.refresh.hasError)) {
      return const [
        SliverPadding(
          padding: pad,
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                SkeletonListTile(),
                SizedBox(height: AppSpace.sm),
                SkeletonListTile(),
              ],
            ),
          ),
        ),
      ];
    }
    if (rows.isEmpty) {
      final offline = state.refresh.error is NetworkFailure;
      return [
        SliverToBoxAdapter(
          child: fetchedAt == null && offline
              ? StateMessage.offline(
                  message: 'Connect to see your past visits.',
                  onAction: ref
                      .read(checkInControllerProvider.notifier)
                      .refresh,
                )
              : const StateMessage(
                  icon: Icons.event_available_rounded,
                  title: 'No visits yet',
                  message: 'Your check-ins appear here after the front desk scans your code.',
                ),
        ),
      ];
    }
    final text = Theme.of(context).textTheme;
    return [
      SliverPadding(
        padding: pad,
        sliver: SliverList.builder(
          itemCount: rows.length,
          itemBuilder: (_, i) {
            final a = rows[i];
            final at = a.checkedInAt.toLocal();
            final manual = a.method == 'manual';
            return Card(
              margin: const EdgeInsets.only(bottom: AppSpace.sm),
              child: ListTile(
                leading: Icon(
                  manual
                      ? Icons.person_search_rounded
                      : Icons.qr_code_scanner_rounded,
                ),
                title: Text(
                  DateFormat('EEEE d MMMM').format(at),
                  style: text.titleSmall,
                ),
                subtitle: Text(
                  '${DateFormat('h:mm a').format(at)} · ${manual ? 'Checked in by staff' : 'QR scan'}',
                  style: text.bodySmall,
                ),
                trailing: i == 0
                    ? Text(
                        formatRelative(at, ref.read(clockProvider)()),
                        style: text.bodySmall,
                      )
                    : null,
              ),
            );
          },
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpace.lg),
          child: Center(
            child: state.loadingMore
                ? const Padding(
                    padding: EdgeInsets.all(AppSpace.md),
                    child: SkeletonListTile(),
                  )
                : state.hasMore
                ? TextButton(
                    onPressed: ref
                        .read(checkInControllerProvider.notifier)
                        .loadMore,
                    child: const Text('Load older visits'),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ),
    ];
  }
}
