import 'package:flutter/foundation.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.username,
    required this.email,
    this.nickname,
  });

  final String id;
  final String username;
  final String email;
  final String? nickname;
}

enum AuthError {
  invalidUsername('아이디는 영문 소문자, 숫자, 밑줄(_)로 4~20자까지 쓸 수 있어요.'),
  usernameTaken('이미 사용 중인 아이디예요.'),
  invalidDomain('성신여자대학교 이메일로만 가입할 수 있어요.'),
  emailTaken('이미 가입에 사용된 학교 이메일이에요.'),
  weakPassword('비밀번호는 영문과 숫자를 포함해 8자 이상으로 만들어 주세요.'),
  invalidCredentials('아이디 또는 비밀번호가 맞지 않아요.'),
  notConfirmed('학교 이메일 인증을 마쳐야 로그인할 수 있어요.'),
  codeMismatch('인증 코드가 맞지 않아요.'),
  codeExpired('인증 코드가 만료됐어요. 코드를 다시 받아 주세요.'),
  tooManyAttempts('시도 횟수가 너무 많아요. 잠시 후 다시 시도해 주세요.'),
  nicknameTaken('이미 사용 중인 닉네임이에요.'),
  network('서버에 연결하지 못했어요. 인터넷 연결을 확인해 주세요.'),
  unknown('잠시 후 다시 시도해 주세요.');

  const AuthError(this.message);

  final String message;
}

class AuthException implements Exception {
  const AuthException(this.error);

  final AuthError error;

  String get message => error.message;
}

/// 로그인·회원가입 기능. 시연용 구현과 Cognito 구현이 같은 인터페이스를 따른다.
/// 로그인은 아이디로 하고, 학교 이메일은 가입할 때 인증에만 쓴다.
abstract class AuthService extends ChangeNotifier {
  AuthUser? get currentUser;

  /// 실제 인증 서버와 연결되지 않은 구현이면 true.
  bool get isDemo;

  Future<void> signUp({
    required String username,
    required String email,
    required String password,
  });

  Future<void> confirmSignUp({required String username, required String code});

  Future<void> resendCode({required String username});

  Future<void> signIn({required String username, required String password});

  Future<void> setNickname(String nickname);

  Future<void> signOut();
}

final usernamePattern = RegExp(r'^[a-z0-9_]{4,20}$');

final nicknamePattern = RegExp(r'^[가-힣a-zA-Z0-9]{2,12}$');

bool isValidPassword(String password) =>
    password.length >= 8 &&
    password.contains(RegExp('[a-zA-Z]')) &&
    password.contains(RegExp('[0-9]'));
