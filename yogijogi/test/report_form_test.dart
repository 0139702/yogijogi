import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yogijogi/core/app_colors.dart';
import 'package:yogijogi/features/reports/report.dart';
import 'package:yogijogi/features/reports/report_api.dart';
import 'package:yogijogi/features/reports/report_category.dart';
import 'package:yogijogi/features/reports/report_form_screen.dart';

class _DeletingReportApi extends ReportApi {
  _DeletingReportApi() : super(null);

  final deleted = <String>[];

  @override
  Future<void> delete(String id) async => deleted.add(id);
}

final _formScrollable = find
    .descendant(
      of: find.byType(ListView).first,
      matching: find.byType(Scrollable),
    )
    .first;

Report _report(String status) => Report.fromJson({
  'id': 'r1',
  'type': '벌레 몬스터',
  'location': '학생회관 (1F)',
  'description': '설명',
  'occurredAt': '2026-11-20T08:00:00Z',
  'status': status,
  'source': 'user_report',
  'authorId': 'demo-1',
  'updatedAt': '2026-11-20T08:00:00Z',
});

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
    await tester.pumpWidget(
      MaterialApp(
        home: ReportFormScreen(api: api, initialLocation: '프라임관'),
      ),
    );
    expect(find.text('프라임관'), findsOneWidget);

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

  testWidgets('deletes my report after confirming', (tester) async {
    tester.view
      ..physicalSize = const Size(1179, 2556)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final api = _DeletingReportApi();
    Report? popped;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              popped = await Navigator.of(context).push<Report>(
                MaterialPageRoute(
                  builder: (_) =>
                      ReportFormScreen(api: api, report: _report('received')),
                ),
              );
            },
            child: const Text('열기'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('제보 삭제'),
      200,
      scrollable: _formScrollable,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('제보 삭제'));
    await tester.pumpAndSettle();
    expect(find.text('제보를 삭제할까요?'), findsOneWidget);

    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();

    expect(api.deleted, ['r1']);
    expect(popped?.id, 'r1');
  });

  testWidgets('hides delete once handling has started', (tester) async {
    tester.view
      ..physicalSize = const Size(1179, 2556)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final api = _DeletingReportApi();
    await tester.pumpWidget(
      MaterialApp(
        home: ReportFormScreen(api: api, report: _report('in_progress')),
      ),
    );

    await tester.scrollUntilVisible(
      find.text('처리가 시작된 제보는 삭제할 수 없어요.'),
      200,
      scrollable: _formScrollable,
    );
    await tester.pumpAndSettle();
    expect(find.text('제보 삭제'), findsNothing);
  });
}
