import 'package:flutter/material.dart';

import 'app_icons.dart';
import 'app_tokens.dart';

/// Material 3 themes built only from [AppColors], [AppSpace], [AppRadius]
/// and [AppFonts]. Light (cream and sand) is the default.
abstract final class AppTheme {
  static ThemeData get dark => _build(Brightness.dark, AppPalette.dark);
  static ThemeData get light => _build(Brightness.light, AppPalette.light);

  /// Full type scale. Caprasimo (one weight) for titles, headings and big
  /// numbers; Figtree for everything else.
  static TextTheme textTheme(Color text, Color muted) {
    TextStyle heading(double size, double height) => TextStyle(
          fontFamily: AppFonts.heading,
          fontSize: size,
          fontWeight: FontWeight.w400,
          height: height,
          color: text,
        );
    TextStyle body(double size, FontWeight weight, {Color? color, double height = 1.4}) =>
        TextStyle(
          fontFamily: AppFonts.body,
          fontSize: size,
          fontWeight: weight,
          height: height,
          color: color ?? text,
        );

    return TextTheme(
      displayLarge: heading(56, 1.05),
      displayMedium: heading(48, 1.05),
      displaySmall: heading(40, 1.1),
      headlineLarge: heading(30, 1.1),
      headlineMedium: heading(25, 1.1),
      headlineSmall: heading(23, 1.15),
      titleLarge: heading(21, 1.2),
      titleMedium: body(17, FontWeight.w700, height: 1.3),
      titleSmall: body(15, FontWeight.w600, height: 1.3),
      bodyLarge: body(16, FontWeight.w400),
      bodyMedium: body(15, FontWeight.w400),
      bodySmall: body(13, FontWeight.w400, color: muted),
      labelLarge: body(15, FontWeight.w600, height: 1),
      labelMedium: body(12, FontWeight.w600, height: 1.2),
      labelSmall: body(11, FontWeight.w600, height: 1.2),
    );
  }

  static ThemeData _build(Brightness brightness, AppPalette p) {
    final isDark = brightness == Brightness.dark;
    final text = textTheme(p.text, p.textMuted);
    final primary = isDark ? AppColors.accent400 : AppColors.accent;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: AppColors.ink,
      primaryContainer: p.accentTint,
      onPrimaryContainer: p.text,
      secondary: AppColors.sage,
      onSecondary: AppColors.ink,
      secondaryContainer: p.selectedChip,
      onSecondaryContainer: p.onSelectedChip,
      tertiary: p.success,
      onTertiary: p.successTint,
      error: p.danger,
      onError: p.dangerTint,
      errorContainer: p.dangerTint,
      onErrorContainer: p.danger,
      surface: p.background,
      onSurface: p.text,
      onSurfaceVariant: p.textMuted,
      surfaceContainerLowest: p.background,
      surfaceContainerLow: p.background,
      surfaceContainer: p.surface,
      surfaceContainerHigh: p.surface,
      surfaceContainerHighest: p.surfaceHigh,
      outline: p.border,
      outlineVariant: p.border,
      shadow: AppColors.neutral900,
      scrim: AppColors.scrim,
      surfaceTint: AppColors.transparent,
    );

    const pill = StadiumBorder();
    const minButton = Size(AppSizes.minTouch, AppSizes.minTouch);
    const buttonPadding = EdgeInsets.symmetric(horizontal: AppSpace.gutter);
    final focusRing = BorderSide(color: primary, width: 2);
    final divider = BorderSide(color: p.border, width: 1.5);

