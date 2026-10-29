import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/db/app_database.dart';
import '../../../data/repositories/workouts_repository.dart';
import '../../../shared/widgets/app_badge.dart';
import '../../../shared/widgets/surfaces.dart';
import '../workout_format.dart';

/// One workout in a list: date, name, totals, and whether it is saved.
class SessionTile extends StatelessWidget {
  const SessionTile({super.key, required this.session});

  final WorkoutSessionRow session;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final s = session;
    final details = [
      if (s.durationMinutes != null) formatDuration(s.durationMinutes!),
      '${s.totalSets} set${s.totalSets == 1 ? '' : 's'}',
      if (s.totalVolume > 0) formatKg(s.totalVolume),
    ].join(' · ');
    final badge = switch (s) {
      _ when s.syncState == SyncState.failed =>
        const AppBadge(label: 'Not saved', tone: BadgeTone.danger, icon: AppIcons.circleAlert),
      _ when s.syncState == SyncState.pending =>
        const AppBadge(label: 'Not sent yet', tone: BadgeTone.warning, icon: AppIcons.cloudUpload),
      _ when s.status == 'in_progress' =>
        const AppBadge(label: 'In progress', tone: BadgeTone.highlight, icon: AppIcons.clock),
      _ when s.rating != null => AppBadge(label: ratingLabel(s.rating), tone: BadgeTone.neutral),
      _ => null,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: SurfaceCard.tile(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: ListRow(
          icon: AppIcons.dumbbell,
          iconColor: context.palette.rowIcon,
          onTap: () => context.push(Routes.workoutSession(s.clientId)),
          title: s.dayType,
          titleStyle: text.titleSmall,
          subtitle: '${DateFormat('EEE d MMM').format(s.sessionDate)} · $details',
          trailing: badge,
        ),
      ),
    );
  }
}
