import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';

class HeaderIconButton extends StatelessWidget {
  const HeaderIconButton.notifications({super.key, required this.onPressed})
    : _profile = false;

  const HeaderIconButton.profile({super.key, required this.onPressed})
    : _profile = true;

  final VoidCallback onPressed;
  final bool _profile;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: _profile ? '프로필' : '알림',
      onPressed: onPressed,
      style: IconButton.styleFrom(
        foregroundColor: _profile ? AppColors.surface : AppColors.brandStrong,
        backgroundColor: _profile ? AppColors.brandStrong : Colors.transparent,
        fixedSize: const Size.square(44),
        shape: const CircleBorder(),
      ),
      icon: Icon(
        _profile ? Icons.person_outline : Icons.notifications_none,
        size: 22,
      ),
    );
  }
}
