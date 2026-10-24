import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../core/sync/outbox_service.dart';
import '../../core/utils/clock.dart';
import '../api/classes_api.dart';
import '../api/workouts_api.dart';
import '../db/app_database.dart';
import '../db/encrypted_cache.dart';
import '../repositories/classes_repository.dart';
import '../repositories/workouts_repository.dart';

final outboxServiceProvider = Provider<OutboxService>((ref) {
  final service = OutboxService(
    db: ref.watch(appDatabaseProvider),
    dio: ref.watch(dioProvider),
    clock: ref.watch(clockProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

final classesRepositoryProvider = Provider<ClassesRepository>((ref) {
  final outbox = ref.watch(outboxServiceProvider);
  final repo = ClassesRepository(
    db: ref.watch(appDatabaseProvider),
    api: ref.watch(classesApiProvider),
    outbox: outbox,
    clock: ref.watch(clockProvider),
  );
  outbox
    ..register(ClassOutboxKind.book, repo.outboxHandler)
    ..register(ClassOutboxKind.cancel, repo.outboxHandler);
  return repo;
});

final workoutsRepositoryProvider = Provider<WorkoutsRepository>((ref) {
  final outbox = ref.watch(outboxServiceProvider);
  final repo = WorkoutsRepository(
    db: ref.watch(appDatabaseProvider),
    cache: ref.watch(encryptedCacheProvider),
    api: ref.watch(workoutsApiProvider),
    outbox: outbox,
    clock: ref.watch(clockProvider),
  );
  outbox
    ..register(WorkoutOutboxKind.sync, repo.outboxHandler)
    ..register(WorkoutOutboxKind.discard, repo.outboxHandler)
    ..coalesce(WorkoutOutboxKind.sync);
  ref.onDispose(repo.dispose);
  return repo;
});

/// Connectivity changes. Only a hint to try sending again: a failed request
/// is the real signal. Overridden in tests.
final connectivityChangesProvider = Provider<Stream<List<ConnectivityResult>>>(
  (_) => Connectivity().onConnectivityChanged,
);

/// Drives the outbox while a member is signed in: on start, when the app
/// returns to the foreground and when connectivity comes back.
class SyncRunner {
  SyncRunner(this._outbox, Stream<List<ConnectivityResult>> connectivity) {
    _connectivity = connectivity.listen((results) {
      if (results.any((r) => r != ConnectivityResult.none)) _outbox.drain();
    });
    _lifecycle = AppLifecycleListener(onResume: _outbox.drain);
    _outbox.recover().then((_) => _outbox.drain());
  }

  final OutboxService _outbox;
  late final StreamSubscription<List<ConnectivityResult>> _connectivity;
  late final AppLifecycleListener _lifecycle;

  void dispose() {
    _connectivity.cancel();
    _lifecycle.dispose();
  }
}

final syncRunnerProvider = Provider.autoDispose<SyncRunner>((ref) {
  // Create every feature that registers outbox handlers before sending.
  ref.watch(classesRepositoryProvider);
  ref.watch(workoutsRepositoryProvider);
  final runner = SyncRunner(ref.watch(outboxServiceProvider), ref.watch(connectivityChangesProvider));
  ref.onDispose(runner.dispose);
  return runner;
});
