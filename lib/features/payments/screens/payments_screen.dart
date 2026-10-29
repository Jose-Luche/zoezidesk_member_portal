import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/repositories/payments_repository.dart';
import '../../../shared/widgets/app_badge.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/state_message.dart';
import '../../../shared/widgets/surfaces.dart';
import '../../../shared/widgets/sync_status.dart';
import '../state/payments_providers.dart';

/// Payment history, as on the web: every payment newest first, with a
/// receipt PDF for completed ones. Readable offline; receipts need a
/// connection.
class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_maybeLoadMore);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(paymentsControllerProvider.notifier).refresh(),
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _maybeLoadMore() {
    if (_scroll.position.extentAfter < 400) {
      ref.read(paymentsControllerProvider.notifier).loadMore();
    }
  }

  Future<void> _openReceipt(int id) async {
    final messenger = ScaffoldMessenger.of(context);
    final error = await ref.read(paymentsControllerProvider.notifier).openReceipt(id);
    if (error != null) messenger.showSnackBar(SnackBar(content: Text(error)));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paymentsControllerProvider);
    final rows = ref.watch(paymentsProvider).value;
    final summary = ref.watch(paymentsSummaryProvider).value;
    final fetchedAt = ref.watch(paymentsFetchedAtProvider).value;
    final now = ref.watch(clockProvider)();
    final controller = ref.read(paymentsControllerProvider.notifier);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const AppTopBar(title: 'Payments'),
      body: RefreshIndicator(
        onRefresh: controller.refresh,
        child: CustomScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.sm, AppSpace.gutter, AppSpace.sm),
              sliver: SliverList.list(
                children: [
                  if (fetchedAt != null) ...[
                    SyncStatus(
                      fetchedAt: fetchedAt,
                      now: now,
                      refreshing: state.refresh.isLoading,
                      refreshError: state.refresh.error,
                      onRetry: controller.refresh,
                    ),
                    const SizedBox(height: AppSpace.md),
                  ],
                  SurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            AppIcon(AppIcons.wallet, size: AppSizes.iconRow, color: context.palette.accentText),
                            const SizedBox(width: AppSpace.sm),
                            Expanded(child: Text('Total paid', style: text.bodySmall)),
                            if (summary != null)
                              AppBadge(
                                label: summary.total == 1 ? '1 payment' : '${summary.total} payments',
                                tone: BadgeTone.neutral,
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpace.sm),
                        Text(summary == null ? '–' : formatKes(summary.totalPaid), style: text.headlineSmall),
                        const SizedBox(height: AppSpace.md),
                        FilledButton.icon(
                          onPressed: () => context.push(Routes.checkout),
                          icon: const AppIcon(AppIcons.smartphone),
                          label: const Text('Renew with M-Pesa'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.lg),
                  const SectionHeader('History'),
                ],
              ),
            ),
            ..._list(rows, fetchedAt, state),
          ],
        ),
      ),
    );
  }

  List<Widget> _list(List<PaymentRecord>? rows, DateTime? fetchedAt, PaymentsState state) {
    const pad = EdgeInsets.symmetric(horizontal: AppSpace.gutter);
    final controller = ref.read(paymentsControllerProvider.notifier);
    if (rows == null || (rows.isEmpty && fetchedAt == null && !state.refresh.hasError)) {
      return const [
        SliverPadding(
          padding: pad,
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                SkeletonListTile(),
                SizedBox(height: AppSpace.sm),
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
      final error = state.refresh.error;
      return [
        SliverToBoxAdapter(
          child: fetchedAt == null && error is NetworkFailure
              ? StateMessage.offline(
                  message: 'Connect to see your payments.',
                  onAction: controller.refresh,
                )
              : fetchedAt == null && error != null
              ? StateMessage.error(onAction: controller.refresh)
              : const StateMessage(
                  icon: AppIcons.banknote,
                  title: 'No payments yet',
                  message: 'Payments made at the front desk or by M-Pesa appear here.',
                ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: pad,
        sliver: SliverList.builder(
          itemCount: rows.length,
          itemBuilder: (_, i) => _PaymentTile(
            payment: rows[i],
            opening: state.openingReceipt == rows[i].id,
            onReceipt: state.openingReceipt == null ? () => _openReceipt(rows[i].id) : null,
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpace.lg),
          child: Center(
            child: state.loadingMore
                ? const Padding(padding: EdgeInsets.all(AppSpace.md), child: SkeletonListTile())
                : state.hasMore
                ? TextButton(onPressed: controller.loadMore, child: const Text('Load older payments'))
                : const SizedBox.shrink(),
          ),
        ),
      ),
    ];
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({required this.payment, required this.opening, this.onReceipt});

  final PaymentRecord payment;
  final bool opening;
  final VoidCallback? onReceipt;

  static final _when = DateFormat('d MMM yyyy · h:mm a');

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = payment;
    final method = switch (p.method) {
      'mpesa' => 'M-Pesa',
      'cash' => 'Cash',
      'bank' => 'Bank',
      final other => other ?? '',
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: SurfaceCard.tile(
        padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 14, AppSpace.sm, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: AppIcon(
                p.method == 'mpesa' ? AppIcons.smartphone : AppIcons.banknote,
                size: AppSizes.iconRow,
                color: context.palette.rowIcon,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.plan ?? 'Membership', style: text.titleSmall),
                  const SizedBox(height: AppSpace.xs),
                  Text(p.paidAt == null ? '—' : _when.format(p.paidAt!.toLocal()), style: text.bodySmall),
                  if ((p.receipt ?? method).isNotEmpty)
                    Text(p.receipt ?? method, style: text.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: AppSpace.sm),
                  child: Text(formatKes(p.amount), style: text.titleSmall),
                ),
                const SizedBox(height: AppSpace.xs),
                switch (p.status) {
                  'completed' when p.hasReceiptPdf => TextButton.icon(
                    onPressed: onReceipt,
                    style: TextButton.styleFrom(minimumSize: const Size(0, 40)),
                    icon: const AppIcon(AppIcons.receipt),
                    label: Text(opening ? 'Opening…' : 'Receipt'),
                  ),
                  'completed' => const _StatusBadge(label: 'Paid', tone: BadgeTone.success, icon: AppIcons.circleCheck),
                  'failed' => const _StatusBadge(label: 'Failed', tone: BadgeTone.danger, icon: AppIcons.circleAlert),
                  'voided' => const _StatusBadge(label: 'Voided', tone: BadgeTone.neutral, icon: AppIcons.x),
                  'cancelled' => const _StatusBadge(label: 'Cancelled', tone: BadgeTone.neutral, icon: AppIcons.x),
                  _ => const _StatusBadge(label: 'Pending', tone: BadgeTone.warning, icon: AppIcons.clock),
                },
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.tone, required this.icon});

  final String label;
  final BadgeTone tone;
  final LucideIcon icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: AppSpace.sm),
    child: AppBadge(label: label, tone: tone, icon: icon),
  );
}
