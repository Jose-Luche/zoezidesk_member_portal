import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zoezidesk_member/core/theme/app_theme.dart';
import 'package:zoezidesk_member/features/auth/widgets/auth_scaffold.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<String> assetShown(WidgetTester tester, ThemeData theme) async {
    await tester.pumpWidget(MaterialApp(theme: theme, home: const Scaffold(body: BrandMark())));
    await tester.pumpAndSettle();
    final loader = tester.widget<SvgPicture>(find.byType(SvgPicture)).bytesLoader as SvgAssetLoader;
    return loader.assetName;
  }

  testWidgets('light wordmark on dark, navy wordmark on light', (tester) async {
    expect(await assetShown(tester, AppTheme.dark), BrandMark.darkAsset);
    expect(await assetShown(tester, AppTheme.light), BrandMark.lightAsset);
    expect(find.bySemanticsLabel('ZoeziDesk'), findsOneWidget);
  });

  test('both wordmarks are bundled', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    for (final asset in [BrandMark.darkAsset, BrandMark.lightAsset]) {
      expect((await rootBundle.loadString(asset)), contains('<svg'));
    }
  });
}
