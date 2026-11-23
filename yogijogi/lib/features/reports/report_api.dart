import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'report.dart';

class ReportApi {
  ReportApi(this.baseUrl);

  static const _timeout = Duration(seconds: 15);
  static const _uploadTimeout = Duration(seconds: 60);

  final Uri? baseUrl;
  final _client = HttpClient()..connectionTimeout = const Duration(seconds: 10);

  void close() => _client.close(force: true);

  Future<List<Report>> list() async {
    final data = await _request('GET', 'reports');
    return (data['items'] as List<dynamic>)
        .map((item) => Report.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Report> save({
    String? id,
    required String type,
    required String location,
    required String description,
    required DateTime occurredAt,
  }) async {
    final data = await _request(
      id == null ? 'POST' : 'PUT',
      id == null ? 'reports' : 'reports/$id',
      {
        'type': type,
        'location': location,
        'description': description,
        'occurredAt': occurredAt.toUtc().toIso8601String(),
      },
    );
    return Report.fromJson(data);
  }

  /// 서버에서 받은 임시 주소로 사진을 올린 뒤, 업로드가 끝났다고 알린다.
  Future<Report> uploadPhoto(String reportId, File file) async {
    final bytes = await file.readAsBytes();
    final contentType = file.path.toLowerCase().endsWith('.png')
        ? 'image/png'
        : 'image/jpeg';
    final issued = await _request('POST', 'reports/$reportId/photos', {
      'contentType': contentType,
      'size': bytes.length,
    });
    final photoId = issued['photoId'] as String;
    final upload = issued['upload'] as Map<String, dynamic>;

    final request = await _client.openUrl(
      upload['method'] as String,
      Uri.parse(upload['url'] as String),
    );
    (upload['headers'] as Map<String, dynamic>? ?? const {}).forEach(
      (name, value) => request.headers.set(name, value as Object),
    );
    request.contentLength = bytes.length;
    request.add(bytes);
    final response = await request.close().timeout(
      _uploadTimeout,
      onTimeout: () {
        request.abort();
        throw TimeoutException('Photo upload timed out', _uploadTimeout);
      },
    );
    await response.drain<void>();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Photo upload failed with HTTP ${response.statusCode}',
      );
    }

    final data = await _request(
      'POST',
      'reports/$reportId/photos/$photoId/complete',
    );
    return Report.fromJson(data);
  }

  Future<Report> deletePhoto(String reportId, String photoId) async {
    final data = await _request('DELETE', 'reports/$reportId/photos/$photoId');
    return Report.fromJson(data);
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String endpoint, [
    Map<String, Object>? body,
  ]) async {
    final base = baseUrl;
    if (base == null) throw StateError('API_BASE_URL is missing or invalid');

    final prefix = base.path.replaceFirst(RegExp(r'/+$'), '');
    final request = await _client.openUrl(
      method,
      base.replace(path: '$prefix/$endpoint'),
    );
    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.add(utf8.encode(jsonEncode(body)));
    }
    final response = await request.close().timeout(
      _timeout,
      onTimeout: () {
        request.abort();
        throw TimeoutException('API response timed out', _timeout);
      },
    );
    final raw = await response.transform(utf8.decoder).join().timeout(_timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'API request failed with HTTP ${response.statusCode}',
      );
    }
    return jsonDecode(raw) as Map<String, dynamic>;
  }
}
