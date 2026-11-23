import 'package:material_ui/material_ui.dart';

import 'core/app_config.dart';
import 'core/app_theme.dart';
import 'features/auth/auth_service.dart';
import 'features/auth/cognito_auth_service.dart';
import 'features/auth/demo_auth_service.dart';
import 'features/map/map_screen.dart';
import 'features/mypage/my_page_screen.dart';
import 'features/map/prime_floor.dart';
import 'features/navigation/guidance.dart';
import 'features/navigation/route_option.dart';
import 'features/navigation/route_screen.dart';
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
  PrimePlace _start = PrimePlace.elevator;
  PrimePlace? _destination;
  RouteOption _routeOption = RouteOption.shortest;
  int? _guideStep;
  GuidanceView _view = GuidanceView.top;

  @override
  void dispose() {
    _api.close();
    _auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final demoRoute = primeDemoRoute(_start, _destination, _routeOption);
    final routeLabel = demoRoute.isEmpty
        ? null
        : _start == PrimePlace.elevator
        ? '샘플 경로 · 엘리베이터 앞 → 603호'
        : '샘플 경로 · 603호 → 엘리베이터 앞';
    return MaterialApp(
      title: '요기조기',
      theme: AppTheme.light,
      home: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(['요기조기', '길찾기', '제보', '마이'][_index]),
            actions: [
              if (_index == 0)
                IconButton(
                  tooltip: '알림',
                  icon: const Icon(Icons.notifications_none),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => Scaffold(
                        appBar: AppBar(title: const Text('알림')),
                        body: const Center(child: Text('받은 알림이 없습니다.')),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          body: IndexedStack(
            index: _index,
            children: [
              MapScreen(
                demoRoute: demoRoute,
                routeLabel: routeLabel,
                start: _start,
                destination: _destination,
                guideStep: _guideStep,
                view: _view,
                onDirections: () => setState(() => _index = 1),
                onPlaceSelected: (place) => setState(() {
                  _destination = place;
                  _guideStep = null;
                  _index = 1;
                }),
                onViewChanged: (view) => setState(() => _view = view),
                onStepChanged: (step) => setState(() => _guideStep = step),
                onEndGuidance: () => setState(() {
                  _guideStep = null;
                  _index = 1;
                }),
              ),
              RouteScreen(
                start: _start,
                destination: _destination,
                option: _routeOption,
                hasDemoRoute: demoRoute.isNotEmpty,
                onOptionChanged: (option) => setState(() {
                  _routeOption = option;
                  _guideStep = null;
                }),
                onStartChanged: (place) => setState(() {
                  _start = place;
                  _guideStep = null;
                }),
                onShowRoute: () => setState(() {
                  _guideStep = null;
                  _index = 0;
                }),
                onStartGuidance: () => setState(() {
                  _guideStep = 0;
                  _view = GuidanceView.top;
                  _index = 0;
                }),
                onDestinationChanged: (place) => setState(() {
                  _destination = place;
                  _guideStep = null;
                }),
                onSwap: () {
                  final destination = _destination;
                  if (destination == null) return;
                  setState(() {
                    _destination = _start;
                    _start = destination;
                    _guideStep = null;
                  });
                },
              ),
              if (_index == 2)
                ReportsGate(auth: _auth, api: _api)
              else
                const SizedBox.shrink(),
              if (_index == 3)
                const MyPageScreen()
              else
                const SizedBox.shrink(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (index) => setState(() => _index = index),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.map_outlined),
                label: '지도',
              ),
              NavigationDestination(
                icon: Icon(Icons.route_outlined),
                label: '길찾기',
              ),
              NavigationDestination(
                icon: Icon(Icons.flag_outlined),
                label: '제보',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                label: '마이',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
