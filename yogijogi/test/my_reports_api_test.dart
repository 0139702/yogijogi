import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yogijogi/features/mypage/my_report.dart';
import 'package:yogijogi/features/mypage/my_reports_api.dart';
import 'package:yogijogi/features/mypage/my_reports_repository.dart';

// 백엔드 backend/src/my_reports.mjs 응답과 같은 형식.
const _response = {
  'items': [
    {
      'id': 'demo-1',
      'type': '벌레 몬스터',
      'location': '중앙도서관 보관실 앞 (B1)',
      'description': '보관실 앞 복도에서 바퀴벌레를 봤어요.',
      'occurredAt': '2026-11-20T11:20:00+09:00',
      'status': 'in_progress',
      'source': 'user_report',
      'updatedAt': '2026-11-20T13:10:00+09:00',
      'statusHistory': [
        {'status': 'received', 'changedAt': '2026-11-20T11:20:00+09:00'},
        {'status': 'checking', 'changedAt': '2026-11-20T11:45:00+09:00'},
        {'status': 'in_progress', 'changedAt': '2026-11-20T13:10:00+09:00'},
      ],
      'staffResponse': {
        'department': '학생지원처',
        'message': '방역업체에 작업 지시를 전달했어요.',
        'plan': '오늘 18:00 야간 방역 예정',
        'respondedAt': '2026-11-20T13:10:00+09:00',
        'isDemo': true,
      },
    },
    {
      'id': 'demo-3',
      'type': '시설 고장 / 파손',
      'location': '법학관 정수기 (1F)',
      'description': '정수기 아래로 물이 새고 있어요.',
      'occurredAt': '2026-11-18T10:00:00+09:00',
      'status': 'resolved',
      'source': 'user_report',
      'updatedAt': '2026-11-18T16:30:00+09:00',
      'statusHistory': [
        {'status': 'received', 'changedAt': '2026-11-18T10:00:00+09:00'},
        {'status': 'resolved', 'changedAt': '2026-11-18T16:30:00+09:00'},
      ],
      'staffResponse': null,
    },
  ],
  'isDemo': true,
  'utcOffsetMinutes': 540,
};

void main() {
  late HttpServer server;
  late List<String> requestedPaths;
  var statusCode = 200;

  setUp(() async {
    requestedPaths = [];
    statusCode = 200;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) {
      requestedPaths.add(request.uri.path);
      request.response
        ..statusCode = statusCode
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(statusCode == 200 ? _response : {'error': 'x'}))
        ..close();
    });
  });

  tearDown(() => server.close(force: true));

  Uri baseUrl([String path = '']) =>
      Uri.parse('http://127.0.0.1:${server.port}$path');

  test('reads my reports from the API', () async {
    final repository = ApiMyReportsRepository(baseUrl('/dev/'));
    addTearDown(repository.close);

    final snapshot = await repository.fetchMyReports();

    expect(requestedPaths, ['/dev/me/reports']);
    expect(snapshot.isDemo, isTrue);
    expect(snapshot.utcOffset, const Duration(hours: 9));
    expect(snapshot.active.single.stage, ReportStage.inProgress);
    expect(snapshot.active.single.history, hasLength(3));
    expect(snapshot.active.single.staffResponse?.isDemo, isTrue);
    expect(snapshot.resolved.single.staffResponse, isNull);
  });

  test('throws when the API fails', () async {
    statusCode = 500;
    final repository = ApiMyReportsRepository(baseUrl());
    addTearDown(repository.close);

    await expectLater(
      repository.fetchMyReports(),
      throwsA(isA<HttpException>()),
    );
  });

  test('uses demo data when no API address is configured', () {
    expect(createMyReportsRepository(null), isA<DemoMyReportsRepository>());
    final api = createMyReportsRepository(baseUrl());
    addTearDown(api.close);
    expect(api, isA<ApiMyReportsRepository>());
  });
}
