import 'package:flutter/material.dart';

/// Single source for every design literal: colors, spacing, radius, motion
/// and font names. Widgets read these through the theme, never directly
/// as hex values. See design.md (Organic: cream and sand, terracotta,
/// sage).
///
/// Every text/background pair used by the app is checked for 4.5:1 contrast
/// in test/core/theme/contrast_test.dart.
abstract final class AppColors {
  // Warm neutral ramp. Never grey or slate.
  static const neutral100 = Color(0xFFF9F4ED);
  static const neutral200 = Color(0xFFEEE7DB);
  static const neutral300 = Color(0xFFDCD3C4);
  static const neutral400 = Color(0xFFC0B6A5);
  static const neutral500 = Color(0xFFA19786);
  static const neutral600 = Color(0xFF82796A);
  static const neutral700 = Color(0xFF645C50);
  static const neutral800 = Color(0xFF474238);
  static const neutral900 = Color(0xFF2E2B25);

  // Terracotta accent ramp.
  static const accent100 = Color(0xFFFFF2EB);
  static const accent200 = Color(0xFFFFE1D0);
  static const accent300 = Color(0xFFFFC6A5);
  static const accent400 = Color(0xFFF6A06B);
  static const accent500 = Color(0xFFD67F48);
  static const accent600 = Color(0xFFB2622D);
  static const accent700 = Color(0xFF8C491A);
  static const accent800 = Color(0xFF643312);
  static const accent900 = Color(0xFF402310);

  // Sage, the second voice.
  static const sage100 = Color(0xFFF0FAE1);
  static const sage200 = Color(0xFFE1EECC);
  static const sage300 = Color(0xFFCCDBB2);
  static const sage400 = Color(0xFFAEBF92);
  static const sage500 = Color(0xFF8FA073);
  static const sage600 = Color(0xFF728157);
  static const sage700 = Color(0xFF56633F);
  static const sage800 = Color(0xFF3D472B);
  static const sage900 = Color(0xFF272E1B);

  // Named roles.
  static const accent = Color(0xFFC67139); // primary fill
  static const sage = Color(0xFF7A8A5E); // second accent
  static const cream = Color(0xFFF5EAD8); // light background
  static const sand = Color(0xFFEBDDC5); // light surface
  static const ink = Color(0xFF201E1D); // text, and labels on the accent

  // Ink and cream at fixed strengths (dividers, pressed and hover tints).
  static const inkDivider = Color(0x29201E1D); // 16%
  static const inkPressed = Color(0x1A201E1D); // 10%
  static const inkHover = Color(0x12201E1D); // 7%
  static const creamDivider = Color(0x29F9F4ED);
  static const creamPressed = Color(0x1AF9F4ED);
  static const creamHover = Color(0x12F9F4ED);

  static const scrim = Color(0x6B201E1D); // 42%, no blur
  static const transparent = Color(0x00000000);
}

/// Ink-tinted shadows for the warm ground, only for things that float.
/// Dark mode drops them.
abstract final class AppShadows {
  static const sm = [BoxShadow(color: Color(0x242E2B25), blurRadius: 2, offset: Offset(0, 1))];
  static const md = [BoxShadow(color: Color(0x292E2B25), blurRadius: 10, offset: Offset(0, 3))];
  static const lg = [BoxShadow(color: Color(0x382E2B25), blurRadius: 32, offset: Offset(0, 12))];
}

abstract final class AppSpace {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;

  /// Screen side padding and card padding.
  static const double gutter = 18;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;
}

abstract final class AppRadius {
  /// QR tile on the card; small insets.
  static const double control = 16;

  /// Snackbars.
  static const double snack = 18;

  /// Stat tiles, banners, list cards, visit and payment rows.
  static const double tile = 22;

  /// Grouped list cards, class cards, the payments card.
  static const double card = 26;

  /// Membership card, active-workout card.
  static const double hero = 30;

  /// Bottom sheet top corners.
  static const double sheet = 32;

  /// Buttons, chips, inputs, badges: a full pill.
  static const double pill = 999;
}

