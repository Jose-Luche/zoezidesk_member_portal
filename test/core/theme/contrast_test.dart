import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoezidesk_member/core/theme/app_tokens.dart';

/// WCAG 2.x relative luminance.
double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double contrast(Color fg, Color bg) {
  final opaqueFg = Color.alphaBlend(fg, bg);
  final a = _luminance(opaqueFg);
  final b = _luminance(bg);
  return (math.max(a, b) + 0.05) / (math.min(a, b) + 0.05);
}

void main() {
  test('contrast helper matches known WCAG values', () {
    expect(contrast(const Color(0xFF000000), const Color(0xFFFFFFFF)),
        closeTo(21, 0.01));
    expect(contrast(const Color(0xFF777777), const Color(0xFFFFFFFF)),
        closeTo(4.48, 0.01));
  });

  for (final (name, p) in [('dark', AppPalette.dark), ('light', AppPalette.light)]) {
    group('$name theme text pairs meet 4.5:1', () {
      final grounds = {'background': p.background, 'surface': p.surface};
      final foregrounds = {
        'text': p.text,
        'textMuted': p.textMuted,
        'textSoft': p.textSoft,
        'accentText': p.accentText,
      };
      for (final bg in grounds.entries) {
        for (final fg in foregrounds.entries) {
          test('${fg.key} on ${bg.key}', () {
            expect(contrast(fg.value, bg.value), greaterThanOrEqualTo(4.5));
          });
        }
      }

      // Insets and sheets. In dark mode surfaceHigh (neutral-700) only
      // carries full-strength text: muted and accent text fall short there,
      // so dark inputs use the background fill instead.
      test('text on surfaceHigh', () {
        expect(contrast(p.text, p.surfaceHigh), greaterThanOrEqualTo(4.5));
        expect(contrast(p.textSoft, p.surfaceHigh), greaterThanOrEqualTo(4.5));
      });
      if (name == 'light') {
        test('muted and accent text on surfaceHigh', () {
          expect(contrast(p.textMuted, p.surfaceHigh), greaterThanOrEqualTo(4.5));
          expect(contrast(p.accentText, p.surfaceHigh), greaterThanOrEqualTo(4.5));
        });
      }

      final tinted = {
        'success on its badge': (p.success, p.successTint),
        'success on its banner': (p.successStrong, p.successBanner),
        'warning on its tint': (p.warning, p.warningTint),
        'danger on its tint': (p.danger, p.dangerTint),
        'info on its tint': (p.info, p.infoTint),
        'selected filter chip': (p.onSelectedChip, p.selectedChip),
        'nav indicator icon': (p.onNavIndicator, p.navIndicator),
        'text on accent tint (quick action pressed)': (p.text, p.accentSoft),
        'text on accent tint (quick action hover)': (p.text, p.accentTint),
        'accent text on accent tint': (p.accentText, p.accentTint),
        'row icons on surface': (p.rowIcon, p.surface),
        'membership card text': (p.onCard, p.cardFill),
        'QR modules': (p.qrInk, p.qrBackground),
        'snackbar': (p.onSnack, p.snackBackground),
      };
      for (final e in tinted.entries) {
        test(e.key, () {
          expect(contrast(e.value.$1, e.value.$2), greaterThanOrEqualTo(4.5));
        });
      }
    });
  }

  test('primary buttons: ink label on the accent, light and dark', () {
    expect(contrast(AppColors.ink, AppColors.accent), greaterThanOrEqualTo(4.5));
    expect(contrast(AppColors.ink, AppColors.accent400), greaterThanOrEqualTo(4.5));
    // Pressed: cream on accent-700.
    expect(contrast(AppColors.cream, AppColors.accent700), greaterThanOrEqualTo(4.5));
  });

  test('cream on the accent fails, which is why it is never used', () {
    expect(contrast(AppColors.cream, AppColors.accent), lessThan(4.5));
  });
}
