import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yogijogi/features/classroom/classroom.dart';
import 'package:yogijogi/features/classroom/classroom_detail_screen.dart';
import 'package:yogijogi/features/classroom/classroom_repository.dart';

class _FixedRepository extends ClassroomRepository {
  _FixedRepository(this.detail);

  final ClassroomDetail detail;

  @override
  Future<ClassroomDetail> fetchDetail(String classroomId) async => detail;
}

void main() {
  Future<void> pumpScreen(
    WidgetTester tester,
    DateTime now, {
    ValueChanged<ClassroomDetail>? onDirections,
  }) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: ClassroomDetailScreen(
          clock: () => now,
          onDirections: onDirections,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows classroom detail sections with sample data', (
    tester,
  ) async {
    await pumpScreen(tester, DateTime(2026, 11, 20, 12, 30));

    expect(find.text('공학관 2호관'), findsOneWidget);
    expect(find.text('204호 멀티미디어실'), findsOneWidget);
    expect(find.textContaining('도보'), findsNothing);
    expect(find.text('현재 비어있음'), findsOneWidget);
    expect(find.text('14:00까지 자유 이용 가능'), findsOneWidget);
    expect(find.textContaining('샘플 데이터'), findsOneWidget);
    expect(find.text('콘센트 전좌석'), findsOneWidget);
    expect(find.text('Wi-Fi 6'), findsOneWidget);
    expect(find.text('완료'), findsOneWidget);
    expect(find.text('지금'), findsOneWidget);
    expect(find.text('예정'), findsOneWidget);
    expect(find.text('에어컨 바람이 조금 약해요'), findsOneWidget);
    expect(find.text('학생 제보 · 30분 전 · 접수'), findsOneWidget);
    expect(find.text('이 강의실로 길찾기'), findsOneWidget);
  });

  testWidgets('map preview fills the screen width', (tester) async {
    await pumpScreen(tester, DateTime(2026, 11, 20, 12, 30));

    final size = tester.getSize(
      find.byKey(const ValueKey('classroom-map-preview')),
    );
    expect(size.width, 390);
  });

  testWidgets('formats API times in campus time zone', (tester) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final detail = ClassroomDetail.fromJson({
      'id': 'eng2-204',
      'buildingName': '공학관 2호관',
      'roomName': '204호 멀티미디어실',
      'walkingMinutes': null,
      'facilities': <String>[],
      'schedule': [
        {
          'title': '모바일UX디자인',
          'start': '2026-11-20T14:00:00+09:00',
          'end': '2026-11-20T16:00:00+09:00',
        },
      ],
      'recentReports': <Object>[],
      'updatedAt': '2026-11-20T09:00:00+09:00',
      'utcOffsetMinutes': 540,
      'isSample': true,
    });
    await tester.pumpWidget(
      MaterialApp(
        home: ClassroomDetailScreen(
          repository: _FixedRepository(detail),
          // 서울 13:00 = UTC 04:00
          clock: () => DateTime.utc(2026, 11, 20, 4),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('14:00–16:00'), findsOneWidget);
    expect(find.text('14:00까지 자유 이용 가능'), findsOneWidget);
    expect(find.textContaining('09:00 갱신'), findsOneWidget);
  });

  testWidgets('shows class in progress during a scheduled class', (
    tester,
  ) async {
    await pumpScreen(tester, DateTime(2026, 11, 20, 10, 30));

    expect(find.text('현재 수업 중'), findsOneWidget);
    expect(find.text('12:00 수업 종료 예정'), findsOneWidget);
  });

  testWidgets('refreshes schedule status every minute', (tester) async {
    var now = DateTime(2026, 11, 20, 11, 59);
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(home: ClassroomDetailScreen(clock: () => now)),
    );
    await tester.pumpAndSettle();
    expect(find.text('현재 수업 중'), findsOneWidget);

    now = DateTime(2026, 11, 20, 12, 0);
    await tester.pump(const Duration(minutes: 1));
    expect(find.text('현재 비어있음'), findsOneWidget);
    expect(find.text('지금'), findsOneWidget);
  });

  testWidgets('passes the classroom to the directions callback', (
    tester,
  ) async {
    ClassroomDetail? selected;
    await pumpScreen(
      tester,
      DateTime(2026, 11, 20, 12, 30),
      onDirections: (detail) => selected = detail,
    );

    await tester.tap(find.text('이 강의실로 길찾기'));
    expect(selected?.roomName, '204호 멀티미디어실');
  });
}
