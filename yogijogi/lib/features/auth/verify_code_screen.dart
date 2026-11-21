import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/app_colors.dart';
import 'auth_service.dart';
import 'auth_widgets.dart';

class VerifyCodeScreen extends StatefulWidget {
  const VerifyCodeScreen({
    super.key,
    required this.auth,
    required this.username,
    required this.password,
    this.email,
  });

  final AuthService auth;
  final String username;
  final String password;

  /// 가입 직후에는 인증 메일을 보낸 주소를 보여 준다. 로그인 중 넘어오면 알 수 없다.
  final String? email;

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  static const _resendWait = 60;

  final _code = TextEditingController();
  Timer? _timer;
  int _resendIn = _resendWait;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _resendIn = _resendWait;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendIn <= 1) timer.cancel();
      setState(() => _resendIn--);
    });
  }

  Future<void> _resend() async {
    try {
      await widget.auth.resendCode(username: widget.username);
      if (!mounted) return;
      setState(_startTimer);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('인증 코드를 다시 보냈어요.')));
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _confirm() async {
    if (_code.text.trim().length != 6) {
      setState(() => _error = '6자리 인증 코드를 입력해 주세요.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.auth.confirmSignUp(
        username: widget.username,
        code: _code.text,
      );
      await widget.auth.signIn(
        username: widget.username,
        password: widget.password,
      );
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        title: Text('이메일 인증', style: AppTextStyles.title),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          24,
          AppSpacing.screenPadding,
          32,
        ),
        children: [
          Text('인증 코드를 입력해 주세요', style: AppTextStyles.title),
          const SizedBox(height: 8),
          Text(
            '${widget.email ?? '가입할 때 입력한 학교 이메일'}(으)로 보낸 6자리 코드를 입력해 주세요. '
            '메일이 보이지 않으면 스팸함도 확인해 주세요.',
            style: AppTextStyles.caption.copyWith(height: 1.5),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _code,
            enabled: !_busy,
            autofocus: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            onSubmitted: (_) => _confirm(),
            style: AppTextStyles.title.copyWith(letterSpacing: 8),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surface,
              hintText: '000000',
              hintStyle: AppTextStyles.title.copyWith(
                color: AppColors.border,
                letterSpacing: 8,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.brand),
              ),
            ),
          ),
          AuthErrorText(_error),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _busy || _resendIn > 0 ? null : _resend,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.brandStrong,
                textStyle: AppTextStyles.body,
              ),
              child: Text(
                _resendIn > 0 ? '코드 다시 받기 ($_resendIn초)' : '코드 다시 받기',
              ),
            ),
          ),
          const SizedBox(height: 16),
          AuthPrimaryButton(
            label: _busy ? '확인 중' : '인증하고 시작하기',
            onPressed: _busy ? null : _confirm,
          ),
        ],
      ),
    );
  }
}
