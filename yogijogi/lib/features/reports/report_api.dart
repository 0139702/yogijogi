import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'report.dart';

class ReportApi {
  ReportApi(this.baseUrl);

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

  Future<Map<String, dynamic>> _request(
    String method,
    String endpoint, [
    Map<String, String>? body,
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
    const timeout = Duration(seconds: 15);
    final response = await request.close().timeout(
      timeout,
      onTimeout: () {
        request.abort();
        throw TimeoutException('API response timed out', timeout);
      },
    );
    final raw = await response.transform(utf8.decoder).join().timeout(timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'API request failed with HTTP ${response.statusCode}',
      );
    }
    return jsonDecode(raw) as Map<String, dynamic>;
  }
}
