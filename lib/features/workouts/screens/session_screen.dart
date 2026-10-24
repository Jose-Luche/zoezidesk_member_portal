import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/db/app_database.dart';
import '../../../data/repositories/workouts_repository.dart';
import '../../../data/sync/sync.dart';
import '../../../shared/widgets/app_badge.dart';
import '../../../shared/widgets/info_banner.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/state_message.dart';
import '../state/workouts_providers.dart';
import '../widgets/exercise_detail_sheet.dart';
import '../widgets/set_sheet.dart';
import '../workout_format.dart';

/// One workout. While it is in progress the member logs sets here, online
/// or not; afterwards it is a read-only summary that can be repeated.
class SessionScreen extends ConsumerStatefulWidget {
  const SessionScreen({super.key, required this.clientId});

  final String clientId;

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  Timer? _tick;
  bool _detailRequested = false;

  @override
  void initState() {
    super.initState();
    // The elapsed time shown in minutes; no animation.
    _tick = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  WorkoutsRepository get _repo => ref.read(workoutsRepositoryProvider);

  Future<void> _loadDetail() =>
      ref.read(sessionDetailRefreshProvider(widget.clientId).notifier).refresh();

  Future<void> _addSet(ExerciseWithSets e, Map<int, LastTime> lastTimes) async {
    final previous = e.sets.isNotEmpty
        ? SetValues.fromRow(e.sets.last)
        : lastTimes[e.exercise.exerciseId]?.sets.firstOrNull;
    final result = await showSetSheet(
      context,
      exerciseName: e.exercise.name,
      setNumber: e.sets.length + 1,
      cardio: isCardio(e.exercise.muscleGroup),
      initial: previous == null ? null : SetValues(
        weight: previous.weight,
        reps: previous.reps,
        durationMinutes: previous.durationMinutes,
        distanceKm: previous.distanceKm,
      ),
    );
    if (result is SaveSet) await _repo.addSet(e.exercise.clientId, result.values);
  }

  Future<void> _editSet(ExerciseWithSets e, WorkoutSetRow set) async {
    final result = await showSetSheet(
      context,
      exerciseName: e.exercise.name,
      setNumber: set.setNumber,
      cardio: isCardio(e.exercise.muscleGroup),
      initial: SetValues.fromRow(set),
      editing: true,
    );
    switch (result) {
      case SaveSet(:final values):
        await _repo.updateSet(set.clientId, values);
      case DeleteSet():
        await _repo.deleteSet(set.clientId);
      case null:
        break;
    }
  }

  Future<void> _finish(SessionDetail d) async {
    final result = await showModalBottomSheet<({String? rating, String notes})>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (_) => _FinishSheet(setCount: d.exercises.expand((e) => e.sets).length),
    );
    if (result == null) return;
    await _repo.finish(widget.clientId, rating: result.rating, notes: result.notes);
    await HapticFeedback.mediumImpact();
  }

