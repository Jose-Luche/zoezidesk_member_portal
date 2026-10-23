abstract final class Routes {
  static const splash = '/splash';
  static const login = '/login';
  static const otp = '/login/otp';
  static const home = '/home';
  static const more = '/more';
  static const profile = '/profile';
  static const membershipCard = '/card';
  static const designGallery = '/dev/design';

  // Destinations of later features. Until each lands they open a
  // "coming soon" screen, so the dashboard's quick actions already work.
  static const classes = '/classes';
  static const checkIn = '/check-in';
  static const payments = '/payments';

  static const publicRoutes = {login, otp};
}

/// Passed to the OTP route as `extra`.
class OtpArgs {
  const OtpArgs({required this.phone, this.debugCode});

  final String phone;
  final String? debugCode;
}
