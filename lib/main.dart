import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Fonts ship in assets/google_fonts so the app renders correctly offline.
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(const ProviderScope(child: ZoeziApp()));
}
