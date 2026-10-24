import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/clock.dart';
import '../../../data/repositories/workouts_repository.dart';
import '../../../shared/widgets/app_badge.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/state_message.dart';
import '../../../shared/widgets/sync_status.dart';
import '../../../shared/widgets/weekly_bars.dart';
import '../state/workouts_providers.dart';
import '../workout_format.dart';

final _n = NumberFormat('#,##0', 'en_KE');

BadgeTone muscleTone(String status) => switch (status) {
      'progressing' => BadgeTone.success,
      'plateau' => BadgeTone.warning,
      'declining' || 'neglected' => BadgeTone.danger,
      _ => BadgeTone.neutral,
    };

/// The web Analytics page: this month and all time, the streak, top
/// exercises, and how each muscle group is doing. Saved for offline.
class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(progressRefreshProvider.notifier).refresh());
  }

  @override
  Widget build(BuildContext context) {
    final cached = ref.watch(progressProvider);
    final refresh = ref.watch(progressRefreshProvider);
    final controller = ref.read(progressRefreshProvider.notifier);
    final now = ref.watch(clockProvider)();

    final Widget body = switch (cached) {
      AsyncData(value: null) => refresh.error is NetworkFailure
          ? StateMessage.offline(message: 'Connect to see your progress.', onAction: controller.refresh)
          : refresh.hasError
          ? StateMessage.error(onAction: controller.refresh)
          : const SkeletonList(),
      AsyncData(value: final c?) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpace.md),
          children: [
            SyncStatus(
              fetchedAt: c.fetchedAt,
              now: now,
              refreshing: refresh.isLoading,
              refreshError: refresh.error,
              onRetry: controller.refresh,
            ),
            const SizedBox(height: AppSpace.sm),
            if (c.data.allTime.sessions == 0)
              const StateMessage(
                icon: Icons.insights_rounded,
                title: 'No finished workouts yet',
                message: 'Finish a workout and your progress shows here.',
              )
            else
              ..._content(context, c.data),
          ],
        ),
      // Saved data that cannot be read (should not happen): offer a refresh.
      AsyncError() => StateMessage.error(onAction: controller.refresh),
      _ => const SkeletonList(),
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: RefreshIndicator(onRefresh: controller.refresh, child: body),
    );
  }

  List<Widget> _content(BuildContext context, ProgressSummary s) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    return [
      Card(
        child: ListTile(
          leading: Icon(Icons.local_fire_department_rounded, color: s.streak > 0 ? p.accentText : p.textMuted),
          title: Text(
            s.streak == 0 ? 'No streak right now' : '${s.streak}-day streak',
            style: text.titleMedium,
          ),
          subtitle: Text(
            s.streak == 0 ? 'Finish a workout today to start one.' : 'Days in a row with a finished workout.',
            style: text.bodySmall,
          ),
        ),
      ),
      const SizedBox(height: AppSpace.md),
      Text('This month', style: text.titleMedium),
      const SizedBox(height: AppSpace.sm),
      _Totals(totals: s.thisMonth),
      const SizedBox(height: AppSpace.md),
      Text('All time', style: text.titleMedium),
      const SizedBox(height: AppSpace.sm),
      _Totals(totals: s.allTime),
      const SizedBox(height: AppSpace.sm),
      Text(
        'Per workout: ${s.setsPerSession} sets and ${_n.format(s.volumePerSession)} kg on average.',
        style: text.bodySmall,
      ),
      if (s.topExercises.isNotEmpty) ...[
        const SizedBox(height: AppSpace.lg),
        Text('Top exercises', style: text.titleMedium),
        Text('By total weight lifted', style: text.bodySmall),
        const SizedBox(height: AppSpace.sm),
        Card(
          child: Column(
            children: [
              for (final (i, e) in s.topExercises.indexed)
                ListTile(
                  leading: Text('${i + 1}', style: text.titleMedium),
                  title: Text(e.name, style: text.titleSmall),
                  subtitle: Text(plural(e.sets, 'set'), style: text.bodySmall),
                  trailing: Text('${_n.format(e.volume)} kg', style: text.titleSmall),
                ),
            ],
          ),
        ),
      ],
      const SizedBox(height: AppSpace.lg),
      Text('Muscle balance', style: text.titleMedium),
      Text(
        'Sets this week; your goal suggests ${s.targetSets.$1}–${s.targetSets.$2} per muscle.',
        style: text.bodySmall,
      ),
      const SizedBox(height: AppSpace.sm),
      for (final m in s.muscles.where((m) => m.status != 'no_data')) _MuscleTile(muscle: m, weekLabels: s.weekLabels),
      if (s.muscles.any((m) => m.status == 'no_data'))
        Card(
          child: ListTile(
            title: Text('Not trained in the last ${s.weekLabels.length} weeks', style: text.titleSmall),
            subtitle: Text(
              s.muscles.where((m) => m.status == 'no_data').map((m) => m.label).join(', '),
              style: text.bodySmall,
            ),
          ),
        ),
      const SizedBox(height: AppSpace.lg),
    ];
  }
}

class _Totals extends StatelessWidget {
  const _Totals({required this.totals});

  final PeriodTotals totals;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(child: _Tile(value: _n.format(totals.sessions), label: 'Workouts')),
          const SizedBox(width: AppSpace.sm),
          Expanded(child: _Tile(value: _n.format(totals.sets), label: 'Sets')),
          const SizedBox(width: AppSpace.sm),
          Expanded(child: _Tile(value: _n.format(totals.volume), label: 'kg lifted')),
          const SizedBox(width: AppSpace.sm),
          Expanded(child: _Tile(value: _n.format(totals.prs), label: 'PRs')),
        ],
      );
}

class _Tile extends StatelessWidget {
  const _Tile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.md),
        child: Column(
          children: [
            FittedBox(child: Text(value, style: text.titleLarge)),
            Text(label, style: text.bodySmall, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _MuscleTile extends StatelessWidget {
  const _MuscleTile({required this.muscle, required this.weekLabels});

  final MuscleStatus muscle;
  final List<String> weekLabels;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final m = muscle;
    final detail = switch (m.status) {
      'neglected' => 'Last trained ${m.daysSince} days ago',
      _ when m.strengthChange != null =>
        '${m.strengthChange! >= 0 ? '+' : ''}${m.strengthChange!.toStringAsFixed(1)}% strength',
      _ => 'Building a baseline',
    };

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpace.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () => context.push(Routes.muscleProgress(m.key)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(child: Text(m.label, style: text.titleSmall)),
                        const SizedBox(width: AppSpace.sm),
                        AppBadge(label: m.statusLabel, tone: muscleTone(m.status)),
                      ],
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Text.rich(
                      TextSpan(children: [
                        // Below the weekly target for the member's goal.
                        TextSpan(
                          text: '${plural(m.setsThisWeek, 'set')} this week',
                          style: m.volumeStatus == 'below' ? TextStyle(color: p.warning) : null,
                        ),
                        TextSpan(text: ' · $detail'),
                      ]),
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.md),
              SizedBox(
                width: 72,
                child: WeeklyBars(
                  values: m.weeklySets,
                  labels: weekLabels,
                  format: (v) => plural(v.round(), 'set'),
                  semanticTitle: '${m.label} sets per week',
                  height: 32,
                  compact: true,
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: p.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
