import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/clock.dart';
import '../../../data/db/app_database.dart';
import '../../../data/repositories/nutrition_repository.dart';
import '../../../data/repositories/workouts_repository.dart' show SyncState;
import '../../../data/sync/sync.dart';
import '../../../shared/widgets/app_badge.dart';
import '../../../shared/widgets/info_banner.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/state_message.dart';
import '../../../shared/widgets/sync_status.dart';
import '../nutrition_format.dart';
import '../state/nutrition_providers.dart';
import '../widgets/portion_sheet.dart';

/// The food diary for one day, as on the web Nutrition page: totals
/// against the daily goal and what was eaten at each meal. Works offline.
class NutritionScreen extends ConsumerStatefulWidget {
  const NutritionScreen({super.key});

  @override
  ConsumerState<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends ConsumerState<NutritionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(diaryControllerProvider.notifier).refresh();
      ref.read(goalControllerProvider.notifier).refresh();
    });
  }

  Future<void> _edit(DiaryEntry e) async {
    final repo = ref.read(nutritionRepositoryProvider);
    final food = ref.read(foodCatalogueProvider).value?.where((f) => f.id == e.foodId).firstOrNull;
    final result = await showPortionSheet(
      context,
      foodName: e.foodName,
      food: food,
      grams: e.quantityG,
      mealType: e.mealType,
      editing: true,
      entryMacros: Macros(calories: e.calories, protein: e.protein, carbs: e.carbs, fat: e.fat),
    );
    switch (result) {
      case SavePortion(:final grams, :final mealType):
        await repo.update(e, grams: grams, mealType: mealType);
      case DeletePortion():
        await repo.delete(e);
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(diaryControllerProvider);
    final controller = ref.read(diaryControllerProvider.notifier);
    final day = state.day;
    final entries = ref.watch(diaryDayProvider(day));
    final fetchedAt = ref.watch(diaryDayFetchedAtProvider(day)).value;
    final goal = ref.watch(nutritionGoalProvider).value?.data.goal;
    final now = ref.watch(clockProvider)();
    final text = Theme.of(context).textTheme;
    final today = DateTime(now.year, now.month, now.day);
    final dayLabel = day == today
        ? 'Today'
        : day == DateTime(today.year, today.month, today.day - 1)
        ? 'Yesterday'
        : DateFormat('EEE d MMM').format(day);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition'),
        actions: [
          TextButton(onPressed: () => context.push(Routes.nutritionGoal), child: const Text('Daily goal')),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        // The primary action: orange with dark text, as the buttons are.
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        onPressed: () => context.push(Routes.nutritionAdd, extra: (day: day, meal: day == today ? mealForTime(now) : 'lunch')),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add food'),
      ),
      body: RefreshIndicator(
        onRefresh: controller.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.sm, AppSpace.md, AppSpace.xxxl + AppSpace.lg),
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Previous day',
                  onPressed: controller.previousDay,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(child: Text(dayLabel, style: text.titleLarge, textAlign: TextAlign.center)),
                IconButton(
                  tooltip: 'Next day',
                  onPressed: controller.canGoForward ? controller.nextDay : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            if (fetchedAt != null) ...[
              SyncStatus(
                fetchedAt: fetchedAt,
                now: now,
                refreshing: state.refresh.isLoading,
                refreshError: state.refresh.error,
                onRetry: controller.refresh,
              ),
              const SizedBox(height: AppSpace.sm),
            ],
            ...switch (entries) {
              AsyncData(:final value) when value.isEmpty && fetchedAt == null && state.refresh.error is NetworkFailure => [
                  StateMessage.offline(message: 'Connect to see this day. You can still add food.', onAction: controller.refresh),
                ],
              AsyncData(:final value) => [
                  _Totals(total: Macros.sum(value), goal: goal),
                  const SizedBox(height: AppSpace.md),
                  for (final meal in mealTypes)
                    if (value.any((e) => e.mealType == meal) || const {'breakfast', 'lunch', 'dinner'}.contains(meal))
                      _MealSection(
                        meal: meal,
                        entries: value.where((e) => e.mealType == meal).toList(),
                        onAdd: () => context.push(Routes.nutritionAdd, extra: (day: day, meal: meal)),
                        onEdit: _edit,
                        onRetry: (e) => ref.read(nutritionRepositoryProvider).retry(e),
                      ),
                ],
              _ => [const SkeletonList.inline()],
            },
          ],
        ),
      ),
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({required this.total, required this.goal});

  final Macros total;
  final NutritionGoalInfo? goal;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final g = goal;
    final left = g == null ? null : g.calories - total.calories;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: Text(formatKcal(total.calories), style: text.headlineMedium)),
                if (left != null)
                  Text(
                    left >= 0 ? '${formatKcal(left)} left' : '${formatKcal(-left)} over',
                    style: text.bodyMedium?.copyWith(color: left >= 0 ? null : p.warning),
                  ),
              ],
            ),
            if (g == null) ...[
              const SizedBox(height: AppSpace.sm),
              InfoBanner(
                tone: BadgeTone.highlight,
                message: 'Set a daily goal to see how your day adds up.',
                actionLabel: 'Set goal',
                onAction: () => context.push(Routes.nutritionGoal),
              ),
            ] else ...[
              const SizedBox(height: AppSpace.sm),
              _Bar(label: 'Calories', value: total.calories, target: g.calories.toDouble(), unit: 'kcal'),
              _Bar(label: 'Protein', value: total.protein, target: g.protein, unit: 'g'),
              _Bar(label: 'Carbs', value: total.carbs, target: g.carbs, unit: 'g'),
              _Bar(label: 'Fat', value: total.fat, target: g.fat, unit: 'g'),
            ],
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.label, required this.value, required this.target, required this.unit});

  final String label;
  final double value;
  final double target;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final share = target <= 0 ? 0.0 : value / target;
    final n = NumberFormat('#,##0', 'en_KE');
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.sm),
      child: Semantics(
        label: '$label ${n.format(value)} of ${n.format(target)} $unit',
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(label, style: text.bodyMedium)),
                Text('${n.format(value)} / ${n.format(target)} $unit', style: text.bodySmall),
              ],
            ),
            const SizedBox(height: AppSpace.xs),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.control),
              child: LinearProgressIndicator(
                value: share.clamp(0, 1).toDouble(),
                minHeight: AppSpace.sm,
                color: share > 1.05 ? p.warning : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealSection extends StatelessWidget {
  const _MealSection({
    required this.meal,
    required this.entries,
    required this.onAdd,
    required this.onEdit,
    required this.onRetry,
  });

  final String meal;
  final List<DiaryEntry> entries;
  final VoidCallback onAdd;
  final void Function(DiaryEntry) onEdit;
  final void Function(DiaryEntry) onRetry;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final total = Macros.sum(entries);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpace.sm),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.xs, AppSpace.xs, AppSpace.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(mealLabel(meal), style: text.titleMedium)),
                if (entries.isNotEmpty) Text(formatKcal(total.calories), style: text.bodySmall),
                IconButton(tooltip: 'Add to ${mealLabel(meal).toLowerCase()}', onPressed: onAdd, icon: const Icon(Icons.add_rounded)),
              ],
            ),
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.sm),
                child: Text('Nothing logged.', style: text.bodySmall),
              ),
            for (final e in entries)
              ListTile(
                contentPadding: const EdgeInsets.only(right: AppSpace.sm),
                title: Text(e.foodName, style: text.bodyLarge),
                subtitle: e.syncState == SyncState.failed
                    ? Text('Not saved: ${e.syncError ?? 'refused'}', style: text.bodySmall?.copyWith(color: context.palette.danger))
                    : Text('${formatGrams(e.quantityG)} · ${formatKcal(e.calories)}', style: text.bodySmall),
                trailing: switch (e.syncState) {
                  SyncState.failed => TextButton(onPressed: () => onRetry(e), child: const Text('Retry')),
                  SyncState.pending => const AppBadge(label: 'Not sent yet', tone: BadgeTone.warning),
                  _ => null,
                },
                onTap: () => onEdit(e),
              ),
          ],
        ),
      ),
    );
  }
}
