import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zoezidesk_member/app.dart';

import '../../helpers/test_app.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    registerFallbackValue(DateTime(2026));
  });

  late TestEnv env;
  final haptics = <String>[];

  setUp(() async {
    env = TestEnv();
    await env.signIn();
    env.dashboardReturns(dashboardJson());
    haptics.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') haptics.add('${call.arguments}');
        return null;
      },
    );
  });

  tearDown(() => env.dispose());

  void serverHas(List<Map<String, dynamic>> classes) {
    when(() => env.classesApi.classes(from: any(named: 'from'), days: any(named: 'days')))
        .thenAnswer((_) async => {'classes': classes});
  }

  void serverOffline() {
    when(() => env.classesApi.classes(from: any(named: 'from'), days: any(named: 'days'))).thenThrow(
      DioException(requestOptions: RequestOptions(), type: DioExceptionType.connectionError),
    );
  }

  Future<void> openClasses(WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(overrides: env.overrides, child: const ZoeziApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Classes')));
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final f = find.text(text).last;
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  testWidgets('shows today with live spots and the day strip', (tester) async {
    serverHas([classJson(1), classJson(2, name: 'Spin', day: 24, hour: 7, booked: true)]);
    await openClasses(tester);

    expect(find.text('Friday 23 October'), findsOneWidget);
    expect(find.text('HIIT Blast'), findsOneWidget);
    expect(find.text('6:00 PM – 7:00 PM'), findsOneWidget);
    expect(find.text('With Coach Amina'), findsOneWidget);
    expect(find.text('6 of 10 spots left'), findsOneWidget);
    expect(find.text('Spin'), findsNothing);

    await tester.tap(find.bySemanticsLabel(RegExp('Saturday 24 October')));
    await tester.pumpAndSettle();
    expect(find.text('Spin'), findsOneWidget);
    expect(find.text('Booked'), findsOneWidget);
  });

  testWidgets('booking online: confirm, pending, then booked with haptic', (tester) async {
    serverHas([classJson(1)]);
    env.http.reply(200, {
      'success': true,
      'message': 'Booked! HIIT Blast on Oct 23 at 6:00 PM.',
      'class': classJson(1, spotsLeft: 5, booked: true),
    });
    await openClasses(tester);

    await tapText(tester, 'Book');
    expect(find.text('Book HIIT Blast?'), findsOneWidget);
    await tapText(tester, 'Book class');

    expect(find.text('Booked'), findsOneWidget);
    expect(find.text('5 of 10 spots left'), findsOneWidget);
    expect(find.text('Booked! HIIT Blast on Oct 23 at 6:00 PM.'), findsOneWidget);
    expect(haptics, contains('HapticFeedbackType.lightImpact'));
    expect(env.http.requests.single.headers['Idempotency-Key'], isNotEmpty);
  });

  testWidgets('offline: cached timetable, no live spots, booking queued', (tester) async {
    serverHas([classJson(1)]);
    await openClasses(tester);
    serverOffline();
    await tester.fling(find.text('HIIT Blast'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(find.textContaining('You are offline. Showing saved data'), findsOneWidget);
    expect(find.text('Live spots need a connection'), findsOneWidget);
    expect(find.text('6 of 10 spots left'), findsNothing);

    await tapText(tester, 'Book');
    await tapText(tester, 'Book class');

    expect(find.text('Booking pending'), findsOneWidget);
    expect(find.text('Will be sent when you are back online.'), findsOneWidget);
    expect(find.text('1 change is waiting to be sent.'), findsOneWidget);
    expect(haptics, isEmpty);
  });

  testWidgets('queued booking is sent when connectivity returns', (tester) async {
    serverHas([classJson(1)]);
    await openClasses(tester);
    await tapText(tester, 'Book');
    await tapText(tester, 'Book class'); // fake HTTP has nothing queued: offline
    expect(find.text('Booking pending'), findsOneWidget);

    // Back online; the backoff timer is not due, connectivity triggers it.
    env.now = testNow.add(const Duration(minutes: 10));
    env.http.reply(200, {'success': true, 'class': classJson(1, spotsLeft: 5, booked: true)});
    env.connectivity.add([ConnectivityResult.wifi]);
    await tester.pumpAndSettle();

    expect(find.text('Booked'), findsOneWidget);
    expect(find.text('1 change is waiting to be sent.'), findsNothing);
  });

  testWidgets('reconnecting refreshes the timetable and clears the offline notice', (tester) async {
    serverOffline();
    await openClasses(tester);
    expect(find.text('You are offline'), findsOneWidget);

    serverHas([classJson(1)]);
    env.connectivity.add([ConnectivityResult.mobile]);
    await tester.pumpAndSettle();

    expect(find.text('HIIT Blast'), findsOneWidget);
    expect(find.text('6 of 10 spots left'), findsOneWidget);
    expect(find.textContaining('You are offline'), findsNothing);
  });

  testWidgets('long badge text never overflows on a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(320 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    serverHas([classJson(1)]);
    await openClasses(tester);
    await tapText(tester, 'Book');
    await tapText(tester, 'Book class'); // offline in the fake HTTP: stays pending

    expect(find.text('Booking pending'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('server rejection shows the reason and can be dismissed', (tester) async {
    serverHas([classJson(1)]);
    env.http.reply(422, {'success': false, 'code': 'full', 'message': 'This class is fully booked.'});
    await openClasses(tester);

    await tapText(tester, 'Book');
    await tapText(tester, 'Book class');

    expect(find.text('Booking failed'), findsOneWidget);
    expect(find.text('This class is fully booked.'), findsOneWidget);
    expect(find.text('Booking failed: This class is fully booked.'), findsOneWidget); // snackbar

    await tapText(tester, 'Dismiss');
    expect(find.text('Book'), findsOneWidget);
  });

  testWidgets('undo a pending booking before it is sent', (tester) async {
    serverHas([classJson(1)]);
    await openClasses(tester);
    await tapText(tester, 'Book');
    await tapText(tester, 'Book class');

    await tapText(tester, 'Undo');

    expect(find.text('Book'), findsOneWidget);
    expect(find.text('1 change is waiting to be sent.'), findsNothing);
  });

  testWidgets('cancel a booking with confirmation', (tester) async {
    serverHas([classJson(1, booked: true)]);
    env.http.reply(200, {'success': true, 'class': classJson(1, spotsLeft: 7)});
    await openClasses(tester);

    await tapText(tester, 'Cancel');
    expect(find.text('You can cancel until the class starts.'), findsOneWidget);
    await tapText(tester, 'Cancel booking');

    expect(find.text('Booking cancelled.'), findsOneWidget);
    expect(find.text('Book'), findsOneWidget);
    expect(env.http.requests.single.path, '/member/classes/1/cancel');
  });

  testWidgets('full and started classes cannot be booked', (tester) async {
    serverHas([classJson(1, spotsLeft: 0), classJson(2, name: 'Early Yoga', hour: 7)]);
    await openClasses(tester);

    expect(find.text('Full'), findsWidgets);
    expect(find.text('Started'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Book'), findsNothing);
  });

  testWidgets('my bookings lists booked classes across days', (tester) async {
    serverHas([
      classJson(1),
      classJson(2, name: 'Spin', day: 25, booked: true),
      classJson(3, name: 'Pilates', day: 27, booked: true),
    ]);
    await openClasses(tester);

    await tapText(tester, 'My bookings');

    expect(find.text('Spin'), findsOneWidget);
    expect(find.text('Pilates'), findsOneWidget);
    expect(find.text('HIIT Blast'), findsNothing);
  });

  testWidgets('first visit offline shows the offline state', (tester) async {
    serverOffline();
    await openClasses(tester);
    expect(find.text('You are offline'), findsOneWidget);
  });

  testWidgets('dashboard quick action opens the Classes tab', (tester) async {
    serverHas([classJson(1)]);
    await tester.pumpWidget(ProviderScope(overrides: env.overrides, child: const ZoeziApp()));
    await tester.pumpAndSettle();

    final action = find.descendant(of: find.byType(Card), matching: find.text('Classes'));
    await tester.ensureVisible(action);
    await tester.pumpAndSettle();
    await tester.tap(action);
    await tester.pumpAndSettle();

    expect(find.text('HIIT Blast'), findsOneWidget);
  });
}
