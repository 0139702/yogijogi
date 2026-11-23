import 'package:material_ui/material_ui.dart';

import 'core/app_config.dart';
import 'core/app_theme.dart';
import 'features/map/map_screen.dart';
import 'features/map/prime_floor.dart';
import 'features/navigation/route_option.dart';
import 'features/navigation/route_screen.dart';
import 'features/reports/report_api.dart';
import 'features/reports/reports_screen.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _api = ReportApi(AppConfig.apiBaseUrl);
  int _index = 0;
  PrimePlace _start = PrimePlace.elevator;
  PrimePlace? _destination;
  RouteOption _routeOption = RouteOption.shortest;
  int? _guideStep;
  bool _routePreview = false;

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final demoRoute = primeDemoRoute(_start, _destination, _routeOption);
    final routeLabel = demoRoute.isEmpty
        ? null
        : _start == PrimePlace.elevator
        ? '경로 · 엘리베이터 앞 → 603호'
        : '경로 · 603호 → 엘리베이터 앞';
    return MaterialApp(
      title: '요기조기',
      theme: AppTheme.light,
      home: Builder(
        builder: (context) => Scaffold(
          appBar: _index <= 1
              ? null
              : AppBar(title: Text(['요기조기', '길찾기', '제보', '마이'][_index])),
          body: IndexedStack(
            index: _index,
            children: [
              MapScreen(
                demoRoute: demoRoute,
                routeLabel: routeLabel,
                start: _start,
                destination: _destination,
                guideStep: _guideStep,
                active: _index == 0,
                routePreview: _routePreview && demoRoute.isNotEmpty,
                onReport: (location) =>
                    showReportForm(context, _api, location: location),
                onDirections: () => setState(() {
                  _routePreview = false;
                  _index = 1;
                }),
                onPlaceSelected: (place) => setState(() {
                  _routePreview = false;
                  _destination = place;
                  _guideStep = null;
                  _index = 1;
                }),
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
                route: demoRoute,
                onOptionChanged: (option) => setState(() {
                  _routeOption = option;
                  _guideStep = null;
                }),
                onStartChanged: (place) => setState(() {
                  _start = place;
                  _guideStep = null;
                }),
                onShowRoute: () => setState(() {
                  _routePreview = true;
                  _guideStep = null;
                  _index = 0;
                }),
                onStartGuidance: () => setState(() {
                  _routePreview = false;
                  _guideStep = 0;
                  _index = 0;
                }),
                onDestinationChanged: (place) => setState(() {
                  _routePreview = false;
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
                ReportsScreen(api: _api)
              else
                const SizedBox.shrink(),
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ListTile(
                    leading: const Icon(Icons.flag_outlined),
                    title: const Text('제보 피드 보기'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => setState(() => _index = 2),
                  ),
                  const ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('캠퍼스 정보'),
                    subtitle: Text('성신여대 수정캠퍼스 · 프라임관 6층'),
                  ),
                ],
              ),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (index) => setState(() {
              _routePreview = false;
              _index = index;
            }),
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
