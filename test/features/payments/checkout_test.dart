import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zoezidesk_member/app.dart';
import 'package:zoezidesk_member/core/errors/app_failure.dart';
import 'package:zoezidesk_member/core/router/app_router.dart';
import 'package:zoezidesk_member/core/router/routes.dart';
import 'package:zoezidesk_member/core/utils/formatters.dart';
import 'package:zoezidesk_member/data/repositories/checkout_repository.dart';

import '../../helpers/test_app.dart';

DioException offline() =>
    DioException(requestOptions: RequestOptions(), type: DioExceptionType.connectionError);

DioException http(int status, Map<String, dynamic> body) {
  final options = RequestOptions(path: '/member/payments/stk');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: options, statusCode: status, data: body),
  );
}

void main() {
  late TestEnv env;

  setUp(() => env = TestEnv());
  tearDown(() => env.dispose());

  group('phone helpers', () {
    test('normalise and validate Safaricom numbers', () {
      expect(normalizeKenyanPhone('0712 345 678'), '254712345678');
      expect(normalizeKenyanPhone('+254 112 345 678'), '254112345678');
      expect(isMpesaPhone('0712345678'), isTrue);
      expect(isMpesaPhone('0112345678'), isTrue);
      expect(isMpesaPhone('0212345678'), isFalse);
      expect(isMpesaPhone('071234'), isFalse);
      expect(formatLocalPhone('254711000001'), '0711 000 001');
    });
  });

  group('CheckoutRepository', () {
    late ProviderContainer c;
    setUp(() => c = ProviderContainer(overrides: env.overrides));
    tearDown(() => c.dispose());
    CheckoutRepository repo() => c.read(checkoutRepositoryProvider);

    test('a 409 resumes the prompt already sent instead of failing', () async {
      when(() => env.checkoutApi.stkPush(planId: 1, phone: any(named: 'phone'), idempotencyKey: 'k'))
          .thenThrow(http(409, {'code': 'pending_exists', 'payment_id': 41}));

      expect(await repo().stkPush(planId: 1, phone: '254711000001', idempotencyKey: 'k'), 41);
    });

    test('M-Pesa refusal comes back with the server message', () async {
      when(() => env.checkoutApi.stkPush(planId: 1, phone: any(named: 'phone'), idempotencyKey: 'k'))
          .thenThrow(http(422, {'code': 'mpesa_rejected', 'message': 'M-Pesa could not send the payment request.'}));

      await expectLater(
        repo().stkPush(planId: 1, phone: '254711000001', idempotencyKey: 'k'),
        throwsA(isA<ValidationFailure>().having((f) => f.message, 'message', 'M-Pesa could not send the payment request.')),
      );
    });
  });

  group('checkout screen', () {
    final haptics = <String>[];

    setUp(() async {
      await env.signIn();
      env.dashboardReturns(dashboardJson());
      when(() => env.paymentsApi.page(any())).thenAnswer((_) async => paymentsJson([]));
      haptics.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') haptics.add('${call.arguments}');
          return null;
        },
      );
    });

    Future<void> openCheckout(WidgetTester tester) async {
      final c = ProviderContainer(overrides: env.overrides);
      addTearDown(c.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(container: c, child: const ZoeziApp()));
      await tester.pumpAndSettle();
      c.read(routerProvider).push(Routes.checkout);
      await tester.pumpAndSettle();
    }

    void plans([Map<String, dynamic>? json]) =>
        when(() => env.checkoutApi.plans()).thenAnswer((_) async => json ?? checkoutPlansJson());

    void pushReturns(int id) => when(() => env.checkoutApi.stkPush(
          planId: any(named: 'planId'),
          phone: any(named: 'phone'),
          idempotencyKey: any(named: 'idempotencyKey'),
        )).thenAnswer((_) async => {'payment_id': id, 'status': 'pending'});

    Finder pay(String amount) => find.text('Pay $amount');

    Future<void> tapPay(WidgetTester tester, String amount) async {
      await tester.scrollUntilVisible(pay(amount), 200, scrollable: find.byType(Scrollable).first);
      await tester.tap(pay(amount));
      await tester.pump();
    }

    testWidgets('pays with M-Pesa and confirms when the callback lands', (tester) async {
      plans();
      pushReturns(7);
      when(() => env.checkoutApi.status(7)).thenAnswer((_) async => checkoutStatusJson(7, 'pending'));
      await openCheckout(tester);

      expect(find.text('Monthly'), findsOneWidget);
      expect(find.text('0711 000 001'), findsOneWidget);
      expect(find.text('Membership from 23 Oct 2026 to 22 Nov 2026.'), findsOneWidget);

      await tapPay(tester, 'KES 3,000');
      await tester.pump();
      expect(find.text('Check your phone'), findsOneWidget);
      expect(find.textContaining('sent to 0711 000 001 to pay KES 3,000'), findsOneWidget);
      verify(() => env.checkoutApi.stkPush(planId: 1, phone: '254711000001', idempotencyKey: any(named: 'idempotencyKey')))
          .called(1);

      // The member enters the PIN; Safaricom calls the server back.
      when(() => env.checkoutApi.status(7)).thenAnswer((_) async => checkoutStatusJson(
            7,
            'completed',
            receipt: 'SJK4H7Q2LM',
            startsAt: '2026-10-23',
            expiresAt: '2026-11-22',
          ));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.text('Payment received'), findsOneWidget);
      expect(find.textContaining('M-Pesa receipt SJK4H7Q2LM'), findsOneWidget);
      expect(find.textContaining('to 22 Nov 2026'), findsOneWidget);
      expect(haptics, contains('HapticFeedbackType.mediumImpact'));
      // The dashboard and history pick up the new membership.
      verify(() => env.dashboardApi.dashboard()).called(greaterThan(1));
      verify(() => env.paymentsApi.page(1)).called(1);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.text('Renew membership'), findsNothing);
    });

    testWidgets('choosing another plan and number', (tester) async {
      plans();
      pushReturns(8);
      when(() => env.checkoutApi.status(8)).thenAnswer((_) async => checkoutStatusJson(8, 'pending'));
      await openCheckout(tester);

      await tester.tap(find.text('Quarterly'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), '0722 000 002');
      await tester.pump();
      expect(find.text('Membership from 23 Oct 2026 to 21 Jan 2027.'), findsOneWidget);

      await tapPay(tester, 'KES 8,000');
      verify(() => env.checkoutApi.stkPush(planId: 2, phone: '254722000002', idempotencyKey: any(named: 'idempotencyKey')))
          .called(1);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    });

    testWidgets('renewal starts after the current plan and preselects it', (tester) async {
      plans(checkoutPlansJson(current: {'plan_id': 2, 'plan_name': 'Quarterly', 'expires_at': '2026-11-12'}));
      await openCheckout(tester);

      expect(find.textContaining('Your Quarterly plan runs to 12 Nov 2026'), findsOneWidget);
      expect(find.text('Your plan'), findsOneWidget);
      expect(find.text('Membership from 13 Nov 2026 to 11 Feb 2027.'), findsOneWidget);
      expect(pay('KES 8,000'), findsOneWidget);
    });

    testWidgets('an invalid number is caught before sending', (tester) async {
      plans();
      await openCheckout(tester);

      await tester.enterText(find.byType(TextField), '0212 000 000');
      await tapPay(tester, 'KES 3,000');

      expect(find.text('Enter a Safaricom number, like 0712 345 678.'), findsOneWidget);
      verifyNever(() => env.checkoutApi.stkPush(
            planId: any(named: 'planId'),
            phone: any(named: 'phone'),
            idempotencyKey: any(named: 'idempotencyKey'),
          ));
    });

    testWidgets('cancelled on the phone: shows the reason and lets you try again', (tester) async {
      plans();
      pushReturns(9);
      when(() => env.checkoutApi.status(9)).thenAnswer(
        (_) async => checkoutStatusJson(9, 'failed', failureReason: 'Request cancelled by user'),
      );
      await openCheckout(tester);
      await tapPay(tester, 'KES 3,000');
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.text('Payment not completed'), findsOneWidget);
      expect(find.text('Request cancelled by user. You have not been charged.'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(pay('KES 3,000'), findsOneWidget);
    });

    testWidgets('no answer in time: explains, and can check again', (tester) async {
      plans();
      pushReturns(10);
      when(() => env.checkoutApi.status(10)).thenAnswer((_) async => checkoutStatusJson(10, 'pending'));
      await openCheckout(tester);
      await tapPay(tester, 'KES 3,000');

      env.now = testNow.add(const Duration(seconds: 6));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('Still waiting for M-Pesa'), findsOneWidget);
      expect(find.textContaining('You will not be charged twice'), findsOneWidget);

      when(() => env.checkoutApi.status(10)).thenAnswer(
        (_) async => checkoutStatusJson(10, 'completed', receipt: 'SJK1', startsAt: '2026-10-23', expiresAt: '2026-11-22'),
      );
      await tester.tap(find.text('Check again'));
      await tester.pumpAndSettle();
      expect(find.text('Payment received'), findsOneWidget);
    });

    testWidgets('a retry after a dropped connection reuses the idempotency key', (tester) async {
      plans();
      final keys = <String>[];
      var calls = 0;
      when(() => env.checkoutApi.stkPush(
            planId: any(named: 'planId'),
            phone: any(named: 'phone'),
            idempotencyKey: any(named: 'idempotencyKey'),
          )).thenAnswer((inv) async {
        keys.add(inv.namedArguments[#idempotencyKey] as String);
        if (calls++ == 0) throw offline();
        return {'payment_id': 11};
      });
      when(() => env.checkoutApi.status(11)).thenAnswer((_) async => checkoutStatusJson(11, 'pending'));
      await openCheckout(tester);

      await tapPay(tester, 'KES 3,000');
      await tester.pump();
      expect(find.text('You are offline. Connect to the internet to pay.'), findsOneWidget);

      await tapPay(tester, 'KES 3,000');
      await tester.pump();
      expect(find.text('Check your phone'), findsOneWidget);
      expect(keys, hasLength(2));
      expect(keys.first, keys.last);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    });

    testWidgets('a prompt already pending is resumed on open', (tester) async {
      plans(checkoutPlansJson(pendingPaymentId: 12));
      when(() => env.checkoutApi.status(12)).thenAnswer((_) async => checkoutStatusJson(12, 'pending'));
      await openCheckout(tester);

      expect(find.text('Check your phone'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    });

    testWidgets('gym without M-Pesa points to the front desk', (tester) async {
      plans(checkoutPlansJson(mpesaEnabled: false));
      await openCheckout(tester);
      expect(find.text('Pay at the front desk'), findsOneWidget);
    });

    testWidgets('offline', (tester) async {
      when(() => env.checkoutApi.plans()).thenThrow(offline());
      await openCheckout(tester);
      expect(find.text('You are offline'), findsOneWidget);
    });

    testWidgets('dashboard renew banner opens checkout', (tester) async {
      env.dashboardReturns(dashboardJson(membership: {
        'plan_name': 'Monthly',
        'expires_at_iso': '2026-10-20',
        'days_remaining': 0,
        'state': 'expired',
      }));
      plans();
      await tester.pumpWidget(ProviderScope(overrides: env.overrides, child: const ZoeziApp()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Renew'));
      await tester.pumpAndSettle();
      expect(find.text('Renew membership'), findsOneWidget);
    });
  });
}
