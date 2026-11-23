import 'package:material_ui/material_ui.dart';

import '../auth/auth_service.dart';
import '../auth/login_screen.dart';
import '../auth/nickname_screen.dart';
import 'report_api.dart';
import 'reports_screen.dart';

/// 제보 탭 입구. 로그인 전에는 로그인 화면, 닉네임을 정하기 전에는 닉네임 화면을 보여 준다.
class ReportsGate extends StatelessWidget {
  const ReportsGate({
    super.key,
    required this.auth,
    required this.api,
    this.initialLocation,
  });

  final AuthService auth;
  final ReportApi api;
  final String? initialLocation;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) {
        final user = auth.currentUser;
        if (user == null) return LoginScreen(auth: auth);
        if (user.nickname == null) return NicknameScreen(auth: auth);
        return ReportsScreen(
          api: api,
          auth: auth,
          initialLocation: initialLocation,
        );
      },
    );
  }
}
