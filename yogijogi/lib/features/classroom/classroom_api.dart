import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'classroom.dart';
import 'classroom_repository.dart';

/// API 주소가 있으면 강의실 API를, 없으면 샘플 데이터를 사용하는 저장소를 만든다.
ClassroomRepository createClassroomRepository(
  Uri? baseUrl, {
  DateTime Function()? clock,
}) {
  if (baseUrl == null) return SampleClassroomRepository(clock: clock);
  return ApiClassroomRepository(baseUrl);
}

/// 백엔드 `GET /classrooms/{id}`를 호출하는 저장소.
class ApiClassroomRepository extends ClassroomRepository {
  ApiClassroomRepository(this.baseUrl);

  final Uri baseUrl;
  final _client = HttpClient()..connectionTimeout = const Duration(seconds: 10);

  @override
  void close() => _client.close(force: true);

  @override
  Future<ClassroomDetail> fetchDetail(String classroomId) async {
    final prefix = baseUrl.path.replaceFirst(RegExp(r'/+$'), '');
    final request = await _client.getUrl(
      baseUrl.replace(
        path: '$prefix/classrooms/${Uri.encodeComponent(classroomId)}',
      ),
    );
    const timeout = Duration(seconds: 15);
    final response = await request.close().timeout(
      timeout,
      onTimeout: () {
        request.abort();
        throw TimeoutException('Classroom API response timed out', timeout);
      },
    );
    final raw = await response.transform(utf8.decoder).join().timeout(timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Classroom API request failed with HTTP ${response.statusCode}',
      );
    }
    return ClassroomDetail.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}
