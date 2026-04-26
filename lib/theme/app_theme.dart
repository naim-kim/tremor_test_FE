import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static const double minTapHeight = 52;

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.teal800,
      brightness: Brightness.light,
      primary: AppColors.teal800,
      secondary: AppColors.amber600,
      surface: AppColors.white,
      error: AppColors.error600,
      onPrimary: Colors.white,
      onSecondary: AppColors.gray900,
      onSurface: AppColors.gray900,
      onError: Colors.white,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.white,
      fontFamily: 'NotoSansKR',
    );

    return base.copyWith(
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: AppColors.teal800,
        foregroundColor: Colors.white,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
          color: Colors.white,
          fontFamily: 'NotoSansKR',
        ),
      ),
      textTheme: base.textTheme.copyWith(
        // Korean-optimized scale
        displaySmall: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w500,
          color: AppColors.teal800,
        ),
        headlineSmall: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: AppColors.teal800,
        ),
        bodyLarge: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          color: AppColors.gray900,
        ),
        bodyMedium: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          color: AppColors.gray900,
        ),
        labelMedium: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColors.gray900,
        ),
      ),
      cardTheme: base.cardTheme.copyWith(
        color: AppColors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: base.snackBarTheme.copyWith(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.gray900,
        contentTextStyle: const TextStyle(fontSize: 16, color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: const TextStyle(fontSize: 17, color: AppColors.gray400),
        labelStyle: const TextStyle(fontSize: 17, color: AppColors.gray900),
        errorStyle: const TextStyle(fontSize: 15, height: 1.2),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: AppColors.gray400.withOpacity(0.35), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.teal400, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error600, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error600, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, minTapHeight),
          backgroundColor: AppColors.teal800,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, minTapHeight),
          foregroundColor: AppColors.teal800,
          side: const BorderSide(color: AppColors.teal800, width: 1.5),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, minTapHeight),
          foregroundColor: AppColors.teal800,
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        side: BorderSide(color: AppColors.gray400.withOpacity(0.25)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }
}
