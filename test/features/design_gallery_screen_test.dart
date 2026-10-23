import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zoezidesk_member/app.dart';
import 'package:zoezidesk_member/core/theme/app_tokens.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ZoeziApp()));
    await tester.pumpAndSettle();
  }

  testWidgets('starts in dark theme and toggles to light', (tester) async {
    await pumpApp(tester);
    BuildContext ctx() => tester.element(find.text('Design system'));

    expect(Theme.of(ctx()).brightness, Brightness.dark);
    expect(ctx().palette.background, AppColors.darkBackground);

    await tester.tap(find.byTooltip('Switch to light theme'));
    await tester.pumpAndSettle();

    expect(Theme.of(ctx()).brightness, Brightness.light);
    expect(ctx().palette.background, AppColors.lightBackground);
  });

  testWidgets('primary button meets the 48dp touch target', (tester) async {
    await pumpApp(tester);
    final size = tester.getSize(find.widgetWithText(FilledButton, 'Book class'));
    expect(size.height, greaterThanOrEqualTo(AppSizes.minTouch));
  });

  testWidgets('bottom sheet opens and closes', (tester) async {
    await pumpApp(tester);
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
