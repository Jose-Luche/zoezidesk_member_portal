import 'package:flutter/material.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/app_tokens.dart';

/// Screen header with no bar fill: the title left-aligned in Caprasimo 30
/// under the status bar. Pushed screens put a back control above the title
/// (chevron-left + "Back" on iOS, arrow-left on Android); tab roots pass
/// `back: false` and keep their actions beside the title.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.actions = const [],
    this.back = true,
  });

  final String title;
  final List<Widget> actions;
  final bool back;

  static const _controlsHeight = 48.0;
  static const _titleHeight = 52.0;

  @override
  Size get preferredSize =>
      Size.fromHeight(back ? _controlsHeight + _titleHeight : _titleHeight + AppSpace.md);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final canPop = ModalRoute.of(context)?.impliesAppBarDismissal ?? false;
    // A fixed-height header: keep very large text sizes from clipping it.
    final heading = MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Semantics(
        header: true,
        child: Text(title, style: text.headlineLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );

    final Widget content;
    if (back) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: _controlsHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
              child: Row(
                children: [
                  if (canPop) const AppBackControl(),
                  const Spacer(),
                  ...actions,
                ],
              ),
            ),
          ),
          SizedBox(
            height: _titleHeight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 0, AppSpace.gutter, AppSpace.sm),
              child: Align(alignment: Alignment.centerLeft, child: heading),
            ),
          ),
        ],
      );
    } else {
      content = Padding(
        padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.md, AppSpace.xs, 0),
        child: Row(
          children: [
            Expanded(child: heading),
            ...actions,
          ],
        ),
      );
    }

    return Material(
      color: context.palette.background,
      child: SafeArea(bottom: false, child: content),
    );
  }
}

/// Back control for pushed screens, styled per platform.
class AppBackControl extends StatelessWidget {
  const AppBackControl({super.key});

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    void pop() => Navigator.of(context).maybePop();
    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      return Semantics(
        button: true,
        label: 'Back',
        excludeSemantics: true,
        child: TextButton.icon(
          onPressed: pop,
          style: TextButton.styleFrom(padding: const EdgeInsets.only(left: 4, right: 12)),
          icon: const AppIcon(AppIcons.chevronLeft),
          label: const Text('Back'),
        ),
      );
    }
    // Draws the Lucide arrow-left through the theme's ActionIconTheme.
    return BackButton(onPressed: pop);
  }
}
