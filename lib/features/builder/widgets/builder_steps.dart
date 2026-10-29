import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/dto/builder_dto.dart';
import '../../../shared/widgets/surfaces.dart';
import '../state/builder_providers.dart';
import 'choice_widgets.dart';

/// Title and helper text for each step, same order as the web flow.
({String title, String? help}) stepCopy(BuilderStep step) => switch (step) {
      BuilderStep.energy => (title: 'How is your energy today?', help: null),
      BuilderStep.time => (title: 'How much time do you have?', help: null),
      BuilderStep.focus => (
          title: 'What do you want to train?',
          help: 'Pick one or more muscle groups, or Full Body.',
        ),
      BuilderStep.exclude => (
          title: 'Anything to avoid?',
          help: 'Sore or injured? Pick muscles to leave out. Skip if none.',
        ),
      BuilderStep.equipment => (
          title: 'What equipment can you use?',
          help: 'Leave empty to use anything available.',
        ),
      BuilderStep.goal => (title: 'What is your goal?', help: null),
      BuilderStep.experience => (title: 'How experienced are you?', help: null),
    };

class BuilderStepBody extends ConsumerWidget {
  const BuilderStepBody({super.key, required this.options});

  final BuilderOptions options;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(builderFormProvider);
    final c = ref.read(builderFormProvider.notifier);
    final i = form.inputs;

    return switch (form.step) {
      BuilderStep.energy => Column(children: [
          for (final (key, icon, description) in const [
            ('low', AppIcons.batteryLow, 'Take it easy today'),
            ('medium', AppIcons.batteryMedium, 'A normal session'),
            ('high', AppIcons.batteryFull, 'Ready to push hard'),
          ])
            ChoiceCard(
              label: options.energyLevels[key] ?? key,
              description: description,
              icon: icon,
              selected: i.energyLevel == key,
              onTap: () => c.setEnergy(key),
            ),
        ]),
      BuilderStep.time => _TimeStep(
          minutes: i.timeMinutes,
          min: options.minMinutes,
          max: options.maxMinutes,
          onChanged: c.setTime,
        ),
      BuilderStep.focus => _FocusStep(options: options, selected: i.focusMuscles, onToggle: c.toggleFocus),
      BuilderStep.exclude => ChipChoices(
          options: {
            for (final e in options.muscles.entries)
              if (e.key != 'full_body') e.key: e.value,
          },
          selected: i.excludedMuscles,
          onToggle: c.toggleExcluded,
        ),
      BuilderStep.equipment =>
        ChipChoices(options: options.equipment, selected: i.equipment, onToggle: c.toggleEquipment),
      BuilderStep.goal => Column(children: [
          for (final e in options.goals.entries)
            ChoiceCard(
              label: e.value,
              selected: i.goal == e.key,
              onTap: () => c.setGoal(e.key),
            ),
        ]),
      BuilderStep.experience => Column(children: [
          for (final e in options.experienceLevels.entries)
            ChoiceCard(
              label: e.value,
              selected: i.experienceLevel == e.key,
              onTap: () => c.setExperience(e.key),
            ),
        ]),
    };
  }
}

class _TimeStep extends StatelessWidget {
  const _TimeStep({
    required this.minutes,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final int minutes;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  static const _presets = [20, 30, 45, 60, 90];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SurfaceCard(
          padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.md, AppSpace.sm, AppSpace.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                liveRegion: true,
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(text: '$minutes', style: text.displaySmall),
                    TextSpan(text: ' min', style: text.titleLarge?.copyWith(color: context.palette.textMuted)),
                  ]),
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              Slider(
          value: minutes.toDouble().clamp(min.toDouble(), max.toDouble()),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: (max - min) ~/ 5,
          label: '$minutes min',
          semanticFormatterCallback: (v) => '${v.round()} minutes',
          onChanged: (v) => onChanged(v.round()),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.md),
        Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: [
            for (final p in _presets)
              ChoiceChip(
                label: Text('$p min'),
                selected: minutes == p,
                onSelected: (_) => onChanged(p),
              ),
          ],
        ),
      ],
    );
  }
}

class _FocusStep extends StatelessWidget {
  const _FocusStep({required this.options, required this.selected, required this.onToggle});

  final BuilderOptions options;
  final List<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final suggested = options.suggestedMuscles;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (suggested.isNotEmpty) ...[
          const SectionHeader('Needs attention', subtitle: 'Based on your workout logs.'),
          ListCard(
            children: [
              for (final m in suggested)
                Semantics(
                  checked: selected.contains(m.key),
                  child: ListRow(
                    icon: AppIcons.trendingDown,
                    iconColor: context.palette.warning,
                    title: m.label,
                    titleStyle: text.titleSmall,
                    subtitle: m.reason,
                    onTap: () => onToggle(m.key),
                    trailing: Checkbox(value: selected.contains(m.key), onChanged: (_) => onToggle(m.key)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          const SectionHeader('All muscle groups'),
        ],
        ChipChoices(options: options.muscles, selected: selected, onToggle: onToggle),
      ],
    );
  }
}
