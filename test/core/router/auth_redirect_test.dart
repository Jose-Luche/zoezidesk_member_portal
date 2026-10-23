import 'package:flutter_test/flutter_test.dart';
import 'package:zoezidesk_member/core/router/app_router.dart';
import 'package:zoezidesk_member/core/router/routes.dart';
import 'package:zoezidesk_member/features/auth/state/session_controller.dart';
import 'package:zoezidesk_member/features/auth/state/otp_controllers.dart';

import '../../helpers/fakes.dart';

void main() {
  group('authRedirect', () {
    test('holds on splash while loading', () {
      expect(authRedirect(const SessionLoading(), Routes.home), Routes.splash);
      expect(authRedirect(const SessionLoading(), Routes.splash), isNull);
    });

    test('signed out users can only reach login screens', () {
      const out = SignedOut();
      expect(authRedirect(out, Routes.home), Routes.login);
      expect(authRedirect(out, Routes.splash), Routes.login);
      expect(authRedirect(out, Routes.login), isNull);
      expect(authRedirect(out, Routes.otp), isNull);
    });

    test('signed in users skip login screens', () {
      const inn = SignedIn(testMember);
      expect(authRedirect(inn, Routes.login), Routes.home);
      expect(authRedirect(inn, Routes.otp), Routes.home);
      expect(authRedirect(inn, Routes.splash), Routes.home);
      expect(authRedirect(inn, Routes.home), isNull);
    });
  });

  test('isPlausiblePhone accepts the formats the web portal accepts', () {
    for (final ok in ['0712345678', '712345678', '+254 712 345 678', '254112345678']) {
      expect(isPlausiblePhone(ok), isTrue, reason: ok);
    }
    for (final bad in ['', '0712', 'abcdefghij', '2547123456789']) {
      expect(isPlausiblePhone(bad), isFalse, reason: bad);
    }
  });
}
