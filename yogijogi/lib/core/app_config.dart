import 'package:flutter/foundation.dart';

class AppConfig {
  static const environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'local',
  );
  static const _rawApiBaseUrl = String.fromEnvironment('API_BASE_URL');

  static Uri? get apiBaseUrl {
    final uri = Uri.tryParse(_rawApiBaseUrl);
    if (uri == null ||
        uri.host.isEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        uri.userInfo.isNotEmpty) {
      return null;
    }
    if (uri.scheme == 'https' ||
        (uri.scheme == 'http' && kDebugMode && environment == 'local')) {
      return uri;
    }
    return null;
  }
}
