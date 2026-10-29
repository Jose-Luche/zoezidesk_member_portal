import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// Opens a bottom sheet over the tab bar, sized to its content and
/// scrollable on short screens or with large text. Prefer sheets to dialogs
/// for every confirmation.
Future<T?> showAppSheet<T>(BuildContext context, {required WidgetBuilder builder}) =>
    showModalBottomSheet<T>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: builder,
    );

/// The inside of a sheet: Caprasimo title, then the body, then any banner,
/// then full-width 52px actions with the primary on top.
class SheetLayout extends StatelessWidget {
  const SheetLayout({
    super.key,
    required this.title,
    this.subtitle,
    this.body = const [],
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final List<Widget> body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final media = MediaQuery.of(context);
    final bottom = media.viewInsets.bottom > 0
        ? media.viewInsets.bottom + AppSpace.md
        : (media.viewPadding.bottom + AppSpace.md).clamp(AppSpace.xl + AppSpace.sm, double.infinity);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(22, 0, 22, bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(header: true, child: Text(title, style: text.headlineSmall?.copyWith(fontSize: 24))),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpace.xs),
            Text(subtitle!, style: text.bodyLarge?.copyWith(color: context.palette.textMuted)),
          ],
          if (body.isNotEmpty) ...[const SizedBox(height: AppSpace.md), ...body],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: AppSpace.lg),
            for (final (i, a) in actions.indexed) ...[
              if (i > 0) const SizedBox(height: AppSpace.sm),
              SizedBox(height: AppSizes.sheetButton, child: a),
            ],
          ],
        ],
      ),
    );
  }
}
