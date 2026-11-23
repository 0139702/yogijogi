import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'my_report.dart';
import 'my_reports_repository.dart';

/// API 주소가 있으면 마이페이지 API를, 없으면 데모 데이터를 사용하는 저장소를 만든다.
MyReportsRepository createMyReportsRepository(
  Uri? baseUrl, {
  DateTime Function()? clock,
}) {
  if (baseUrl == null) return DemoMyReportsRepository(clock: clock);
  return ApiMyReportsRepository(baseUrl);
}

/// 백엔드 `GET /me/reports`를 호출하는 저장소.
class ApiMyReportsRepository extends MyReportsRepository {
  ApiMyReportsRepository(this.baseUrl);

  final Uri baseUrl;
  final _client = HttpClient()..connectionTimeout = const Duration(seconds: 10);

  @override
  void close() => _client.close(force: true);

  @override
  Future<MyReportsSnapshot> fetchMyReports() async {
    final prefix = baseUrl.path.replaceFirst(RegExp(r'/+$'), '');
    final request = await _client.getUrl(
      baseUrl.replace(path: '$prefix/me/reports'),
    );
    const timeout = Duration(seconds: 15);
    final response = await request.close().timeout(
      timeout,
      onTimeout: () {
        request.abort();
        throw TimeoutException('My reports API response timed out', timeout);
      },
    );
    final raw = await response.transform(utf8.decoder).join().timeout(timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'My reports API request failed with HTTP ${response.statusCode}',
      );
    }
    return MyReportsSnapshot.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}
