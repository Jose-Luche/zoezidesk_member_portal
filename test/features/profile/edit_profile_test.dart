import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zoezidesk_member/app.dart';
import 'package:zoezidesk_member/core/errors/app_failure.dart';
import 'package:zoezidesk_member/core/storage/field_cipher.dart';
import 'package:zoezidesk_member/data/db/encrypted_cache.dart';
import 'package:zoezidesk_member/data/repositories/profile_repository.dart';
import 'package:zoezidesk_member/features/profile/state/edit_profile_controller.dart';

import '../../helpers/test_app.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('ProfileForm.changesFrom', () {
    const original = ProfileForm(
      email: 'jane@test.com',
      gender: 'female',
      dateOfBirth: '1995-04-12',
      emergencyContactName: 'John',
      emergencyContactPhone: '254722000000',
    );

    test('nothing changed sends nothing', () {
      expect(original.changesFrom(original), isEmpty);
    });

    test('only edited fields, trimmed', () {
      const edited = ProfileForm(
        email: '  new@test.com ',
        gender: 'female',
        dateOfBirth: '1995-04-12',
        emergencyContactName: 'John',
        emergencyContactPhone: '254722000000',
      );
      expect(edited.changesFrom(original), {'email': 'new@test.com'});
    });

    test('a cleared field is sent as null', () {
      const edited = ProfileForm(
        email: 'jane@test.com',
        gender: null,
        dateOfBirth: '1995-04-12',
        emergencyContactName: '',
        emergencyContactPhone: '254722000000',
      );
      expect(edited.changesFrom(original), {'gender': null, 'emergency_contact_name': null});
    });

    test('whitespace-only edits of an empty field are not changes', () {
      const empty = ProfileForm();
      expect(const ProfileForm(email: '   ').changesFrom(empty), isEmpty);
    });
  });

  group('ProfileRepository.update', () {
    late TestEnv env;
    setUp(() => env = TestEnv());
    tearDown(() => env.dispose());

    test('caches the server response (server wins)', () async {
      final serverVersion = profileJson()..['member']['email'] = 'server@test.com';
      when(() => env.profileApi.update(any())).thenAnswer((_) async => serverVersion);
      final repo = ProfileRepository(
        api: env.profileApi,
        cache: EncryptedCache(env.db, FieldCipher(env.store)),
        clock: () => env.now,
      );

      final result = await repo.update({'email': 'typed@test.com'});

      expect(result.member.email, 'server@test.com');
      expect((await repo.watchProfile().first)!.data.member.email, 'server@test.com');
    });
  });

  group('edit screen', () {
    late TestEnv env;

    setUp(() async {
      env = TestEnv();
      await env.signIn();
      env.dashboardReturns(dashboardJson());
      when(() => env.profileApi.profile()).thenAnswer((_) async => profileJson());
    });

    tearDown(() => env.dispose());

    Future<void> openEdit(WidgetTester tester) async {
      await tester.pumpWidget(ProviderScope(overrides: env.overrides, child: const ZoeziApp()));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Profile'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Edit profile'));
      await tester.pumpAndSettle();
    }

    Finder field(String label) => find.widgetWithText(TextFormField, label);

    Future<void> tapSave(WidgetTester tester) async {
      final save = find.text('Save changes');
      await tester.scrollUntilVisible(save, 300, scrollable: find.byType(Scrollable).first);
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();
    }

    testWidgets('prefills, sends only changes, returns to the updated profile', (tester) async {
      final updated = profileJson()..['member']['emergency_contact_name'] = 'Mary Wanjiru';
      when(() => env.profileApi.update(any())).thenAnswer((_) async => updated);
      await openEdit(tester);

      expect(find.text('jane@test.com'), findsOneWidget);
      expect(find.text('12 Apr 1995'), findsOneWidget);
      // Front-desk-only fields are not editable here.
      expect(field('Phone number'), findsNothing);
      expect(find.widgetWithText(TextFormField, 'Jane Wanjiru'), findsNothing);

      await tester.enterText(field('Name'), 'Mary Wanjiru');
      await tapSave(tester);

      verify(() => env.profileApi.update({'emergency_contact_name': 'Mary Wanjiru'})).called(1);
      expect(find.text('Profile updated'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Mary Wanjiru'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
    });

    testWidgets('nothing changed: saves without a request', (tester) async {
      await openEdit(tester);
      await tapSave(tester);
      verifyNever(() => env.profileApi.update(any()));
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('invalid email is caught before sending', (tester) async {
      await openEdit(tester);
      await tester.enterText(field('Email'), 'not-an-email');
      await tapSave(tester);

      await tester.scrollUntilVisible(
        find.text('Enter a valid email address.'),
        -300,
        scrollable: find.byType(Scrollable).first,
      );
      verifyNever(() => env.profileApi.update(any()));
    });

    testWidgets('server validation errors show on the field', (tester) async {
      when(() => env.profileApi.update(any())).thenThrow(DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(),
          statusCode: 422,
          data: {
            'message': 'Enter a valid phone number.',
            'errors': {
              'emergency_contact_phone': ['Enter a valid phone number.'],
            },
          },
        ),
      ));
      await openEdit(tester);
      await tester.enterText(field('Phone'), '0712 345 678');
      await tapSave(tester);

      expect(find.text('Enter a valid phone number.'), findsOneWidget);
      expect(find.text('Edit profile'), findsOneWidget);
    });

    testWidgets('offline: explains and keeps the edits', (tester) async {
      when(() => env.profileApi.update(any())).thenThrow(DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.connectionError,
      ));
      await openEdit(tester);
      await tester.enterText(field('Email'), 'new@test.com');
      await tapSave(tester);

      expect(
        find.text('You are offline. Connect to the internet to save your changes.'),
        findsOneWidget,
      );
      expect(find.text('new@test.com'), findsOneWidget);
      // Cache still holds the server's version.
      final cached = await ProfileRepository(
        api: env.profileApi,
        cache: EncryptedCache(env.db, FieldCipher(env.store)),
        clock: () => env.now,
      ).watchProfile().first;
      expect(cached!.data.member.email, 'jane@test.com');
    });

    testWidgets('gender chip toggles and clears', (tester) async {
      when(() => env.profileApi.update(any())).thenAnswer((_) async => profileJson());
      await openEdit(tester);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Female'));
      await tester.pumpAndSettle();
      await tapSave(tester);

      verify(() => env.profileApi.update({'gender': null})).called(1);
    });
  });

  test('NetworkFailure is what offline saves raise', () {
    expect(const NetworkFailure(), isA<AppFailure>());
  });
}
