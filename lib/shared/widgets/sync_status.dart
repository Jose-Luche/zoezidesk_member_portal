import 'package:flutter/material.dart';

import '../../core/errors/app_failure.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/formatters.dart';
import 'app_badge.dart';
import 'info_banner.dart';

/// "Updated 5 min ago" for cached screens, plus a warning when the cache is
/// over 24 hours old or the last refresh failed.
class SyncStatus extends StatelessWidget {
  const SyncStatus({
    super.key,
    required this.fetchedAt,
    required this.now,
    this.refreshError,
    this.refreshing = false,
    this.onRetry,
  });

  static const staleAfter = Duration(hours: 24);

  final DateTime fetchedAt;
  final DateTime now;
  final Object? refreshError;
  final bool refreshing;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final stale = now.difference(fetchedAt) > staleAfter;
    final when = formatRelative(fetchedAt, now);
    final offline = refreshError is NetworkFailure;

    final String? warning = offline
        ? 'You are offline. Showing saved data from $when.'
        : refreshError != null
            ? 'Could not refresh. Showing saved data from $when.'
            : stale
                ? 'This may be out of date. Last updated $when.'
                : null;

    if (warning != null) {
      return InfoBanner(
        message: warning,
        tone: BadgeTone.warning,
        icon: offline ? Icons.cloud_off_rounded : null,
        actionLabel: refreshing ? null : 'Retry',
        onAction: onRetry,
      );
    }

    return Row(
      children: [
        Icon(
          refreshing ? Icons.sync_rounded : Icons.check_rounded,
          size: AppSpace.md,
          color: context.palette.textMuted,
        ),
        const SizedBox(width: AppSpace.xs),
        Text(
          refreshing ? 'Refreshing…' : 'Updated $when',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
