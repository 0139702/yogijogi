import 'package:material_ui/material_ui.dart';

import '../../core/app_colors.dart';
import '../../core/school_config.dart';

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.suffixText,
    this.obscure = false,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.trailing,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? suffixText;
  final bool obscure;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.body),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          obscureText: obscure,
          autocorrect: false,
          enableSuggestions: !obscure,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface,
            hintText: hint,
            hintStyle: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
            suffixIcon:
                trailing ??
                (suffixText == null
                    ? null
                    : Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Text(
                          suffixText!,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )),
            suffixIconConstraints: trailing == null
                ? const BoxConstraints(minHeight: 0)
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            enabledBorder: border(AppColors.border),
            disabledBorder: border(AppColors.border),
            focusedBorder: border(AppColors.brand),
          ),
        ),
      ],
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.brandStrong,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
      ),
      child: Text(label),
    );
  }
}

class AuthErrorText extends StatelessWidget {
  const AuthErrorText(this.text, {super.key});

  final String? text;

  @override
  Widget build(BuildContext context) {
    final text = this.text;
    if (text == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          color: Theme.of(context).colorScheme.error,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// 이메일 아이디만 받고 학교 도메인을 붙인다. 전체 주소를 붙여 넣어도 그대로 쓴다.
String schoolEmailFrom(String input) {
  final value = input.trim();
  return value.contains('@') ? value : '$value@${SchoolConfig.emailDomain}';
}
