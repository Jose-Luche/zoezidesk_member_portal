import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/db/app_database.dart';
import '../../../data/repositories/workouts_repository.dart';
import '../../../data/sync/sync.dart';
import '../../../shared/widgets/app_badge.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/info_banner.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/state_message.dart';
import '../../../shared/widgets/surfaces.dart';
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
    final result = await showAppSheet<({String? rating, String notes})>(
      context,
      builder: (_) => _FinishSheet(setCount: d.exercises.expand((e) => e.sets).length),
    );
    if (result == null) return;
    await _repo.finish(widget.clientId, rating: result.rating, notes: result.notes);
    await HapticFeedback.mediumImpact();
  }

  Future<void> _discard() async {
    final ok = await showAppSheet<bool>(
      context,
      builder: (sheet) => SheetLayout(
        title: 'Discard this workout?',
        body: const [
          InfoBanner(
            tone: BadgeTone.danger,
            message: 'Its exercises and sets are deleted. This cannot be undone.',
          ),
        ],
        actions: [
          FilledButton(onPressed: () => Navigator.pop(sheet, true), child: const Text('Discard')),
          OutlinedButton(onPressed: () => Navigator.pop(sheet, false), child: const Text('Keep it')),
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
        content: Text('New personal record. ${pr.exerciseName}: ${recordLabel(pr.metricType, pr.value, pr.repCount)}'),
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
      appBar: AppTopBar(
        title: d?.session.dayType ?? 'Workout',
        actions: [
          if (d != null && d.isActive)
            PopupMenuButton<String>(
              tooltip: 'Workout options',
              icon: const AppIcon(AppIcons.ellipsisVertical),
              onSelected: (v) => v == 'discard' ? _discard() : null,
              itemBuilder: (_) => const [PopupMenuItem(value: 'discard', child: Text('Discard workout'))],
            ),
        ],
      ),
      body: switch (detail) {
        AsyncData(value: null) => const StateMessage(
            icon: AppIcons.dumbbell,
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
      padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.sm, AppSpace.gutter, AppSpace.lg),
      children: [
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppIcon(AppIcons.clock, size: AppSizes.iconRow, color: context.palette.accentText),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Text(
                      d.isActive
                          ? 'Started ${DateFormat('h:mm a').format(s.startedAt)}'
                              '${minutes != null ? ' · ${formatDuration(minutes)}' : ''}'
                          : '${DateFormat('EEEE d MMMM').format(s.sessionDate)}'
                              '${minutes != null ? ' · ${formatDuration(minutes)}' : ''}',
                      style: text.titleSmall?.copyWith(color: context.palette.accentText),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.sm,
                children: [
                  AppBadge(label: plural(d.exercises.length, 'exercise'), tone: BadgeTone.neutral),
                  AppBadge(label: plural(sets.length, 'set'), tone: BadgeTone.neutral),
                  if (volume > 0) AppBadge(label: formatKg(volume), tone: BadgeTone.neutral),
                  if (d.prCount > 0)
                    AppBadge(label: plural(d.prCount, 'PR'), tone: BadgeTone.highlight, icon: AppIcons.trophy),
                  if (!d.isActive && s.rating != null) AppBadge(label: ratingLabel(s.rating), tone: BadgeTone.success),
                ],
              ),
              const SizedBox(height: 12),
              _SyncLine(session: s, onRetry: () => _repo.retrySync(widget.clientId)),
            ],
          ),
        ),
        if (!d.isActive && s.status == 'completed' && s.syncState != SyncState.failed) ...[
          const SizedBox(height: AppSpace.sm),
          const InfoBanner(tone: BadgeTone.success, icon: AppIcons.circleCheck, message: 'Workout complete. Well done.'),
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
            icon: AppIcons.dumbbell,
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
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(AppSizes.sheetButton)),
            onPressed: () => context.push(Routes.exercises, extra: widget.clientId),
            icon: const AppIcon(AppIcons.plus),
            label: const Text('Add exercise'),
          ),
          const SizedBox(height: AppSpace.sm),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(AppSizes.sheetButton)),
            onPressed: () => _finish(d),
            child: const Text('Finish workout'),
          ),
        ] else if (d.exercises.isNotEmpty)
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(AppSizes.sheetButton)),
            onPressed: () => _repeat(d),
            icon: const AppIcon(AppIcons.rotateCcw),
            label: const Text('Repeat this workout'),
          ),
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
          const AppBadge(label: 'Not sent yet', tone: BadgeTone.warning, icon: AppIcons.cloudUpload),
          const SizedBox(width: AppSpace.sm),
          Expanded(child: Text('Saved on this phone. Sends to your account when online.', style: text.bodySmall)),
        ]),
      _ => Row(children: [
          AppIcon(AppIcons.circleCheck, size: AppSizes.iconBadge, color: p.rowIcon),
          const SizedBox(width: 6),
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

    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: SurfaceCard(
        padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.xs, AppSpace.xs, AppSpace.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(e.name, style: text.titleMedium)),
                PopupMenuButton<String>(
                  tooltip: 'Exercise options',
                  icon: const AppIcon(AppIcons.ellipsisVertical),
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
                padding: const EdgeInsets.only(right: AppSpace.md, bottom: AppSpace.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: AppIcon(AppIcons.history, size: AppSizes.iconBadge, color: p.textMuted),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Last time (${formatDate(lastTime!.date)}): ${lastTime!.sets.map(formatSet).join(', ')}',
                        style: text.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            for (final set in entry.sets)
              Padding(
                padding: const EdgeInsets.only(right: 14, bottom: 6),
                child: Material(
                  // An inset pill; dark mode insets go darker, not lighter.
                  color: Theme.of(context).brightness == Brightness.dark ? p.background : p.surfaceHigh,
                  shape: const StadiumBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: editable ? () => onEditSet(set) : null,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: AppSizes.minTouch),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
                        child: Row(
                          children: [
                            SizedBox(width: 52, child: Text('Set ${set.setNumber}', style: text.bodySmall?.copyWith(color: p.text))),
                            Expanded(child: Text(formatSet(SetValues.fromRow(set)), style: text.titleSmall)),
                            if (set.prTypes.isNotEmpty)
                              const Padding(
                                padding: EdgeInsets.only(left: AppSpace.sm),
                                child: AppBadge(label: 'PR', tone: BadgeTone.highlight, icon: AppIcons.trophy),
                              ),
                            if (editable)
                              Padding(
                                padding: const EdgeInsets.only(left: AppSpace.sm),
                                child: AppIcon(AppIcons.pencil, size: AppSizes.iconBadge, color: p.text),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (entry.sets.isEmpty && !editable)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.sm),
                child: Text('No sets logged.', style: text.bodySmall),
              ),
            if (editable)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: TextButton.icon(
                    style: TextButton.styleFrom(padding: const EdgeInsets.only(left: 6, right: 12)),
                    onPressed: onAddSet,
                    icon: const AppIcon(AppIcons.plus),
                    label: Text(entry.sets.isEmpty ? 'Log first set' : 'Add set'),
                  ),
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
    return SheetLayout(
      title: 'Finish workout',
      body: [
        if (widget.setCount == 0) ...[
          const InfoBanner(tone: BadgeTone.warning, message: 'No sets logged yet. You can still finish.'),
          const SizedBox(height: AppSpace.md),
        ],
        LabeledField(
          label: 'How did it go?',
          child: Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              for (final r in const ['great', 'good', 'okay', 'tough'])
                ChoiceChip(
                  label: Text(ratingLabel(r)),
                  selected: _rating == r,
                  onSelected: (on) => setState(() => _rating = on ? r : null),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.md),
        LabeledField(
          label: 'Notes (optional)',
          child: TextField(
            controller: _notes,
            maxLength: 1000,
            maxLines: 3,
            minLines: 1,
            textCapitalization: TextCapitalization.sentences,
          ),
        ),
      ],
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop((rating: _rating, notes: _notes.text)),
          child: const Text('Finish workout'),
        ),
      ],
    );
  }
}
