import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoezidesk_member/core/theme/app_theme.dart';
import 'package:zoezidesk_member/core/theme/app_tokens.dart';
import 'package:zoezidesk_member/core/theme/theme_mode_controller.dart';
import 'package:zoezidesk_member/features/design_gallery/design_gallery_screen.dart';

class _ThemedGallery extends ConsumerWidget {
  const _ThemedGallery();

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ref.watch(themeModeProvider),
        home: const DesignGalleryScreen(),
      );
}

void main() {
  Future<void> pumpGallery(WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: _ThemedGallery()));
    await tester.pumpAndSettle();
  }

  testWidgets('starts in light theme and toggles to dark', (tester) async {
    await pumpGallery(tester);
    BuildContext ctx() => tester.element(find.text('Design system'));

    expect(Theme.of(ctx()).brightness, Brightness.light);
    expect(ctx().palette.background, AppColors.cream);

    await tester.tap(find.byTooltip('Switch to dark theme'));
    await tester.pumpAndSettle();

    expect(Theme.of(ctx()).brightness, Brightness.dark);
    expect(ctx().palette.background, AppColors.neutral900);
  });

  testWidgets('primary button meets the 48dp touch target', (tester) async {
    await pumpGallery(tester);
    final size = tester.getSize(find.widgetWithText(FilledButton, 'Book class'));
    expect(size.height, greaterThanOrEqualTo(AppSizes.minTouch));
  });

  testWidgets('bottom sheet opens and closes', (tester) async {
    await pumpGallery(tester);
    final open = find.text('Open bottom sheet');
    await tester.scrollUntilVisible(
      open,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(open);
    await tester.pumpAndSettle();
    await tester.tap(open);
    await tester.pumpAndSettle();
    expect(find.text('Confirm booking'), findsOneWidget);

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(find.text('Confirm booking'), findsNothing);
  });
}
