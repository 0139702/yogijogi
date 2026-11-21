import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'auth_service.dart';

/// AWS Cognito 사용자 풀과 직접 통신하는 인증.
/// 로그인 토큰은 앱 메모리에만 보관하므로 앱을 다시 실행하면 다시 로그인해야 한다.
class CognitoAuthService extends AuthService {
  CognitoAuthService({required this.region, required this.clientId});

  final String region;
  final String clientId;
  final _client = HttpClient()..connectionTimeout = const Duration(seconds: 10);

  AuthUser? _currentUser;
  String? _accessToken;

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  bool get isDemo => false;

  /// 로그인한 사용자의 토큰. 제보 API 인증에 사용한다.
  String? get accessToken => _accessToken;

  @override
  void dispose() {
    _client.close(force: true);
    super.dispose();
  }

  @override
  Future<void> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    await _call('SignUp', {
      'ClientId': clientId,
      'Username': username.trim().toLowerCase(),
      'Password': password,
      'UserAttributes': [
        {'Name': 'email', 'Value': email.trim().toLowerCase()},
      ],
    });
  }

  @override
  Future<void> confirmSignUp({
    required String username,
    required String code,
  }) async {
    await _call('ConfirmSignUp', {
      'ClientId': clientId,
      'Username': username.trim().toLowerCase(),
      'ConfirmationCode': code.trim(),
    });
  }

  @override
  Future<void> resendCode({required String username}) async {
    await _call('ResendConfirmationCode', {
      'ClientId': clientId,
      'Username': username.trim().toLowerCase(),
    });
  }

  @override
  Future<void> signIn({
    required String username,
    required String password,
  }) async {
    final result = await _call('InitiateAuth', {
      'AuthFlow': 'USER_PASSWORD_AUTH',
      'ClientId': clientId,
      'AuthParameters': {
        'USERNAME': username.trim().toLowerCase(),
        'PASSWORD': password,
      },
    });
    final tokens = result['AuthenticationResult'] as Map<String, dynamic>?;
    final accessToken = tokens?['AccessToken'] as String?;
    if (accessToken == null) throw const AuthException(AuthError.unknown);
    _accessToken = accessToken;
    await _loadUser();
  }

  @override
  Future<void> setNickname(String nickname) async {
    final accessToken = _accessToken;
    if (accessToken == null) throw const AuthException(AuthError.unknown);
    await _call('UpdateUserAttributes', {
      'AccessToken': accessToken,
      'UserAttributes': [
        {'Name': 'nickname', 'Value': nickname},
      ],
    });
    await _loadUser();
  }

  @override
  Future<void> signOut() async {
    _accessToken = null;
    _currentUser = null;
    notifyListeners();
  }

  Future<void> _loadUser() async {
    final result = await _call('GetUser', {'AccessToken': _accessToken});
    final attributes = {
      for (final item in result['UserAttributes'] as List<dynamic>)
        (item as Map<String, dynamic>)['Name'] as String:
            item['Value'] as String,
    };
    _currentUser = AuthUser(
      id: attributes['sub']!,
      username: result['Username'] as String,
      email: attributes['email'] ?? '',
      nickname: attributes['nickname'],
    );
    notifyListeners();
  }

  Future<Map<String, dynamic>> _call(
    String action,
    Map<String, Object?> body,
  ) async {
    const timeout = Duration(seconds: 15);
    try {
      final request = await _client.postUrl(
        Uri.https('cognito-idp.$region.amazonaws.com', '/'),
      );
      request.headers
        ..set(HttpHeaders.contentTypeHeader, 'application/x-amz-json-1.1')
        ..set('X-Amz-Target', 'AWSCognitoIdentityProviderService.$action');
      request.add(utf8.encode(jsonEncode(body)));
      final response = await request.close().timeout(timeout);
      final raw = await response
          .transform(utf8.decoder)
          .join()
          .timeout(timeout);
      final data = raw.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(raw) as Map<String, dynamic>;
      if (response.statusCode >= 200 && response.statusCode < 300) return data;
      throw AuthException(
        cognitoError(data['__type'] as String?, data['message'] as String?),
      );
    } on AuthException {
      rethrow;
    } on IOException {
      throw const AuthException(AuthError.network);
    } on TimeoutException {
      throw const AuthException(AuthError.network);
    } on FormatException {
      throw const AuthException(AuthError.unknown);
    }
  }
}

/// Cognito 오류를 화면 문구로 바꾼다. 가입 전 검사 Lambda의 코드는 메시지에 담겨 온다.
AuthError cognitoError(String? type, String? message) {
  final name = type?.split('#').last;
  final text = message ?? '';
  return switch (name) {
    'UsernameExistsException' => AuthError.usernameTaken,
    'UserLambdaValidationException'
        when text.contains('INVALID_EMAIL_DOMAIN') =>
      AuthError.invalidDomain,
    'UserLambdaValidationException' when text.contains('EMAIL_TAKEN') =>
      AuthError.emailTaken,
    'UserLambdaValidationException' when text.contains('INVALID_USERNAME') =>
      AuthError.invalidUsername,
    'InvalidPasswordException' => AuthError.weakPassword,
    'CodeMismatchException' => AuthError.codeMismatch,
    'ExpiredCodeException' => AuthError.codeExpired,
    'NotAuthorizedException' ||
    'UserNotFoundException' => AuthError.invalidCredentials,
    'UserNotConfirmedException' => AuthError.notConfirmed,
    'LimitExceededException' ||
    'TooManyRequestsException' ||
    'TooManyFailedAttemptsException' => AuthError.tooManyAttempts,
    _ => AuthError.unknown,
  };
}
