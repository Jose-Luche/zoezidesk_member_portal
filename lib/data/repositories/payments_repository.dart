import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_failure.dart';
import '../../core/storage/field_cipher.dart';
import '../../core/utils/clock.dart';
import '../api/payments_api.dart';
import '../db/app_database.dart';
import '../db/encrypted_cache.dart';

/// One payment as shown in the history.
class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.amount,
    required this.status,
    this.method,
    this.receipt,
    this.plan,
    this.paidAt,
    this.hasReceiptPdf = false,
  });

  final int id;

  /// Whole shillings.
  final int amount;

  /// completed, pending or failed
  final String status;
  final String? method;

  /// M-Pesa receipt number.
  final String? receipt;
  final String? plan;
  final DateTime? paidAt;
  final bool hasReceiptPdf;
}

class PaymentsSummary {
  const PaymentsSummary({required this.totalPaid, this.total = 0});

  factory PaymentsSummary.fromJson(Map<String, dynamic> json) => PaymentsSummary(
        totalPaid: (json['total_paid'] as num?)?.toInt() ?? 0,
        total: (json['total'] as num?)?.toInt() ?? 0,
      );

  /// Sum of completed payments, across all pages.
  final int totalPaid;

  /// Number of payments, across all pages.
  final int total;
}

class PaymentsPage {
  const PaymentsPage({required this.page, required this.lastPage});

  final int page;
  final int lastPage;

  bool get hasMore => page < lastPage;
}

/// Payment history, cached for offline reading with amounts and receipts
/// encrypted. A refresh replaces the cache with the first page (server
/// wins); older pages load on demand. Receipt links are online only.
class PaymentsRepository {
  const PaymentsRepository({
    required this._db,
    required this._cache,
    required this._cipher,
    required this._api,
    required this._clock,
  });

  static const syncKey = 'payments';
  static const summaryKey = 'payments_summary';

  final AppDatabase _db;
  final EncryptedCache _cache;
  final FieldCipher _cipher;
  final PaymentsApi _api;
  final DateTime Function() _clock;

  // Same order as the server: paid_at newest first (unpaid last), then id.
  Stream<List<PaymentRecord>> watchAll() => (_db.select(_db.payments)
        ..orderBy([(p) => OrderingTerm.desc(p.paidAt), (p) => OrderingTerm.desc(p.id)]))
      .watch()
      .asyncMap(_decode);

  Stream<DateTime?> watchFetchedAt() =>
      (_db.select(_db.syncMeta)..where((m) => m.key.equals(syncKey)))
          .watchSingleOrNull()
          .map((m) => m?.fetchedAt);

  Stream<PaymentsSummary?> watchSummary() =>
      _cache.watch(summaryKey).map((c) => c == null ? null : PaymentsSummary.fromJson(c.data));

  /// Throws [AppFailure].
  Future<PaymentsPage> refresh() async {
    final (rows, page, summary) = await _fetch(1);
    await _db.transaction(() async {
      await _db.delete(_db.payments).go();
      await _insert(rows);
      await _db.into(_db.syncMeta).insertOnConflictUpdate(
            SyncMetaCompanion.insert(key: syncKey, fetchedAt: _clock()),
          );
    });
    await _cache.put(summaryKey, summary, _clock());
    return page;
  }

  /// Throws [AppFailure].
  Future<PaymentsPage> loadPage(int pageNumber) async {
    final (rows, page, _) = await _fetch(pageNumber);
    await _insert(rows);
    return page;
  }

  /// A link the phone's browser can open for about ten minutes.
  /// Throws [AppFailure].
  Future<Uri> receiptLink(int paymentId) => guardRequest(() async {
        final json = await _api.receiptLink(paymentId);
        return Uri.parse('${json['url']}');
      });

  Future<(List<PaymentsCompanion>, PaymentsPage, Map<String, dynamic>)> _fetch(int page) async {
    final json = await guardRequest(() => _api.page(page));
    final meta = (json['meta'] as Map?)?.cast<String, dynamic>() ?? const {};
    int n(Object? v, int fallback) => v is num ? v.toInt() : fallback;
    final rows = <PaymentsCompanion>[];
    for (final raw in (json['data'] as List? ?? const [])) {
      final p = (raw as Map).cast<String, dynamic>();
      final secret = {
        'amount': n(p['amount'], 0),
        'method': p['method'],
        'receipt': p['receipt'],
        'plan': p['plan'],
        'has_receipt_pdf': p['has_receipt_pdf'] == true,
      };
      rows.add(PaymentsCompanion.insert(
        id: Value(n(p['id'], 0)),
        status: '${p['status'] ?? 'pending'}',
        paidAt: Value(DateTime.tryParse('${p['paid_at']}')),
        payload: await _cipher.encrypt(jsonEncode(secret)),
      ));
    }
    return (
      rows,
      PaymentsPage(page: n(meta['current_page'], page), lastPage: n(meta['last_page'], page)),
      {'total_paid': json['total_paid'], 'total': meta['total']},
    );
  }

  Future<void> _insert(List<PaymentsCompanion> rows) => _db.batch(
        (b) => b.insertAllOnConflictUpdate(_db.payments, rows),
      );

  Future<List<PaymentRecord>> _decode(List<Payment> rows) async {
    try {
      return await Future.wait(rows.map(_decodeOne));
    } catch (_) {
      // Written with a key that no longer exists, or corrupt: drop the
      // cache so the next refresh replaces it.
      await _db.transaction(() async {
        await _db.delete(_db.payments).go();
        await (_db.delete(_db.syncMeta)..where((m) => m.key.equals(syncKey))).go();
      });
      return const [];
    }
  }

  Future<PaymentRecord> _decodeOne(Payment row) async {
    final p = jsonDecode(await _cipher.decrypt(row.payload)) as Map<String, dynamic>;
    return PaymentRecord(
      id: row.id,
      amount: (p['amount'] as num?)?.toInt() ?? 0,
      status: row.status,
      method: p['method'] as String?,
      receipt: p['receipt'] as String?,
      plan: p['plan'] as String?,
      paidAt: row.paidAt,
      hasReceiptPdf: p['has_receipt_pdf'] == true,
    );
  }
}

final paymentsRepositoryProvider = Provider<PaymentsRepository>(
  (ref) => PaymentsRepository(
    db: ref.watch(appDatabaseProvider),
    cache: ref.watch(encryptedCacheProvider),
    cipher: ref.watch(fieldCipherProvider),
    api: ref.watch(paymentsApiProvider),
    clock: ref.watch(clockProvider),
  ),
);
