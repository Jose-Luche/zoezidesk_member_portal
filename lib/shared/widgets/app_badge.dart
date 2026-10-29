import 'package:flutter/material.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/app_tokens.dart';

/// How a badge or banner reads. Status always pairs color with words, and
/// with an icon wherever the meaning is not obvious from the label.
enum BadgeTone { highlight, success, warning, danger, neutral }

extension BadgeToneColors on BadgeTone {
  /// (text, fill) for a badge of this tone.
  (Color, Color) badgeColors(AppPalette p) => switch (this) {
        BadgeTone.success => (p.success, p.successTint),
        BadgeTone.highlight || BadgeTone.warning => (p.warning, p.warningTint),
        BadgeTone.danger => (p.danger, p.dangerTint),
        BadgeTone.neutral => (p.info, p.infoTint),
      };
}

/// Small pill status label, e.g. "Booked", "Pending", "9 this month".
class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.tone = BadgeTone.highlight,
    this.icon,
  });

  final String label;
  final BadgeTone tone;
  final LucideIcon? icon;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = tone.badgeColors(context.palette);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: ShapeDecoration(color: bg, shape: const StadiumBorder()),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            AppIcon(icon!, size: AppSizes.iconBadge, color: fg),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
