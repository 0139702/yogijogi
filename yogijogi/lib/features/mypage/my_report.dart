import '../reports/report.dart';

/// 제보 처리 단계. 마이페이지 단계 표시(접수 → 담당자 확인 → 조치 중 → 완료)에 사용한다.
enum ReportStage {
  received('received', '접수'),
  checking('checking', '담당자 확인'),
  inProgress('in_progress', '조치 중'),
  resolved('resolved', '완료');

  const ReportStage(this.status, this.label);

  /// 백엔드 `status` 값.
  final String status;
  final String label;

  /// 알 수 없는 상태는 가장 앞 단계인 접수로 취급한다.
  static ReportStage fromStatus(String status) => values.firstWhere(
    (stage) => stage.status == status,
    orElse: () => received,
  );
}

/// 처리 단계가 바뀐 기록.
class StageChange {
  const StageChange({required this.stage, required this.changedAt});

  StageChange.fromJson(Map<String, dynamic> json)
    : stage = ReportStage.fromStatus(json['status'] as String),
      changedAt = DateTime.parse(json['changedAt'] as String);

  final ReportStage stage;
  final DateTime changedAt;
}

/// 담당자 답변.
class StaffResponse {
  const StaffResponse({
    required this.department,
    required this.message,
    required this.respondedAt,
    required this.isDemo,
    this.plan,
  });

  StaffResponse.fromJson(Map<String, dynamic> json)
    : department = json['department'] as String,
      message = json['message'] as String,
      plan = json['plan'] as String?,
      respondedAt = DateTime.parse(json['respondedAt'] as String),
      isDemo = json['isDemo'] as bool? ?? false;

  final String department;
  final String message;

  /// 예정된 조치 안내. 없으면 null.
  final String? plan;
  final DateTime respondedAt;

  /// 실제 담당 부서가 아닌 가상 담당자의 답변인지 여부.
  /// 실제 부서와 연동되기 전에는 반드시 true로 표시한다.
  final bool isDemo;
}

/// 마이페이지에서 보여 주는 내 제보.
///
/// 기존 제보 모델 [Report]에 처리 단계 이력과 담당자 답변을 더한다.
/// API 응답은 제보 JSON에 `statusHistory`, `staffResponse` 필드가
/// 추가된 형태를 가정한다.
class MyReport {
  MyReport({
    required this.report,
    required List<StageChange> history,
    this.staffResponse,
  }) : history = List.unmodifiable(
         [...history]..sort((a, b) => a.changedAt.compareTo(b.changedAt)),
       );

  MyReport.fromJson(Map<String, dynamic> json)
    : this(
        report: Report.fromJson(json),
        history: (json['statusHistory'] as List<dynamic>? ?? const [])
            .map((item) => StageChange.fromJson(item as Map<String, dynamic>))
            .toList(),
        staffResponse: json['staffResponse'] == null
            ? null
            : StaffResponse.fromJson(
                json['staffResponse'] as Map<String, dynamic>,
              ),
      );

  final Report report;

  /// 시간순으로 정렬된 처리 단계 변경 기록.
  final List<StageChange> history;
  final StaffResponse? staffResponse;

  ReportStage get stage => ReportStage.fromStatus(report.status);

  bool get isResolved => stage == ReportStage.resolved;

  /// 현재 단계로 바뀐 시각. 기록이 없으면 제보 갱신 시각을 사용한다.
  DateTime get stageChangedAt {
    for (final change in history.reversed) {
      if (change.stage == stage) return change.changedAt;
    }
    return report.updatedAt;
  }
}

/// 마이페이지 데이터 묶음.
class MyReportsSnapshot {
  const MyReportsSnapshot({
    required this.reports,
    required this.isDemo,
    this.utcOffset,
  });

  /// `GET /me/reports` 응답을 읽는다.
  MyReportsSnapshot.fromJson(Map<String, dynamic> json)
    : reports = (json['items'] as List<dynamic>)
          .map((item) => MyReport.fromJson(item as Map<String, dynamic>))
          .toList(),
      isDemo = json['isDemo'] as bool? ?? false,
      utcOffset = json['utcOffsetMinutes'] == null
          ? null
          : Duration(minutes: json['utcOffsetMinutes'] as int);

  final List<MyReport> reports;

  /// 데모 데이터인지 여부. true면 화면에 데모 안내를 표시한다.
  final bool isDemo;

  /// 캠퍼스 기준 시간대의 UTC 오프셋. 없으면 기기 시간대로 표시한다.
  final Duration? utcOffset;

  /// 진행 중인 제보. 최근 상태 변경 순.
  List<MyReport> get active => _sorted(reports.where((r) => !r.isResolved));

  /// 처리 완료된 제보. 최근 완료 순.
  List<MyReport> get resolved => _sorted(reports.where((r) => r.isResolved));

  static List<MyReport> _sorted(Iterable<MyReport> reports) =>
      reports.toList()
        ..sort((a, b) => b.stageChangedAt.compareTo(a.stageChangedAt));
}
