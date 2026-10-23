import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/dto/dashboard_dto.dart';
import '../../../shared/widgets/skeleton.dart';

class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.md),
        child: MergeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: context.palette.accentText),
              const SizedBox(height: AppSpace.sm),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value, style: text.headlineSmall),
              ),
              Text(label, style: text.bodySmall, maxLines: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class QuickAction {
  const QuickAction({required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

/// Two-column grid of large touch targets.
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
          Expanded(child: _ActionTile(actions[i])),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: i + 1 < actions.length ? _ActionTile(actions[i + 1]) : const SizedBox.shrink(),
          ),
        ],
      ));
    }
    return Column(children: rows);
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile(this.action);

  final QuickAction action;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: action.onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSpace.xxxl),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm),
            child: Row(
              children: [
                Icon(action.icon, color: context.palette.accentText),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Text(action.label, style: Theme.of(context).textTheme.titleSmall),
                ),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: AppSpace.md, right: AppSpace.sm),
              child: Row(
                children: [
                  Expanded(child: Text('Recent payments', style: text.titleLarge)),
                  if (onSeeAll != null)
                    TextButton(onPressed: onSeeAll, child: const Text('See all')),
                ],
              ),
            ),
            if (payments.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpace.md),
                child: Text('No payments yet.', style: text.bodySmall),
              )
            else
              for (final payment in payments) _PaymentRow(payment),
          ],
        ),
      ),
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

    return ListTile(
      leading: Icon(
        payment.method == 'mpesa' ? Icons.phone_android_rounded : Icons.payments_rounded,
      ),
      title: Text(payment.plan ?? 'Membership', style: text.titleSmall),
      subtitle: Text(detail, style: text.bodySmall),
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
        padding: const EdgeInsets.all(AppSpace.md),
        children: const [
          SkeletonBox(height: 220, radius: AppRadius.card),
          SizedBox(height: AppSpace.md),
          Row(
            children: [
              Expanded(child: SkeletonBox(height: 104, radius: AppRadius.card)),
              SizedBox(width: AppSpace.sm),
              Expanded(child: SkeletonBox(height: 104, radius: AppRadius.card)),
              SizedBox(width: AppSpace.sm),
              Expanded(child: SkeletonBox(height: 104, radius: AppRadius.card)),
            ],
          ),
          SizedBox(height: AppSpace.md),
          SkeletonListTile(),
          SizedBox(height: AppSpace.sm),
          SkeletonListTile(),
        ],
      ),
    );
  }
}
