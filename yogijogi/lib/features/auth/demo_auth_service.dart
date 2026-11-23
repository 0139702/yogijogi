import '../../core/school_config.dart';
import 'auth_service.dart';

/// 시연용 인증. 계정은 앱 메모리에만 있고 앱을 다시 실행하면 사라진다.
/// 인증 메일을 보내지 않으며 인증 코드는 [demoCode]로 고정된다.
class DemoAuthService extends AuthService {
  static const demoCode = '000000';

  final _accounts = <String, _DemoAccount>{};
  final _nicknames = <String>{};
  AuthUser? _currentUser;

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  bool get isDemo => true;

  @override
  Future<void> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    final name = username.trim().toLowerCase();
    final address = email.trim().toLowerCase();
    if (!usernamePattern.hasMatch(name)) {
      throw const AuthException(AuthError.invalidUsername);
    }
    if (!SchoolConfig.isSchoolEmail(address)) {
      throw const AuthException(AuthError.invalidDomain);
    }
    if (_accounts.containsKey(name)) {
      throw const AuthException(AuthError.usernameTaken);
    }
    if (_accounts.values.any((account) => account.email == address)) {
      throw const AuthException(AuthError.emailTaken);
    }
    _accounts[name] = _DemoAccount(
      id: 'demo-${_accounts.length + 1}',
      email: address,
      password: password,
    );
  }

  @override
  Future<void> confirmSignUp({
    required String username,
    required String code,
  }) async {
    final account = _accounts[username.trim().toLowerCase()];
    if (account == null || code.trim() != demoCode) {
      throw const AuthException(AuthError.codeMismatch);
    }
    account.confirmed = true;
  }

  @override
  Future<void> resendCode({required String username}) async {}

  @override
  Future<void> signIn({
    required String username,
    required String password,
  }) async {
    final name = username.trim().toLowerCase();
    final account = _accounts[name];
    if (account == null || account.password != password) {
      throw const AuthException(AuthError.invalidCredentials);
    }
    if (!account.confirmed) {
      throw const AuthException(AuthError.notConfirmed);
    }
    _currentUser = AuthUser(
      id: account.id,
      username: name,
      email: account.email,
      nickname: account.nickname,
    );
    notifyListeners();
  }

  @override
  Future<void> setNickname(String nickname) async {
    final user = _currentUser;
    if (user == null) throw const AuthException(AuthError.unknown);
    final key = nickname.toLowerCase();
    final account = _accounts[user.username]!;
    if (account.nickname?.toLowerCase() != key && _nicknames.contains(key)) {
      throw const AuthException(AuthError.nicknameTaken);
    }
    if (account.nickname != null) {
      _nicknames.remove(account.nickname!.toLowerCase());
    }
    _nicknames.add(key);
    account.nickname = nickname;
    _currentUser = AuthUser(
      id: user.id,
      username: user.username,
      email: user.email,
      nickname: nickname,
    );
    notifyListeners();
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    notifyListeners();
  }
}

class _DemoAccount {
  _DemoAccount({required this.id, required this.email, required this.password});

  final String id;
  final String email;
  final String password;
  bool confirmed = false;
  String? nickname;
}
