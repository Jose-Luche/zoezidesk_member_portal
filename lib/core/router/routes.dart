abstract final class Routes {
  static const splash = '/splash';
  static const login = '/login';
  static const otp = '/login/otp';
  static const home = '/home';
  static const classes = '/classes';
  static const builder = '/builder';
  static const workouts = '/workouts';
  static const workoutHistory = '/workouts/history';
  static const workoutRecords = '/workouts/records';

  /// The exercise library. With a session id as `extra`, picking an
  /// exercise adds it to that session.
  static const exercises = '/workouts/exercises';
  static String workoutSession(String clientId) => '/workouts/session/$clientId';
  static const builderWorkout = '/builder/workout';
  static const more = '/more';
  static const profile = '/profile';
  static const editProfile = '/profile/edit';
  static const membershipCard = '/card';
  static const designGallery = '/dev/design';

  // Destinations of later features. Until each lands they open a
  // "coming soon" screen, so the dashboard's quick actions already work.
  static const checkIn = '/check-in';
  static const payments = '/payments';
  static const checkout = '/payments/pay';

  static const publicRoutes = {login, otp};
}

/// Passed to the OTP route as `extra`.
class OtpArgs {
  const OtpArgs({required this.phone, this.debugCode});

  final String phone;
  final String? debugCode;
}
