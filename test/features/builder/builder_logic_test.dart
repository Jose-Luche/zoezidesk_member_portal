import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zoezidesk_member/core/errors/app_failure.dart';
import 'package:zoezidesk_member/data/dto/builder_dto.dart';
import 'package:zoezidesk_member/data/repositories/builder_repository.dart';
import 'package:zoezidesk_member/features/builder/state/builder_providers.dart';

import '../../helpers/test_app.dart';

void main() {
  setUpAll(() => registerFallbackValue(const BuilderInputs()));

  group('BuilderFormController', () {
    late ProviderContainer c;
    late TestEnv env;

    setUp(() {
      env = TestEnv();
      c = ProviderContainer(overrides: env.overrides);
      c.listen(builderFormProvider, (_, _) {});
    });

    tearDown(() async {
      c.dispose();
      await env.dispose();
    });

    BuilderFormController form() => c.read(builderFormProvider.notifier);
    BuilderFormState state() => c.read(builderFormProvider);

    test('seeds defaults once and normalises Full Body', () {
      form().seed(const BuilderInputs(focusMuscles: ['full_body', 'chest'], timeMinutes: 30));
      expect(state().inputs.focusMuscles, ['chest']);
      expect(state().inputs.timeMinutes, 30);

      form().seed(const BuilderInputs(timeMinutes: 90));
      expect(state().inputs.timeMinutes, 30);
    });

    test('Full Body is exclusive of specific muscles (web rule)', () {
      form().toggleFocus('chest');
      form().toggleFocus('biceps');
      expect(state().inputs.focusMuscles, ['chest', 'biceps']);

      form().toggleFocus('full_body');
      expect(state().inputs.focusMuscles, ['full_body']);

      form().toggleFocus('quads');
      expect(state().inputs.focusMuscles, ['quads']);

      form().toggleFocus('quads');
      expect(state().inputs.focusMuscles, isEmpty);
    });

    test('cannot leave the focus step with nothing picked', () {
      form().next();
      form().next();
      expect(state().step, BuilderStep.focus);
      expect(state().canAdvance, isFalse);
      form().next();
      expect(state().step, BuilderStep.focus);

      form().toggleFocus('chest');
      form().next();
      expect(state().step, BuilderStep.exclude);
    });

    test('back and next stay within the 7 steps', () {
      form().back();
      expect(state().step, BuilderStep.energy);
      form().toggleFocus('chest');
      for (var i = 0; i < 10; i++) {
        form().next();
      }
      expect(state().step, BuilderStep.experience);
      expect(state().isLast, isTrue);
      expect(state().number, 7);
    });

    test('time is clamped to 10–180', () {
      form().setTime(5);
      expect(state().inputs.timeMinutes, 10);
      form().setTime(400);
      expect(state().inputs.timeMinutes, 180);
    });
  });

  group('parsing', () {
    test('options tolerate loose server types', () {
      final o = BuilderOptions.fromJson(builderOptionsJson());
      expect(o.lastInputs.timeMinutes, 45); // sent as "45"
      expect(o.muscles['back_lats'], 'Back (Lats)');
      expect(o.suggestedMuscles.single.reason, '12 days since last trained');
    });

    test('workout parses decimals as strings and sorts by order', () {
      final w = GuidedWorkout.fromJson(guidedWorkoutJson(exercises: [
        guidedExerciseJson(2, 'B', 2),
        guidedExerciseJson(1, 'A', 1),
      ]));
      expect(w.exercises.map((e) => e.name), ['A', 'B']);
      expect(w.exercises.first.targetWeightKg, 12.5);
      expect(w.started, isFalse);
      expect(GuidedWorkout.fromJson(guidedWorkoutJson(status: 'in_progress')).started, isTrue);
    });
  });

  group('BuilderRepository', () {
    late TestEnv env;
    late ProviderContainer c;

    setUp(() {
      env = TestEnv();
      c = ProviderContainer(overrides: env.overrides);
    });

    tearDown(() async {
      c.dispose();
      await env.dispose();
    });

    BuilderRepository repo() => c.read(builderRepositoryProvider);

    test('generate caches the workout for offline viewing', () async {
      when(() => env.builderApi.generate(any())).thenAnswer((_) async => guidedWorkoutJson());

      final w = await repo().generate(const BuilderInputs(focusMuscles: ['chest']));

      expect(w.exercises, hasLength(3));
      final cached = await repo().watchWorkout().first;
      expect(cached!.data.id, 9);
      expect(cached.fetchedAt, testNow);
    });

    test('edits re-read the workout from the server (server wins)', () async {
      when(() => env.builderApi.generate(any())).thenAnswer((_) async => guidedWorkoutJson());
      await repo().generate(const BuilderInputs(focusMuscles: ['chest']));

      when(() => env.builderApi.remove(9, 1)).thenAnswer((_) async {});
      when(() => env.builderApi.workout(9)).thenAnswer((_) async => guidedWorkoutJson(exercises: [
            guidedExerciseJson(2, 'Incline Dumbbell Press', 1),
            guidedExerciseJson(3, 'Push-up', 2),
          ]));

      await repo().remove(9, 1);

      final cached = await repo().watchWorkout().first;
      expect(cached!.data.exercises.map((e) => e.id), [2, 3]);
    });

    test('a failed edit leaves the cached workout alone', () async {
      when(() => env.builderApi.generate(any())).thenAnswer((_) async => guidedWorkoutJson());
      await repo().generate(const BuilderInputs(focusMuscles: ['chest']));
      when(() => env.builderApi.remove(any(), any())).thenThrow(
        DioException(requestOptions: RequestOptions(), type: DioExceptionType.connectionError),
      );

      await expectLater(repo().remove(9, 1), throwsA(isA<NetworkFailure>()));
      expect((await repo().watchWorkout().first)!.data.exercises, hasLength(3));
    });
  });
}
