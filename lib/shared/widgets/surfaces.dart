import 'package:flutter/material.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/app_tokens.dart';

/// A flat `surface` fill with a soft radius. No shadow: cards sit on the
/// ground; only floating things cast one. Tappable when [onTap] is given,
/// with a pressed tint from the ramp.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.md, AppSpace.gutter, AppSpace.md),
    this.radius = AppRadius.card,
    this.color,
    this.onTap,
    this.semanticLabel,
  });

  /// A tile: 22 radius, 14 padding (stat tiles, rows).
  const SurfaceCard.tile({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.color,
    this.onTap,
    this.semanticLabel,
  }) : radius = AppRadius.tile;

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));
    final body = Padding(padding: padding, child: child);
    return Material(
      color: color ?? context.palette.surface,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? body : InkWell(onTap: onTap, customBorder: shape, child: body),
    );
  }
}

/// A choice card (plans, goals, builder answers): `surface` at rest, an
/// accent tint with an accent ring when selected. Callers pair it with a
/// radio or check icon so selection never relies on color alone.
class SelectableSurface extends StatelessWidget {
  const SelectableSurface({super.key, required this.selected, required this.child, this.onTap});

  final bool selected;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.tile),
      side: selected
          ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
          : const BorderSide(color: AppColors.transparent, width: 2),
    );
    return AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.curve,
      decoration: ShapeDecoration(color: selected ? p.accentTint : p.surface, shape: shape),
      child: Material(
        type: MaterialType.transparency,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, hoverColor: p.accentTint, highlightColor: p.accentSoft, child: child),
      ),
    );
  }
}

/// A grouped list on a surface card, rows separated by whitespace only.
class ListCard extends StatelessWidget {
  const ListCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }
}

/// One row in a [ListCard]: icon · title and subtitle · trailing, with a
/// chevron when it opens something.
class ListRow extends StatelessWidget {
  const ListRow({
    super.key,
    required this.title,
    this.icon,
    this.iconColor,
    this.leading,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.chevron,
    this.titleStyle,
    this.selectableSubtitle = false,
  });

  final String title;
  final LucideIcon? icon;
  final Color? iconColor;

  /// In place of [icon], e.g. a rank number.
  final Widget? leading;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Defaults to showing a chevron whenever the row is tappable and has no
  /// [trailing] widget.
  final bool? chevron;
  final TextStyle? titleStyle;

  /// For contact details people may want to copy.
  final bool selectableSubtitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final showChevron = chevron ?? (onTap != null && trailing == null);
    final lead = leading ?? (icon == null ? null : AppIcon(icon!, size: AppSizes.iconRow, color: iconColor ?? p.accentText));

    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter, vertical: 10),
        child: Row(
          children: [
            if (lead != null) ...[lead, const SizedBox(width: 14)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: titleStyle ?? text.titleMedium),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    selectableSubtitle
                        ? SelectableText(subtitle!, style: text.bodyLarge)
                        : Text(subtitle!, style: text.bodySmall),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: AppSpace.sm), trailing!],
            if (showChevron) ...[
              const SizedBox(width: AppSpace.sm),
              AppIcon(AppIcons.chevronRight, size: AppSizes.iconRow, color: p.textMuted),
            ],
          ],
        ),
      ),
    );
    return onTap == null
        ? MergeSemantics(child: row)
        : MergeSemantics(child: InkWell(onTap: onTap, child: row));
  }
}

/// A section heading, flush left in Caprasimo, with an optional ghost
/// action ("See all") on the right.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.subtitle, this.actionLabel, this.onAction});

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(header: true, child: Text(title, style: text.titleLarge)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: text.bodySmall),
                ],
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

/// A form field with its label above it (never as a placeholder). The label
/// is merged into the field's semantics.
class LabeledField extends StatelessWidget {
  const LabeledField({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 6),
            child: Text(
              label,
              style: text.labelLarge?.copyWith(fontSize: 13, height: 1.3, color: context.palette.textSoft),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// Field-styled button for values picked from a dialog (dates).
class PickerField extends StatelessWidget {
  const PickerField({
    super.key,
    required this.value,
    required this.onTap,
    this.icon,
    this.trailingIcon,
    this.errorText,
  });

  final String value;
  final VoidCallback onTap;
  final LucideIcon? icon;
  final LucideIcon? trailingIcon;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: onTap,
      customBorder: const StadiumBorder(),
      child: InputDecorator(
        decoration: InputDecoration(
          prefixIcon: icon == null ? null : Padding(
            padding: const EdgeInsets.only(left: 14, right: 10),
            child: AppIcon(icon!, size: AppSizes.iconRow, color: p.textMuted),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          suffixIcon: trailingIcon == null ? null : Padding(
            padding: const EdgeInsets.only(right: 14),
            child: AppIcon(trailingIcon!, size: AppSizes.iconRow, color: p.accentText),
          ),
          suffixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          errorText: errorText,
        ),
        child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
      ),
    );
  }
}

/// An input prefix icon, muted and padded to sit inside the pill.
class FieldIcon extends StatelessWidget {
  const FieldIcon(this.icon, {super.key});

  final LucideIcon icon;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 14, right: 10),
        child: AppIcon(icon, size: AppSizes.iconRow, color: context.palette.textMuted),
      );
}
