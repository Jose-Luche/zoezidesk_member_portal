import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoezidesk_member/core/theme/app_theme.dart';
import 'package:zoezidesk_member/core/theme/app_tokens.dart';
import 'package:zoezidesk_member/core/theme/theme_mode_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final (name, theme, primary) in [
    ('dark', AppTheme.dark, AppColors.accent400),
    ('light', AppTheme.light, AppColors.accent),
  ]) {
    group('$name theme', () {
      test('primary is terracotta with an ink label, never cream', () {
        expect(theme.colorScheme.primary, primary);
        expect(theme.colorScheme.onPrimary, AppColors.ink);
        final fg = theme.filledButtonTheme.style!.foregroundColor!.resolve({});
        expect(fg, AppColors.ink);
      });

      test('carries the semantic palette', () {
        expect(theme.extension<AppPalette>(), isNotNull);
      });

      test('Caprasimo for titles and headings, Figtree for body', () {
        final t = theme.textTheme;
        for (final style in [t.headlineLarge, t.headlineMedium, t.headlineSmall, t.titleLarge]) {
          expect(style!.fontFamily, AppFonts.heading);
          expect(style.fontWeight, FontWeight.w400);
        }
        for (final style in [t.titleMedium, t.titleSmall, t.bodyLarge, t.bodyMedium, t.bodySmall, t.labelLarge]) {
          expect(style!.fontFamily, AppFonts.body);
        }
        expect(t.headlineLarge!.fontSize, 30);
        expect(t.bodyLarge!.fontSize, 16);
      });

      test('buttons are pills at least 48dp tall', () {
        for (final style in [
          theme.filledButtonTheme.style!,
          theme.outlinedButtonTheme.style!,
          theme.textButtonTheme.style!,
        ]) {
          expect(style.minimumSize!.resolve({})!.height, greaterThanOrEqualTo(AppSizes.minTouch));
          expect(style.shape!.resolve({}), isA<StadiumBorder>());
        }
      });

      test('cards are flat with a 26dp radius', () {
        final shape = theme.cardTheme.shape! as RoundedRectangleBorder;
        expect(shape.borderRadius, BorderRadius.circular(AppRadius.card));
        expect(theme.cardTheme.elevation, 0);
      });

      test('inputs are pills; labels sit above, never inside', () {
        final input = theme.inputDecorationTheme;
        expect(input.floatingLabelBehavior, FloatingLabelBehavior.never);
        final focused = input.focusedBorder! as OutlineInputBorder;
        expect(focused.borderSide.color, primary);
        expect(focused.borderRadius, BorderRadius.circular(AppSizes.input / 2));
      });

      test('bottom sheets use 32dp top corners and a plain ink scrim', () {
        final sheet = theme.bottomSheetTheme;
        expect(sheet.modalBarrierColor, AppColors.scrim);
        expect((sheet.shape! as RoundedRectangleBorder).borderRadius,
            const BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)));
      });

      test('no ripples: pressed states tint from the ramp', () {
        expect(theme.splashFactory, NoSplash.splashFactory);
      });
    });
  }

  test('light is the default theme', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(themeModeProvider), ThemeMode.light);
  });

  test('dark mode drops shadows', () {
    expect(AppPalette.dark.shadows, isEmpty);
    expect(AppPalette.light.shadows, isNotEmpty);
  });
}