  Future<void> _discard() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard this workout?'),
        content: const Text('Its exercises and sets are deleted. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep it')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: context.palette.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _repo.discard(widget.clientId);
    if (mounted) context.pop();
  }

  Future<void> _repeat(SessionDetail d) async {
    final active = await _repo.active();
    if (!mounted) return;
    if (active != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Finish or discard the workout in progress first.')),
      );
      return;
    }
    final id = await _repo.start(
      dayType: d.session.dayType,
      muscleGroup: d.session.muscleGroup,
      copyFrom: widget.clientId,
    );
    if (mounted) context.pushReplacement(Routes.workoutSession(id));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(newPrProvider, (_, next) {
      final pr = next.value;
      if (pr == null || pr.sessionClientId != widget.clientId) return;
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('New personal record! ${pr.exerciseName}: ${recordLabel(pr.metricType, pr.value, pr.repCount)}'),
      ));
    });

    final detail = ref.watch(workoutSessionProvider(widget.clientId));
    final loading = ref.watch(sessionDetailRefreshProvider(widget.clientId));
    final library = ref.watch(exerciseLibraryProvider).value ?? const [];
    final lastTimes = {
      for (final e in library)
        e.id: ?LastTime.of(e),
    };

    final d = detail.value;
    // A workout from history comes without its sets: fetch them once.
    if (d != null && !d.session.detailLoaded && !_detailRequested) {
      _detailRequested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadDetail());
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(d?.session.dayType ?? 'Workout'),
        actions: [
          if (d != null && d.isActive)
            PopupMenuButton<String>(
              tooltip: 'Workout options',
              onSelected: (v) => v == 'discard' ? _discard() : null,
              itemBuilder: (_) => const [PopupMenuItem(value: 'discard', child: Text('Discard workout'))],
            ),
        ],
      ),
      body: switch (detail) {
        AsyncData(value: null) => const StateMessage(
            icon: Icons.fitness_center_rounded,
            title: 'Workout not found',
            message: 'It may have been discarded.',
          ),
        AsyncData(value: final d?) => _body(context, d, lastTimes, loading),
        _ => const SkeletonList(),
      },
    );
  }

  Widget _body(BuildContext context, SessionDetail d, Map<int, LastTime> lastTimes, AsyncValue<void> loading) {
    final s = d.session;
    final text = Theme.of(context).textTheme;
    final now = ref.watch(clockProvider)();
    final minutes = s.durationMinutes ?? (d.isActive ? now.difference(s.startedAt).inMinutes : null);
    final sets = d.exercises.expand((e) => e.sets).toList();
    final volume = sets.fold(0.0, (sum, x) => sum + SetValues.fromRow(x).volume);

    return ListView(
      padding: const EdgeInsets.all(AppSpace.md),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.isActive
                      ? 'Started ${DateFormat('h:mm a').format(s.startedAt)}'
                          '${minutes != null ? ' · ${formatDuration(minutes)}' : ''}'
                      : '${DateFormat('EEEE d MMMM').format(s.sessionDate)}'
                          '${minutes != null ? ' · ${formatDuration(minutes)}' : ''}',
                  style: text.titleSmall,
                ),
                const SizedBox(height: AppSpace.sm),
                Wrap(
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.sm,
                  children: [
                    AppBadge(label: plural(d.exercises.length, 'exercise'), tone: BadgeTone.neutral),
                    AppBadge(label: plural(sets.length, 'set'), tone: BadgeTone.neutral),
                    if (volume > 0) AppBadge(label: formatKg(volume), tone: BadgeTone.neutral),
                    if (d.prCount > 0)
                      AppBadge(label: plural(d.prCount, 'PR'), tone: BadgeTone.highlight,
                          icon: Icons.emoji_events_rounded),
                    if (!d.isActive && s.rating != null) AppBadge(label: ratingLabel(s.rating), tone: BadgeTone.success),
                  ],
                ),
                const SizedBox(height: AppSpace.sm),
                _SyncLine(session: s, onRetry: () => _repo.retrySync(widget.clientId)),
              ],
            ),
          ),
        ),
        if (!d.isActive && s.status == 'completed' && s.syncState != SyncState.failed) ...[
          const SizedBox(height: AppSpace.sm),
          const InfoBanner(tone: BadgeTone.success, icon: Icons.check_circle_rounded, message: 'Workout complete. Nice work!'),
        ],
        if (s.notes != null && s.notes!.isNotEmpty && !d.isActive) ...[
          const SizedBox(height: AppSpace.sm),
          Text(s.notes!, style: text.bodyMedium),
        ],
        const SizedBox(height: AppSpace.md),
        if (!s.detailLoaded && d.exercises.isEmpty)
          loading.hasError
              ? (loading.error is NetworkFailure
                  ? StateMessage.offline(message: 'Connect to see this workout\'s sets.', onAction: _loadDetail)
                  : StateMessage.error(onAction: _loadDetail))
              : const SkeletonList.inline()
        else if (d.exercises.isEmpty && d.isActive)
          const StateMessage(
            icon: Icons.fitness_center_rounded,
            title: 'Add your first exercise',
            message: 'Pick from the gym\'s exercise library. You can log sets offline.',
          ),
        for (final e in d.exercises)
          _ExerciseCard(
            entry: e,
            editable: d.isActive,
            lastTime: lastTimes[e.exercise.exerciseId],
            onAddSet: () => _addSet(e, lastTimes),
            onEditSet: (set) => _editSet(e, set),
            onRemove: () => _repo.removeExercise(e.exercise.clientId),
            onAbout: () {
              final lib = ref.read(exerciseLibraryProvider).value?.where((x) => x.id == e.exercise.exerciseId).firstOrNull;
              if (lib != null) showExerciseDetail(context, lib);
            },
          ),
        const SizedBox(height: AppSpace.sm),
        if (d.isActive) ...[
          OutlinedButton.icon(
            onPressed: () => context.push(Routes.exercises, extra: widget.clientId),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add exercise'),
          ),
          const SizedBox(height: AppSpace.md),
          FilledButton(onPressed: () => _finish(d), child: const Text('Finish workout')),
        ] else if (d.exercises.isNotEmpty)
          FilledButton.icon(
            onPressed: () => _repeat(d),
            icon: const Icon(Icons.replay_rounded),
            label: const Text('Repeat this workout'),
          ),
        const SizedBox(height: AppSpace.lg),
      ],
    );
  }
}

class _SyncLine extends StatelessWidget {
  const _SyncLine({required this.session, required this.onRetry});

