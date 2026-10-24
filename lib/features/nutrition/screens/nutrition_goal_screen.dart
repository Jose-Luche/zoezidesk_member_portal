import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/repositories/nutrition_repository.dart';
import '../../../shared/widgets/app_badge.dart';
import '../../../shared/widgets/info_banner.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/state_message.dart';
import '../nutrition_format.dart';
import '../state/nutrition_providers.dart';

/// Daily calorie and macro targets: pick one of the web's presets and
/// adjust it. Saving needs a connection.
class NutritionGoalScreen extends ConsumerStatefulWidget {
  const NutritionGoalScreen({super.key});

  @override
  ConsumerState<NutritionGoalScreen> createState() => _NutritionGoalScreenState();
}

class _NutritionGoalScreenState extends ConsumerState<NutritionGoalScreen> {
  final _calories = TextEditingController();
  final _protein = TextEditingController();
  final _carbs = TextEditingController();
  final _fat = TextEditingController();
  String? _type;
  String? _error;
  bool _filled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(goalControllerProvider.notifier).refresh());
  }

  @override
  void dispose() {
    for (final c in [_calories, _protein, _carbs, _fat]) {
      c.dispose();
    }
    super.dispose();
  }

  void _fill(NutritionGoalInfo g) {
    String n(num v) => v == v.roundToDouble() ? '${v.round()}' : '$v';
    _type = g.goalType;
    _calories.text = n(g.calories);
    _protein.text = n(g.protein);
    _carbs.text = n(g.carbs);
    _fat.text = n(g.fat);
    _error = null;
  }

  Future<void> _save() async {
    double? d(TextEditingController c) => double.tryParse(c.text.trim().replaceAll(',', '.'));
    final calories = int.tryParse(_calories.text.trim());
    final values = [d(_protein), d(_carbs), d(_fat)];
    final error = switch (calories) {
      null => 'Enter your daily calories.',
      < 1200 => 'Daily calories should be at least 1,200.',
      > 6000 => 'Daily calories should be at most 6,000.',
      _ when values.any((v) => v == null || v < 0 || v > 1000) => 'Enter protein, carbs and fat in grams (0–1,000).',
      _ => null,
    };
    if (error != null || _type == null) {
      setState(() => _error = error ?? 'Choose a goal type.');
      return;
    }
    final saved = await ref.read(goalControllerProvider.notifier).save(NutritionGoalInfo(
          goalType: _type!,
          calories: calories!,
          protein: values[0]!,
          carbs: values[1]!,
          fat: values[2]!,
        ));
    if (!mounted) return;
    if (saved) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Daily goal saved.')));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cached = ref.watch(nutritionGoalProvider);
    final saving = ref.watch(goalControllerProvider);
    final text = Theme.of(context).textTheme;
    final settings = cached.value?.data;
    if (settings != null && !_filled) {
      _filled = true;
      final start = settings.goal ?? settings.presets.where((p) => p.goalType == 'maintenance').firstOrNull;
      if (start != null) _fill(start);
    }

    final Widget body;
    if (!cached.hasValue) {
      body = const SkeletonList();
    } else if (settings == null) {
      body = const StateMessage(
        icon: Icons.flag_rounded,
        title: 'Goal not loaded yet',
        message: 'Connect to the internet to set your daily goal.',
      );
    } else {
      final failure = saving.error;
      body = ListView(
        padding: const EdgeInsets.all(AppSpace.md),
        children: [
          Text('Start from a goal', style: text.titleMedium),
          const SizedBox(height: AppSpace.sm),
          for (final p in settings.presets)
            Card(
              margin: const EdgeInsets.only(bottom: AppSpace.sm),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.card),
                side: BorderSide(
                  color: _type == p.goalType ? context.palette.accentText : context.palette.border,
                  width: _type == p.goalType ? 2 : 1,
                ),
              ),
              child: ListTile(
                selected: _type == p.goalType,
                title: Text(p.name ?? p.goalType, style: text.titleSmall),
                subtitle: Text(
                  '${formatKcal(p.calories.toDouble())} · protein ${formatMacro(p.protein)} · '
                  'carbs ${formatMacro(p.carbs)} · fat ${formatMacro(p.fat)}',
                  style: text.bodySmall,
                ),
                trailing: settings.goal?.goalType == p.goalType
                    ? const AppBadge(label: 'Current', tone: BadgeTone.neutral)
                    : null,
                onTap: () => setState(() => _fill(p)),
              ),
            ),
          const SizedBox(height: AppSpace.md),
          Text('Adjust your targets', style: text.titleMedium),
          const SizedBox(height: AppSpace.sm),
          _field(_calories, 'Calories (kcal)', decimals: false),
          _field(_protein, 'Protein (g)'),
          _field(_carbs, 'Carbs (g)'),
          _field(_fat, 'Fat (g)'),
          if (_error != null || failure is AppFailure) ...[
            const SizedBox(height: AppSpace.sm),
            InfoBanner(
              tone: BadgeTone.danger,
              message: _error ??
                  (failure is NetworkFailure
                      ? 'You are offline. Saving your goal needs an internet connection.'
                      : (failure! as AppFailure).message),
            ),
          ],
          const SizedBox(height: AppSpace.md),
          FilledButton(
            onPressed: saving.isLoading ? null : _save,
            child: Text(saving.isLoading ? 'Saving…' : 'Save daily goal'),
          ),
        ],
      );
    }

    return Scaffold(appBar: AppBar(title: const Text('Daily goal')), body: body);
  }

  Widget _field(TextEditingController c, String label, {bool decimals = true}) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpace.sm),
        child: TextField(
          controller: c,
          keyboardType: TextInputType.numberWithOptions(decimal: decimals),
          inputFormatters: [FilteringTextInputFormatter.allow(decimals ? RegExp(r'[0-9.,]') : RegExp(r'[0-9]'))],
          onChanged: (_) => setState(() => _error = null),
          decoration: InputDecoration(labelText: label),
        ),
      );
}
