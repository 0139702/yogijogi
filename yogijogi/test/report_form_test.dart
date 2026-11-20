import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yogijogi/core/app_colors.dart';
import 'package:yogijogi/features/reports/report.dart';
import 'package:yogijogi/features/reports/report_api.dart';
import 'package:yogijogi/features/reports/report_category.dart';
import 'package:yogijogi/features/reports/report_form_screen.dart';

void main() {
  test('reads photo URLs and tolerates reports without photos', () {
    final json = <String, dynamic>{
      'id': 'r1',
      'type': '벌레 몬스터',
      'location': '학생회관 (1F)',
      'description': '설명',
      'occurredAt': '2026-11-20T08:00:00Z',
      'status': 'received',
      'source': 'user_report',
      'updatedAt': '2026-11-20T08:00:00Z',
    };
    expect(Report.fromJson(json).photos, isEmpty);

    final report = Report.fromJson({
      ...json,
      'photos': [
        {'id': 'p1', 'url': 'http://localhost:3000/_local/photos/a'},
      ],
    });
    expect(report.photos.single.id, 'p1');
    expect(report.photos.single.url.path, '/_local/photos/a');
  });

  test('keeps the floor inside the saved location', () {
    final location = ReportLocation.parse(
      const ReportLocation('사회과학관 동편 복도', '2F').encode(),
    );
    expect(location.place, '사회과학관 동편 복도');
    expect(location.floor, '2F');
    expect(ReportLocation.parse('정문 앞').floor, isNull);
  });

  testWidgets('asks for a category before saving', (tester) async {
    tester.view
      ..physicalSize = const Size(1179, 2556)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final api = ReportApi(null);
    addTearDown(api.close);
    await tester.pumpWidget(MaterialApp(home: ReportFormScreen(api: api)));

    await tester.tap(find.text('제보 등록하기'));
    await tester.pump();

    expect(find.text('어떤 상황인지 선택해 주세요.'), findsOneWidget);
  });

  testWidgets('keeps Pretendard on buttons with a custom text style', (
    tester,
  ) async {
    final api = ReportApi(null);
    addTearDown(api.close);
    await tester.pumpWidget(MaterialApp(home: ReportFormScreen(api: api)));

    final label = tester.widget<RichText>(
      find.descendant(
        of: find.text('제보 등록하기'),
        matching: find.byType(RichText),
      ),
    );
    expect(label.text.style?.fontFamily, AppTextStyles.fontFamily);
  });
}
