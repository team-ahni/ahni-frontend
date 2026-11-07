import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// AHNI 색 토큰. 강조색은 인하대 출신을 드러내는 AHNI 파랑이다.
/// 화면 코드는 이 값을 직접 쓰지 않고 `Theme.of(context).colorScheme`으로 읽는다.
abstract final class AppColors {
  static const canvas = Color(0xFFF7F8FA);
  static const subtle = Color(0xFFEEF1F4);
  static const line = Color(0xFFDDE2E8);
  static const muted = Color(0xFF9AA3AE);
  static const supportingText = Color(0xFF646E7A);
  static const secondaryText = Color(0xFF5B6470);
  static const primaryText = Color(0xFF18202A);
  static const inverse = Color(0xFF2A323D);
  static const accent = Color(0xFF1558A6);
  static const accentSoft = Color(0xFFEAF2FC);
  static const accentStrong = Color(0xFF0F4A8C);
  static const danger = Color(0xFFD63B3B);
  static const dangerSoft = Color(0xFFFDECEC);
  static const dangerStrong = Color(0xFFA52A2A);
}

ThemeData buildAppTheme() {
  final colorScheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColors.accent,
        onPrimary: Colors.white,
        primaryContainer: AppColors.accentSoft,
        onPrimaryContainer: AppColors.primaryText,
        secondaryContainer: AppColors.subtle,
        onSecondaryContainer: AppColors.primaryText,
        surface: Colors.white,
        onSurface: AppColors.primaryText,
        onSurfaceVariant: AppColors.secondaryText,
        outline: AppColors.line,
        outlineVariant: AppColors.line,
        surfaceTint: Colors.transparent,
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: AppColors.canvas,
        surfaceContainer: AppColors.canvas,
        surfaceContainerHigh: AppColors.subtle,
        surfaceContainerHighest: AppColors.subtle,
        error: AppColors.danger,
        onError: Colors.white,
        errorContainer: AppColors.dangerSoft,
        onErrorContainer: AppColors.dangerStrong,
      );

  final buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  );
  final fieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: AppColors.line),
  );

  // 컴포넌트 글꼴은 테마 textTheme에서 파생해 플랫폼 기본 글꼴과 섞이지 않게 한다.
  final base = ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.canvas,
    canvasColor: Colors.white,
    dividerColor: AppColors.line,
    textTheme: _textTheme,
  );
  final text = base.textTheme;
  final label = text.labelLarge!;

  return base.copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.canvas,
      foregroundColor: AppColors.primaryText,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: text.titleLarge,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.canvas,
      hintStyle: text.bodyLarge!.copyWith(color: AppColors.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: fieldBorder,
      enabledBorder: fieldBorder,
      disabledBorder: fieldBorder,
      focusedBorder: fieldBorder.copyWith(
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
      errorBorder: fieldBorder.copyWith(
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: fieldBorder.copyWith(
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(44, 56),
        shape: buttonShape,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        disabledBackgroundColor: AppColors.line,
        disabledForegroundColor: AppColors.muted,
        textStyle: label.copyWith(fontSize: 17),
      ),
    ),
    // 보조 버튼은 테두리 없이 옅은 강조색 면으로 구분한다. 회색 배경과 흰 카드 모두에서 보인다.
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(44, 48),
        backgroundColor: AppColors.accentSoft,
        foregroundColor: AppColors.accentStrong,
        disabledBackgroundColor: AppColors.subtle,
        disabledForegroundColor: AppColors.muted,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: label.copyWith(fontSize: 15),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(44, 44),
        foregroundColor: AppColors.accent,
        textStyle: label.copyWith(fontSize: 15),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: AppColors.secondaryText),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 64,
      indicatorColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => label.copyWith(
          fontSize: 12,
          letterSpacing: 0,
          color: states.contains(WidgetState.selected)
              ? AppColors.primaryText
              : AppColors.supportingText,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 24,
          color: states.contains(WidgetState.selected)
              ? AppColors.primaryText
              : AppColors.supportingText,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.subtle,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      labelStyle: label.copyWith(fontSize: 13, color: AppColors.secondaryText),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.inverse,
      contentTextStyle: text.bodyMedium!.copyWith(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: text.titleLarge,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.accent,
      linearTrackColor: AppColors.subtle,
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
  );
}

const _textTheme = TextTheme(
  headlineMedium: TextStyle(
    color: AppColors.primaryText,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 32 / 24,
    letterSpacing: -0.5,
  ),
  titleLarge: TextStyle(
    color: AppColors.primaryText,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.4,
    letterSpacing: -0.4,
  ),
  titleMedium: TextStyle(
    color: AppColors.primaryText,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: _tight,
  ),
  bodyLarge: TextStyle(
    color: AppColors.secondaryText,
    fontSize: 16,
    height: 1.5,
    letterSpacing: _tight,
  ),
  bodyMedium: TextStyle(
    color: AppColors.primaryText,
    fontSize: 15,
    height: 1.45,
    letterSpacing: _tight,
  ),
  bodySmall: TextStyle(
    color: AppColors.supportingText,
    fontSize: 13,
    height: 1.45,
    letterSpacing: -0.1,
  ),
  labelLarge: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: _tight,
  ),
);

/// 한글 본문 자간을 살짝 좁혀 단어 덩어리가 잘 읽히게 한다.
const _tight = -0.3;
