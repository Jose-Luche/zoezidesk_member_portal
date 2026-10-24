import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../data/db/app_database.dart';
import '../../../data/sync/sync.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/state_message.dart';
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
      appBar: AppBar(title: const Text('Add food')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.sm, AppSpace.md, 0),
            child: TextField(
              controller: _search,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: 'Search foods, e.g. ugali or sukuma',
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(tooltip: 'Clear', onPressed: _search.clear, icon: const Icon(Icons.close_rounded)),
              ),
            ),
          ),
          if (categories.length > 1)
            SizedBox(
              height: AppSizes.minTouch + AppSpace.md,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm),
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
                  icon: Icons.restaurant_rounded,
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
        icon: Icons.search_off_rounded,
        title: 'No matches',
        message: 'Try another name, in English or Swahili.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(AppSpace.md, 0, AppSpace.md, AppSpace.lg),
      itemCount: rows.length,
      itemBuilder: (_, i) {
        final f = rows[i];
        final swahili = f.nameSwahili != null && f.nameSwahili!.toLowerCase() != f.name.toLowerCase() ? ' (${f.nameSwahili})' : '';
        return Card(
          margin: const EdgeInsets.only(bottom: AppSpace.sm),
          child: ListTile(
            title: Text('${f.name}$swahili', style: text.titleSmall),
            subtitle: Text(
              '${formatKcal(f.caloriesPer100g)} per 100 g · ${f.servingDescription ?? '1 serving = ${formatGrams(f.defaultServingG)}'}',
              style: text.bodySmall,
            ),
            trailing: const Icon(Icons.add_rounded),
            onTap: () => _pick(f),
          ),
        );
      },
    );
  }
}
