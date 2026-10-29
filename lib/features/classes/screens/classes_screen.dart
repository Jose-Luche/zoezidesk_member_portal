import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/sync/outbox_service.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/clock.dart';
import '../../../data/db/app_database.dart';
import '../../../data/repositories/classes_repository.dart';
import '../../../data/sync/sync.dart';
import '../../../shared/widgets/app_badge.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/info_banner.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/state_message.dart';
import '../../../shared/widgets/surfaces.dart';
import '../../../shared/widgets/sync_status.dart';
import '../state/classes_providers.dart';
import '../widgets/class_card.dart';

/// Class timetable for the next two weeks with bookings. Works offline:
/// the timetable comes from the local table and bookings are queued.
class ClassesScreen extends ConsumerStatefulWidget {
  const ClassesScreen({super.key});

  @override
  ConsumerState<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends ConsumerState<ClassesScreen> with WidgetsBindingObserver {
  static const liveFor = Duration(minutes: 15);

  late DateTime _day;
  bool _mineOnly = false;
  StreamSubscription<OutboxEvent>? _events;
  StreamSubscription<Object?>? _connectivity;

  @override
  void initState() {
    super.initState();
    _day = startOfDay(ref.read(clockProvider)());
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
    _events = ref.read(outboxServiceProvider).events.listen(_onOutboxEvent);
    // Back online: refresh so live spots and the offline notice update.
    _connectivity = ref.read(connectivityChangesProvider).listen((results) {
      if (results.any((r) => r != ConnectivityResult.none)) _refresh();
    });
  }

  @override
  void dispose() {
    _events?.cancel();
    _connectivity?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() => ref.read(classesRefreshProvider.notifier).refresh();

  void _onOutboxEvent(OutboxEvent e) {
    if (!mounted || !e.entry.kind.startsWith('class_')) return;
    // A confirmed change means the server is reachable again.
    if (e.succeeded && ref.read(classesRefreshProvider).hasError) _refresh();
    final String message;
    if (e.succeeded) {
      if (e.entry.kind == ClassOutboxKind.book) {
        HapticFeedback.lightImpact();
        message = (e.response['message'] as String?) ?? 'Class booked.';
      } else {
        message = 'Booking cancelled.';
      }
    } else {
      message = e.entry.kind == ClassOutboxKind.book
          ? 'Booking failed: ${e.error}'
          : 'Could not cancel: ${e.error}';
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirm(ClassSession c, {required bool booking}) async {
    final text = Theme.of(context).textTheme;
    final when = '${DateFormat('EEE d MMM').format(c.startsAt.toLocal())}, ${classTimeRange(c)}';
    final ok = await showAppSheet<bool>(
      context,
      builder: (sheet) => SheetLayout(
        title: booking ? 'Book ${c.className}?' : 'Cancel ${c.className}?',
        body: [
          Text(when, style: text.titleSmall?.copyWith(color: sheet.palette.accentText)),
          if (c.instructor != null) Text('With ${c.instructor}', style: text.bodyMedium),
          if (c.description != null) ...[
            const SizedBox(height: AppSpace.sm),
            Text(c.description!, style: text.bodyLarge),
          ],
          if (!booking) ...[
            const SizedBox(height: AppSpace.md),
            const InfoBanner(icon: AppIcons.clock, message: 'You can cancel until the class starts.'),
          ],
        ],
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(sheet, true),
            child: Text(booking ? 'Book class' : 'Cancel booking'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(sheet, false),
            child: Text(booking ? 'Not now' : 'Keep booking'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final repo = ref.read(classesRepositoryProvider);
    booking ? await repo.book(c.id) : await repo.cancel(c.id);
  }

  @override
  Widget build(BuildContext context) {
    final classes = ref.watch(classesProvider);
    final fetchedAt = ref.watch(classesFetchedAtProvider).value;
    final refresh = ref.watch(classesRefreshProvider);
    final pending = ref.watch(pendingSyncCountProvider).value ?? 0;
    final now = ref.watch(clockProvider)();
    final offline = refresh.error is NetworkFailure;
    final live = !offline && fetchedAt != null && now.difference(fetchedAt) < liveFor;

    final rows = classes.value;
    final Widget body;
    if (rows == null || (rows.isEmpty && fetchedAt == null && !refresh.hasError)) {
      body = const SkeletonList(itemCount: 4);
    } else if (rows.isEmpty && fetchedAt == null) {
      body = offline
          ? StateMessage.offline(
              message: 'Connect to the internet once to load the timetable. '
                  'After that it is available offline.',
              onAction: _refresh,
            )
          : StateMessage.error(onAction: _refresh);
    } else {
      body = _Timetable(
        all: rows,
        day: _day,
        mineOnly: _mineOnly,
        now: now,
        live: live,
        offline: offline,
        header: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (fetchedAt != null)
              SyncStatus(
                fetchedAt: fetchedAt,
                now: now,
                refreshing: refresh.isLoading,
                refreshError: refresh.error,
                onRetry: _refresh,
              ),
            if (pending > 0) ...[
              const SizedBox(height: AppSpace.sm),
              InfoBanner(
                tone: BadgeTone.warning,
                icon: AppIcons.refreshCw,
                message: pending == 1
                    ? '1 change is waiting to be sent.'
                    : '$pending changes are waiting to be sent.',
              ),
            ],
          ],
        ),
        onDay: (d) => setState(() {
          _day = d;
          _mineOnly = false;
        }),
        onMineOnly: (v) => setState(() => _mineOnly = v),
        onRefresh: _refresh,
        onBook: (c) => _confirm(c, booking: true),
        onCancel: (c) => c.localState == LocalBookingState.bookPending
            ? ref.read(classesRepositoryProvider).cancel(c.id)
            : _confirm(c, booking: false),
        onKeep: (c) => ref.read(classesRepositoryProvider).book(c.id),
        onDismiss: (c) => ref.read(classesRepositoryProvider).dismissFailure(c.id),
      );
    }

    return Scaffold(appBar: const AppTopBar(title: 'Classes', back: false), body: body);
  }
}

class _Timetable extends StatelessWidget {
  const _Timetable({
    required this.all,
    required this.day,
    required this.mineOnly,
    required this.now,
    required this.live,
    required this.offline,
    required this.header,
    required this.onDay,
    required this.onMineOnly,
    required this.onRefresh,
    required this.onBook,
    required this.onCancel,
    required this.onKeep,
    required this.onDismiss,
  });

  final List<ClassSession> all;
  final DateTime day;
  final bool mineOnly;
  final DateTime now;
  final bool live;
  final bool offline;
  final Widget header;
  final ValueChanged<DateTime> onDay;
  final ValueChanged<bool> onMineOnly;
  final Future<void> Function() onRefresh;
  final ValueChanged<ClassSession> onBook;
  final ValueChanged<ClassSession> onCancel;
  final ValueChanged<ClassSession> onKeep;
  final ValueChanged<ClassSession> onDismiss;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final today = startOfDay(now);
    final days = [for (var i = 0; i < ClassesRepository.windowDays; i++) today.add(Duration(days: i))];
    final mineDays = {for (final c in all.where(countsAsMine)) startOfDay(c.startsAt.toLocal())};

    final shown = mineOnly
        ? all.where(countsAsMine).toList()
        : all.where((c) => startOfDay(c.startsAt.toLocal()) == day).toList();

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: 76 + AppSpace.md,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.xs, AppSpace.gutter, 12),
                itemCount: days.length,
                separatorBuilder: (_, _) => const SizedBox(width: AppSpace.sm),
                itemBuilder: (_, i) => _DayChip(
                  day: days[i],
                  selected: !mineOnly && days[i] == day,
                  hasBooking: mineDays.contains(days[i]),
                  onTap: () => onDay(days[i]),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
            sliver: SliverList.list(children: [
              Align(
                alignment: Alignment.centerLeft,
                child: FilterChip(
                  label: const Text('My bookings', maxLines: 1, softWrap: false),
                  selected: mineOnly,
                  onSelected: onMineOnly,
                ),
              ),
              const SizedBox(height: AppSpace.md),
              header,
              if (offline) ...[
                const SizedBox(height: AppSpace.sm),
                const InfoBanner(
                  icon: AppIcons.cloudOff,
                  message: 'Live spot counts need a connection. You can still book: '
                      'it is sent when you are back online.',
                ),
              ],
              const SizedBox(height: AppSpace.lg),
              SectionHeader(mineOnly ? 'My bookings' : DateFormat('EEEE d MMMM').format(day)),
            ]),
          ),
          if (shown.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: StateMessage.empty(
                title: mineOnly ? 'No bookings yet' : 'No classes on this day',
                message: mineOnly ? 'Book a class and it shows up here.' : 'Pick another day above.',
                actionLabel: mineOnly ? 'See the timetable' : null,
                onAction: mineOnly ? () => onMineOnly(false) : null,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 0, AppSpace.gutter, AppSpace.lg),
              sliver: SliverList.builder(
                itemCount: shown.length,
                itemBuilder: (_, i) {
                  final c = shown[i];
                  final view = bookingView(c, now);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (mineOnly &&
                          (i == 0 ||
                              startOfDay(shown[i - 1].startsAt.toLocal()) !=
                                  startOfDay(c.startsAt.toLocal())))
                        Padding(
                          padding: EdgeInsets.only(top: i == 0 ? 0 : AppSpace.sm, bottom: AppSpace.sm),
                          child: Text(DateFormat('EEEE d MMM').format(c.startsAt.toLocal()), style: text.titleMedium),
                        ),
                      ClassCard(
                        session: c,
                        view: view,
                        liveSpots: live,
                        offline: offline,
                        onTap: () => switch (view) {
                          BookingView.open => onBook(c),
                          BookingView.booked => onCancel(c),
                          _ => null,
                        },
                        onBook: () => view == BookingView.cancelPending ? onKeep(c) : onBook(c),
                        onCancel: () => onCancel(c),
                        onDismiss: () => onDismiss(c),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.day, required this.selected, required this.hasBooking, required this.onTap});

  final DateTime day;
  final bool selected;
  final bool hasBooking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final label = '${DateFormat('EEEE d MMMM').format(day)}${hasBooking ? ', you have a booking' : ''}';
    // Ink on the accent, never cream: cream on terracotta is only 3:1.
    final fg = selected ? scheme.onPrimary : p.text;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.curve,
        width: 54,
        decoration: ShapeDecoration(color: selected ? scheme.primary : p.surface, shape: const StadiumBorder()),
        child: Material(
          type: MaterialType.transparency,
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('EEE').format(day),
                  style: text.labelMedium?.copyWith(color: selected ? fg : p.textMuted),
                ),
                const SizedBox(height: 2),
                Text('${day.day}', style: text.titleMedium?.copyWith(color: fg)),
                const SizedBox(height: AppSpace.xs),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasBooking ? (selected ? fg : p.accentText) : AppColors.transparent,
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
