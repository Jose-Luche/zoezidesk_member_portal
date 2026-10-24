import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/db/app_database.dart';
import '../../../data/repositories/workouts_repository.dart';
import '../../../shared/widgets/app_badge.dart';
import '../workout_format.dart';

List<String> equipmentOf(LibraryExercise e) {
  try {
    return [for (final x in jsonDecode(e.equipment) as List) _titleCase('$x')];
  } on FormatException {
    return const [];
  }
}

String _titleCase(String s) =>
    s.isEmpty ? s : s.replaceAll('_', ' ').replaceFirst(s[0], s[0].toUpperCase());

/// How to do an exercise, and what the member did last time.
Future<void> showExerciseDetail(BuildContext context, LibraryExercise exercise) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (context, scroll) => _ExerciseDetail(exercise: exercise, scroll: scroll),
      ),
    );

class _ExerciseDetail extends StatelessWidget {
  const _ExerciseDetail({required this.exercise, required this.scroll});

  final LibraryExercise exercise;
  final ScrollController scroll;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final last = LastTime.of(exercise);
    final steps = (exercise.instructions ?? '')
        .split(RegExp(r'\n+|(?<=\.)\s+(?=\d+\.)'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return ListView(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(AppSpace.md, 0, AppSpace.md, AppSpace.lg),
      children: [
        Text(exercise.name, style: text.headlineSmall),
        const SizedBox(height: AppSpace.sm),
        Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: [
            AppBadge(label: muscleLabel(exercise.muscleGroup), tone: BadgeTone.highlight),
            for (final e in equipmentOf(exercise)) AppBadge(label: e, tone: BadgeTone.neutral),
            if (exercise.difficulty != null) AppBadge(label: _titleCase(exercise.difficulty!), tone: BadgeTone.neutral),
          ],
        ),
        if (exercise.imageUrl != null) ...[
          const SizedBox(height: AppSpace.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: CachedNetworkImage(
              imageUrl: exercise.imageUrl!,
              height: 200,
              fit: BoxFit.cover,
              fadeInDuration: AppMotion.fast,
              errorWidget: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ],
        if (last != null) ...[
          const SizedBox(height: AppSpace.md),
          Text('Last time · ${formatDate(last.date)}', style: text.titleSmall),
          const SizedBox(height: AppSpace.xs),
          Text(last.sets.map(formatSet).join('\n'), style: text.bodyMedium),
        ],
        const SizedBox(height: AppSpace.md),
        Text('How to do it', style: text.titleSmall),
        const SizedBox(height: AppSpace.xs),
        if (steps.isEmpty)
          Text('No instructions yet. Ask a trainer at the gym.', style: text.bodyMedium)
        else
          for (final s in steps)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.xs),
              child: Text(s, style: text.bodyMedium),
            ),
      ],
    );
  }
}
