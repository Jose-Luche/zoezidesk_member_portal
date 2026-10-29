import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/db/app_database.dart';
import '../../../shared/widgets/app_badge.dart';
import '../state/classes_providers.dart';

final _time = DateFormat('h:mm a');

String classTimeRange(ClassSession c) =>
    '${_time.format(c.startsAt.toLocal())} – ${_time.format(c.endsAt.toLocal())}';

class ClassCard extends StatelessWidget {
  const ClassCard({
    super.key,
    required this.session,
    required this.view,
    required this.liveSpots,
    required this.offline,
    required this.onTap,
    required this.onBook,
    required this.onCancel,
    required this.onDismiss,
  });

  final ClassSession session;
  final BookingView view;

  /// Show spot counts only when they are live (real-time availability is
  /// online only).
  final bool liveSpots;
  final bool offline;
  final VoidCallback onTap;
  final VoidCallback onBook;
  final VoidCallback onCancel;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final c = session;

    final spots = !liveSpots
        ? 'live spots need a connection'
        : c.isFull
            ? 'full'
            : '${c.spotsLeft} of ${c.capacity} spots left';
    final meta = [if (c.instructor != null) 'With ${c.instructor}', spots].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: Material(
        color: p.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.md, AppSpace.md, AppSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(classTimeRange(c), style: text.titleSmall?.copyWith(color: p.accentText)),
                const SizedBox(height: 2),
                Text(c.className, style: text.titleMedium),
                const SizedBox(height: 2),
                Text(meta[0].toUpperCase() + meta.substring(1), style: text.bodySmall),
                const SizedBox(height: 12),
                _StatusAndAction(
                  view: view,
                  error: c.localError,
                  offline: offline,
                  onBook: onBook,
                  onCancel: onCancel,
                  onDismiss: onDismiss,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusAndAction extends StatelessWidget {
  const _StatusAndAction({
    required this.view,
    required this.error,
    required this.offline,
    required this.onBook,
    required this.onCancel,
    required this.onDismiss,
  });

  final BookingView view;
  final String? error;
  final bool offline;
  final VoidCallback onBook;
  final VoidCallback onCancel;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final waiting = offline ? 'Will be sent when you are back online.' : 'Sending…';
    const compact = Size(0, 40);

    Widget row(Widget? badge, [Widget? action, String? note]) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (badge != null) Flexible(child: badge),
                const Spacer(),
                if (action != null) ...[const SizedBox(width: AppSpace.sm), action],
              ],
            ),
            if (note != null) ...[
              const SizedBox(height: AppSpace.xs),
              Text(note, style: text.bodySmall),
            ],
          ],
        );

    return switch (view) {
      BookingView.open => row(
          null,
          FilledButton(
            onPressed: onBook,
            style: FilledButton.styleFrom(minimumSize: compact),
            child: const Text('Book'),
          ),
        ),
      BookingView.full => row(const AppBadge(label: 'Full', tone: BadgeTone.neutral, icon: AppIcons.circleAlert)),
      BookingView.started => row(const AppBadge(label: 'Started', tone: BadgeTone.neutral, icon: AppIcons.clock)),
      BookingView.booked => row(
          const AppBadge(label: 'Booked', tone: BadgeTone.success, icon: AppIcons.circleCheck),
          OutlinedButton(
            onPressed: onCancel,
            style: OutlinedButton.styleFrom(minimumSize: compact),
            child: const Text('Cancel'),
          ),
        ),
      BookingView.bookPending => row(
          const AppBadge(label: 'Booking pending', tone: BadgeTone.neutral, icon: AppIcons.clock),
          TextButton(onPressed: onCancel, child: const Text('Undo')),
          waiting,
        ),
      BookingView.cancelPending => row(
          const AppBadge(label: 'Cancelling', tone: BadgeTone.neutral, icon: AppIcons.clock),
          TextButton(onPressed: onBook, child: const Text('Keep booking')),
          waiting,
        ),
      BookingView.bookFailed => row(
          const AppBadge(label: 'Booking failed', tone: BadgeTone.danger, icon: AppIcons.circleAlert),
          TextButton(onPressed: onDismiss, child: const Text('Dismiss')),
          error,
        ),
      BookingView.cancelFailed => row(
          const AppBadge(label: 'Cancel failed', tone: BadgeTone.danger, icon: AppIcons.circleAlert),
          TextButton(onPressed: onDismiss, child: const Text('Dismiss')),
          error,
        ),
    };
  }
}
