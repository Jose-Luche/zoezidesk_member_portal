import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app.dart';
import 'core/config/env.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Fonts ship in assets/google_fonts so the app renders correctly offline.
  GoogleFonts.config.allowRuntimeFetching = false;

  if (!Env.isConfigured) {
    throw StateError(
      'API_BASE_URL is not set. Run with '
      '--dart-define-from-file=env/dev.json (see env/example.json).',
    );
  }

  runApp(const ProviderScope(child: ZoeziApp()));
}
