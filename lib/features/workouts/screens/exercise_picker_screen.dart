import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/db/app_database.dart';
import '../../../data/sync/sync.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/state_message.dart';
import '../state/workouts_providers.dart';
import '../widgets/exercise_detail_sheet.dart';
import '../workout_format.dart';

/// The gym's exercise library, searchable offline. Given a session, tapping
/// an exercise adds it to that workout; otherwise it shows how to do it.
class ExercisePickerScreen extends ConsumerStatefulWidget {
  const ExercisePickerScreen({super.key, this.sessionClientId});

  final String? sessionClientId;

  @override
  ConsumerState<ExercisePickerScreen> createState() => _ExercisePickerScreenState();
}

class _ExercisePickerScreenState extends ConsumerState<ExercisePickerScreen> {
  final _search = TextEditingController();
  String? _group;
  bool _groupSet = false;

  bool get _picking => widget.sessionClientId != null;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(libraryRefreshProvider.notifier).refresh());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _pick(LibraryExercise e) async {
    await ref.read(workoutsRepositoryProvider).addExercise(widget.sessionClientId!, e);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    // Start filtered to the workout's focus, as on the web.
    if (_picking && !_groupSet) {
      final focus = ref.watch(workoutSessionProvider(widget.sessionClientId!)).value?.session.muscleGroup;
      if (ref.watch(workoutSessionProvider(widget.sessionClientId!)).hasValue) {
        _group = focus == 'full_body' ? null : focus;
        _groupSet = true;
      }
    }

    final library = ref.watch(exerciseLibraryProvider);
    final refresh = ref.watch(libraryRefreshProvider);
    final query = _search.text.trim().toLowerCase();
    final groups = _group == null ? null : exerciseGroupsFor(_group!);

    return Scaffold(
      appBar: AppBar(title: Text(_picking ? 'Add exercise' : 'Exercise library')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.sm, AppSpace.md, 0),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: 'Search exercises',
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(tooltip: 'Clear', onPressed: _search.clear, icon: const Icon(Icons.close_rounded)),
              ),
            ),
          ),
          SizedBox(
            height: AppSizes.minTouch + AppSpace.md,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm),
              children: [
                _GroupChip(label: 'All', selected: _group == null, onTap: () => setState(() => _group = null)),
                for (final (value, label) in muscleGroups)
                  _GroupChip(label: label, selected: _group == value, onTap: () => setState(() => _group = value)),
              ],
            ),
          ),
          Expanded(
            child: switch (library) {
              AsyncData(:final value) when value.isEmpty => refresh.isLoading
                  ? const SkeletonList()
                  : refresh.error is NetworkFailure
                  ? StateMessage.offline(
                      message: 'Connect once to save the exercise library on this phone.',
                      onAction: ref.read(libraryRefreshProvider.notifier).refresh,
                    )
                  : const StateMessage(
                      icon: Icons.fitness_center_rounded,
                      title: 'No exercises yet',
                      message: 'Your gym has not added exercises.',
                    ),
              AsyncData(:final value) => _list(
                  value
                      .where((e) => groups == null || groups.contains(e.muscleGroup))
                      .where((e) => query.isEmpty || e.name.toLowerCase().contains(query))
                      .toList(),
                ),
              _ => const SkeletonList(),
            },
          ),
        ],
      ),
    );
  }

  Widget _list(List<LibraryExercise> rows) {
    if (rows.isEmpty) {
      return const StateMessage(
        icon: Icons.search_off_rounded,
        title: 'No matches',
        message: 'Try another name or muscle group.',
      );
    }
    final text = Theme.of(context).textTheme;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(AppSpace.md, 0, AppSpace.md, AppSpace.lg),
      itemCount: rows.length,
      itemBuilder: (_, i) {
        final e = rows[i];
        final subtitle = [muscleLabel(e.muscleGroup), ...equipmentOf(e)].join(' · ');
        return Card(
          margin: const EdgeInsets.only(bottom: AppSpace.sm),
          child: ListTile(
            title: Text(e.name, style: text.titleSmall),
            subtitle: Text(subtitle, style: text.bodySmall),
            onTap: () => _picking ? _pick(e) : showExerciseDetail(context, e),
            trailing: _picking
                ? IconButton(
                    tooltip: 'How to do it',
                    icon: const Icon(Icons.info_outline_rounded),
                    onPressed: () => showExerciseDetail(context, e),
                  )
                : const Icon(Icons.chevron_right_rounded),
          ),
        );
      },
    );
  }
}

class _GroupChip extends StatelessWidget {
  const _GroupChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: AppSpace.sm),
        child: ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onTap()),
      );
}
