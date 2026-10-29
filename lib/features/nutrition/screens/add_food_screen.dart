import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/db/app_database.dart';
import '../../../data/sync/sync.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/state_message.dart';
import '../../../shared/widgets/surfaces.dart';
import '../nutrition_format.dart';
import '../state/nutrition_providers.dart';
import '../widgets/portion_sheet.dart';

/// Pick a food (by English or Swahili name) and how much, for a day and
/// meal. Works offline once the list is saved.
class AddFoodScreen extends ConsumerStatefulWidget {
  const AddFoodScreen({super.key, required this.day, required this.meal});

  final DateTime day;
  final String meal;

  @override
  ConsumerState<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends ConsumerState<AddFoodScreen> {
  final _search = TextEditingController();
  String? _category;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _pick(FoodItem food) async {
    final result = await showPortionSheet(
      context,
      foodName: food.name,
      food: food,
      grams: food.defaultServingG,
      mealType: widget.meal,
    );
    if (result is! SavePortion || !mounted) return;
    await ref.read(nutritionRepositoryProvider).add(food, grams: result.grams, mealType: result.mealType, day: widget.day);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${food.name} added to ${mealLabel(result.mealType).toLowerCase()}.')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final foods = ref.watch(foodCatalogueProvider);
    final query = _search.text.trim().toLowerCase();
    final text = Theme.of(context).textTheme;
    final categories = {for (final f in foods.value ?? const <FoodItem>[]) f.category}.toList()..sort();

    return Scaffold(
      appBar: const AppTopBar(title: 'Add food'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 0, AppSpace.gutter, 0),
            child: TextField(
              controller: _search,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                prefixIcon: const FieldIcon(AppIcons.search),
                hintText: 'Search foods, e.g. ugali or sukuma',
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(tooltip: 'Clear', onPressed: _search.clear, icon: const AppIcon(AppIcons.x)),
              ),
            ),
          ),
          if (categories.length > 1)
            SizedBox(
              height: AppSizes.minTouch + AppSpace.lg,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter, vertical: 12),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpace.sm),
                    child: ChoiceChip(label: const Text('All'), selected: _category == null, onSelected: (_) => setState(() => _category = null)),
                  ),
                  for (final c in categories)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpace.sm),
                      child: ChoiceChip(
                        label: Text(categoryLabel(c)),
                        selected: _category == c,
                        onSelected: (_) => setState(() => _category = c),
                      ),
                    ),
                ],
              ),
            ),
          Expanded(
            child: switch (foods) {
              AsyncData(:final value) when value.isEmpty => const StateMessage(
                  icon: AppIcons.utensils,
                  title: 'Food list not saved yet',
                  message: 'Open Nutrition once with an internet connection to save the food list.',
                ),
              AsyncData(:final value) => _list(
                  value
                      .where((f) => _category == null || f.category == _category)
                      .where((f) =>
                          query.isEmpty ||
                          f.name.toLowerCase().contains(query) ||
                          (f.nameSwahili?.toLowerCase().contains(query) ?? false))
                      .toList(),
                  text,
                ),
              _ => const SkeletonList(),
            },
          ),
        ],
      ),
    );
  }

  Widget _list(List<FoodItem> rows, TextTheme text) {
    if (rows.isEmpty) {
      return const StateMessage(
        icon: AppIcons.searchX,
        title: 'No matches',
        message: 'Try another name, in English or Swahili.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.xs, AppSpace.gutter, AppSpace.lg),
      itemCount: rows.length,
      itemBuilder: (_, i) {
        final f = rows[i];
        final swahili = f.nameSwahili != null && f.nameSwahili!.toLowerCase() != f.name.toLowerCase() ? ' (${f.nameSwahili})' : '';
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpace.sm),
          child: SurfaceCard.tile(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: ListRow(
              title: '${f.name}$swahili',
              titleStyle: text.titleSmall,
              subtitle: '${formatKcal(f.caloriesPer100g)} per 100 g · ${f.servingDescription ?? '1 serving = ${formatGrams(f.defaultServingG)}'}',
              trailing: AppIcon(AppIcons.plus, size: AppSizes.iconRow, color: context.palette.accentText),
              onTap: () => _pick(f),
            ),
          ),
        );
      },
    );
  }
}
