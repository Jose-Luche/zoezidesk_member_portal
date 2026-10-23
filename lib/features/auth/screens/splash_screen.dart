import 'package:flutter/material.dart';

import '../widgets/auth_scaffold.dart';

/// Shown for the moment it takes to read the stored session.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Semantics(
          label: 'Loading',
          child: const IntrinsicWidth(child: BrandMark()),
        ),
      ),
    );
  }
}
