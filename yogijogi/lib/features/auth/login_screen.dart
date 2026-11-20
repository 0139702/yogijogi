import 'package:material_ui/material_ui.dart';

import '../../core/app_colors.dart';
import '../../core/school_config.dart';
import 'auth_service.dart';
import 'auth_widgets.dart';
import 'signup_screen.dart';
import 'verify_code_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.auth});

  final AuthService auth;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _hidePassword = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final username = _username.text.trim().toLowerCase();
    if (username.isEmpty || _password.text.isEmpty) {
      setState(() => _error = '아이디와 비밀번호를 입력해 주세요.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.auth.signIn(username: username, password: _password.text);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
      if (e.error == AuthError.notConfirmed) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => VerifyCodeScreen(
              auth: widget.auth,
              username: username,
              password: _password.text,
            ),
          ),
        );
      }
    }
  }

  void _openSignUp() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => SignUpScreen(auth: widget.auth)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            32,
            AppSpacing.screenPadding,
            32,
          ),
          children: [
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.brand,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.explore_outlined,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '로그인하고 제보에 참여해요',
              textAlign: TextAlign.center,
              style: AppTextStyles.title,
            ),
            const SizedBox(height: 8),
            Text(
              '${SchoolConfig.name} 학생만 제보를 보고 남길 수 있어요.',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 24),
            AuthTextField(
              controller: _username,
              label: '아이디',
              hint: '아이디를 입력해 주세요',
              enabled: !_busy,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: _password,
              label: '비밀번호',
              obscure: _hidePassword,
              enabled: !_busy,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _signIn(),
              trailing: IconButton(
                tooltip: _hidePassword ? '비밀번호 보기' : '비밀번호 숨기기',
                onPressed: () => setState(() => _hidePassword = !_hidePassword),
                icon: Icon(
                  _hidePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            AuthErrorText(_error),
            const SizedBox(height: 24),
            AuthPrimaryButton(
              label: _busy ? '로그인 중' : '로그인',
              onPressed: _busy ? null : _signIn,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('아직 계정이 없나요?', style: AppTextStyles.caption),
                TextButton(
                  onPressed: _busy ? null : _openSignUp,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.brandStrong,
                    textStyle: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('회원가입'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
