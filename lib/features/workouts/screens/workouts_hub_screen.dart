import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/db/app_database.dart';
import '../../../data/sync/sync.dart';
import '../../../shared/widgets/skeleton.dart';
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
      final resume = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('A workout is in progress'),
          content: Text('Finish or discard "${active.dayType}" before starting another.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Open it')),
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
      appBar: AppBar(title: const Text('Workouts')),
      body: RefreshIndicator(
        onRefresh: ref.read(workoutHistoryControllerProvider.notifier).refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpace.md),
          children: [
            if (active != null) ...[
              _ActiveCard(session: active),
              const SizedBox(height: AppSpace.lg),
            ],
            Text('Start a workout', style: text.titleLarge),
            const SizedBox(height: AppSpace.xs),
            Text('Pick a focus. You can log sets without signal.', style: text.bodySmall),
            const SizedBox(height: AppSpace.sm),
            Wrap(
              spacing: AppSpace.sm,
              runSpacing: AppSpace.sm,
              children: [
                for (final (value, label) in muscleGroups)
                  ActionChip(label: Text(label), onPressed: () => _start(value)),
              ],
            ),
            const SizedBox(height: AppSpace.lg),
            Card(
              child: ListTile(
                leading: const Icon(Icons.auto_awesome_rounded),
                title: const Text('Build me a workout'),
                subtitle: const Text('Choose your goal and time; we pick the exercises.'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push(Routes.builder),
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.history_rounded),
                    title: const Text('Workout history'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(Routes.workoutHistory),
                  ),
                  ListTile(
                    leading: const Icon(Icons.emoji_events_outlined),
                    title: const Text('Personal records'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(Routes.workoutRecords),
                  ),
                  ListTile(
                    leading: const Icon(Icons.menu_book_rounded),
                    title: const Text('Exercise library'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(Routes.exercises),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            Text('Recent workouts', style: text.titleLarge),
            const SizedBox(height: AppSpace.sm),
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
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: p.accentText, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Workout in progress', style: text.labelLarge?.copyWith(color: p.accentText)),
            const SizedBox(height: AppSpace.xs),
            Text(session.dayType, style: text.titleLarge),
            Text(
              'Started ${DateFormat('h:mm a').format(session.startedAt)} · '
              '${session.totalSets} set${session.totalSets == 1 ? '' : 's'}',
              style: text.bodySmall,
            ),
            const SizedBox(height: AppSpace.md),
            FilledButton(
              onPressed: () => context.push(Routes.workoutSession(session.clientId)),
              child: const Text('Resume workout'),
            ),
          ],
        ),
      ),
    );
  }
}
