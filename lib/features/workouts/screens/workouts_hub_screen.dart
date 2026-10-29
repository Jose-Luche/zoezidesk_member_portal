import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/db/app_database.dart';
import '../../../data/sync/sync.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/surfaces.dart';
import '../state/workouts_providers.dart';
import '../widgets/session_tile.dart';
import '../workout_format.dart';

/// The Workouts tab: resume or start a workout, build one, and find
/// history, records and the exercise library.
class WorkoutsHubScreen extends ConsumerStatefulWidget {
  const WorkoutsHubScreen({super.key});

  @override
  ConsumerState<WorkoutsHubScreen> createState() => _WorkoutsHubScreenState();
}

class _WorkoutsHubScreenState extends ConsumerState<WorkoutsHubScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(workoutHistoryControllerProvider.notifier).refresh(),
    );
  }

  Future<void> _start(String muscleGroup) async {
    final repo = ref.read(workoutsRepositoryProvider);
    final active = await repo.active();
    if (!mounted) return;
    if (active != null) {
      final resume = await showAppSheet<bool>(
        context,
        builder: (sheet) => SheetLayout(
          title: 'A workout is in progress',
          body: [
            Text(
              'Finish or discard "${active.dayType}" before starting another.',
              style: Theme.of(sheet).textTheme.bodyLarge,
            ),
          ],
          actions: [
            FilledButton(onPressed: () => Navigator.pop(sheet, true), child: const Text('Open it')),
            OutlinedButton(onPressed: () => Navigator.pop(sheet, false), child: const Text('Cancel')),
          ],
        ),
      );
      if (resume == true && mounted) await context.push(Routes.workoutSession(active.clientId));
      return;
    }
    final id = await repo.start(dayType: '${muscleLabel(muscleGroup)} workout', muscleGroup: muscleGroup);
    if (mounted) await context.push(Routes.workoutSession(id));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // Keeps the refresh alive while the tab is shown.
    ref.watch(workoutHistoryControllerProvider);
    final active = ref.watch(activeWorkoutProvider).value;
    final history = ref.watch(workoutHistoryProvider);
    final recent = (history.value ?? const <WorkoutSessionRow>[])
        .where((s) => s.status != 'in_progress')
        .take(3)
        .toList();

    return Scaffold(
      appBar: const AppTopBar(title: 'Workouts', back: false),
      body: RefreshIndicator(
        onRefresh: ref.read(workoutHistoryControllerProvider.notifier).refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.sm, AppSpace.gutter, AppSpace.lg),
          children: [
            if (active != null) ...[
              _ActiveCard(session: active),
              const SizedBox(height: AppSpace.lg),
            ],
            const SectionHeader('Start a workout', subtitle: 'Pick a focus. You can log sets without signal.'),
            Wrap(
              spacing: AppSpace.sm,
              runSpacing: AppSpace.sm,
              children: [
                for (final (value, label) in muscleGroups)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(backgroundColor: context.palette.surfaceHigh),
                    onPressed: () => _start(value),
                    child: Text(label),
                  ),
              ],
            ),
            const SizedBox(height: AppSpace.lg),
            ListCard(
              children: [
                ListRow(
                  icon: AppIcons.sparkles,
                  title: 'Build me a workout',
                  subtitle: 'Choose your goal and time; we pick the exercises.',
                  onTap: () => context.push(Routes.builder),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.sm),
            ListCard(
              children: [
                ListRow(
                  icon: AppIcons.trendingUp,
                  title: 'Progress',
                  subtitle: 'Streak, totals and muscle balance',
                  onTap: () => context.push(Routes.workoutProgress),
                ),
                ListRow(
                  icon: AppIcons.history,
                  title: 'Workout history',
                  onTap: () => context.push(Routes.workoutHistory),
                ),
                ListRow(
                  icon: AppIcons.trophy,
                  title: 'Personal records',
                  onTap: () => context.push(Routes.workoutRecords),
                ),
                ListRow(
                  icon: AppIcons.bookOpen,
                  title: 'Exercise library',
                  onTap: () => context.push(Routes.exercises),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.lg),
            const SectionHeader('Recent workouts'),
            if (!history.hasValue)
              const SkeletonList.inline()
            else if (recent.isEmpty)
              Text('Your finished workouts appear here.', style: text.bodySmall)
            else
              for (final s in recent) SessionTile(session: s),
          ],
        ),
      ),
    );
  }
}

class _ActiveCard extends StatelessWidget {
  const _ActiveCard({required this.session});

  final WorkoutSessionRow session;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final on = p.onCard;
    return Material(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    AppIcon(AppIcons.dumbbell, size: AppSizes.iconBadge, color: on),
                    const SizedBox(width: 6),
                    Expanded(child: Text('Workout in progress', style: text.titleSmall?.copyWith(color: on, fontSize: 14))),
                  ],
                ),
                const SizedBox(height: AppSpace.md),
                Text(session.dayType, style: text.headlineSmall?.copyWith(color: on)),
                const SizedBox(height: AppSpace.xs),
                Text(
                  'Started ${DateFormat('h:mm a').format(session.startedAt)} · '
                  '${session.totalSets} set${session.totalSets == 1 ? '' : 's'}',
                  style: text.bodyMedium?.copyWith(color: on),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () => context.push(Routes.workoutSession(session.clientId)),
                  child: const Text('Resume workout'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
