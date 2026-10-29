import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../shared/widgets/surfaces.dart';

/// Single-choice option as a full-width card (energy, goal, experience).
class ChoiceCard extends StatelessWidget {
  const ChoiceCard({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.description,
    this.icon,
  });

  final String label;
  final String? description;
  final LucideIcon? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: Semantics(
        selected: selected,
        inMutuallyExclusiveGroup: true,
        button: true,
        child: SelectableSurface(
          selected: selected,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 14, AppSpace.gutter, 14),
              child: Row(
                children: [
                  if (icon != null) ...[
                    AppIcon(icon!, color: p.accentText),
                    const SizedBox(width: 14),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: text.titleMedium),
                        if (description != null) ...[
                          const SizedBox(height: 2),
                          Text(description!, style: text.bodySmall),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  AppIcon(
                    selected ? AppIcons.circleDot : AppIcons.circle,
                    size: AppSizes.iconRow,
                    color: selected ? p.accentText : p.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Multi-choice chips (muscles, equipment).
class ChipChoices extends StatelessWidget {
  const ChipChoices({
    super.key,
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  /// key → label, in display order.
  final Map<String, String> options;
  final List<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpace.sm,
      runSpacing: AppSpace.sm,
      children: [
        for (final e in options.entries)
          FilterChip(
            label: Text(e.value),
            selected: selected.contains(e.key),
            onSelected: (_) => onToggle(e.key),
            materialTapTargetSize: MaterialTapTargetSize.padded,
          ),
      ],
    );
  }
}
