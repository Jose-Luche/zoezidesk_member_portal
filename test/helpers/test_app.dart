import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zoezidesk_member/core/storage/local_data_wiper.dart';
import 'package:zoezidesk_member/core/storage/session_storage.dart';
import 'package:zoezidesk_member/core/utils/clock.dart';
import 'package:zoezidesk_member/data/api/auth_api.dart';
import 'package:zoezidesk_member/data/api/builder_api.dart';
import 'package:zoezidesk_member/data/api/dashboard_api.dart';
import 'package:zoezidesk_member/data/api/profile_api.dart';
import 'package:zoezidesk_member/data/db/app_database.dart';

import 'fakes.dart';

class MockDashboardApi extends Mock implements DashboardApi {}

class MockProfileApi extends Mock implements ProfileApi {}

class MockBuilderApi extends Mock implements BuilderApi {}

AppDatabase memoryDatabase() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(
    DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
  );
}

/// Fixed "now" for tests: 23 Oct 2026, 10:00.
final testNow = DateTime(2026, 10, 23, 10);

/// Everything the app touches outside Dart, replaced with fakes.
class TestEnv {
  TestEnv() {
    when(() => authApi.logout()).thenAnswer((_) async {});
  }

  final store = InMemorySecureStore();
  final db = memoryDatabase();
  final authApi = MockAuthApi();
  final dashboardApi = MockDashboardApi();
  final profileApi = MockProfileApi();
  final builderApi = MockBuilderApi();
  DateTime now = testNow;

  List<Override> get overrides => [
        secureStoreProvider.overrideWithValue(store),
        appDatabaseProvider.overrideWithValue(db),
        authApiProvider.overrideWithValue(authApi),
        dashboardApiProvider.overrideWithValue(dashboardApi),
        profileApiProvider.overrideWithValue(profileApi),
        builderApiProvider.overrideWithValue(builderApi),
        clockProvider.overrideWithValue(() => now),
        imageCacheClearerProvider.overrideWithValue(() async => imageCacheCleared++),
      ];

  int imageCacheCleared = 0;

  Future<void> signIn() =>
      SessionStorage(store).save(token: 'tok', member: testMember);

  void dashboardReturns(Map<String, dynamic> dashboard, [Map<String, dynamic>? card]) {
    when(() => dashboardApi.dashboard()).thenAnswer((_) async => dashboard);
    when(() => dashboardApi.memberCard()).thenAnswer((_) async => card ?? testCardJson);
  }

  Future<void> dispose() => db.close();
}

Map<String, dynamic> dashboardJson({
  Map<String, dynamic>? membership = const {
    'plan_name': 'Monthly',
    'starts_at': '13 Oct 2026',
    'expires_at': '12 Nov 2026',
    'starts_at_iso': '2026-10-13',
    'expires_at_iso': '2026-11-12',
    'days_left': 20.4,
    'days_remaining': 20,
    'expiry_percent': 33,
    'state': 'active',
    'is_active': true,
  },
  List<Map<String, dynamic>> payments = const [
    {
      'id': 1,
      'amount': 3000,
      'method': 'mpesa',
      'receipt': 'QWE123',
      'date': '13 Oct 2026',
      'date_iso': '2026-10-13T09:00:00+03:00',
      'plan': 'Monthly',
    },
  ],
  int? totalPaid = 4500,
}) =>
    {
      'member': {
        'id': 7,
        'name': 'Jane Wanjiru',
        'member_number': 'ZD-0007',
        'gym_name': 'Test Gym',
        'status': 'active',
      },
      'membership': membership,
      'recent_payments': payments,
      'attendance_month': 6,
      'total_paid': ?totalPaid,
      'generated_at': '2026-10-23T10:00:00+03:00',
    };

