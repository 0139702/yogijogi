import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yogijogi/features/mypage/my_page_screen.dart';
import 'package:yogijogi/features/mypage/my_report.dart';
import 'package:yogijogi/features/mypage/my_reports_repository.dart';

class _FixedRepository extends MyReportsRepository {
  _FixedRepository(this.result);

  final Future<MyReportsSnapshot> Function() result;

  @override
  Future<MyReportsSnapshot> fetchMyReports() => result();
}

Map<String, Object?> _reportJson({
  required String status,
  List<Map<String, String>> history = const [],
  Map<String, Object?>? response,
}) => {
  'id': 'r1',
  'type': '벌레 몬스터',
  'location': '중앙도서관 보관실 앞 (B1)',
  'description': '바퀴벌레를 봤어요.',
  'occurredAt': '2026-11-20T02:20:00Z',
  'status': status,
  'source': 'user_report',
  'updatedAt': '2026-11-20T05:00:00Z',
  'statusHistory': history,
  'staffResponse': response,
};

void main() {
  final now = DateTime(2026, 11, 20, 14);

  group('MyReport', () {
    test('maps backend status values to stages', () {
      expect(ReportStage.fromStatus('in_progress'), ReportStage.inProgress);
      expect(ReportStage.fromStatus('resolved'), ReportStage.resolved);
      expect(ReportStage.fromStatus('unknown'), ReportStage.received);
    });

    test('reads history and staff response from report JSON', () {
      final report = MyReport.fromJson(
        _reportJson(
          status: 'checking',
          history: [
            {'status': 'checking', 'changedAt': '2026-11-20T03:00:00Z'},
            {'status': 'received', 'changedAt': '2026-11-20T02:20:00Z'},
          ],
          response: {
            'department': '학생지원처',
            'message': '확인 중이에요.',
            'respondedAt': '2026-11-20T03:00:00Z',
            'isDemo': true,
          },
        ),
      );

      expect(report.stage, ReportStage.checking);
      expect(report.history.map((c) => c.stage), [
        ReportStage.received,
        ReportStage.checking,
      ]);
      expect(report.stageChangedAt, DateTime.utc(2026, 11, 20, 3));
      expect(report.staffResponse?.isDemo, isTrue);
      expect(report.staffResponse?.plan, isNull);
    });

    test('falls back to updatedAt when there is no history', () {
      final report = MyReport.fromJson(_reportJson(status: 'received'));
      expect(report.history, isEmpty);
      expect(report.staffResponse, isNull);
      expect(report.stageChangedAt, DateTime.utc(2026, 11, 20, 5));
    });

    test('demo data marks every staff response as demo', () async {
      final snapshot = await DemoMyReportsRepository(clock: () => now)
          .fetchMyReports();

      expect(snapshot.isDemo, isTrue);
      expect(snapshot.active, hasLength(2));
      expect(snapshot.resolved, hasLength(5));
      expect(
        snapshot.reports.every((r) => r.staffResponse?.isDemo ?? true),
        isTrue,
      );
      // 최근 상태 변경 순으로 정렬된다.
      expect(snapshot.active.first.report.id, 'demo-1');
      expect(snapshot.resolved.first.report.id, 'demo-3');
    });
  });

  group('MyPageScreen', () {
    Future<void> pump(WidgetTester tester, {MyReportsRepository? repo}) async {
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: MyPageScreen(repository: repo, clock: () => now),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows in-progress reports with stages and response', (
      tester,
    ) async {
      await pump(tester);

      expect(find.text('요기조기'), findsOneWidget);
      expect(find.text('내 제보 내역'), findsOneWidget);
      expect(find.textContaining('데모 데이터예요'), findsOneWidget);
      expect(find.text('진행 중'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);

      expect(find.text('중앙도서관 보관실 앞  B1'), findsOneWidget);
      expect(find.text('등록 11.20 · 11:20'), findsOneWidget);
      expect(find.text('조치 중 단계로 변경 · 11.20 13:10'), findsOneWidget);
      expect(find.text('학생지원처 · 담당자 답변'), findsOneWidget);
      expect(find.text('방역업체에 작업 지시를 전달했어요.'), findsOneWidget);
      expect(find.text('오늘 18:00 야간 방역 예정'), findsOneWidget);
      expect(find.text('가상 담당자 확인'), findsOneWidget);
      expect(find.text('데모'), findsOneWidget);
      // 실제로 전달되지 않았으므로 공식 이관처럼 표시하지 않는다.
      expect(find.textContaining('공식'), findsNothing);

      // 답변이 없는 제보
      expect(find.text('학생 제보'), findsOneWidget);
      expect(find.text('아직 담당자 답변이 없어요.'), findsOneWidget);

      expect(find.text('최근 완료된 제보'), findsOneWidget);
      expect(find.text('11.18 16:30 · 시설관리팀 답변 확인 (가상)'), findsOneWidget);
    });

    testWidgets('places each stage label under its dot', (tester) async {
      await pump(tester);

      Finder byType(String name) =>
          find.byWidgetPredicate((w) => w.runtimeType.toString() == name);
      // 첫 번째 카드의 단계 표시 안에서만 찾는다 ('완료' 탭 라벨과 구분).
      final progress = byType('_StageProgress').first;
      final dots = find.descendant(of: progress, matching: byType('_StageDot'));
      const labels = ['접수', '담당자 확인', '조치 중', '완료'];
      for (var i = 0; i < labels.length; i++) {
        final dotX = tester.getCenter(dots.at(i)).dx;
        final labelX = tester
            .getCenter(
              find.descendant(of: progress, matching: find.text(labels[i])),
            )
            .dx;
        expect(labelX, moreOrLessEquals(dotX, epsilon: 0.5), reason: labels[i]);
      }
    });

    testWidgets('switches to the completed tab', (tester) async {
      await pump(tester);

      await tester.tap(find.text('완료').first);
      await tester.pumpAndSettle();

      expect(find.text('조치 완료'), findsNWidgets(5));
      expect(find.text('최근 완료된 제보'), findsNothing);
      expect(find.text('중앙도서관 보관실 앞  B1'), findsNothing);
    });

    testWidgets('opens the stage history sheet', (tester) async {
      await pump(tester);

      await tester.tap(find.text('처리 상황 상세 보기 ›').first);
      await tester.pumpAndSettle();

      expect(find.text('처리 상황'), findsOneWidget);
      expect(find.text('11.20 11:45'), findsOneWidget);
      expect(find.text('대기'), findsOneWidget);
    });

    testWidgets('formats times in the campus time zone from the API', (
      tester,
    ) async {
      // 기기 시간대와 다른 오프셋(UTC+0)을 주어, 기기 시간대가 아니라
      // API가 알려준 캠퍼스 시간대로 표시하는지 확인한다.
      final snapshot = MyReportsSnapshot.fromJson({
        'items': [
          _reportJson(
            status: 'checking',
            history: [
              {'status': 'received', 'changedAt': '2026-11-20T02:20:00Z'},
              {'status': 'checking', 'changedAt': '2026-11-20T03:00:00Z'},
            ],
          ),
        ],
        'isDemo': true,
        'utcOffsetMinutes': 0,
      });
      await pump(tester, repo: _FixedRepository(() async => snapshot));

      expect(find.text('등록 11.20 · 02:20'), findsOneWidget);
      expect(find.text('담당자 확인 단계로 변경 · 11.20 03:00'), findsOneWidget);

      await tester.tap(find.text('처리 상황 상세 보기 ›'));
      await tester.pumpAndSettle();
      expect(find.text('11.20 03:00'), findsOneWidget);
    });

    testWidgets('shows empty states', (tester) async {
      await pump(
        tester,
        repo: _FixedRepository(
          () async => const MyReportsSnapshot(reports: [], isDemo: false),
        ),
      );

      expect(find.text('진행 중인 제보가 없어요.'), findsOneWidget);
      expect(find.textContaining('데모 데이터예요'), findsNothing);
    });

    testWidgets('shows an error with retry', (tester) async {
      var calls = 0;
      await pump(
        tester,
        repo: _FixedRepository(() async {
          calls++;
          if (calls == 1) throw StateError('offline');
          return const MyReportsSnapshot(reports: [], isDemo: false);
        }),
      );

      expect(find.text('내 제보를 불러오지 못했습니다.'), findsOneWidget);
      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();
      expect(find.text('진행 중인 제보가 없어요.'), findsOneWidget);
    });
  });
}
