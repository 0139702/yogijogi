import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yogijogi/features/auth/auth_service.dart';
import 'package:yogijogi/features/auth/cognito_auth_service.dart';
import 'package:yogijogi/features/auth/demo_auth_service.dart';
import 'package:yogijogi/features/reports/report_api.dart';
import 'package:yogijogi/features/reports/reports_gate.dart';

Future<void> _register(DemoAuthService auth, String username, String email) =>
    auth.signUp(username: username, email: email, password: 'password1');

Future<void> _registerAndSignIn(
  DemoAuthService auth,
  String username,
  String email,
) async {
  await _register(auth, username, email);
  await auth.confirmSignUp(username: username, code: DemoAuthService.demoCode);
  await auth.signIn(username: username, password: 'password1');
}

Matcher _throws(AuthError error) =>
    throwsA(isA<AuthException>().having((e) => e.error, 'error', error));

void main() {
  test('accepts only school email addresses', () async {
    final auth = DemoAuthService();
    expect(
      _register(auth, 'yogi_1', 'student@gmail.com'),
      _throws(AuthError.invalidDomain),
    );
    expect(
      _register(auth, 'yogi_1', 'student@evil-sungshin.ac.kr'),
      _throws(AuthError.invalidDomain),
    );
    await _register(auth, 'yogi_1', 'Student@Sungshin.ac.kr');
  });

  test('keeps usernames and school emails unique', () async {
    final auth = DemoAuthService();
    await _register(auth, 'yogi_1', 'a@sungshin.ac.kr');
    expect(
      _register(auth, 'YOGI_1', 'b@sungshin.ac.kr'),
      _throws(AuthError.usernameTaken),
    );
    expect(
      _register(auth, 'yogi_2', 'A@sungshin.ac.kr'),
      _throws(AuthError.emailTaken),
    );
  });

  test('rejects usernames outside the allowed pattern', () {
    final auth = DemoAuthService();
    expect(
      _register(auth, 'abc', 'a@sungshin.ac.kr'),
      _throws(AuthError.invalidUsername),
    );
  });

  test('signs in with the username after email confirmation', () async {
    final auth = DemoAuthService();
    await _register(auth, 'yogi_1', 'a@sungshin.ac.kr');
    expect(
      auth.signIn(username: 'yogi_1', password: 'password1'),
      _throws(AuthError.notConfirmed),
    );
    expect(
      auth.confirmSignUp(username: 'yogi_1', code: '123456'),
      _throws(AuthError.codeMismatch),
    );
    await auth.confirmSignUp(
      username: 'yogi_1',
      code: DemoAuthService.demoCode,
    );
    await auth.signIn(username: 'Yogi_1', password: 'password1');
    expect(auth.currentUser?.username, 'yogi_1');
    expect(auth.currentUser?.email, 'a@sungshin.ac.kr');
  });

  test('keeps nicknames unique regardless of letter case', () async {
    final auth = DemoAuthService();
    await _registerAndSignIn(auth, 'yogi_1', 'a@sungshin.ac.kr');
    await auth.setNickname('Yogi');
    await auth.signOut();
    await _registerAndSignIn(auth, 'yogi_2', 'b@sungshin.ac.kr');
    expect(auth.setNickname('YOGI'), _throws(AuthError.nicknameTaken));
  });

  test('maps Cognito errors to user-facing errors', () {
    expect(
      cognitoError('UsernameExistsException', null),
      AuthError.usernameTaken,
    );
    expect(
      cognitoError(
        'UserLambdaValidationException',
        'PreSignUp failed with error INVALID_EMAIL_DOMAIN.',
      ),
      AuthError.invalidDomain,
    );
    expect(
      cognitoError(
        'UserLambdaValidationException',
        'PreSignUp failed with error EMAIL_TAKEN.',
      ),
      AuthError.emailTaken,
    );
    expect(
      cognitoError('com.amazonaws#CodeMismatchException', null),
      AuthError.codeMismatch,
    );
    expect(
      cognitoError('NotAuthorizedException', null),
      AuthError.invalidCredentials,
    );
    expect(
      cognitoError('UserNotConfirmedException', null),
      AuthError.notConfirmed,
    );
    expect(cognitoError('SomethingNew', null), AuthError.unknown);
  });

  testWidgets('shows the feed only after login and nickname setup', (
    tester,
  ) async {
    final auth = DemoAuthService();
    final api = ReportApi(null);
    addTearDown(api.close);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReportsGate(auth: auth, api: api),
        ),
      ),
    );
    expect(find.text('로그인하고 제보에 참여해요'), findsOneWidget);

    await _registerAndSignIn(auth, 'yogi_1', 'a@sungshin.ac.kr');
    await tester.pump();
    expect(find.text('닉네임을 정해 주세요'), findsOneWidget);

    await auth.setNickname('요기');
    await tester.pump();
    expect(find.text('제보를 보려면 API 주소를 설정해 주세요.'), findsOneWidget);
  });
}
