import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../shared/widgets/app_top_bar.dart';

/// Shared layout for the login steps: brand mark, title, subtitle, form,
/// left-aligned over a soft circle that bleeds off the top-right corner.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.showBack = false,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -120,
            right: -110,
            child: ExcludeSemantics(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: dark ? AppColors.sage800 : AppColors.sage200,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showBack)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpace.xs),
                    child: Align(alignment: Alignment.centerLeft, child: AppBackControl()),
                  ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.lg, AppSpace.gutter, AppSpace.xl),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const BrandMark(),
                            const SizedBox(height: AppSpace.xl + AppSpace.sm),
                            Semantics(header: true, child: Text(title, style: text.headlineLarge)),
                            const SizedBox(height: AppSpace.sm),
                            Text(subtitle, style: text.bodyLarge?.copyWith(color: p.textMuted)),
                            const SizedBox(height: AppSpace.lg),
                            child,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The ZoeziDesk wordmark, light text on dark and navy text on light.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key});

  static const darkAsset = 'assets/logo/zoezi-desk-horizontal-dark.svg';
  static const lightAsset = 'assets/logo/zoezi-desk-horizontal-light.svg';

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: Alignment.centerLeft,
      child: SvgPicture.asset(
        dark ? darkAsset : lightAsset,
        height: AppSpace.xl,
        semanticsLabel: 'ZoeziDesk',
      ),
    );
  }
}

/// Inline error under a form: alert icon and plain words, never color alone.
class FormErrorText extends StatelessWidget {
  const FormErrorText(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: 12),
        decoration: BoxDecoration(color: p.dangerTint, borderRadius: BorderRadius.circular(AppRadius.tile)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIcon(AppIcons.circleAlert, color: p.danger, size: AppSizes.iconRow),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: p.danger),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
