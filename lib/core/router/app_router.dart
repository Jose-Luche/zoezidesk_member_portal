import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/state/session_controller.dart';
import '../../features/builder/screens/builder_screen.dart';
import '../../features/builder/screens/workout_result_screen.dart';
import '../../features/checkin/screens/checkin_screen.dart';
import '../../features/classes/screens/classes_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/design_gallery/design_gallery_screen.dart';
import '../../features/more/more_screen.dart';
import '../../features/payments/screens/payments_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/membership_card_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
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
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => _AppShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.home, builder: (_, _) => const DashboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.classes, builder: (_, _) => const ClassesScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.builder, builder: (_, _) => const BuilderScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.more, builder: (_, _) => const MoreScreen()),
          ]),
        ],
      ),
      // Outside the shell so it covers the bottom bar while editing.
      GoRoute(path: Routes.builderWorkout, builder: (_, _) => const WorkoutResultScreen()),
      GoRoute(path: Routes.membershipCard, builder: (_, _) => const MembershipCardScreen()),
      GoRoute(
        path: Routes.profile,
        builder: (_, _) => const ProfileScreen(),
        routes: [
          GoRoute(path: 'edit', builder: (_, _) => const EditProfileScreen()),
        ],
      ),
      GoRoute(path: Routes.checkIn, builder: (_, _) => const CheckInScreen()),
      GoRoute(path: Routes.payments, builder: (_, _) => const PaymentsScreen()),
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

/// Bottom navigation. Tabs are added as their features land.
class _AppShell extends StatelessWidget {
  const _AppShell({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Classes',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center_rounded),
            label: 'Builder',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_rounded),
            label: 'More',
          ),
        ],
      ),
    );
  }
}
