import 'package:material_ui/material_ui.dart';

abstract final class AppColors {
  static const brand = Color(0xFF696FB8);
  static const brandStrong = Color(0xFF50569A);
  static const brandSoft = Color(0xFFECECF8);
  static const accentMint = Color(0xFF9CCDBB);
  static const accentCoral = Color(0xFFF29A8C);
  static const background = Color(0xFFF7F8FC);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF1B2438);
  static const textSecondary = Color(0xFF737D92);
  static const border = Color(0xFFE3E6EF);

  static const hazard = Color(0xFFD95757);
  static const smoking = Color(0xFFE8894A);
  static const event = Color(0xFF568F83);
  static const resolved = Color(0xFF4F8A70);
}

abstract final class AppTextStyles {
  static const title = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  static const body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );
  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w300,
    color: AppColors.textSecondary,
  );
}

abstract final class AppSpacing {
  static const screenPadding = 16.0;
  static const elementGapHorizontal = 10.0;
}
