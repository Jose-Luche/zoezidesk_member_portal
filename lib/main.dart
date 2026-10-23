import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/theme.dart';
import 'core/storage.dart';
import 'screens/login_screen.dart';
import 'screens/otp_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  // Always call this before using async in main
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GymDeskApp());
}

class GymDeskApp extends StatelessWidget {
  const GymDeskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'GymDesk',
      theme: AppTheme.theme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

// GoRouter — your routes/web.php equivalent
final _router = GoRouter(
  // Decide start route based on whether user is logged in
  redirect: (context, state) async {
    bool loggedIn;
    try {
      loggedIn = await AppStorage.isLoggedIn();
    } catch (_) {
      loggedIn = false;
    }

    final onAuth = state.matchedLocation == '/login' ||
        state.matchedLocation == '/otp';

    if (!loggedIn && !onAuth) return '/login';
    if (loggedIn && onAuth) return '/home';
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      redirect: (context, state) => '/login',
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/otp',
      builder: (context, state) {
        final phone = state.extra as String;
        return OtpScreen(phone: phone);
      },
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
  ],
);