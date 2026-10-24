import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/dto/builder_dto.dart';
import '../../../data/sync/sync.dart';
import '../../../shared/widgets/app_badge.dart';
import '../../../shared/widgets/info_banner.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/state_message.dart';
import '../state/builder_providers.dart';

/// The generated workout: review, swap, remove, reorder, save as a template
/// or start it, as on the web results page. Viewable offline; changes need
/// a connection.
class WorkoutResultScreen extends ConsumerStatefulWidget {
  const WorkoutResultScreen({super.key});

  @override
  ConsumerState<WorkoutResultScreen> createState() => _WorkoutResultScreenState();
}

class _WorkoutResultScreenState extends ConsumerState<WorkoutResultScreen> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Starting creates the session on the server; logging then happens in
  /// the app's workout screen.
  Future<void> _start(GuidedWorkout workout) async {
    final sessionId = await ref.read(workoutEditorProvider.notifier).start(workout);
    if (sessionId != null && mounted) await _open(sessionId);
  }

  Future<void> _open(int sessionId) async {
    try {
      final clientId = await ref.read(workoutsRepositoryProvider).adoptServerSession(sessionId);
      if (mounted) await context.push(Routes.workoutSession(clientId));
    } on AppFailure catch (e) {
      if (mounted) _report(context, e);
    }
  }

  void _report(BuildContext context, Object? error) {
    if (error is! AppFailure) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        error is NetworkFailure
            ? 'You are offline. Changing the workout needs an internet connection.'
            : error.message,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final workout = ref.watch(builderWorkoutProvider).value?.data;
    final editing = ref.watch(workoutEditorProvider);

    ref.listen(workoutEditorProvider, (_, next) {
      if (next.hasError) _report(context, next.error);
    });

    if (workout == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Your workout')),
        body: StateMessage.empty(
          title: 'No workout yet',
          message: 'Build one with the workout builder.',
          actionLabel: 'Back',
          onAction: () => Navigator.of(context).maybePop(),
        ),
      );
    }

    final busy = editing.isLoading;
    final locked = workout.started;
    final text = Theme.of(context).textTheme;
    final editor = ref.read(workoutEditorProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(workout.templateName ?? 'Your workout')),
      body: CustomScrollView(
        controller: _scroll,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(AppSpace.md),
            sliver: SliverList.list(children: [
              _Summary(workout: workout),
              if (locked) ...[
                const SizedBox(height: AppSpace.md),
                InfoBanner(
                  tone: BadgeTone.success,
                  icon: Icons.play_circle_rounded,
                  message: 'Workout started. Log your sets as you go.',
                  actionLabel: workout.sessionId == null ? null : 'Open workout',
                  onAction: workout.sessionId == null ? null : () => _open(workout.sessionId!),
                ),
              ],
              if (busy) ...[
                const SizedBox(height: AppSpace.sm),
                const LinearProgressIndicator(),
              ],
              const SizedBox(height: AppSpace.md),
              if (workout.exercises.isEmpty)
                Text('No exercises left. Build a new workout.', style: text.bodySmall),
            ]),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
            sliver: SliverList.builder(
              itemCount: workout.exercises.length,
              itemBuilder: (context, i) => _ExerciseCard(
                index: i,
                count: workout.exercises.length,
                exercise: workout.exercises[i],
                enabled: !busy && !locked,
                onUp: () => editor.move(workout, i, -1),
                onDown: () => editor.move(workout, i, 1),
                onRemove: () => editor.remove(workout, workout.exercises[i]),
                onSwap: () => _showSwap(workout, workout.exercises[i]),
              ),
            ),
          ),
          if (!locked)
            SliverPadding(
              padding: const EdgeInsets.all(AppSpace.md),
              sliver: SliverList.list(children: [
                FilledButton.icon(
                  onPressed: busy || workout.exercises.isEmpty ? null : () => _start(workout),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Start workout'),
                ),
                const SizedBox(height: AppSpace.sm),
                OutlinedButton.icon(
                  onPressed: busy ? null : () => _showSaveTemplate(workout),
                  icon: const Icon(Icons.bookmark_add_rounded),
                  label: Text(workout.status == 'saved_template' ? 'Rename template' : 'Save as template'),
                ),
                const SizedBox(height: AppSpace.lg),
              ]),
            ),
        ],
      ),
    );
  }

  Future<void> _showSwap(GuidedWorkout workout, GuidedExercise exercise) async {
    final chosen = await showModalBottomSheet<ExerciseAlternative>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _SwapSheet(workout: workout, exercise: exercise),
    );
    if (chosen != null) {
      await ref.read(workoutEditorProvider.notifier).swap(workout, exercise, chosen);
    }
  }

  Future<void> _showSaveTemplate(GuidedWorkout workout) async {
    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _TemplateSheet(initial: workout.templateName),
    );
    if (name == null) return;
    final saved = await ref.read(workoutEditorProvider.notifier).saveTemplate(workout, name);
    if (saved && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Saved as template.')));
    }
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.workout});

  final GuidedWorkout workout;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppSpace.sm,
              runSpacing: AppSpace.sm,
              children: [
                AppBadge(
                  label: '${workout.exercises.length} exercises',
                  tone: BadgeTone.neutral,
                  icon: Icons.fitness_center_rounded,
                ),
                if (workout.estimatedDurationMinutes != null)
                  AppBadge(
                    label: '~${workout.estimatedDurationMinutes} min',
                    tone: BadgeTone.neutral,
                    icon: Icons.timer_rounded,
                  ),
                if (workout.status == 'saved_template')
                  const AppBadge(label: 'Template', icon: Icons.bookmark_rounded),
              ],
            ),
            if (workout.explanation != null) ...[
              const SizedBox(height: AppSpace.md),
              Text(workout.explanation!, style: text.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatefulWidget {
  const _ExerciseCard({
    required this.index,
    required this.count,
    required this.exercise,
    required this.enabled,
    required this.onUp,
    required this.onDown,
    required this.onRemove,
    required this.onSwap,
  });

  final int index;
  final int count;
  final GuidedExercise exercise;
  final bool enabled;
  final VoidCallback onUp;
  final VoidCallback onDown;
  final VoidCallback onRemove;
  final VoidCallback onSwap;

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard> {
  bool _showHow = false;

  String _title(String? s) =>
      s == null || s.isEmpty ? '' : s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    final e = widget.exercise;
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final scheme = Theme.of(context).colorScheme;

    final weight = e.targetWeightKg == null || e.targetWeightKg == 0
        ? null
        : '${e.targetWeightKg!.toStringAsFixed(e.targetWeightKg! % 1 == 0 ? 0 : 1)} kg';
    final targets = [
      '${e.targetSets} × ${e.targetReps}',
      ?weight,
      '${e.restSeconds}s rest',
    ].join(' · ');
    final meta = [_title(e.muscleGroup), _title(e.difficulty)].where((s) => s.isNotEmpty).join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.md, AppSpace.sm, AppSpace.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: AppSpace.md,
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                    child: Text('${widget.index + 1}', style: text.labelLarge?.copyWith(color: scheme.onPrimary)),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.name, style: text.titleMedium),
                        if (meta.isNotEmpty) Text(meta, style: text.bodySmall),
                        const SizedBox(height: AppSpace.xs),
                        Text(targets, style: text.bodyLarge),
                        if (e.suggestedWeightProgression != null)
                          Text('Next time: ${e.suggestedWeightProgression}', style: text.bodySmall),
                        if (e.plateau) ...[
                          const SizedBox(height: AppSpace.xs),
                          const AppBadge(
                            label: 'Plateau: consider a swap',
                            tone: BadgeTone.warning,
                            icon: Icons.trending_flat_rounded,
                          ),
                        ],
                        if (e.reason != null) ...[
                          const SizedBox(height: AppSpace.xs),
                          Text(e.reason!, style: text.bodySmall?.copyWith(color: p.textMuted)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (_showHow && e.instructions != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpace.sm, right: AppSpace.sm),
                  child: Text(e.instructions!, style: text.bodyMedium),
                ),
              Row(
                children: [
                  if (e.instructions != null)
                    TextButton(
                      onPressed: () => setState(() => _showHow = !_showHow),
                      child: Text(_showHow ? 'Hide how-to' : 'How to'),
                    ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Move up',
                    onPressed: widget.enabled && widget.index > 0 ? widget.onUp : null,
                    icon: const Icon(Icons.arrow_upward_rounded),
                  ),
                  IconButton(
                    tooltip: 'Move down',
                    onPressed: widget.enabled && widget.index < widget.count - 1 ? widget.onDown : null,
                    icon: const Icon(Icons.arrow_downward_rounded),
                  ),
                  IconButton(
                    tooltip: 'Swap exercise',
                    onPressed: widget.enabled ? widget.onSwap : null,
                    icon: const Icon(Icons.swap_horiz_rounded),
                  ),
                  IconButton(
                    tooltip: 'Remove exercise',
                    onPressed: widget.enabled ? widget.onRemove : null,
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwapSheet extends ConsumerWidget {
  const _SwapSheet({required this.workout, required this.exercise});

  final GuidedWorkout workout;
  final GuidedExercise exercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alternatives = ref.watch(alternativesProvider((workout.id, exercise.id)));
    final text = Theme.of(context).textTheme;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.md, 0, AppSpace.md, AppSpace.sm),
              child: Text('Swap ${exercise.name}', style: text.headlineSmall),
            ),
            Flexible(
              child: switch (alternatives) {
                AsyncData(:final value) when value.isEmpty => const Padding(
                    padding: EdgeInsets.all(AppSpace.lg),
                    child: Text('No alternatives match your answers.'),
                  ),
                AsyncData(:final value) => ListView.builder(
                    shrinkWrap: true,
                    itemCount: value.length,
                    itemBuilder: (_, i) {
                      final a = value[i];
                      return ListTile(
                        leading: const Icon(Icons.fitness_center_rounded),
                        title: Text(a.name),
                        subtitle: Text(
                          [a.difficulty, ...a.equipment]
                              .whereType<String>()
                              .where((s) => s.isNotEmpty)
                              .map((s) => s[0].toUpperCase() + s.substring(1))
                              .join(' · '),
                          style: text.bodySmall,
                        ),
                        onTap: () => Navigator.pop(context, a),
                      );
                    },
                  ),
                AsyncError(:final error) => StateMessage(
                    icon: error is NetworkFailure ? Icons.cloud_off_rounded : Icons.error_outline_rounded,
                    title: error is NetworkFailure ? 'You are offline' : 'Could not load alternatives',
                    message: 'Swapping needs an internet connection.',
                    actionLabel: 'Try again',
                    onAction: () => ref.invalidate(alternativesProvider((workout.id, exercise.id))),
                  ),
                _ => const SkeletonList(itemCount: 3),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateSheet extends StatefulWidget {
  const _TemplateSheet({this.initial});

  final String? initial;

  @override
  State<_TemplateSheet> createState() => _TemplateSheetState();
}

class _TemplateSheetState extends State<_TemplateSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial ?? '');

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpace.md,
        0,
        AppSpace.md,
        AppSpace.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Save as template', style: text.headlineSmall),
            const SizedBox(height: AppSpace.md),
            TextFormField(
              controller: _name,
              autofocus: true,
              maxLength: 255,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Template name', hintText: 'Push day'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Give the template a name.' : null,
            ),
            const SizedBox(height: AppSpace.md),
            FilledButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) Navigator.pop(context, _name.text.trim());
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
