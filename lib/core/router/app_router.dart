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
import '../../features/nutrition/screens/add_food_screen.dart';
import '../../features/nutrition/screens/nutrition_goal_screen.dart';
import '../../features/nutrition/screens/nutrition_screen.dart';
import '../../features/payments/screens/checkout_screen.dart';
import '../../features/payments/screens/payments_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/membership_card_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/workouts/screens/exercise_picker_screen.dart';
import '../../features/workouts/screens/muscle_progress_screen.dart';
import '../../features/workouts/screens/progress_screen.dart';
import '../../features/workouts/screens/records_screen.dart';
import '../../features/workouts/screens/session_screen.dart';
import '../../features/workouts/screens/workout_history_screen.dart';
import '../../features/workouts/screens/workouts_hub_screen.dart';
import '../theme/app_icons.dart';
import '../theme/app_tokens.dart';
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
            GoRoute(path: Routes.workouts, builder: (_, _) => const WorkoutsHubScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.more, builder: (_, _) => const MoreScreen()),
          ]),
        ],
      ),
      // Outside the shell so it covers the bottom bar while editing.
      GoRoute(path: Routes.builder, builder: (_, _) => const BuilderScreen()),
      GoRoute(path: Routes.settings, builder: (_, _) => const SettingsScreen()),
      GoRoute(
        path: Routes.nutrition,
        builder: (_, _) => const NutritionScreen(),
        routes: [
          GoRoute(path: 'goal', builder: (_, _) => const NutritionGoalScreen()),
          GoRoute(
            path: 'add',
            redirect: (_, state) => state.extra is ({DateTime day, String meal}) ? null : Routes.nutrition,
            builder: (_, state) {
              final args = state.extra! as ({DateTime day, String meal});
              return AddFoodScreen(day: args.day, meal: args.meal);
            },
          ),
        ],
      ),
      GoRoute(path: Routes.workoutHistory, builder: (_, _) => const WorkoutHistoryScreen()),
      GoRoute(path: Routes.workoutRecords, builder: (_, _) => const RecordsScreen()),
      GoRoute(
        path: Routes.workoutProgress,
        builder: (_, _) => const ProgressScreen(),
        routes: [
          GoRoute(
            path: ':muscle',
            builder: (_, state) => MuscleProgressScreen(muscle: state.pathParameters['muscle']!),
          ),
        ],
      ),
      GoRoute(
        path: Routes.exercises,
        builder: (_, state) => ExercisePickerScreen(sessionClientId: state.extra as String?),
      ),
      GoRoute(
        path: '/workouts/session/:id',
        builder: (_, state) => SessionScreen(clientId: state.pathParameters['id']!),
      ),
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
      GoRoute(
        path: Routes.payments,
        builder: (_, _) => const PaymentsScreen(),
        routes: [
          GoRoute(path: 'pay', builder: (_, _) => const CheckoutScreen()),
        ],
      ),
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

/// The four tabs. Android gets a navigation bar with the active icon in an
/// accent pill; iOS a tab bar with icon over label.
class _AppShell extends StatelessWidget {
  const _AppShell({required this.shell});

  final StatefulNavigationShell shell;

  static const _tabs = [
    (AppIcons.house, 'Home'),
    (AppIcons.calendar, 'Classes'),
    (AppIcons.dumbbell, 'Workouts'),
    (AppIcons.menu, 'More'),
  ];

  void _go(int i) => shell.goBranch(i, initialLocation: i == shell.currentIndex);

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    final ios = platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
    return Scaffold(
      body: shell,
      bottomNavigationBar: ios
          ? _IosTabBar(tabs: _tabs, index: shell.currentIndex, onTap: _go)
          : NavigationBar(
              selectedIndex: shell.currentIndex,
              onDestinationSelected: _go,
              destinations: [
                for (final (icon, label) in _tabs)
                  NavigationDestination(icon: AppIcon(icon), label: label),
              ],
            ),
    );
  }
}

class _IosTabBar extends StatelessWidget {
  const _IosTabBar({required this.tabs, required this.index, required this.onTap});

  final List<(LucideIcon, String)> tabs;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final active = dark ? AppColors.accent400 : AppColors.accent700;
    final label = Theme.of(context).textTheme.labelSmall;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: dark ? p.surface : AppColors.neutral100,
        border: Border(top: BorderSide(color: p.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              for (final (i, (icon, text)) in tabs.indexed)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: i == index,
                    label: text,
                    excludeSemantics: true,
                    child: InkResponse(
                      onTap: () => onTap(i),
                      highlightShape: BoxShape.rectangle,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppIcon(icon, color: i == index ? active : p.textMuted),
                          const SizedBox(height: 3),
                          Text(text, style: label?.copyWith(color: i == index ? active : p.textMuted)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
