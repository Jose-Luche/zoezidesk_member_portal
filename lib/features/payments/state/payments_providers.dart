import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/utils/url_opener.dart';
import '../../../data/repositories/payments_repository.dart';

final paymentsProvider = StreamProvider.autoDispose<List<PaymentRecord>>(
  (ref) => ref.watch(paymentsRepositoryProvider).watchAll(),
);

final paymentsSummaryProvider = StreamProvider.autoDispose<PaymentsSummary?>(
  (ref) => ref.watch(paymentsRepositoryProvider).watchSummary(),
);

final paymentsFetchedAtProvider = StreamProvider.autoDispose<DateTime?>(
  (ref) => ref.watch(paymentsRepositoryProvider).watchFetchedAt(),
);

class PaymentsState {
  const PaymentsState({
    this.refresh = const AsyncData(null),
    this.hasMore = false,
    this.loadingMore = false,
    this.nextPage = 2,
    this.openingReceipt,
  });

  final AsyncValue<void> refresh;
  final bool hasMore;
  final bool loadingMore;
  final int nextPage;

  /// The payment whose receipt link is being fetched.
  final int? openingReceipt;

  PaymentsState copyWith({
    AsyncValue<void>? refresh,
    bool? hasMore,
    bool? loadingMore,
    int? nextPage,
    int? Function()? openingReceipt,
  }) => PaymentsState(
    refresh: refresh ?? this.refresh,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
    nextPage: nextPage ?? this.nextPage,
    openingReceipt: openingReceipt != null ? openingReceipt() : this.openingReceipt,
  );
}

class PaymentsController extends Notifier<PaymentsState> {
  @override
  PaymentsState build() => const PaymentsState();

  PaymentsRepository get _repo => ref.read(paymentsRepositoryProvider);

  Future<void> refresh() async {
    if (state.refresh.isLoading) return;
    state = state.copyWith(refresh: const AsyncLoading());
    try {
      final page = await _repo.refresh();
      if (ref.mounted) {
        state = state.copyWith(refresh: const AsyncData(null), hasMore: page.hasMore, nextPage: 2);
      }
    } on AppFailure catch (e, st) {
      if (ref.mounted) state = state.copyWith(refresh: AsyncError(e, st));
    }
  }

  Future<void> loadMore() async {
    if (state.loadingMore || !state.hasMore) return;
    state = state.copyWith(loadingMore: true);
    try {
      final page = await _repo.loadPage(state.nextPage);
      if (ref.mounted) {
        state = state.copyWith(loadingMore: false, hasMore: page.hasMore, nextPage: page.page + 1);
      }
    } on AppFailure {
      if (ref.mounted) state = state.copyWith(loadingMore: false);
    }
  }

  /// Fetches a fresh signed link and opens it in the browser. Returns a
  /// message to show when that fails, or null on success.
  Future<String?> openReceipt(int paymentId) async {
    if (state.openingReceipt != null) return null;
    state = state.copyWith(openingReceipt: () => paymentId);
    try {
      final url = await _repo.receiptLink(paymentId);
      final opened = await ref.read(urlOpenerProvider)(url);
      return opened ? null : 'No app on this phone can open the receipt.';
    } on NetworkFailure {
      return 'Receipts need an internet connection. Try again when you are online.';
    } on AppFailure catch (e) {
      return e.message;
    } finally {
      if (ref.mounted) state = state.copyWith(openingReceipt: () => null);
    }
  }
}

final paymentsControllerProvider =
    NotifierProvider.autoDispose<PaymentsController, PaymentsState>(PaymentsController.new);
