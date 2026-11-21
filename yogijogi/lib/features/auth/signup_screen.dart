import 'package:material_ui/material_ui.dart';

import '../../core/app_colors.dart';
import '../../core/school_config.dart';
import 'auth_service.dart';
import 'auth_widgets.dart';
import 'verify_code_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key, required this.auth});

  final AuthService auth;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirm = TextEditingController();
  bool _privacyAgreed = false;
  bool _rulesAgreed = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _passwordConfirm.dispose();
    super.dispose();
  }

  String? _validate() {
    if (!usernamePattern.hasMatch(_username.text.trim().toLowerCase())) {
      return AuthError.invalidUsername.message;
    }
    final email = schoolEmailFrom(_email.text);
    if (_email.text.trim().isEmpty) return '학교 이메일을 입력해 주세요.';
    if (!SchoolConfig.isSchoolEmail(email)) {
      return AuthError.invalidDomain.message;
    }
    if (!isValidPassword(_password.text)) {
      return AuthError.weakPassword.message;
    }
    if (_password.text != _passwordConfirm.text) {
      return '비밀번호 확인이 일치하지 않아요.';
    }
    if (!_privacyAgreed || !_rulesAgreed) return '필수 항목에 모두 동의해 주세요.';
    return null;
  }

  Future<void> _signUp() async {
    final error = _validate();
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    final username = _username.text.trim().toLowerCase();
    final email = schoolEmailFrom(_email.text).toLowerCase();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.auth.signUp(
        username: username,
        email: email,
        password: _password.text,
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => VerifyCodeScreen(
            auth: widget.auth,
            username: username,
            email: email,
            password: _password.text,
          ),
        ),
      );
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final allAgreed = _privacyAgreed && _rulesAgreed;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        title: Text('회원가입', style: AppTextStyles.title),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          24,
          AppSpacing.screenPadding,
          32,
        ),
        children: [
          Text('${SchoolConfig.name} 이메일로 가입해요', style: AppTextStyles.title),
          const SizedBox(height: 8),
          Text(
            '로그인은 아이디로 하고, 학교 이메일은 재학생 인증에만 써요. '
            '학교 메일로 받은 인증 코드를 입력하면 가입이 완료돼요.',
            style: AppTextStyles.caption.copyWith(height: 1.5),
          ),
          const SizedBox(height: 24),
          AuthTextField(
            controller: _username,
            label: '아이디',
            hint: '영문 소문자, 숫자, _ 4~20자',
            enabled: !_busy,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _email,
            label: '학교 이메일 (인증용)',
            hint: '메일 주소 앞부분',
            suffixText: '@${SchoolConfig.emailDomain}',
            enabled: !_busy,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _password,
            label: '비밀번호',
            hint: '영문, 숫자 포함 8자 이상',
            obscure: true,
            enabled: !_busy,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _passwordConfirm,
            label: '비밀번호 확인',
            obscure: true,
            enabled: !_busy,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 24),
          Material(
            color: AppColors.surface,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Column(
              children: [
                CheckboxListTile(
                  value: allAgreed,
                  onChanged: _busy
                      ? null
                      : (value) => setState(() {
                          _privacyAgreed = value ?? false;
                          _rulesAgreed = value ?? false;
                        }),
                  activeColor: AppColors.brandStrong,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    '전체 동의',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Divider(height: 1, color: AppColors.border),
                _ConsentTile(
                  value: _privacyAgreed,
                  enabled: !_busy,
                  title: '(필수) 개인정보 수집·이용 동의',
                  detail:
                      '아이디, 학교 이메일, 닉네임을 재학생 확인과 제보 서비스 제공에만 사용하고, 탈퇴하면 삭제해요.',
                  onChanged: (value) => setState(() => _privacyAgreed = value),
                ),
                _ConsentTile(
                  value: _rulesAgreed,
                  enabled: !_busy,
                  title: '(필수) 커뮤니티 원칙 동의',
                  detail:
                      '특정인을 지목하거나 비난하지 않고, 다른 사람의 얼굴·이름·연락처가 담긴 내용은 올리지 않아요.',
                  onChanged: (value) => setState(() => _rulesAgreed = value),
                ),
              ],
            ),
          ),
          AuthErrorText(_error),
          const SizedBox(height: 24),
          AuthPrimaryButton(
            label: _busy ? '가입 중' : '인증 코드 받기',
            onPressed: _busy ? null : _signUp,
          ),
        ],
      ),
    );
  }
}

class _ConsentTile extends StatelessWidget {
  const _ConsentTile({
    required this.value,
    required this.enabled,
    required this.title,
    required this.detail,
    required this.onChanged,
  });

  final bool value;
  final bool enabled;
  final String title;
  final String detail;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: enabled ? (value) => onChanged(value ?? false) : null,
      activeColor: AppColors.brandStrong,
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(title, style: AppTextStyles.body),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(detail, style: AppTextStyles.caption.copyWith(height: 1.5)),
      ),
    );
  }
}
