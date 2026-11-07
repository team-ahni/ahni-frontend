import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 토스 디자인 시스템(TDS)의 회색·파랑 단계를 따른 색 토큰.
/// 화면 코드는 이 값을 직접 쓰지 않고 `Theme.of(context).colorScheme`으로 읽는다.
abstract final class AppColors {
  static const grey50 = Color(0xFFF9FAFB);
  static const grey100 = Color(0xFFF2F4F6);
  static const grey200 = Color(0xFFE5E8EB);
  static const grey300 = Color(0xFFD1D6DB);
  static const grey400 = Color(0xFFB0B8C1);
  static const grey500 = Color(0xFF8B95A1);
  static const grey600 = Color(0xFF6B7684);
  static const grey700 = Color(0xFF4E5968);
  static const grey800 = Color(0xFF333D4B);
  static const grey900 = Color(0xFF191F28);
  static const blue50 = Color(0xFFE8F3FF);
  static const blue500 = Color(0xFF3182F6);
  static const blue700 = Color(0xFF1B64DA);
  static const red50 = Color(0xFFFFEEEE);
  static const red500 = Color(0xFFF04452);
  static const red700 = Color(0xFFD22030);
}

ThemeData buildAppTheme() {
  final colorScheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.blue500,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColors.blue500,
        onPrimary: Colors.white,
        primaryContainer: AppColors.blue50,
        onPrimaryContainer: AppColors.grey900,
        secondaryContainer: AppColors.grey100,
        onSecondaryContainer: AppColors.grey900,
        surface: Colors.white,
        onSurface: AppColors.grey900,
        onSurfaceVariant: AppColors.grey700,
        outline: AppColors.grey200,
        outlineVariant: AppColors.grey200,
        surfaceTint: Colors.transparent,
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: AppColors.grey50,
        surfaceContainer: AppColors.grey100,
        surfaceContainerHigh: AppColors.grey100,
        surfaceContainerHighest: AppColors.grey100,
        error: AppColors.red500,
        onError: Colors.white,
        errorContainer: AppColors.red50,
        onErrorContainer: AppColors.red700,
      );

  final buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  );
  final fieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: AppColors.grey200),
  );

  // 컴포넌트 글꼴은 테마 textTheme에서 파생해 플랫폼 기본 글꼴과 섞이지 않게 한다.
  final base = ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.grey100,
    canvasColor: Colors.white,
    dividerColor: AppColors.grey200,
    textTheme: _textTheme,
  );
  final text = base.textTheme;
  final label = text.labelLarge!;

  return base.copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.grey100,
      foregroundColor: AppColors.grey900,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: text.titleLarge,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.grey50,
      hintStyle: text.bodyLarge!.copyWith(color: AppColors.grey400),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: fieldBorder,
      enabledBorder: fieldBorder,
      disabledBorder: fieldBorder,
      focusedBorder: fieldBorder.copyWith(
        borderSide: const BorderSide(color: AppColors.blue500, width: 1.5),
      ),
      errorBorder: fieldBorder.copyWith(
        borderSide: const BorderSide(color: AppColors.red500),
      ),
      focusedErrorBorder: fieldBorder.copyWith(
        borderSide: const BorderSide(color: AppColors.red500, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(44, 56),
        shape: buttonShape,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        disabledBackgroundColor: AppColors.grey200,
        disabledForegroundColor: AppColors.grey400,
        textStyle: label.copyWith(fontSize: 17),
      ),
    ),
    // 토스의 weak 버튼처럼 테두리 없이 옅은 파랑 면으로 구분한다. 회색 배경과 흰 카드 모두에서 보인다.
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(44, 48),
        backgroundColor: AppColors.blue50,
        foregroundColor: AppColors.blue700,
        disabledBackgroundColor: AppColors.grey100,
        disabledForegroundColor: AppColors.grey400,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: label.copyWith(fontSize: 15),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(44, 44),
        foregroundColor: AppColors.blue500,
        textStyle: label.copyWith(fontSize: 15),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: AppColors.grey700),
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
              ? AppColors.grey900
              : AppColors.grey400,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 24,
          color: states.contains(WidgetState.selected)
              ? AppColors.grey900
              : AppColors.grey400,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.grey200,
      thickness: 1,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.grey100,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      labelStyle: label.copyWith(fontSize: 13, color: AppColors.grey700),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.grey800,
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
      color: AppColors.blue500,
      linearTrackColor: AppColors.grey100,
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
  );
}

const _textTheme = TextTheme(
  headlineMedium: TextStyle(
    color: AppColors.grey900,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    height: 1.35,
    letterSpacing: -0.6,
  ),
  titleLarge: TextStyle(
    color: AppColors.grey900,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.4,
    letterSpacing: -0.4,
  ),
  titleMedium: TextStyle(
    color: AppColors.grey900,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: _tight,
  ),
  bodyLarge: TextStyle(
    color: AppColors.grey700,
    fontSize: 16,
    height: 1.5,
    letterSpacing: _tight,
  ),
  bodyMedium: TextStyle(
    color: AppColors.grey900,
    fontSize: 15,
    height: 1.45,
    letterSpacing: _tight,
  ),
  bodySmall: TextStyle(
    color: AppColors.grey600,
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

/// 토스처럼 한글 본문 자간을 살짝 좁힌다.
const _tight = -0.3;
