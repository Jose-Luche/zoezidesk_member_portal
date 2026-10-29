import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/dto/builder_dto.dart';
import '../../../data/sync/sync.dart';
import '../../../shared/widgets/app_badge.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/info_banner.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/state_message.dart';
import '../../../shared/widgets/surfaces.dart';
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
        appBar: const AppTopBar(title: 'Your workout'),
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
      appBar: AppTopBar(title: workout.templateName ?? 'Your workout'),
      body: CustomScrollView(
        controller: _scroll,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.sm, AppSpace.gutter, 0),
            sliver: SliverList.list(children: [
              _Summary(workout: workout),
              if (locked) ...[
                const SizedBox(height: AppSpace.md),
                InfoBanner(
                  tone: BadgeTone.success,
                  icon: AppIcons.circlePlay,
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
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
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
              padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.md, AppSpace.gutter, AppSpace.lg),
              sliver: SliverList.list(children: [
                FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(AppSizes.sheetButton)),
                  onPressed: busy || workout.exercises.isEmpty ? null : () => _start(workout),
                  icon: const AppIcon(AppIcons.play),
                  label: const Text('Start workout'),
                ),
                const SizedBox(height: AppSpace.sm),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(AppSizes.sheetButton)),
                  onPressed: busy ? null : () => _showSaveTemplate(workout),
                  icon: const AppIcon(AppIcons.bookmarkPlus),
                  label: Text(workout.status == 'saved_template' ? 'Rename template' : 'Save as template'),
                ),
              ]),
            ),
        ],
      ),
    );
  }

  Future<void> _showSwap(GuidedWorkout workout, GuidedExercise exercise) async {
    final chosen = await showAppSheet<ExerciseAlternative>(
      context,
      builder: (_) => _SwapSheet(workout: workout, exercise: exercise),
    );
    if (chosen != null) {
      await ref.read(workoutEditorProvider.notifier).swap(workout, exercise, chosen);
    }
  }

  Future<void> _showSaveTemplate(GuidedWorkout workout) async {
    final name = await showAppSheet<String>(
      context,
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
    return SurfaceCard(
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
                icon: AppIcons.dumbbell,
              ),
              if (workout.estimatedDurationMinutes != null)
                AppBadge(
                  label: '~${workout.estimatedDurationMinutes} min',
                  tone: BadgeTone.neutral,
                  icon: AppIcons.timer,
                ),
              if (workout.status == 'saved_template')
                const AppBadge(label: 'Template', icon: AppIcons.bookmark),
            ],
          ),
          if (workout.explanation != null) ...[
            const SizedBox(height: 12),
            Text(workout.explanation!, style: text.bodyMedium),
          ],
        ],
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
      child: SurfaceCard(
        padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.md, AppSpace.sm, AppSpace.xs),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: p.accentTint, shape: BoxShape.circle),
                    child: Text('${widget.index + 1}', style: text.titleMedium?.copyWith(color: p.accentText)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.name, style: text.titleMedium),
                        if (meta.isNotEmpty) Text(meta, style: text.bodySmall),
                        const SizedBox(height: 6),
                        Text(targets, style: text.titleSmall?.copyWith(color: p.accentText)),
                        if (e.suggestedWeightProgression != null)
                          Text('Next time: ${e.suggestedWeightProgression}', style: text.bodySmall),
                        if (e.plateau) ...[
                          const SizedBox(height: AppSpace.xs),
                          const AppBadge(
                            label: 'Plateau: consider a swap',
                            tone: BadgeTone.warning,
                            icon: AppIcons.moveRight,
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
                  padding: const EdgeInsets.only(top: 12, right: AppSpace.sm, left: 48),
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
                    icon: const AppIcon(AppIcons.arrowUp, size: AppSizes.iconRow),
                  ),
                  IconButton(
                    tooltip: 'Move down',
                    onPressed: widget.enabled && widget.index < widget.count - 1 ? widget.onDown : null,
                    icon: const AppIcon(AppIcons.arrowDown, size: AppSizes.iconRow),
                  ),
                  IconButton(
                    tooltip: 'Swap exercise',
                    onPressed: widget.enabled ? widget.onSwap : null,
                    icon: const AppIcon(AppIcons.arrowLeftRight, size: AppSizes.iconRow),
                  ),
                  IconButton(
                    tooltip: 'Remove exercise',
                    onPressed: widget.enabled ? widget.onRemove : null,
                    icon: const AppIcon(AppIcons.trash2, size: AppSizes.iconRow),
                  ),
                ],
              ),
            ],
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
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
              child: Semantics(
                header: true,
                child: Text('Swap ${exercise.name}', style: text.headlineSmall?.copyWith(fontSize: 24)),
              ),
            ),
            Flexible(
              child: switch (alternatives) {
                AsyncData(:final value) when value.isEmpty => Padding(
                    padding: const EdgeInsets.fromLTRB(22, AppSpace.sm, 22, AppSpace.xl),
                    child: Text('No alternatives match your answers.', style: text.bodyLarge),
                  ),
                AsyncData(:final value) => ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(AppSpace.md, 0, AppSpace.md, AppSpace.lg),
                    itemCount: value.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpace.sm),
                    itemBuilder: (_, i) {
                      final a = value[i];
                      return SurfaceCard.tile(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: ListRow(
                          icon: AppIcons.dumbbell,
                          title: a.name,
                          titleStyle: text.titleSmall,
                          subtitle: [a.difficulty, ...a.equipment]
                              .whereType<String>()
                              .where((s) => s.isNotEmpty)
                              .map((s) => s[0].toUpperCase() + s.substring(1))
                              .join(' · '),
                          onTap: () => Navigator.pop(context, a),
                        ),
                      );
                    },
                  ),
                AsyncError(:final error) => StateMessage(
                    icon: error is NetworkFailure ? AppIcons.cloudOff : AppIcons.circleAlert,
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
    return Form(
      key: _formKey,
      child: SheetLayout(
        title: 'Save as template',
        body: [
          LabeledField(
            label: 'Template name',
            child: TextFormField(
              controller: _name,
              autofocus: true,
              maxLength: 255,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'Push day'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Give the template a name.' : null,
            ),
          ),
        ],
        actions: [
          FilledButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) Navigator.pop(context, _name.text.trim());
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
