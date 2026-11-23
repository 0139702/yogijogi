import 'classroom.dart';

/// 강의실 상세 데이터를 가져오는 저장소.
///
/// API 주소가 설정되어 있으면 `ApiClassroomRepository`를, 없으면
/// [SampleClassroomRepository]를 사용한다.
abstract class ClassroomRepository {
  Future<ClassroomDetail> fetchDetail(String classroomId);

  /// 저장소가 사용하는 연결 등 자원을 정리한다.
  void close() {}
}

/// 데모용 샘플 데이터 저장소. 실제 시간표·제보와 연동되지 않는다.
class SampleClassroomRepository extends ClassroomRepository {
  SampleClassroomRepository({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  static const sampleClassroomId = 'eng2-204';

  @override
  Future<ClassroomDetail> fetchDetail(String classroomId) async {
    final now = _clock();
    final today = DateTime(now.year, now.month, now.day);
    DateTime at(int hour) => today.add(Duration(hours: hour));

    return ClassroomDetail(
      id: classroomId,
      buildingName: '공학관 2호관',
      roomName: '204호 멀티미디어실',
      // 실제 위치·경로 데이터가 없으므로 도보 시간은 제공하지 않는다.
      walkingMinutes: null,
      facilities: const ['콘센트 전좌석', '빔프로젝터', 'Wi-Fi 6', '냉난방 가동'],
      schedule: [
        ClassSession(title: '컴퓨터그래픽스', start: at(10), end: at(12)),
        ClassSession(
          title: '공강 / 자율 개방',
          start: at(12),
          end: at(14),
          isOpenUse: true,
        ),
        ClassSession(title: '모바일UX디자인', start: at(14), end: at(16)),
      ],
      recentReports: [
        SpaceReport(
          id: 'sample-report-1',
          description: '에어컨 바람이 조금 약해요',
          source: 'user_report',
          status: 'received',
          reportedAt: now.subtract(const Duration(minutes: 30)),
        ),
      ],
      updatedAt: today.add(const Duration(hours: 9)),
      isSample: true,
    );
  }
}
