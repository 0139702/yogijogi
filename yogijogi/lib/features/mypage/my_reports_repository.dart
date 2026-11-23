import '../reports/report_category.dart';
import 'my_report.dart';

/// 내 제보를 가져오는 저장소.
///
/// API 주소가 설정되어 있으면 `ApiMyReportsRepository`(`GET /me/reports`)를,
/// 없으면 [DemoMyReportsRepository]를 사용한다 (`createMyReportsRepository`).
abstract class MyReportsRepository {
  Future<MyReportsSnapshot> fetchMyReports();

  /// 저장소가 사용하는 연결 등 자원을 정리한다.
  void close() {}
}

/// 데모용 내 제보 저장소.
///
/// 실제 사용자·담당 부서와 연결되지 않은 예시 데이터다. 담당자 답변은
/// 모두 가상 답변(`isDemo: true`)으로 만든다.
class DemoMyReportsRepository extends MyReportsRepository {
  DemoMyReportsRepository({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  @override
  Future<MyReportsSnapshot> fetchMyReports() async {
    final now = _clock();
    final today = DateTime(now.year, now.month, now.day);
    DateTime daysAgo(int days, int hour, int minute) => today
        .subtract(Duration(days: days))
        .add(Duration(hours: hour, minutes: minute));

    final reports = [
      _report(
        id: 'demo-1',
        type: '벌레 몬스터',
        location: const ReportLocation('중앙도서관 보관실 앞', 'B1'),
        description: '보관실 앞 복도에서 바퀴벌레를 봤어요.',
        occurredAt: daysAgo(0, 11, 20),
        history: [
          (ReportStage.received, daysAgo(0, 11, 20)),
          (ReportStage.checking, daysAgo(0, 11, 45)),
          (ReportStage.inProgress, daysAgo(0, 13, 10)),
        ],
        response: {
          'department': '학생지원처',
          'message': '방역업체에 작업 지시를 전달했어요.',
          'plan': '오늘 18:00 야간 방역 예정',
          'respondedAt': daysAgo(0, 13, 10).toIso8601String(),
          'isDemo': true,
        },
      ),
      _report(
        id: 'demo-2',
        type: '비흡연구역 흡연',
        location: const ReportLocation('수정관 동편 계단', '1F'),
        description: '계단 출입구 근처에서 담배 냄새가 나요.',
        occurredAt: daysAgo(0, 9, 5),
        history: [(ReportStage.received, daysAgo(0, 9, 5))],
      ),
      _report(
        id: 'demo-3',
        type: '시설 고장 / 파손',
        location: const ReportLocation('과학관 정수기', '1F'),
        description: '정수기 아래로 물이 새고 있어요.',
        occurredAt: daysAgo(2, 10, 0),
        history: [
          (ReportStage.received, daysAgo(2, 10, 0)),
          (ReportStage.checking, daysAgo(2, 11, 30)),
          (ReportStage.inProgress, daysAgo(2, 14, 0)),
          (ReportStage.resolved, daysAgo(2, 16, 30)),
        ],
        response: {
          'department': '시설관리팀',
          'message': '정수기 배관을 교체했어요.',
          'respondedAt': daysAgo(2, 16, 30).toIso8601String(),
          'isDemo': true,
        },
      ),
      _report(
        id: 'demo-4',
        type: '기타 불편 / 제안',
        location: const ReportLocation('성신관 라운지', '2F'),
        description: '라운지 의자 몇 개가 흔들려요.',
        occurredAt: daysAgo(4, 15, 0),
        history: [
          (ReportStage.received, daysAgo(4, 15, 0)),
          (ReportStage.checking, daysAgo(4, 17, 0)),
          (ReportStage.resolved, daysAgo(3, 11, 0)),
        ],
        response: {
          'department': '시설관리팀',
          'message': '흔들리는 의자를 교체했어요.',
          'respondedAt': daysAgo(3, 11, 0).toIso8601String(),
          'isDemo': true,
        },
      ),
      _report(
        id: 'demo-5',
        type: '시설 고장 / 파손',
        location: const ReportLocation('수정관 강의실 복도 조명', '3F'),
        description: '복도 조명 하나가 깜빡거려요.',
        occurredAt: daysAgo(6, 9, 30),
        history: [
          (ReportStage.received, daysAgo(6, 9, 30)),
          (ReportStage.inProgress, daysAgo(6, 13, 0)),
          (ReportStage.resolved, daysAgo(5, 10, 0)),
        ],
        response: {
          'department': '시설관리팀',
          'message': '조명 안정기를 교체했어요.',
          'respondedAt': daysAgo(5, 10, 0).toIso8601String(),
          'isDemo': true,
        },
      ),
      _report(
        id: 'demo-6',
        type: '벌레 몬스터',
        location: const ReportLocation('난향관 식당 출입구', '1F'),
        description: '출입구 근처에 날벌레가 많아요.',
        occurredAt: daysAgo(9, 12, 10),
        history: [
          (ReportStage.received, daysAgo(9, 12, 10)),
          (ReportStage.checking, daysAgo(9, 15, 0)),
          (ReportStage.inProgress, daysAgo(8, 10, 0)),
          (ReportStage.resolved, daysAgo(7, 18, 0)),
        ],
        response: {
          'department': '학생지원처',
          'message': '출입구 주변 방역을 마쳤어요.',
          'respondedAt': daysAgo(7, 18, 0).toIso8601String(),
          'isDemo': true,
        },
      ),
      _report(
        id: 'demo-7',
        type: '비흡연구역 흡연',
        location: const ReportLocation('수정캠퍼스 정문 옆', null),
        description: '정문 옆 벤치 주변에 꽁초가 많아요.',
        occurredAt: daysAgo(12, 17, 40),
        history: [
          (ReportStage.received, daysAgo(12, 17, 40)),
          (ReportStage.checking, daysAgo(11, 9, 0)),
          (ReportStage.resolved, daysAgo(10, 14, 0)),
        ],
        response: {
          'department': '총무팀',
          'message': '금연 안내 표지를 추가로 설치했어요.',
          'respondedAt': daysAgo(10, 14, 0).toIso8601String(),
          'isDemo': true,
        },
      ),
    ];
    return MyReportsSnapshot(reports: reports, isDemo: true);
  }

  // 백엔드 응답과 같은 JSON 형태로 만들어 API 연동 시 같은 경로로 읽히게 한다.
  MyReport _report({
    required String id,
    required String type,
    required ReportLocation location,
    required String description,
    required DateTime occurredAt,
    required List<(ReportStage, DateTime)> history,
    Map<String, Object?>? response,
  }) {
    final (lastStage, lastChangedAt) = history.last;
    return MyReport.fromJson({
      'id': id,
      'type': type,
      'location': location.encode(),
      'description': description,
      'occurredAt': occurredAt.toIso8601String(),
      'status': lastStage.status,
      'source': 'user_report',
      'updatedAt': lastChangedAt.toIso8601String(),
      'statusHistory': [
        for (final (stage, changedAt) in history)
          {'status': stage.status, 'changedAt': changedAt.toIso8601String()},
      ],
      'staffResponse': response,
    });
  }
}
