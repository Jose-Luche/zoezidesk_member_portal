abstract final class Routes {
  static const splash = '/splash';
  static const login = '/login';
  static const otp = '/login/otp';
  static const home = '/home';
  static const designGallery = '/dev/design';

  static const publicRoutes = {login, otp};
}

/// Passed to the OTP route as `extra`.
class OtpArgs {
  const OtpArgs({required this.phone, this.debugCode});

  final String phone;
  final String? debugCode;
}