  final WorkoutSessionRow session;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    return switch (session.syncState) {
      SyncState.failed => InfoBanner(
          tone: BadgeTone.danger,
          message: 'Not saved to your account: ${session.syncError ?? 'the server refused it.'}',
          actionLabel: 'Retry',
          onAction: onRetry,
        ),
      SyncState.pending => Row(children: [
          Icon(Icons.cloud_upload_outlined, size: AppSpace.md, color: p.textMuted),
          const SizedBox(width: AppSpace.xs),
          Expanded(child: Text('Saved on this phone. Sends to your account when online.', style: text.bodySmall)),
        ]),
      _ => Row(children: [
          Icon(Icons.cloud_done_outlined, size: AppSpace.md, color: p.textMuted),
          const SizedBox(width: AppSpace.xs),
          Text('Saved to your account', style: text.bodySmall),
        ]),
    };
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.entry,
    required this.editable,
    required this.onAddSet,
    required this.onEditSet,
    required this.onRemove,
    required this.onAbout,
    this.lastTime,
  });

  final ExerciseWithSets entry;
  final bool editable;
  final LastTime? lastTime;
  final VoidCallback onAddSet;
  final void Function(WorkoutSetRow) onEditSet;
  final VoidCallback onRemove;
  final VoidCallback onAbout;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final e = entry.exercise;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpace.sm),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.sm, AppSpace.xs, AppSpace.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(e.name, style: text.titleMedium)),
                PopupMenuButton<String>(
                  tooltip: 'Exercise options',
                  onSelected: (v) => v == 'remove' ? onRemove() : onAbout(),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'about', child: Text('How to do it')),
                    if (editable) const PopupMenuItem(value: 'remove', child: Text('Remove exercise')),
                  ],
                ),
              ],
            ),
            if (editable && lastTime != null)
              Padding(
                padding: const EdgeInsets.only(right: AppSpace.sm, bottom: AppSpace.xs),
                child: Text(
                  'Last time (${formatDate(lastTime!.date)}): ${lastTime!.sets.map(formatSet).join(', ')}',
                  style: text.bodySmall,
                ),
              ),
            for (final set in entry.sets)
              InkWell(
                onTap: editable ? () => onEditSet(set) : null,
                borderRadius: BorderRadius.circular(AppRadius.control),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: AppSizes.minTouch),
                  child: Row(
                    children: [
                      SizedBox(width: 56, child: Text('Set ${set.setNumber}', style: text.bodySmall)),
                      Expanded(child: Text(formatSet(SetValues.fromRow(set)), style: text.bodyLarge)),
                      if (set.prTypes.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.only(right: AppSpace.sm),
                          child: AppBadge(label: 'PR', tone: BadgeTone.highlight, icon: Icons.emoji_events_rounded),
                        ),
                      if (editable)
                        const Padding(
                          padding: EdgeInsets.only(right: AppSpace.sm),
                          child: Icon(Icons.edit_outlined, size: AppSpace.md),
                        ),
                    ],
                  ),
                ),
              ),
            if (entry.sets.isEmpty && !editable)
              Text('No sets logged.', style: text.bodySmall),
            if (editable)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onAddSet,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(entry.sets.isEmpty ? 'Log first set' : 'Add set'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FinishSheet extends StatefulWidget {
  const _FinishSheet({required this.setCount});

  final int setCount;

  @override
  State<_FinishSheet> createState() => _FinishSheetState();
}

class _FinishSheetState extends State<_FinishSheet> {
  String? _rating;
  final _notes = TextEditingController();

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpace.md, 0, AppSpace.md, AppSpace.md + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Finish workout', style: text.titleLarge),
            if (widget.setCount == 0) ...[
              const SizedBox(height: AppSpace.sm),
              const InfoBanner(tone: BadgeTone.warning, message: 'No sets logged yet. You can still finish.'),
            ],
            const SizedBox(height: AppSpace.md),
            Text('How did it go?', style: text.titleSmall),
            const SizedBox(height: AppSpace.sm),
            Wrap(
              spacing: AppSpace.sm,
              children: [
                for (final r in const ['great', 'good', 'okay', 'tough'])
                  ChoiceChip(
                    label: Text(ratingLabel(r)),
                    selected: _rating == r,
                    onSelected: (on) => setState(() => _rating = on ? r : null),
                  ),
              ],
            ),
            const SizedBox(height: AppSpace.md),
            TextField(
              controller: _notes,
              maxLength: 1000,
              maxLines: 3,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
            const SizedBox(height: AppSpace.sm),
            FilledButton(
              onPressed: () => Navigator.of(context).pop((rating: _rating, notes: _notes.text)),
              child: const Text('Finish workout'),
            ),
          ],
        ),
      ),
    );
  }
}
