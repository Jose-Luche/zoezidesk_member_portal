import 'package:flutter/material.dart';

import '../../core/errors/app_failure.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/formatters.dart';
import 'app_badge.dart';
import 'info_banner.dart';

/// "Updated 5 min ago" for cached screens, led by an "Offline" badge with
/// no connection. A failed refresh shows a pending banner and a cache over
/// 24 hours old an info banner, both with Retry.
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
    final text = Theme.of(context).textTheme;
    final retry = refreshing ? null : onRetry;

    if (!offline && refreshError != null) {
      return InfoBanner(
        tone: BadgeTone.warning,
        message: 'Could not refresh. Showing saved data from $when.',
        actionLabel: retry == null ? null : 'Retry',
        onAction: retry,
      );
    }
    if (!offline && stale && !refreshing) {
      return InfoBanner(
        message: 'This may be out of date. Last updated $when.',
        actionLabel: retry == null ? null : 'Retry',
        onAction: retry,
      );
    }

    return Semantics(
      liveRegion: true,
      child: Row(
        children: [
          if (offline) ...[
            const AppBadge(label: 'Offline', tone: BadgeTone.neutral, icon: AppIcons.cloudOff),
            const SizedBox(width: AppSpace.sm),
          ],
          Expanded(
            child: Text(
              refreshing
                  ? 'Refreshing…'
                  : offline
                      ? 'You are offline. Showing saved data from $when.'
                      : 'Updated $when',
              style: text.bodySmall,
            ),
          ),
          if (offline && retry != null)
            TextButton(
              onPressed: retry,
              style: TextButton.styleFrom(minimumSize: const Size(0, 40)),
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}
