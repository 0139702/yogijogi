import 'package:material_ui/material_ui.dart';

import 'core/app_config.dart';
import 'core/app_colors.dart';
import 'core/app_theme.dart';
import 'features/map/map_screen.dart';
import 'features/map/prime_floor.dart';
import 'features/navigation/guidance.dart';
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
  GuidanceView _view = GuidanceView.top;

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final demoRoute = primeDemoRoute(_start, _destination, _routeOption);
    final isMapHome = _index == 0 && _guideStep == null;
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
            backgroundColor: isMapHome ? CampusHomeColors.header : null,
            toolbarHeight: isMapHome ? 64 : null,
            titleSpacing: isMapHome ? 16 : null,
            title: _index == 0
                ? (isMapHome ? const _CampusTitle() : const Text('요기조기'))
                : Text(['요기조기', '길찾기', '제보', '마이'][_index]),
            actions: [
              if (_index == 0)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: IconButton.filledTonal(
                    style: IconButton.styleFrom(
                      backgroundColor: CampusHomeColors.blueSoft,
                      foregroundColor: AppColors.textPrimary,
                    ),
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
                    title: Text('캠퍼스 데모'),
                    subtitle: Text('성신여대 수정캠퍼스 · 프라임관 6층'),
                  ),
                ],
              ),
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

class _CampusTitle extends StatelessWidget {
  const _CampusTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 18,
          backgroundColor: CampusHomeColors.blueStrong,
          foregroundColor: Colors.white,
          child: Icon(Icons.explore_outlined, size: 21),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SUNGSHIN WOMEN’S UNIVERSITY',
                style: AppTextStyles.caption.copyWith(
                  color: CampusHomeColors.blueStrong,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .25,
                  height: 1.15,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'YogiJogi',
                semanticsLabel: '요기조기',
                style: AppTextStyles.title.copyWith(
                  color: CampusHomeColors.wordmark,
                  fontSize: 20,
                  height: 1.05,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
