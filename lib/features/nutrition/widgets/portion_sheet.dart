import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/db/app_database.dart';
import '../../../data/repositories/nutrition_repository.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/surfaces.dart';
import '../nutrition_format.dart';

sealed class PortionResult {
  const PortionResult();
}

class SavePortion extends PortionResult {
  const SavePortion(this.grams, this.mealType);

  final double grams;
  final String mealType;
}

class DeletePortion extends PortionResult {
  const DeletePortion();
}

/// How much was eaten, and at which meal, with the macros shown as you
/// type. [food] may be null when editing an entry whose food left the list.
Future<PortionResult?> showPortionSheet(
  BuildContext context, {
  required String foodName,
  required FoodItem? food,
  required double grams,
  required String mealType,
  bool editing = false,
  Macros? entryMacros,
}) =>
    showAppSheet<PortionResult>(
      context,
      builder: (_) => _PortionSheet(
        foodName: foodName,
        food: food,
        grams: grams,
        mealType: mealType,
        editing: editing,
        entryMacros: entryMacros,
        entryGrams: grams,
      ),
    );

class _PortionSheet extends StatefulWidget {
  const _PortionSheet({
    required this.foodName,
    required this.food,
    required this.grams,
    required this.mealType,
    required this.editing,
    required this.entryGrams,
    this.entryMacros,
  });

  final String foodName;
  final FoodItem? food;
  final double grams;
  final String mealType;
  final bool editing;
  final double entryGrams;
  final Macros? entryMacros;

  @override
  State<_PortionSheet> createState() => _PortionSheetState();
}

class _PortionSheetState extends State<_PortionSheet> {
  static final _fmt = NumberFormat('0.#');
  late final _grams = TextEditingController(text: _fmt.format(widget.grams));
  late String _meal = widget.mealType;
  String? _error;

  @override
  void initState() {
    super.initState();
    _grams.addListener(() => setState(() => _error = null));
  }

  @override
  void dispose() {
    _grams.dispose();
    super.dispose();
  }

  double? get _value => double.tryParse(_grams.text.trim().replaceAll(',', '.'));

  double get _step => widget.food == null ? 10 : (widget.food!.defaultServingG / 2).clamp(5, 100).toDouble();

  void _change(double by) {
    final next = ((_value ?? 0) + by).clamp(0, 5000).toDouble();
    _grams.text = _fmt.format(next);
  }

  Macros _macros(double g) {
    if (widget.food != null) return Macros.of(widget.food!, g);
    final m = widget.entryMacros ?? const Macros();
    final s = widget.entryGrams == 0 ? 0 : g / widget.entryGrams;
    return Macros(calories: m.calories * s, protein: m.protein * s, carbs: m.carbs * s, fat: m.fat * s);
  }

  void _save() {
    final g = _value;
    if (g == null || g < 1) {
      setState(() => _error = 'Enter how many grams you had.');
      return;
    }
    if (g > 5000) {
      setState(() => _error = 'That is more than 5 kg. Check the amount.');
      return;
    }
    Navigator.of(context).pop(SavePortion(g, _meal));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final food = widget.food;
    final m = _macros(_value ?? 0);
    const stepper = BoxConstraints.tightFor(width: AppSizes.input, height: AppSizes.input);

    return SheetLayout(
      title: widget.foodName,
      subtitle: food?.servingDescription,
      body: [
        LabeledField(
          label: 'Amount (grams)',
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton.outlined(
                tooltip: 'Decrease amount',
                onPressed: () => _change(-_step),
                icon: const AppIcon(AppIcons.minus),
                constraints: stepper,
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: TextField(
                  controller: _grams,
                  textAlign: TextAlign.center,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                  decoration: InputDecoration(errorText: _error),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              IconButton.outlined(
                tooltip: 'Increase amount',
                onPressed: () => _change(_step),
                icon: const AppIcon(AppIcons.plus),
                constraints: stepper,
              ),
            ],
          ),
        ),
        if (food != null) ...[
          const SizedBox(height: AppSpace.sm),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              for (final n in const [1, 2])
                ActionChip(
                  label: Text('$n serving${n == 1 ? '' : 's'} (${formatGrams(food.defaultServingG * n)})'),
                  onPressed: () => _grams.text = _fmt.format(food.defaultServingG * n),
                ),
            ],
          ),
        ],
        const SizedBox(height: AppSpace.md),
        Semantics(
          liveRegion: true,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: 12),
            decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(AppRadius.tile)),
            child: Text(
              '${formatKcal(m.calories)} · protein ${formatMacro(m.protein)} · '
              'carbs ${formatMacro(m.carbs)} · fat ${formatMacro(m.fat)}',
              style: text.titleSmall,
            ),
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        Text('Meal', style: text.labelLarge?.copyWith(fontSize: 13, color: p.textSoft)),
        const SizedBox(height: AppSpace.sm),
        Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: [
            for (final meal in mealTypes)
              ChoiceChip(
                label: Text(mealLabel(meal)),
                selected: _meal == meal,
                onSelected: (_) => setState(() => _meal = meal),
              ),
          ],
        ),
      ],
      actions: [
        FilledButton(onPressed: _save, child: Text(widget.editing ? 'Save changes' : 'Add to diary')),
        if (widget.editing)
          OutlinedButton(
            style: OutlinedButton.styleFrom(foregroundColor: p.danger),
            onPressed: () => Navigator.of(context).pop(const DeletePortion()),
            child: const Text('Remove from diary'),
          ),
      ],
    );
  }
}
