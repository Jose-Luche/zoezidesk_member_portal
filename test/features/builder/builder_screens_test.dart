import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zoezidesk_member/app.dart';
import 'package:zoezidesk_member/data/dto/builder_dto.dart';

import '../../helpers/test_app.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(const BuilderInputs());
  });

  late TestEnv env;

  setUp(() async {
    env = TestEnv();
    await env.signIn();
    env.dashboardReturns(dashboardJson());
    when(() => env.builderApi.options()).thenAnswer((_) async => builderOptionsJson());
  });

  tearDown(() => env.dispose());

  DioException offline() =>
      DioException(requestOptions: RequestOptions(), type: DioExceptionType.connectionError);

  Future<void> openBuilder(WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(overrides: env.overrides, child: const ZoeziApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Workouts'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Build me a workout'));
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final f = find.text(text);
    if (f.evaluate().isEmpty) {
      // Lazily built lists: scroll until the target exists.
      await tester.scrollUntilVisible(f, 300, scrollable: find.byType(Scrollable).first);
    }
    await tester.ensureVisible(f.first);
    await tester.pumpAndSettle();
    await tester.tap(f.first);
    await tester.pumpAndSettle();
  }

  group('form', () {
    testWidgets('there is no describe-it mode', (tester) async {
      await openBuilder(tester);
      expect(find.text('Describe it'), findsNothing);
    });

    testWidgets('offline with nothing cached', (tester) async {
      when(() => env.builderApi.options()).thenThrow(offline());
      await openBuilder(tester);

      expect(find.text('You are offline'), findsOneWidget);
      expect(find.text('Building a workout needs an internet connection.'), findsOneWidget);
    });

    testWidgets('walks the 7 steps from last answers and builds', (tester) async {
      when(() => env.builderApi.generate(any())).thenAnswer((_) async => guidedWorkoutJson());
      await openBuilder(tester);

      expect(find.text('Step 1 of 7'), findsOneWidget);
      expect(find.text('How is your energy today?'), findsOneWidget);
      await tapText(tester, 'High');
      await tapText(tester, 'Next');

      expect(find.text('45 min'), findsWidgets); // seeded from last answers
      await tapText(tester, '30 min');
      await tapText(tester, 'Next');

      // Needs-attention suggestion from the member's logs.
      expect(find.text('Needs attention'), findsOneWidget);
      expect(find.text('12 days since last trained'), findsOneWidget);
      await tapText(tester, 'Chest');
      await tapText(tester, 'Next');
      await tapText(tester, 'Shoulders'); // avoid
      await tapText(tester, 'Next');
      await tapText(tester, 'Dumbbells');
      await tapText(tester, 'Next');
      await tapText(tester, 'Muscle Growth');
      await tapText(tester, 'Next');
      expect(find.text('Step 7 of 7'), findsOneWidget);
      await tapText(tester, 'Intermediate');
      await tapText(tester, 'Build my workout');

      final sent = verify(() => env.builderApi.generate(captureAny())).captured.single as BuilderInputs;
      expect(sent.energyLevel, 'high');
      expect(sent.timeMinutes, 30);
      expect(sent.focusMuscles, ['chest']); // Full Body default replaced
      expect(sent.excludedMuscles, ['shoulders']);
      expect(sent.equipment, ['dumbbells']);
      expect(sent.goal, 'growth');
      expect(sent.experienceLevel, 'intermediate');

      expect(find.text('Your workout'), findsOneWidget);
      expect(find.text('Bench Press'), findsOneWidget);
    });

    testWidgets('building offline explains and keeps the answers', (tester) async {
      when(() => env.builderApi.generate(any())).thenThrow(offline());
      await openBuilder(tester);
      for (var i = 0; i < 6; i++) {
        await tapText(tester, 'Next');
      }
      await tapText(tester, 'Build my workout');

      expect(
        find.text('You are offline. Building a workout needs an internet connection.'),
        findsOneWidget,
      );
      expect(find.text('Step 7 of 7'), findsOneWidget);
    });
  });

  group('workout', () {
    Future<void> openWorkout(WidgetTester tester, {Map<String, dynamic>? workout}) async {
      when(() => env.builderApi.generate(any())).thenAnswer((_) async => workout ?? guidedWorkoutJson());
      when(() => env.builderApi.workout(9)).thenAnswer((_) async => workout ?? guidedWorkoutJson());
      await openBuilder(tester);
      for (var i = 0; i < 6; i++) {
        await tapText(tester, 'Next');
      }
      await tapText(tester, 'Build my workout');
      expect(find.text('Your workout'), findsOneWidget);
    }

    testWidgets('shows targets, reasons and plateau flags', (tester) async {
      await openWorkout(tester);

      expect(find.text('A balanced chest session for muscle growth.'), findsOneWidget);
      expect(find.text('3 exercises'), findsOneWidget);
      expect(find.text('3 × 10 · 12.5 kg · 90s rest'), findsWidgets);
      expect(find.text('Plateau: consider a swap'), findsOneWidget);

      await tapText(tester, 'How to');
      expect(find.text('Keep your back flat.'), findsOneWidget);
    });

    testWidgets('move down sends the new order', (tester) async {
      when(() => env.builderApi.reorder(any(), any())).thenAnswer((_) async {});
      await openWorkout(tester);

      await tester.tap(find.byTooltip('Move down').first);
      await tester.pumpAndSettle();

      verify(() => env.builderApi.reorder(9, [2, 1, 3])).called(1);
    });

    testWidgets('swap lists alternatives and swaps', (tester) async {
      when(() => env.builderApi.alternatives(9, 1)).thenAnswer((_) async => [
            {'id': 201, 'name': 'Dumbbell Bench Press', 'difficulty': 'beginner', 'equipment': ['dumbbells']},
          ]);
      when(() => env.builderApi.swap(9, 1, 201)).thenAnswer((_) async {});
      await openWorkout(tester);

      await tester.tap(find.byTooltip('Swap exercise').first);
      await tester.pumpAndSettle();
      expect(find.text('Swap Bench Press'), findsOneWidget);
      await tester.tap(find.text('Dumbbell Bench Press'));
      await tester.pumpAndSettle();

      verify(() => env.builderApi.swap(9, 1, 201)).called(1);
      verify(() => env.builderApi.workout(9)).called(1);
    });

    testWidgets('remove offline shows a message and keeps the exercise', (tester) async {
      when(() => env.builderApi.remove(any(), any())).thenThrow(offline());
      await openWorkout(tester);

      await tester.tap(find.byTooltip('Remove exercise').first);
      await tester.pumpAndSettle();

      expect(find.text('You are offline. Changing the workout needs an internet connection.'), findsOneWidget);
      expect(find.text('Bench Press'), findsOneWidget);
    });

    testWidgets('save as template', (tester) async {
      when(() => env.builderApi.saveTemplate(9, 'Push day')).thenAnswer((_) async {});
      await openWorkout(tester);

      await tapText(tester, 'Save as template');
      await tester.enterText(find.widgetWithText(TextFormField, 'Template name'), 'Push day');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      verify(() => env.builderApi.saveTemplate(9, 'Push day')).called(1);
      expect(find.text('Saved as template.'), findsOneWidget);
    });

    testWidgets('start workout opens it for logging and locks editing', (tester) async {
      when(() => env.builderApi.startSession(9)).thenAnswer((_) async => 55);
      when(() => env.workoutsApi.show(55)).thenAnswer((_) async => {
            'session': workoutSummaryJson(55, 'srv-55', dayType: 'Guided Workout', status: 'in_progress', date: '2026-10-23'),
            'exercises': [
              {'client_id': 'we-1', 'exercise_id': 1, 'name': 'Bench Press', 'muscle_group': 'chest', 'position': 1, 'notes': null, 'sets': []},
            ],
          });
      await openWorkout(tester);
      when(() => env.builderApi.workout(9)).thenAnswer((_) async => guidedWorkoutJson(status: 'in_progress'));

      await tapText(tester, 'Start workout');

      verify(() => env.builderApi.startSession(9)).called(1);
      // The session screen, ready to log.
      expect(find.text('Guided Workout'), findsOneWidget);
      expect(find.text('Log first set'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.textContaining('Workout started. Log your sets'),
        -300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Open workout'), findsOneWidget);
      expect(find.text('Start workout'), findsNothing);
      final moveUp = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.delete_outline_rounded).first);
      expect(moveUp.onPressed, isNull);
    });

    testWidgets('last workout is available offline from the builder', (tester) async {
      await openWorkout(tester);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tapText(tester, 'Back');
      for (var i = 0; i < 5; i++) {
        await tapText(tester, 'Back');
      }

      expect(find.text('Your last workout'), findsOneWidget);
      await tapText(tester, 'Your last workout');
      expect(find.text('Bench Press'), findsOneWidget);
    });
  });
}
