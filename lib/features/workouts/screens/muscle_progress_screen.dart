import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
import '../../../shared/widgets/weekly_bars.dart';
import '../state/workouts_providers.dart';
import '../workout_format.dart';
import 'progress_screen.dart' show muscleIcon, muscleTone;

final _n = NumberFormat('#,##0', 'en_KE');

/// Twelve weeks for one muscle group, as the web muscle page: weekly
/// volume, each exercise's best week by week, and recent records.
class MuscleProgressScreen extends ConsumerStatefulWidget {
  const MuscleProgressScreen({super.key, required this.muscle});

  final String muscle;

  @override
  ConsumerState<MuscleProgressScreen> createState() => _MuscleProgressScreenState();
}

class _MuscleProgressScreenState extends ConsumerState<MuscleProgressScreen> {
  int? _exerciseId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(muscleRefreshProvider(widget.muscle).notifier).refresh(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cached = ref.watch(muscleProgressProvider(widget.muscle));
    final refresh = ref.watch(muscleRefreshProvider(widget.muscle));
    final controller = ref.read(muscleRefreshProvider(widget.muscle).notifier);
    final now = ref.watch(clockProvider)();
    final label = cached.value?.data.muscle.label ?? muscleLabel(widget.muscle);

    final Widget body = switch (cached) {
      AsyncData(value: null) => refresh.error is NetworkFailure
          ? StateMessage.offline(message: 'Connect to see this muscle group.', onAction: controller.refresh)
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
            ..._content(context, c.data),
          ],
        ),
      // Saved data that cannot be read (should not happen): offer a refresh.
      AsyncError() => StateMessage.error(onAction: controller.refresh),
      _ => const SkeletonList(),
    };

    return Scaffold(
      appBar: AppTopBar(title: label),
      body: RefreshIndicator(onRefresh: controller.refresh, child: body),
    );
  }

  List<Widget> _content(BuildContext context, MuscleDetail d) {
    final text = Theme.of(context).textTheme;
    final m = d.muscle;
    final selected = d.exercises.where((e) => e.id == _exerciseId).firstOrNull ?? d.exercises.firstOrNull;

    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppBadge(label: m.statusLabel, tone: muscleTone(m.status), icon: muscleIcon(m.status)),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(
              [
                '${plural(m.setsThisWeek, 'set')} this week (goal ${d.targetSets.$1}–${d.targetSets.$2})',
                if (m.strengthChange != null)
                  '${m.strengthChange! >= 0 ? '+' : ''}${m.strengthChange!.toStringAsFixed(1)}% strength',
              ].join(' · '),
              style: text.bodySmall,
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpace.lg),
      if (d.exercises.isEmpty)
        const StateMessage(
          icon: AppIcons.dumbbell,
          title: 'Not trained in the last 12 weeks',
          message: 'Log a workout with these exercises and the charts fill in.',
        )
      else ...[
        _ChartCard(
          title: 'Weight lifted per week',
          subtitle: 'Weight × reps, last 12 weeks',
          values: d.weeklyVolume,
          labels: d.weekLabels,
          format: (v) => '${_n.format(v)} kg',
        ),
        const SizedBox(height: AppSpace.lg),
        const SectionHeader('Exercises'),
        Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: [
            for (final e in d.exercises)
              ChoiceChip(
                label: Text(e.name),
                selected: e.id == selected?.id,
                onSelected: (_) => setState(() => _exerciseId = e.id),
              ),
          ],
        ),
        if (selected != null) ...[
          const SizedBox(height: AppSpace.md),
          SurfaceCard.tile(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(selected.name, style: text.titleMedium),
                const SizedBox(height: 2),
                Text(
                  [
                    'Best set ${selected.bestSet}',
                    if (selected.bestE1rm != null) 'est. 1RM ${formatKg(selected.bestE1rm!)}',
                    plural(selected.sessions, 'workout'),
                    if (selected.lastDate != null) 'last ${formatDate(selected.lastDate!)}',
                  ].join(' · '),
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          _ChartCard(
            title: selected.usesWeight ? 'Best estimated 1RM per week' : 'Best reps per week',
            subtitle: selected.name,
            values: selected.weeklyBest,
            labels: d.weekLabels,
            format: (v) => selected.usesWeight ? formatKg(v) : plural(v.round(), 'rep'),
          ),
        ],
      ],
      if (d.prs.isNotEmpty) ...[
        const SizedBox(height: AppSpace.lg),
        const SectionHeader('Recent records'),
        ListCard(
          children: [
            for (final pr in d.prs)
              ListRow(
                icon: AppIcons.trophy,
                title: pr.exercise,
                titleStyle: text.titleSmall,
                subtitle: pr.description,
                trailing: pr.date == null ? null : Text(formatDate(pr.date!), style: text.bodySmall),
              ),
          ],
        ),
      ],
    ];
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.values,
    required this.labels,
    required this.format,
  });

  final String title;
  final String subtitle;
  final List<double?> values;
  final List<String> labels;
  final String Function(double) format;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.md + 2, AppSpace.gutter, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: text.titleMedium),
          Text(subtitle, style: text.bodySmall),
          const SizedBox(height: AppSpace.md),
          WeeklyBars(values: values, labels: labels, format: format, semanticTitle: title),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text('See the numbers', style: text.titleSmall?.copyWith(color: context.palette.accentText)),
            children: [WeeklyTable(values: values, labels: labels, format: format)],
          ),
        ],
      ),
    );
  }
}
