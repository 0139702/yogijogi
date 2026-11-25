import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yogijogi/features/reports/report.dart';
import 'package:yogijogi/features/reports/report_api.dart';
import 'package:yogijogi/features/reports/reports_screen.dart';

class _FakeReportApi extends ReportApi {
  _FakeReportApi() : super(Uri.parse('http://127.0.0.1:3000'));

  int listCalls = 0;

  @override
  Future<List<Report>> list() async {
    listCalls++;
    return [
      Report.fromJson({
        'id': 'report-1',
        'type': '벌레 몬스터',
        'location': '수정관 (1F)',
        'description': '복도에서 봤어요.',
        'occurredAt': '2026-11-25T00:00:00Z',
        'status': 'received',
        'source': 'user_report',
        'updatedAt': '2026-11-25T00:00:00Z',
      }),
    ];
  }
}

void main() {
  testWidgets('pull to refresh reloads the feed and stops the spinner', (
    tester,
  ) async {
    final api = _FakeReportApi();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ReportsScreen(api: api)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.fling(find.byType(ListView).last, const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(api.listCalls, 2);
    expect(find.byType(RefreshProgressIndicator), findsNothing);
  });
}