abstract final class AppSizes {
  static const double minTouch = 48;
  static const double icon = 22;
  static const double iconRow = 20;
  static const double iconBadge = 15;
  static const double qrOnCard = 92;
  static const double qrFullScreen = 228;
  static const double avatar = 72;

  /// Full-width actions in sheets, and text inputs.
  static const double sheetButton = 52;
  static const double input = 52;
  static const double quickAction = 58;
}

abstract final class AppMotion {
  static const fast = Duration(milliseconds: 200);
  static const medium = Duration(milliseconds: 250);
  static const slow = Duration(milliseconds: 350);
  static const curve = Curves.easeOutCubic;
}

abstract final class AppFonts {
  static const heading = 'Caprasimo';
  static const body = 'Figtree';
}

/// Semantic colors that ColorScheme has no slot for. Read with
/// `context.palette`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceHigh,
    required this.text,
    required this.textMuted,
    required this.textSoft,
    required this.border,
    required this.pressed,
    required this.hover,
    required this.accentText,
    required this.accentTint,
    required this.accentSoft,
    required this.navIndicator,
    required this.onNavIndicator,
    required this.rowIcon,
    required this.success,
    required this.successTint,
    required this.successStrong,
    required this.successBanner,
    required this.warning,
    required this.warningTint,
    required this.danger,
    required this.dangerTint,
    required this.info,
    required this.infoTint,
    required this.selectedChip,
    required this.onSelectedChip,
    required this.skeleton,
    required this.cardFill,
    required this.cardDecor,
    required this.onCard,
    required this.qrBackground,
    required this.qrInk,
    required this.snackBackground,
    required this.onSnack,
    required this.shadows,
  });

  final Color background;
  final Color surface;
  final Color surfaceHigh;
  final Color text;
  final Color textMuted;

  /// Field labels above inputs (neutral-800).
  final Color textSoft;
  final Color border;

  /// Pressed and hover tints laid over a surface.
  final Color pressed;
  final Color hover;

  /// The accent as text and icons on neutral surfaces.
  final Color accentText;

  /// Accent fill behind accent badges and highlights (accent-100).
  final Color accentTint;

  /// Hover on accent-tinted tiles, e.g. quick actions (accent-200).
  final Color accentSoft;

  /// Android navigation bar's active pill and its icon.
  final Color navIndicator;
  final Color onNavIndicator;

  /// Icons on payment and visit rows (sage).
  final Color rowIcon;

  /// Status text, each with the fill it sits on. Status never relies on
  /// color alone: it always comes with an icon and words.
  final Color success;
  final Color successTint;
  final Color successStrong;
  final Color successBanner;
  final Color warning;
  final Color warningTint;
  final Color danger;
  final Color dangerTint;
  final Color info;
  final Color infoTint;

  /// Selected filter chip ("My bookings").
  final Color selectedChip;
  final Color onSelectedChip;
  final Color skeleton;

  /// Membership card hero: a solid sage fill with a soft circle.
  final Color cardFill;
  final Color cardDecor;
  final Color onCard;
  final Color qrBackground;
  final Color qrInk;

  final Color snackBackground;
  final Color onSnack;

  /// Shadows for floating things; empty in dark mode.
  final List<BoxShadow> shadows;

  static const light = AppPalette(
    background: AppColors.cream,
    surface: AppColors.sand,
    surfaceHigh: AppColors.neutral100,
    text: AppColors.ink,
    textMuted: AppColors.neutral700,
    textSoft: AppColors.neutral800,
    border: AppColors.inkDivider,
    pressed: AppColors.inkPressed,
    hover: AppColors.inkHover,
    accentText: AppColors.accent700,
    accentTint: AppColors.accent100,
    accentSoft: AppColors.accent200,
    navIndicator: AppColors.accent300,
    onNavIndicator: AppColors.accent900,
    rowIcon: AppColors.sage700,
    success: AppColors.sage800,
    successTint: AppColors.sage100,
    successStrong: AppColors.sage900,
    successBanner: AppColors.sage200,
    warning: AppColors.accent800,
    warningTint: AppColors.accent100,
    danger: AppColors.accent900,
    dangerTint: AppColors.accent200,
    info: AppColors.neutral800,
    infoTint: AppColors.neutral100,
    selectedChip: AppColors.sage200,
    onSelectedChip: AppColors.sage900,
    skeleton: AppColors.neutral300,
    cardFill: AppColors.sage700,
    cardDecor: AppColors.sage600,
    onCard: AppColors.cream,
    qrBackground: AppColors.cream,
    qrInk: AppColors.ink,
    snackBackground: AppColors.ink,
    onSnack: AppColors.cream,
    shadows: AppShadows.md,
  );

  static const dark = AppPalette(
    background: AppColors.neutral900,
    surface: AppColors.neutral800,
    surfaceHigh: AppColors.neutral700,
    text: AppColors.neutral100,
    textMuted: AppColors.neutral300,
    textSoft: AppColors.neutral200,
    border: AppColors.creamDivider,
    pressed: AppColors.creamPressed,
    hover: AppColors.creamHover,
    accentText: AppColors.accent400,
    accentTint: AppColors.accent900,
    accentSoft: AppColors.accent800,
    navIndicator: AppColors.accent800,
    onNavIndicator: AppColors.accent200,
    rowIcon: AppColors.sage300,
    success: AppColors.sage300,
    successTint: AppColors.sage900,
    successStrong: AppColors.sage200,
    successBanner: AppColors.sage900,
    warning: AppColors.accent300,
    warningTint: AppColors.accent900,
    danger: AppColors.accent200,
    dangerTint: AppColors.accent800,
    info: AppColors.neutral100,
    infoTint: AppColors.neutral700,
    selectedChip: AppColors.sage800,
    onSelectedChip: AppColors.sage100,
    skeleton: AppColors.neutral700,
    cardFill: AppColors.sage700,
    cardDecor: AppColors.sage600,
    onCard: AppColors.cream,
    qrBackground: AppColors.cream,
    qrInk: AppColors.ink,
    snackBackground: AppColors.neutral100,
    onSnack: AppColors.ink,
    shadows: [],
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      background: c(background, other.background),
      surface: c(surface, other.surface),
      surfaceHigh: c(surfaceHigh, other.surfaceHigh),
      text: c(text, other.text),
      textMuted: c(textMuted, other.textMuted),
      textSoft: c(textSoft, other.textSoft),
      border: c(border, other.border),
      pressed: c(pressed, other.pressed),
      hover: c(hover, other.hover),
      accentText: c(accentText, other.accentText),
      accentTint: c(accentTint, other.accentTint),
      accentSoft: c(accentSoft, other.accentSoft),
      navIndicator: c(navIndicator, other.navIndicator),
      onNavIndicator: c(onNavIndicator, other.onNavIndicator),
      rowIcon: c(rowIcon, other.rowIcon),
      success: c(success, other.success),
      successTint: c(successTint, other.successTint),
      successStrong: c(successStrong, other.successStrong),
      successBanner: c(successBanner, other.successBanner),
      warning: c(warning, other.warning),
      warningTint: c(warningTint, other.warningTint),
      danger: c(danger, other.danger),
      dangerTint: c(dangerTint, other.dangerTint),
      info: c(info, other.info),
      infoTint: c(infoTint, other.infoTint),
      selectedChip: c(selectedChip, other.selectedChip),
      onSelectedChip: c(onSelectedChip, other.onSelectedChip),
      skeleton: c(skeleton, other.skeleton),
      cardFill: c(cardFill, other.cardFill),
      cardDecor: c(cardDecor, other.cardDecor),
      onCard: c(onCard, other.onCard),
      qrBackground: c(qrBackground, other.qrBackground),
      qrInk: c(qrInk, other.qrInk),
      snackBackground: c(snackBackground, other.snackBackground),
      onSnack: c(onSnack, other.onSnack),
      shadows: t < 0.5 ? shadows : other.shadows,
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}
