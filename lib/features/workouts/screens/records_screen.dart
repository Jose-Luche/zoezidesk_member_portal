import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/repositories/workouts_repository.dart';
import '../../../shared/widgets/app_badge.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/state_message.dart';
import '../../../shared/widgets/surfaces.dart';
import '../../../shared/widgets/sync_status.dart';
import '../state/workouts_providers.dart';
import '../workout_format.dart';

/// Personal records per exercise, as on the web PR history page.
class RecordsScreen extends ConsumerStatefulWidget {
  const RecordsScreen({super.key});

  @override
  ConsumerState<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends ConsumerState<RecordsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(recordsRefreshProvider.notifier).refresh());
  }

  @override
  Widget build(BuildContext context) {
    final cached = ref.watch(personalRecordsProvider);
    final refresh = ref.watch(recordsRefreshProvider);
    final controller = ref.read(recordsRefreshProvider.notifier);
    final now = ref.watch(clockProvider)();
    final text = Theme.of(context).textTheme;

    final Widget body = switch (cached) {
      AsyncData(value: null) => refresh.error is NetworkFailure
          ? StateMessage.offline(message: 'Connect to see your records.', onAction: controller.refresh)
          : refresh.hasError
          ? StateMessage.error(onAction: controller.refresh)
          : const SkeletonList(),
      AsyncData(value: final c?) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.sm, AppSpace.gutter, AppSpace.lg),
          children: [
            SyncStatus(
              fetchedAt: c.fetchedAt,
              now: now,
              refreshing: refresh.isLoading,
              refreshError: refresh.error,
              onRetry: controller.refresh,
            ),
            const SizedBox(height: AppSpace.md),
            Row(
              children: [
                Expanded(child: _Stat(icon: AppIcons.trophy, label: 'Records', value: '${c.data.total}')),
                const SizedBox(width: AppSpace.sm),
                Expanded(child: _Stat(icon: AppIcons.calendar, label: 'This month', value: '${c.data.thisMonth}')),
              ],
            ),
            const SizedBox(height: AppSpace.lg),
            if (c.data.exercises.isEmpty)
              const StateMessage(
                icon: AppIcons.trophy,
                title: 'No records yet',
                message: 'Log sets with weight and reps. A new best is marked as a PR.',
              )
            else
              for (final e in c.data.exercises) _ExerciseRecordsCard(records: e),
            const SizedBox(height: AppSpace.sm),
            Text('Estimated 1RM uses the Brzycki formula, as on the web.', style: text.bodySmall),
          ],
        ),
      _ => const SkeletonList(),
    };

    return Scaffold(
      appBar: const AppTopBar(title: 'Personal records'),
      body: RefreshIndicator(onRefresh: controller.refresh, child: body),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label, required this.value});

  final LucideIcon icon;
  final String label;
  final String value;

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
            Text(value, style: text.headlineSmall?.copyWith(fontSize: 22)),
            Text(label, style: text.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _ExerciseRecordsCard extends StatelessWidget {
  const _ExerciseRecordsCard({required this.records});

  final ExerciseRecords records;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final r = records;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: SurfaceCard.tile(
        padding: EdgeInsets.zero,
        child: ExpansionTile(
        title: Text(r.name, style: text.titleSmall),
        subtitle: Text(
          [
            if (r.best1rm != null) 'Best est. 1RM ${formatKg(r.best1rm!)}',
            if (r.lastAt != null) 'last PR ${formatDate(r.lastAt!.toLocal())}',
          ].join(' · '),
          style: text.bodySmall,
        ),
        trailing: AppBadge(label: '${r.records.length}', tone: BadgeTone.highlight, icon: AppIcons.trophy),
        childrenPadding: const EdgeInsets.fromLTRB(AppSpace.gutter, 0, AppSpace.gutter, AppSpace.md),
        children: [
          for (final pr in r.records)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
              child: Row(
                children: [
                  Expanded(child: Text(recordLabel(pr.metricType, pr.value, pr.repCount), style: text.bodyMedium)),
                  Text(formatDate(pr.loggedAt.toLocal()), style: text.bodySmall),
                ],
              ),
            ),
        ],
        ),
      ),
    );
  }
}
