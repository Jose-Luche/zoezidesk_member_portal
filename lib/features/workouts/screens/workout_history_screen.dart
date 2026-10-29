import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/clock.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/state_message.dart';
import '../../../shared/widgets/sync_status.dart';
import '../state/workouts_providers.dart';
import '../widgets/session_tile.dart';

/// Every workout, newest first, as on the web history page. Readable
/// offline; older pages load on demand.
class WorkoutHistoryScreen extends ConsumerStatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  ConsumerState<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends ConsumerState<WorkoutHistoryScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 400) ref.read(workoutHistoryControllerProvider.notifier).loadMore();
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(workoutHistoryControllerProvider.notifier).refresh(),
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workoutHistoryControllerProvider);
    final controller = ref.read(workoutHistoryControllerProvider.notifier);
    final rows = ref.watch(workoutHistoryProvider).value;
    final fetchedAt = ref.watch(workoutHistoryFetchedAtProvider).value;
    final now = ref.watch(clockProvider)();

    final Widget content;
    if (rows == null || (rows.isEmpty && fetchedAt == null && !state.refresh.hasError)) {
      content = const SkeletonList.inline();
    } else if (rows.isEmpty) {
      content = fetchedAt == null && state.refresh.error is NetworkFailure
          ? StateMessage.offline(message: 'Connect to see your past workouts.', onAction: controller.refresh)
          : const StateMessage(
              icon: AppIcons.dumbbell,
              title: 'No workouts yet',
              message: 'Start one from the Workouts tab. Finished workouts appear here.',
            );
    } else {
      content = Column(
        children: [
          for (final s in rows) SessionTile(session: s),
          if (state.loadingMore)
            const SkeletonListTile()
          else if (state.hasMore)
            TextButton(onPressed: controller.loadMore, child: const Text('Load older workouts')),
        ],
      );
    }

    return Scaffold(
      appBar: const AppTopBar(title: 'Workout history'),
      body: RefreshIndicator(
        onRefresh: controller.refresh,
        child: ListView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.sm, AppSpace.gutter, AppSpace.lg),
          children: [
            if (fetchedAt != null) ...[
              SyncStatus(
                fetchedAt: fetchedAt,
                now: now,
                refreshing: state.refresh.isLoading,
                refreshError: state.refresh.error,
                onRetry: controller.refresh,
              ),
              const SizedBox(height: AppSpace.md),
            ],
            content,
          ],
        ),
      ),
    );
  }
}
