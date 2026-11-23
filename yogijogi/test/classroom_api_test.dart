import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yogijogi/features/classroom/classroom_api.dart';
import 'package:yogijogi/features/classroom/classroom_repository.dart';

// 백엔드 backend/src/classrooms.mjs 응답과 같은 형식.
const _response = {
  'id': 'eng2-204',
  'buildingName': '공학관 2호관',
  'roomName': '204호 멀티미디어실',
  'walkingMinutes': null,
  'facilities': ['콘센트 전좌석', '빔프로젝터', 'Wi-Fi 6', '냉난방 가동'],
  'schedule': [
    {
      'title': '공강 / 자율 개방',
      'start': '2026-11-20T12:00:00+09:00',
      'end': '2026-11-20T14:00:00+09:00',
      'isOpenUse': true,
    },
  ],
  'recentReports': [
    {
      'id': 'sample-report-1',
      'description': '에어컨 바람이 조금 약해요',
      'source': 'user_report',
      'status': 'received',
      'reportedAt': '2026-11-20T03:00:00.000Z',
    },
  ],
  'updatedAt': '2026-11-20T09:00:00+09:00',
  'utcOffsetMinutes': 540,
  'isSample': true,
};

void main() {
  late HttpServer server;
  late List<String> requestedPaths;

  setUp(() async {
    requestedPaths = [];
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) {
      requestedPaths.add(request.uri.path);
      final found = request.uri.path.endsWith('/classrooms/eng2-204');
      request.response
        ..statusCode = found ? 200 : 404
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(found ? _response : {'error': 'not_found'}))
        ..close();
    });
  });

  tearDown(() => server.close(force: true));

  Uri baseUrl([String path = '']) =>
      Uri.parse('http://127.0.0.1:${server.port}$path');

  test('reads classroom detail from the API', () async {
    final repository = ApiClassroomRepository(baseUrl('/dev/'));
    addTearDown(repository.close);

    final detail = await repository.fetchDetail('eng2-204');

    expect(requestedPaths, ['/dev/classrooms/eng2-204']);
    expect(detail.roomName, '204호 멀티미디어실');
    expect(detail.walkingMinutes, isNull);
    expect(detail.isSample, isTrue);
    expect(detail.facilities, hasLength(4));
    expect(detail.schedule.single.isOpenUse, isTrue);
    expect(
      detail.schedule.single.start,
      DateTime.utc(2026, 11, 20, 3).toLocal(),
    );
    expect(detail.recentReports.single.source, 'user_report');
    // 기기 시간대와 관계없이 캠퍼스(KST) 시각으로 표시된다.
    final campusStart = detail.toCampusTime(detail.schedule.single.start);
    expect((campusStart.hour, campusStart.minute), (12, 0));
  });

  test('throws when the classroom does not exist', () async {
    final repository = ApiClassroomRepository(baseUrl());
    addTearDown(repository.close);

    await expectLater(
      repository.fetchDetail('unknown-room'),
      throwsA(isA<HttpException>()),
    );
  });

  test('uses sample data when no API address is configured', () {
    expect(createClassroomRepository(null), isA<SampleClassroomRepository>());
    final api = createClassroomRepository(baseUrl());
    addTearDown(api.close);
    expect(api, isA<ApiClassroomRepository>());
  });
}
