/// 강의실 상세 화면에서 사용하는 데이터 모델.
///
/// 백엔드 API가 준비되면 같은 필드 이름의 JSON을 [ClassroomDetail.fromJson]으로
/// 읽어 사용할 수 있도록 구성한다.
class ClassroomDetail {
  const ClassroomDetail({
    required this.id,
    required this.buildingName,
    required this.roomName,
    required this.walkingMinutes,
    required this.facilities,
    required this.schedule,
    required this.recentReports,
    required this.updatedAt,
    required this.isSample,
    this.utcOffset,
  });

  ClassroomDetail.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      buildingName = json['buildingName'] as String,
      roomName = json['roomName'] as String,
      walkingMinutes = json['walkingMinutes'] as int?,
      facilities = (json['facilities'] as List<dynamic>).cast<String>(),
      schedule = (json['schedule'] as List<dynamic>)
          .map((item) => ClassSession.fromJson(item as Map<String, dynamic>))
          .toList(),
      recentReports = (json['recentReports'] as List<dynamic>)
          .map((item) => SpaceReport.fromJson(item as Map<String, dynamic>))
          .toList(),
      updatedAt = DateTime.parse(json['updatedAt'] as String),
      isSample = json['isSample'] as bool? ?? false,
      utcOffset = json['utcOffsetMinutes'] == null
          ? null
          : Duration(minutes: json['utcOffsetMinutes'] as int);

  final String id;
  final String buildingName;
  final String roomName;

  /// 현재 위치에서의 도보 시간(분). 위치 정보가 없으면 null.
  final int? walkingMinutes;
  final List<String> facilities;
  final List<ClassSession> schedule;
  final List<SpaceReport> recentReports;

  /// 시간표·시설 정보의 마지막 갱신 시각.
  final DateTime updatedAt;

  /// 실제 연동 데이터가 아닌 샘플 데이터인지 여부.
  final bool isSample;

  /// 캠퍼스 기준 시간대의 UTC 오프셋. 없으면 기기 시간대를 사용한다.
  final Duration? utcOffset;

  /// [time]을 캠퍼스 기준 시각으로 바꾼다. 표시용으로만 사용한다.
  DateTime toCampusTime(DateTime time) {
    final offset = utcOffset;
    return offset == null ? time.toLocal() : time.toUtc().add(offset);
  }

  /// [now] 시점에 진행 중인 시간표 항목.
  ClassSession? currentSession(DateTime now) {
    for (final session in schedule) {
      if (session.statusAt(now) == SessionStatus.ongoing) return session;
    }
    return null;
  }

  /// [now] 시점의 시간표 기준 이용 상태.
  ///
  /// 실시간 점유 센서가 없으므로 "수업이 없음"을 뜻할 뿐,
  /// 실제로 비어 있다는 보장은 아니다.
  RoomAvailability availabilityAt(DateTime now) {
    final current = currentSession(now);
    if (current != null) {
      return RoomAvailability(isFree: current.isOpenUse, until: current.end);
    }
    final upcoming =
        schedule
            .where(
              (session) => !session.start.isBefore(now) && !session.isOpenUse,
            )
            .toList()
          ..sort((a, b) => a.start.compareTo(b.start));
    return RoomAvailability(
      isFree: true,
      until: upcoming.isEmpty ? null : upcoming.first.start,
    );
  }

  /// [now] 기준으로 만료되지 않은 제보만 최신순으로 반환한다.
  List<SpaceReport> visibleReports(DateTime now) {
    return recentReports.where((report) => !report.isExpiredAt(now)).toList()
      ..sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
  }
}

class RoomAvailability {
  const RoomAvailability({required this.isFree, this.until});

  final bool isFree;

  /// 현재 상태가 유지되는 예정 시각. 이후 일정이 없으면 null.
  final DateTime? until;
}

enum SessionStatus { done, ongoing, upcoming }

class ClassSession {
  const ClassSession({
    required this.title,
    required this.start,
    required this.end,
    this.isOpenUse = false,
  });

  ClassSession.fromJson(Map<String, dynamic> json)
    : title = json['title'] as String,
      start = DateTime.parse(json['start'] as String).toLocal(),
      end = DateTime.parse(json['end'] as String).toLocal(),
      isOpenUse = json['isOpenUse'] as bool? ?? false;

  final String title;
  final DateTime start;
  final DateTime end;

  /// 수업이 없는 공강·자율 개방 시간인지 여부.
  final bool isOpenUse;

  SessionStatus statusAt(DateTime now) {
    if (!now.isBefore(end)) return SessionStatus.done;
    if (!now.isBefore(start)) return SessionStatus.ongoing;
    return SessionStatus.upcoming;
  }
}

class SpaceReport {
  const SpaceReport({
    required this.id,
    required this.description,
    required this.source,
    required this.status,
    required this.reportedAt,
  });

  SpaceReport.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      description = json['description'] as String,
      source = json['source'] as String,
      status = json['status'] as String,
      reportedAt = DateTime.parse(json['reportedAt'] as String).toLocal();

  /// 제보를 화면에 노출하는 최대 기간.
  static const visibleFor = Duration(hours: 24);

  final String id;
  final String description;

  /// 예: `user_report`(학생 제보), `staff_confirmed`(학교 확인).
  final String source;

  /// 예: `received`, `checking`, `in_progress`, `resolved`.
  final String status;
  final DateTime reportedAt;

  bool isExpiredAt(DateTime now) => now.difference(reportedAt) > visibleFor;
}
