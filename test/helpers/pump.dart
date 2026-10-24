import 'package:flutter_test/flutter_test.dart';

// Database (drift) and outbox work runs on real async I/O, which a widget
// test's fake clock does not advance. Running it inside tester.runAsync
// can deadlock with queries the screen started in the test zone, so these
// start work in the test zone and give it real time in small slices.

/// Lets pending database and outbox work finish between frames.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await tester.pump(const Duration(milliseconds: 20));
  }
  await tester.pumpAndSettle();
}

/// Runs database work from a test body and returns its result.
Future<T> io<T>(WidgetTester tester, Future<T> Function() run) async {
  var done = false;
  late T result;
  Object? error;
  run().then((v) {
    result = v;
    done = true;
  }, onError: (Object e) {
    error = e;
    done = true;
  });
  for (var i = 0; i < 400 && !done; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
    // Fake time too: dio and the outbox use timers in the test zone.
    await tester.pump(const Duration(milliseconds: 20));
  }
  if (!done) throw StateError('Database work did not finish');
  if (error != null) throw error!;
  return result;
}
