import 'package:material_ui/material_ui.dart';

import 'features/classroom/classroom_detail_screen.dart';

/// 강의실 상세 화면만 단독으로 확인하기 위한 개발용 진입점.
///
/// 샘플 데이터로 실행:
///   flutter run -t lib/main_classroom_preview.dart
/// 로컬 강의실 API로 실행(backend에서 npm start 후):
///   flutter run -t lib/main_classroom_preview.dart
///     --dart-define-from-file=config/android.example.json
void main() => runApp(
  const MaterialApp(
    title: '요기조기 강의실 상세 미리보기',
    debugShowCheckedModeBanner: false,
    home: ClassroomDetailScreen(),
  ),
);
