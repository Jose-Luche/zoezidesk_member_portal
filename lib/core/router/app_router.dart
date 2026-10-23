import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/state/session_controller.dart';
import '../../features/design_gallery/design_gallery_screen.dart';
import '../../features/home/home_placeholder_screen.dart';
import 'routes.dart';

/// Guard rules, kept pure so they can be unit tested.
String? authRedirect(SessionState session, String location) {
  final onPublic = Routes.publicRoutes.contains(location);
  return switch (session) {
    SessionLoading() => location == Routes.splash ? null : Routes.splash,
    SignedOut() => onPublic ? null : Routes.login,
    SignedIn() =>
      onPublic || location == Routes.splash ? Routes.home : null,
  };
}

final routerProvider = Provider<GoRouter>((ref) {
  final session = ValueNotifier<SessionState>(ref.read(sessionControllerProvider));
  ref.listen(sessionControllerProvider, (_, next) => session.value = next);

  final router = GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: session,
    redirect: (_, state) => authRedirect(session.value, state.matchedLocation),
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(
        path: Routes.login,
        builder: (_, _) => const LoginScreen(),
        routes: [
          GoRoute(
            path: 'otp',
            redirect: (_, state) => state.extra is OtpArgs ? null : Routes.login,
            builder: (_, state) => OtpScreen(args: state.extra! as OtpArgs),
          ),
        ],
      ),
      GoRoute(path: Routes.home, builder: (_, _) => const HomePlaceholderScreen()),
      if (kDebugMode)
        GoRoute(
          path: Routes.designGallery,
          builder: (_, _) => const DesignGalleryScreen(),
        ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    session.dispose();
  });
  return router;
});
