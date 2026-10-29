import 'package:flutter/material.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/app_tokens.dart';

/// Empty, error and offline states: left-aligned, a small icon, a title,
/// one muted line and an optional secondary button. No illustrations.
class StateMessage extends StatelessWidget {
  const StateMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  const StateMessage.empty({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  }) : icon = AppIcons.inbox;

  const StateMessage.error({
    super.key,
    this.title = 'Something went wrong',
    this.message = 'We could not load this. Check your connection and try again.',
    this.actionLabel = 'Try again',
    this.onAction,
  }) : icon = AppIcons.circleAlert;

  const StateMessage.offline({
    super.key,
    this.title = 'You are offline',
    this.message = 'This needs an internet connection. Reconnect and try again.',
    this.actionLabel = 'Try again',
    this.onAction,
  }) : icon = AppIcons.cloudOff;

  final LucideIcon icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.lg, AppSpace.xxl, AppSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIcon(icon, size: 28, color: palette.accentText),
            const SizedBox(height: AppSpace.md),
            Text(title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpace.sm),
            Text(message, style: theme.textTheme.bodyMedium?.copyWith(color: palette.textMuted)),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpace.lg),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
