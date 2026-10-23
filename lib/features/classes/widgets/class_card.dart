import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../data/db/app_database.dart';
import '../../../shared/widgets/app_badge.dart';
import '../state/classes_providers.dart';

final _time = DateFormat('h:mm a');

String classTimeRange(ClassSession c) =>
    '${_time.format(c.startsAt.toLocal())} – ${_time.format(c.endsAt.toLocal())}';

/// The class type's color from the gym's settings, as a thin accent only
/// (never behind text), with the brand color as a fallback.
Color classAccent(BuildContext context, String? hex) {
  final digits = (hex ?? '').replaceFirst('#', '');
  final value = digits.length == 6 ? int.tryParse(digits, radix: 16) : null;
  return value == null ? Theme.of(context).colorScheme.primary : Color(0xFF000000 | value);
}

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
        ? 'Live spots need a connection'
        : c.isFull
            ? 'Full'
            : '${c.spotsLeft} of ${c.capacity} spots left';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: Card(
        child: InkWell(
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: AppSpace.xs, color: classAccent(context, c.color)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpace.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(classTimeRange(c), style: text.titleSmall?.copyWith(color: p.accentText)),
                        Text(c.className, style: text.titleMedium),
                        if (c.instructor != null) Text('With ${c.instructor}', style: text.bodySmall),
                        Text(spots, style: text.bodySmall),
                        const SizedBox(height: AppSpace.sm),
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

    Widget row(Widget badge, [Widget? action, String? note]) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: badge),
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
      BookingView.open => Align(
          alignment: Alignment.centerRight,
          child: FilledButton(onPressed: onBook, child: const Text('Book')),
        ),
      BookingView.full => row(const AppBadge(label: 'Full', tone: BadgeTone.neutral)),
      BookingView.started => row(const AppBadge(label: 'Started', tone: BadgeTone.neutral)),
      BookingView.booked => row(
          const AppBadge(label: 'Booked', tone: BadgeTone.success, icon: Icons.check_circle_rounded),
          OutlinedButton(onPressed: onCancel, child: const Text('Cancel')),
        ),
      BookingView.bookPending => row(
          const AppBadge(label: 'Booking pending', tone: BadgeTone.neutral, icon: Icons.schedule_rounded),
          TextButton(onPressed: onCancel, child: const Text('Undo')),
          waiting,
        ),
      BookingView.cancelPending => row(
          const AppBadge(label: 'Cancelling', tone: BadgeTone.neutral, icon: Icons.schedule_rounded),
          TextButton(onPressed: onBook, child: const Text('Keep booking')),
          waiting,
        ),
      BookingView.bookFailed => row(
          const AppBadge(label: 'Booking failed', tone: BadgeTone.danger, icon: Icons.error_outline_rounded),
          TextButton(onPressed: onDismiss, child: const Text('Dismiss')),
          error,
        ),
      BookingView.cancelFailed => row(
          const AppBadge(label: 'Cancel failed', tone: BadgeTone.danger, icon: Icons.error_outline_rounded),
          TextButton(onPressed: onDismiss, child: const Text('Dismiss')),
          error,
        ),
    };
  }
}
