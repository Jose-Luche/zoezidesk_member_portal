import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_controller.dart';
import 'data/sync/sync.dart';
import 'features/auth/state/session_controller.dart';
import 'features/notifications/notifications_controller.dart';

class ZoeziApp extends ConsumerWidget {
  const ZoeziApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Queued writes are sent, and the phone gets notifications, only while
    // a member is signed in.
    if (ref.watch(sessionControllerProvider) is SignedIn) {
      ref.watch(syncRunnerProvider);
      ref.watch(notificationsControllerProvider);
    }

    return MaterialApp.router(
      title: 'ZoeziDesk',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      themeAnimationDuration: Duration.zero,
      routerConfig: ref.watch(routerProvider),
      scaffoldMessengerKey: ref.watch(scaffoldMessengerKeyProvider),
    );
  }
}
