import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/clock.dart';
import '../../../data/repositories/workouts_repository.dart';
import '../../../shared/widgets/app_badge.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/info_banner.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/state_message.dart';
import '../../../shared/widgets/surfaces.dart';
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

/// The icon that goes with a muscle's status, so it never relies on color.
LucideIcon muscleIcon(String status) => switch (status) {
      'progressing' => AppIcons.trendingUp,
      'plateau' => AppIcons.moveRight,
      'declining' => AppIcons.trendingDown,
      'neglected' => AppIcons.circleAlert,
      _ => AppIcons.clock,
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
            if (c.data.allTime.sessions == 0)
              const StateMessage(
                icon: AppIcons.trendingUp,
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
      appBar: const AppTopBar(title: 'Progress'),
      body: RefreshIndicator(onRefresh: controller.refresh, child: body),
    );
  }

  List<Widget> _content(BuildContext context, ProgressSummary s) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    return [
      Material(
        color: p.cardFill,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.hero)),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              top: -90,
              right: -70,
              child: ExcludeSemantics(
                child: Container(
                  width: 210,
                  height: 210,
                  decoration: BoxDecoration(color: p.cardDecor, shape: BoxShape.circle),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: MergeSemantics(
                child: Row(
                  children: [
                    AppIcon(AppIcons.flame, size: 28, color: p.onCard),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.streak == 0 ? 'No streak right now' : '${s.streak}-day streak',
                            style: text.headlineSmall?.copyWith(color: p.onCard),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            s.streak == 0 ? 'Finish a workout today to start one.' : 'Days in a row with a finished workout.',
                            style: text.bodyMedium?.copyWith(color: p.onCard),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpace.lg),
      const SectionHeader('This month'),
      _Totals(totals: s.thisMonth),
      const SizedBox(height: AppSpace.lg),
      const SectionHeader('All time'),
      _Totals(totals: s.allTime),
      const SizedBox(height: AppSpace.sm),
      Text(
        'Per workout: ${s.setsPerSession} sets and ${_n.format(s.volumePerSession)} kg on average.',
        style: text.bodySmall,
      ),
      if (s.topExercises.isNotEmpty) ...[
        const SizedBox(height: AppSpace.lg),
        const SectionHeader('Top exercises', subtitle: 'By total weight lifted'),
        ListCard(
          children: [
            for (final (i, e) in s.topExercises.indexed)
              ListRow(
                leading: SizedBox(
                  width: 22,
                  child: Text('${i + 1}', style: text.titleLarge?.copyWith(color: p.accentText)),
                ),
                title: e.name,
                titleStyle: text.titleSmall,
                subtitle: plural(e.sets, 'set'),
                trailing: Text('${_n.format(e.volume)} kg', style: text.titleSmall),
              ),
          ],
        ),
      ],
      const SizedBox(height: AppSpace.lg),
      SectionHeader(
        'Muscle balance',
        subtitle: 'Sets this week; your goal suggests ${s.targetSets.$1}–${s.targetSets.$2} per muscle.',
      ),
      for (final m in s.muscles.where((m) => m.status != 'no_data')) _MuscleTile(muscle: m, weekLabels: s.weekLabels),
      if (s.muscles.any((m) => m.status == 'no_data'))
        InfoBanner(
          icon: AppIcons.clock,
          message: 'Not trained in the last ${s.weekLabels.length} weeks: '
              '${s.muscles.where((m) => m.status == 'no_data').map((m) => m.label).join(', ')}.',
        ),
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
    return SurfaceCard.tile(
      padding: const EdgeInsets.fromLTRB(12, 14, AppSpace.sm, 14),
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: text.headlineSmall?.copyWith(fontSize: 22)),
            ),
            Text(label, style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
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

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: SurfaceCard.tile(
        onTap: () => context.push(Routes.muscleProgress(m.key)),
        padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 14, 12, 14),
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
                        Flexible(child: AppBadge(label: m.statusLabel, tone: muscleTone(m.status), icon: muscleIcon(m.status))),
                      ],
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Text.rich(
                      TextSpan(children: [
                        // Below the weekly target for the member's goal.
                        TextSpan(
                          text: '${plural(m.setsThisWeek, 'set')} this week',
                          style: m.volumeStatus == 'below' ? TextStyle(color: p.warning, fontWeight: FontWeight.w600) : null,
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
              const SizedBox(width: AppSpace.xs),
              AppIcon(AppIcons.chevronRight, size: AppSizes.iconRow, color: p.textMuted),
            ],
          ),
      ),
    );
  }
}
