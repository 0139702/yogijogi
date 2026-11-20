import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yogijogi/features/reports/report_api.dart';
import 'package:yogijogi/features/reports/report_category.dart';
import 'package:yogijogi/features/reports/report_form_screen.dart';

void main() {
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
}
