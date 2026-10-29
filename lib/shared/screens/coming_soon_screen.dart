import 'package:flutter/material.dart';

import '../../core/theme/app_icons.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/state_message.dart';

/// Placeholder for a destination whose feature has not been built yet.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(title: title),
      body: StateMessage(
        icon: AppIcons.clock,
        title: 'Coming soon',
        message: '$title is not in the app yet. You can use it on the web portal for now.',
        actionLabel: 'Back',
        onAction: () => Navigator.of(context).maybePop(),
      ),
    );
  }
}
