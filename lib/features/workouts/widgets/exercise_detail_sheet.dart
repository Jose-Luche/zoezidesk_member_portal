import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/db/app_database.dart';
import '../../../data/repositories/workouts_repository.dart';
import '../../../shared/widgets/app_badge.dart';
import '../../../shared/widgets/surfaces.dart';
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

    final p = context.palette;
    return ListView(
      controller: scroll,
      padding: EdgeInsets.fromLTRB(22, 0, 22, AppSpace.xl + MediaQuery.viewPaddingOf(context).bottom),
      children: [
        Semantics(header: true, child: Text(exercise.name, style: text.headlineSmall?.copyWith(fontSize: 24))),
        const SizedBox(height: 12),
        Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: [
            AppBadge(label: muscleLabel(exercise.muscleGroup), tone: BadgeTone.highlight, icon: AppIcons.dumbbell),
            for (final e in equipmentOf(exercise)) AppBadge(label: e, tone: BadgeTone.neutral),
            if (exercise.difficulty != null) AppBadge(label: _titleCase(exercise.difficulty!), tone: BadgeTone.neutral),
          ],
        ),
        if (exercise.imageUrl != null) ...[
          const SizedBox(height: AppSpace.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.tile),
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
          SurfaceCard.tile(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppIcon(AppIcons.history, size: AppSizes.iconRow, color: p.accentText),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(child: Text('Last time · ${formatDate(last.date)}', style: text.titleSmall)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(last.sets.map(formatSet).join('\n'), style: text.bodyLarge),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpace.lg),
        Text('How to do it', style: text.titleLarge),
        const SizedBox(height: AppSpace.sm),
        if (steps.isEmpty)
          Text('No instructions yet. Ask a trainer at the gym.', style: text.bodyLarge)
        else
          for (final s in steps)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.sm),
              child: Text(s, style: text.bodyLarge),
            ),
      ],
    );
  }
}