Map<String, dynamic> profileJson({String? photoUrl}) => {
      'member': {
        'id': 7,
        'name': 'Jane Wanjiru',
        'member_number': 'ZD-0007',
        'phone': '254711000001',
        'email': 'jane@test.com',
        'gender': 'female',
        'date_of_birth': '1995-04-12',
        'emergency_contact_name': 'John Wanjiru',
        'emergency_contact_phone': '254722000000',
        'photo_url': photoUrl,
        'status': 'active',
        'member_since': '2026-01-10',
        'updated_at': '2026-10-01T09:00:00+03:00',
      },
      'gym': {
        'name': 'Test Gym',
        'phone': '+254700000000',
        'email': 'gym@test.com',
        'address': 'Moi Avenue',
        'town': 'Nairobi',
      },
      'memberships': [
        {
          'id': 2,
          'plan_name': 'Monthly',
          'starts_at_iso': '2026-10-13',
          'expires_at_iso': '2026-11-12',
          'status': 'active',
          'lapsed': false,
        },
        {
          'id': 1,
          'plan_name': 'Monthly',
          'starts_at_iso': '2026-08-01',
          'expires_at_iso': '2026-08-31',
          'status': 'active',
          'lapsed': true,
        },
      ],
      'generated_at': '2026-10-23T10:00:00+03:00',
    };

Map<String, dynamic> builderOptionsJson({
  Map<String, dynamic> lastInputs = const {
    'energy_level': 'medium',
    'time_minutes': '45',
    'focus_muscles': ['full_body'],
    'excluded_muscles': [],
    'equipment': [],
    'goal': 'stay_active',
    'experience_level': 'beginner',
  },
  List<Map<String, dynamic>> suggested = const [
    {'key': 'back_lats', 'label': 'Lats', 'reason': '12 days since last trained'},
  ],
}) =>
    {
      'muscles': {
        'chest': 'Chest', 'back_lats': 'Back (Lats)', 'shoulders': 'Shoulders',
        'biceps': 'Biceps', 'triceps': 'Triceps', 'quads': 'Quads', 'full_body': 'Full Body',
      },
      'equipment': {'dumbbells': 'Dumbbells', 'barbell': 'Barbell', 'bodyweight': 'Bodyweight'},
      'goals': {
        'strength': 'Build Strength', 'growth': 'Muscle Growth', 'stay_active': 'Stay Active',
      },
      'experience_levels': {
        'beginner': 'Beginner', 'intermediate': 'Intermediate', 'advanced': 'Advanced',
      },
      'energy_levels': {'low': 'Low', 'medium': 'Medium', 'high': 'High'},
      'time_minutes': {'min': 10, 'max': 180},
      'last_inputs': lastInputs,
      'suggested_muscles': suggested,
    };

Map<String, dynamic> guidedExerciseJson(int id, String name, int order, {bool plateau = false}) => {
      'id': id,
      'exercise_id': 100 + id,
      'name': name,
      'instructions': 'Keep your back flat.',
      'equipment': ['dumbbells'],
      'muscle_group': 'push',
      'difficulty': 'beginner',
      'target_sets': 3,
      'target_reps': 10,
      'target_weight_kg': '12.50',
      'rest_seconds': 90,
      'suggested_weight_progression': '+2.5kg if all reps completed',
      'reason': 'Targets your chest',
      'order': order,
      'plateau': plateau,
    };

Map<String, dynamic> guidedWorkoutJson({
  String status = 'draft',
  List<Map<String, dynamic>>? exercises,
  String? templateName,
}) =>
    {
      'id': 9,
      'explanation': 'A balanced chest session for muscle growth.',
      'estimated_duration_minutes': 45,
      'status': status,
      'template_name': templateName,
      'session_id': status == 'in_progress' ? 55 : null,
      'exercises': exercises ??
          [
            guidedExerciseJson(1, 'Bench Press', 1),
            guidedExerciseJson(2, 'Incline Dumbbell Press', 2, plateau: true),
            guidedExerciseJson(3, 'Push-up', 3),
          ],
    };

const testCardJson = {
  'qr_code': 'ZD-QR-7f3a9c',
  'member_number': 'ZD-0007',
  'name': 'Jane Wanjiru',
  'gym_name': 'Test Gym',
};
