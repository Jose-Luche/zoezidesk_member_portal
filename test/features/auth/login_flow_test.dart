import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zoezidesk_member/app.dart';
import 'package:zoezidesk_member/data/dto/auth_dto.dart';
import 'package:zoezidesk_member/features/auth/state/session_controller.dart';

import '../../helpers/fakes.dart';
import '../../helpers/test_app.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  late TestEnv env;

  setUp(() {
    env = TestEnv();
    env.dashboardReturns(dashboardJson());
    when(() => env.authApi.requestOtp(any())).thenAnswer(
      (_) async => const OtpRequestResult(success: true, message: 'sent'),
    );
  });

  tearDown(() => env.dispose());

  Future<ProviderContainer> pumpApp(WidgetTester tester) async {
    final container = ProviderContainer(overrides: env.overrides);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const ZoeziApp()),
    );
    await tester.pumpAndSettle();
    return container;
  }

  DioException wrongCode() {
    final o = RequestOptions(path: '/member/otp/verify');
    return DioException(
      requestOptions: o,
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: o,
        statusCode: 422,
        data: {'success': false, 'message': 'Invalid or expired code. Please request a new one.'},
      ),
    );
  }

  testWidgets('signed out users land on login', (tester) async {
    await pumpApp(tester);
    expect(find.text('Member login'), findsOneWidget);
  });

  testWidgets('invalid phone shows a field error and sends nothing', (tester) async {
    await pumpApp(tester);
    await tester.enterText(find.byType(TextFormField), '0712');
    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid phone number.'), findsOneWidget);
    verifyNever(() => env.authApi.requestOtp(any()));
  });

  testWidgets('full flow: phone, wrong code, right code, dashboard', (tester) async {
    var attempts = 0;
    when(() => env.authApi.verifyOtp(
          phone: any(named: 'phone'),
          code: any(named: 'code'),
          deviceName: any(named: 'deviceName'),
        )).thenAnswer((_) async {
      if (attempts++ == 0) throw wrongCode();
      return const LoginResult(token: 'tok', member: testMember);
    });

    final container = await pumpApp(tester);

    await tester.enterText(find.byType(TextFormField), '0711000001');
    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your code'), findsOneWidget);
    verify(() => env.authApi.requestOtp('0711000001')).called(1);

    // Six digits submit automatically.
    await tester.enterText(find.byType(TextField), '000000');
    await tester.pumpAndSettle();
    expect(find.text('Invalid or expired code. Please request a new one.'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);
    expect(env.store.values, isEmpty);

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pumpAndSettle();

    expect(find.text('Hi, Jane'), findsOneWidget);
    expect(container.read(sessionControllerProvider), isA<SignedIn>());
    expect(env.store.values, isNotEmpty);
  });

  testWidgets('resend is locked for 60 seconds', (tester) async {
    await pumpApp(tester);
    await tester.enterText(find.byType(TextFormField), '0711000001');
    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();

    expect(find.text('Resend code in 60s'), findsOneWidget);
    await tester.pump(const Duration(seconds: 60));
    expect(find.text('Resend code'), findsOneWidget);

    await tester.tap(find.text('Resend code'));
    await tester.pumpAndSettle();
    verify(() => env.authApi.requestOtp('0711000001')).called(2);
    expect(find.text('A new code is on its way.'), findsOneWidget);
  });

  testWidgets('expired session returns to login with a reason', (tester) async {
    await env.signIn();
    final container = await pumpApp(tester);
    expect(find.text('Hi, Jane'), findsOneWidget);

    await container.read(sessionControllerProvider.notifier).expire();
    await tester.pumpAndSettle();

    expect(find.text('Member login'), findsOneWidget);
    expect(find.text('Your session has ended. Please log in again.'), findsOneWidget);
    expect(env.store.values, isEmpty);
    expect(await env.db.select(env.db.cachedDocuments).get(), isEmpty);
  });
}
