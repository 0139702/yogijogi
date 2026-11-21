import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';

/// DESIGN_SYSTEM.md 기준의 앱 공통 테마. 화면에서 색을 직접 지정하지 않아도 되게 한다.
abstract final class AppTheme {
  static final light = _build();

  static ThemeData _build() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      primary: AppColors.brandStrong,
      secondaryContainer: AppColors.brandSoft,
      onSecondaryContainer: AppColors.brandStrong,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
    );
    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: AppColors.border),
    );
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    OutlineInputBorder inputBorder(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color),
    );

    return ThemeData(
      colorScheme: scheme,
      fontFamily: AppTextStyles.fontFamily,
      scaffoldBackgroundColor: AppColors.background,
      dividerColor: AppColors.border,
      textTheme: TextTheme(
        headlineSmall: AppTextStyles.title,
        titleLarge: AppTextStyles.title,
        titleMedium: AppTextStyles.body.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        titleSmall: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
        bodyLarge: AppTextStyles.body,
        bodyMedium: AppTextStyles.body,
        bodySmall: AppTextStyles.caption,
        labelLarge: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
        labelMedium: AppTextStyles.caption.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        titleTextStyle: AppTextStyles.title,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.brandSoft,
        surfaceTintColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.brand
                : AppColors.textSecondary,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? AppColors.brand
                : AppColors.textSecondary,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brandStrong,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 48),
          shape: buttonShape,
          textStyle: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brandStrong,
          backgroundColor: AppColors.surface,
          minimumSize: const Size(0, 48),
          side: const BorderSide(color: AppColors.border),
          shape: buttonShape,
          textStyle: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brandStrong,
          textStyle: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.brandSoft,
        checkmarkColor: AppColors.brandStrong,
        side: const BorderSide(color: AppColors.border),
        shape: const StadiumBorder(),
        labelStyle: AppTextStyles.body,
        secondaryLabelStyle: AppTextStyles.body.copyWith(
          color: AppColors.brandStrong,
          fontWeight: FontWeight.w700,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: cardShape,
        margin: const EdgeInsets.symmetric(vertical: 4),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.textSecondary,
        selectedColor: AppColors.brandStrong,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        labelStyle: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        border: inputBorder(AppColors.border),
        enabledBorder: inputBorder(AppColors.border),
        focusedBorder: inputBorder(AppColors.brand),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: AppTextStyles.title,
      ),
    );
  }
}