    // Pressed and hover tints come from the ramps; no ripple, no scale.
    WidgetStateProperty<Color?> overlay(Color hover, Color pressed) =>
        WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.pressed)) return pressed;
          if (s.contains(WidgetState.hovered) || s.contains(WidgetState.focused)) return hover;
          return null;
        });

    final primaryStyle = ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.disabled)) return isDark ? AppColors.neutral700 : AppColors.neutral300;
        if (s.contains(WidgetState.pressed)) return AppColors.accent700;
        if (s.contains(WidgetState.hovered)) return isDark ? AppColors.accent500 : AppColors.accent600;
        return primary;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.disabled)) return isDark ? AppColors.neutral200 : AppColors.neutral700;
        if (s.contains(WidgetState.pressed)) return AppColors.cream;
        return AppColors.ink;
      }),
      overlayColor: const WidgetStatePropertyAll(AppColors.transparent),
      elevation: const WidgetStatePropertyAll(0),
      minimumSize: const WidgetStatePropertyAll(minButton),
      padding: const WidgetStatePropertyAll(buttonPadding),
      shape: const WidgetStatePropertyAll(pill),
      textStyle: WidgetStatePropertyAll(text.labelLarge),
      iconSize: const WidgetStatePropertyAll(AppSizes.iconRow),
      side: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.focused) ? focusRing : null,
      ),
      animationDuration: AppMotion.fast,
    );

    OutlineInputBorder inputBorder(Color color, [double width = 1.5]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.input / 2),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      textTheme: text,
      fontFamily: AppFonts.body,
      scaffoldBackgroundColor: p.background,
      canvasColor: p.background,
      dividerColor: p.border,
      splashFactory: NoSplash.splashFactory,
      highlightColor: p.pressed,
      hoverColor: p.hover,
      focusColor: p.hover,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      iconTheme: IconThemeData(color: p.text, size: AppSizes.icon),
      extensions: [p],
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.text,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.headlineLarge,
      ),
      filledButtonTheme: FilledButtonThemeData(style: primaryStyle),
      elevatedButtonTheme: ElevatedButtonThemeData(style: primaryStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled) ? p.textMuted : p.text,
          ),
          overlayColor: overlay(p.hover, p.pressed),
          side: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.focused) ? focusRing : divider,
          ),
          minimumSize: const WidgetStatePropertyAll(minButton),
          padding: const WidgetStatePropertyAll(buttonPadding),
          shape: const WidgetStatePropertyAll(pill),
          textStyle: WidgetStatePropertyAll(text.labelLarge),
          iconSize: const WidgetStatePropertyAll(AppSizes.iconRow),
          animationDuration: AppMotion.fast,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled) ? p.textMuted : p.accentText,
          ),
          overlayColor: overlay(p.accentTint, p.accentSoft),
          minimumSize: const WidgetStatePropertyAll(minButton),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12)),
          shape: const WidgetStatePropertyAll(pill),
          textStyle: WidgetStatePropertyAll(text.labelLarge),
          iconSize: const WidgetStatePropertyAll(AppSizes.iconRow),
          side: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.focused) ? focusRing : null,
          ),
          animationDuration: AppMotion.fast,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled) ? p.textMuted.withValues(alpha: 0.5) : p.text,
          ),
          overlayColor: overlay(p.hover, p.pressed),
          minimumSize: const WidgetStatePropertyAll(minButton),
          iconSize: const WidgetStatePropertyAll(AppSizes.icon),
          shape: const WidgetStatePropertyAll(pill),
          side: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.focused) ? focusRing : null,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: AppColors.ink,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: pill,
        extendedTextStyle: text.labelLarge,
        splashColor: AppColors.transparent,
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        surfaceTintColor: AppColors.transparent,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        shadowColor: AppColors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        // Dark muted text needs the darker ground to reach 4.5:1.
        fillColor: isDark ? p.background : p.surfaceHigh,
        // Labels sit above the field (see LabeledField), never inside.
        floatingLabelBehavior: FloatingLabelBehavior.never,
        hintStyle: text.bodyLarge?.copyWith(color: p.textMuted),
        helperStyle: text.bodySmall,
        helperMaxLines: 3,
        errorStyle: text.bodySmall?.copyWith(color: p.danger, fontWeight: FontWeight.w600),
        errorMaxLines: 3,
        prefixIconColor: p.textMuted,
        suffixIconColor: p.textMuted,
        constraints: const BoxConstraints(minHeight: AppSizes.input),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: 15),
        border: inputBorder(p.border),
        enabledBorder: inputBorder(p.border),
        disabledBorder: inputBorder(p.border.withValues(alpha: p.border.a * 0.5)),
        focusedBorder: inputBorder(primary, 2),
        errorBorder: inputBorder(p.danger),
        focusedErrorBorder: inputBorder(p.danger, 2),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: primary,
        selectionColor: p.accentSoft,
        selectionHandleColor: primary,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.background,
        surfaceTintColor: AppColors.transparent,
        modalBackgroundColor: p.background,
        modalBarrierColor: AppColors.scrim,
        elevation: 0,
        modalElevation: 0,
        showDragHandle: true,
        dragHandleColor: isDark ? AppColors.neutral600 : AppColors.neutral400,
        dragHandleSize: const Size(40, 5),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.background,
        surfaceTintColor: AppColors.transparent,
        barrierColor: AppColors.scrim,
        titleTextStyle: text.headlineSmall,
        contentTextStyle: text.bodyLarge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sheet)),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: p.background,
        surfaceTintColor: AppColors.transparent,
        headerHeadlineStyle: text.headlineSmall,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sheet)),
        dayShape: const WidgetStatePropertyAll(StadiumBorder()),
        todayBorder: BorderSide(color: primary, width: 1.5),
        dayForegroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.ink : null,
        ),
        dayBackgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? primary : null,
        ),
        cancelButtonStyle: const ButtonStyle(shape: WidgetStatePropertyAll(pill)),
        confirmButtonStyle: const ButtonStyle(shape: WidgetStatePropertyAll(pill)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: p.surfaceHigh,
        surfaceTintColor: AppColors.transparent,
        elevation: isDark ? 0 : 3,
        shadowColor: AppColors.neutral900.withValues(alpha: 0.3),
        textStyle: text.bodyLarge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.tile)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: AppColors.transparent,
        indicatorColor: p.navIndicator,
        indicatorShape: const StadiumBorder(),
        elevation: 0,
        height: 72,
        overlayColor: const WidgetStatePropertyAll(AppColors.transparent),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            size: AppSizes.icon,
            color: s.contains(WidgetState.selected) ? p.onNavIndicator : p.textMuted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => text.labelMedium?.copyWith(
            color: s.contains(WidgetState.selected) ? p.text : p.textMuted,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? p.surface : p.surfaceHigh,
        selectedColor: p.selectedChip,
        disabledColor: p.surface,
        checkmarkColor: p.onSelectedChip,
        showCheckmark: true,
        labelStyle: text.labelLarge?.copyWith(color: p.text, height: 1.2),
        secondaryLabelStyle: text.labelLarge?.copyWith(color: p.onSelectedChip, height: 1.2),
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.sm),
        shape: const StadiumBorder(),
        side: WidgetStateBorderSide.resolveWith(
          (s) => s.contains(WidgetState.selected) ? BorderSide.none : divider,
        ),
        color: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) return p.selectedChip;
          if (s.contains(WidgetState.pressed)) return isDark ? p.surfaceHigh : AppColors.accent200;
          return isDark ? p.surface : p.surfaceHigh;
        }),
        iconTheme: IconThemeData(color: p.onSelectedChip, size: AppSizes.iconBadge),
        elevation: 0,
        pressElevation: 0,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(pill),
          side: WidgetStatePropertyAll(divider),
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? p.selectedChip : AppColors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? p.onSelectedChip : p.text,
          ),
          textStyle: WidgetStatePropertyAll(text.labelLarge),
          minimumSize: const WidgetStatePropertyAll(minButton),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.snackBackground,
        contentTextStyle: text.bodyMedium?.copyWith(color: p.onSnack),
        actionTextColor: isDark ? AppColors.accent700 : AppColors.accent300,
        elevation: isDark ? 0 : 6,
        insetPadding: const EdgeInsets.fromLTRB(AppSpace.md, 0, AppSpace.md, AppSpace.md),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.snack)),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: p.accentText,
        textColor: p.text,
        titleTextStyle: text.titleSmall,
        subtitleTextStyle: text.bodySmall,
        minVerticalPadding: AppSpace.sm,
        minTileHeight: 56,
        horizontalTitleGap: 14,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        iconColor: p.textMuted,
        collapsedIconColor: p.textMuted,
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
      ),
      dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: isDark ? p.surfaceHigh : AppColors.neutral300,
        linearMinHeight: 8,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        circularTrackColor: AppColors.transparent,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: isDark ? p.surfaceHigh : AppColors.neutral300,
        thumbColor: primary,
        overlayColor: p.accentTint,
        valueIndicatorColor: p.snackBackground,
        valueIndicatorTextStyle: text.labelLarge?.copyWith(color: p.onSnack),
        trackHeight: 8,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.ink : p.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? primary : p.background,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? primary : p.textMuted,
        ),
        trackOutlineWidth: const WidgetStatePropertyAll(1.5),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.accentText : p.textMuted,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.accentText : AppColors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(p.background),
        side: BorderSide(color: p.textMuted, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      actionIconTheme: ActionIconThemeData(
        backButtonIconBuilder: (_) => const AppIcon(AppIcons.arrowLeft),
        closeButtonIconBuilder: (_) => const AppIcon(AppIcons.x),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
