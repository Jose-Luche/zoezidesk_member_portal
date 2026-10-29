import 'package:flutter/material.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/app_tokens.dart';
import 'app_badge.dart';

/// Inline notice that always leads with an icon, so meaning never relies on
/// color alone. An action, when there is one, sits on the right as a
/// primary pill.
///
/// Tones: neutral is info (scan instructions, offline), highlight and
/// warning are pending ("1 change is waiting to be sent."), success and
/// danger (expired, with Renew).
class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.message,
    this.tone = BadgeTone.neutral,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final BadgeTone tone;
  final LucideIcon? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (fg, bg) = switch (tone) {
      BadgeTone.success => (p.successStrong, p.successBanner),
      BadgeTone.highlight || BadgeTone.warning => (p.warning, p.warningTint),
      BadgeTone.danger => (p.danger, p.dangerTint),
      BadgeTone.neutral => (p.info, p.infoTint),
    };
    final fallbackIcon = switch (tone) {
      BadgeTone.danger => AppIcons.circleAlert,
      BadgeTone.warning || BadgeTone.highlight => AppIcons.clock,
      BadgeTone.success => AppIcons.circleCheck,
      BadgeTone.neutral => AppIcons.info,
    };
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: fg,
          fontWeight: tone == BadgeTone.success ? FontWeight.w600 : null,
        );

    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          AppSpace.md,
          12,
          actionLabel != null && onAction != null ? 8 : AppSpace.md,
          12,
        ),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.tile)),
        child: Row(
          children: [
            AppIcon(icon ?? fallbackIcon, color: fg, size: AppSizes.iconRow),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: style)),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(width: AppSpace.sm),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
                  tapTargetSize: MaterialTapTargetSize.padded,
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
