import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/dto/dashboard_dto.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/surfaces.dart';

/// Icon in the accent, the value in Caprasimo and a muted label. Three sit
/// in a row.
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final LucideIcon icon;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SurfaceCard.tile(
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIcon(icon, size: AppSizes.iconRow, color: context.palette.accentText),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: text.headlineSmall?.copyWith(fontSize: 22)),
            ),
            const SizedBox(height: 2),
            Text(label, style: text.bodySmall, maxLines: 2),
          ],
        ),
      ),
    );
  }
}

class QuickAction {
  const QuickAction({required this.label, required this.icon, required this.onTap});

  final String label;
  final LucideIcon icon;
  final VoidCallback onTap;
}

/// Two-per-row pill tiles, 58 tall.
class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key, required this.actions});

  final List<QuickAction> actions;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < actions.length; i += 2) {
      if (i > 0) rows.add(const SizedBox(height: AppSpace.sm));
      rows.add(Row(
        children: [
          Expanded(child: QuickActionTile(actions[i])),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: i + 1 < actions.length ? QuickActionTile(actions[i + 1]) : const SizedBox.shrink(),
          ),
        ],
      ));
    }
    return Column(children: rows);
  }
}

class QuickActionTile extends StatelessWidget {
  const QuickActionTile(this.action, {super.key});

  final QuickAction action;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: p.surface,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: action.onTap,
        customBorder: const StadiumBorder(),
        hoverColor: p.accentTint,
        highlightColor: p.accentSoft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.quickAction),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter, vertical: AppSpace.sm),
            child: Row(
              children: [
                AppIcon(action.icon, size: AppSizes.iconRow, color: p.accentText),
                const SizedBox(width: 10),
                Expanded(child: Text(action.label, style: Theme.of(context).textTheme.titleSmall)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RecentPaymentsCard extends StatelessWidget {
  const RecentPaymentsCard({super.key, required this.payments, this.onSeeAll});

  final List<RecentPayment> payments;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader('Recent payments', actionLabel: 'See all', onAction: onSeeAll),
        if (payments.isEmpty)
          Text('No payments yet.', style: text.bodySmall)
        else
          ListCard(children: [for (final payment in payments) _PaymentRow(payment)]),
      ],
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow(this.payment);

  final RecentPayment payment;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final date = DateTime.tryParse(payment.dateIso ?? '');
    final method = switch (payment.method) {
      'mpesa' => 'M-Pesa',
      'cash' => 'Cash',
      'bank' => 'Bank',
      final other => other ?? '',
    };
    final detail = [
      if (date != null) formatDate(date.toLocal()) else if (payment.date != null) payment.date!,
      payment.receipt ?? method,
    ].where((s) => s.isNotEmpty).join(' · ');

    return ListRow(
      icon: payment.method == 'mpesa' ? AppIcons.smartphone : AppIcons.banknote,
      iconColor: context.palette.rowIcon,
      title: payment.plan ?? 'Membership',
      titleStyle: text.titleSmall,
      subtitle: detail,
      trailing: Text(formatKes(payment.amount), style: text.titleSmall),
    );
  }
}

/// First load with nothing cached yet. Static blocks, no shimmer.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading dashboard',
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.sm, AppSpace.gutter, AppSpace.md),
        children: const [
          SkeletonBox(width: 120, height: 12),
          SizedBox(height: AppSpace.md),
          SkeletonBox(height: 220, radius: AppRadius.hero),
          SizedBox(height: AppSpace.md),
          Row(
            children: [
              Expanded(child: SkeletonBox(height: 104, radius: AppRadius.tile)),
              SizedBox(width: AppSpace.sm),
              Expanded(child: SkeletonBox(height: 104, radius: AppRadius.tile)),
              SizedBox(width: AppSpace.sm),
              Expanded(child: SkeletonBox(height: 104, radius: AppRadius.tile)),
            ],
          ),
          SizedBox(height: AppSpace.lg),
          Row(
            children: [
              Expanded(child: SkeletonBox(height: AppSizes.quickAction)),
              SizedBox(width: AppSpace.sm),
              Expanded(child: SkeletonBox(height: AppSizes.quickAction)),
            ],
          ),
          SizedBox(height: AppSpace.lg),
          SkeletonListTile(),
          SizedBox(height: AppSpace.sm),
          SkeletonListTile(),
        ],
      ),
    );
  }
}
