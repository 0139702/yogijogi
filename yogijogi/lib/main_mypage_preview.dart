import 'package:material_ui/material_ui.dart';

import 'core/app_colors.dart';
import 'features/mypage/my_page_screen.dart';

/// 마이페이지만 단독으로 확인하기 위한 개발용 진입점.
///
/// 앱 내장 데모 데이터로 실행:
///   flutter run -t lib/main_mypage_preview.dart
/// 로컬 마이페이지 API로 실행(backend에서 npm start 후):
///   flutter run -t lib/main_mypage_preview.dart
///     --dart-define-from-file=config/android.example.json
void main() => runApp(
  MaterialApp(
    title: '요기조기 마이페이지 미리보기',
    debugShowCheckedModeBanner: false,
    // 앱 테마(lib/app.dart)와 같은 설정을 사용한다.
    theme: ThemeData(
      fontFamily: 'Pretendard',
      colorSchemeSeed: AppColors.brand,
      scaffoldBackgroundColor: AppColors.background,
    ),
    home: const MyPageScreen(),
  ),
);
