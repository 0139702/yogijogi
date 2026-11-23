import 'package:material_ui/material_ui.dart';

import '../../core/app_colors.dart';
import 'auth_service.dart';
import 'auth_widgets.dart';

class NicknameScreen extends StatefulWidget {
  const NicknameScreen({super.key, required this.auth});

  final AuthService auth;

  @override
  State<NicknameScreen> createState() => _NicknameScreenState();
}

class _NicknameScreenState extends State<NicknameScreen> {
  final _nickname = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _nickname.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final nickname = _nickname.text.trim();
    if (!nicknamePattern.hasMatch(nickname)) {
      setState(() => _error = '닉네임은 한글, 영문, 숫자로 2~12자까지 쓸 수 있어요.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.auth.setNickname(nickname);
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
            Text('닉네임을 정해 주세요', style: AppTextStyles.title),
            const SizedBox(height: 8),
            Text(
              "제보는 기본적으로 '익명의 학우'로 공개돼요. "
              '닉네임은 내 정보와 닉네임 공개를 선택한 제보에 쓰여요.',
              style: AppTextStyles.caption.copyWith(height: 1.5),
            ),
            const SizedBox(height: 24),
            AuthTextField(
              controller: _nickname,
              label: '닉네임',
              hint: '한글, 영문, 숫자 2~12자',
              enabled: !_busy,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
            ),
            AuthErrorText(_error),
            const SizedBox(height: 24),
            AuthPrimaryButton(
              label: _busy ? '저장 중' : '시작하기',
              onPressed: _busy ? null : _save,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _busy ? null : widget.auth.signOut,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                textStyle: AppTextStyles.body,
              ),
              child: const Text('로그아웃'),
            ),
          ],
        ),
      ),
    );
  }
}
