import 'package:material_ui/material_ui.dart';

import 'core/app_colors.dart';
import 'core/app_config.dart';
import 'features/auth/auth_service.dart';
import 'features/auth/cognito_auth_service.dart';
import 'features/auth/demo_auth_service.dart';
import 'features/map/map_screen.dart';
import 'features/reports/report_api.dart';
import 'features/reports/reports_gate.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _api = ReportApi(AppConfig.apiBaseUrl);
  final AuthService _auth = AppConfig.isCognitoConfigured
      ? CognitoAuthService(
          region: AppConfig.cognitoRegion,
          clientId: AppConfig.cognitoClientId,
        )
      : DemoAuthService();
  int _index = 0;

  @override
  void dispose() {
    _api.close();
    _auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '요기조기',
      theme: ThemeData(
        fontFamily: AppTextStyles.fontFamily,
        colorSchemeSeed: AppColors.brand,
        scaffoldBackgroundColor: AppColors.background,
      ),
      home: Scaffold(
        appBar: _index == 0 ? AppBar(title: const Text('캠퍼스 지도')) : null,
        body: _index == 0
            ? const MapScreen()
            : ReportsGate(auth: _auth, api: _api),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (index) => setState(() => _index = index),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.map_outlined), label: '지도'),
            NavigationDestination(icon: Icon(Icons.flag_outlined), label: '제보'),
          ],
        ),
      ),
    );
  }
}
