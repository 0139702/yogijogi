import 'package:material_ui/material_ui.dart';

import 'core/app_config.dart';
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

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final demoRoute = primeDemoRoute(_start, _destination, _routeOption);
    return MaterialApp(
      title: '요기조기',
      theme: ThemeData(colorSchemeSeed: Colors.teal),
      home: Scaffold(
        appBar: AppBar(title: Text(['캠퍼스 지도', '길찾기', '제보'][_index])),
        body: IndexedStack(
          index: _index,
          children: [
            MapScreen(
              demoRoute: demoRoute,
              onDirections: () => setState(() => _index = 1),
              onPlaceSelected: (place) => setState(() {
                _destination = place;
                _index = 1;
              }),
            ),
            RouteScreen(
              start: _start,
              destination: _destination,
              option: _routeOption,
              hasDemoRoute: demoRoute.isNotEmpty,
              onOptionChanged: (option) =>
                  setState(() => _routeOption = option),
              onStartChanged: (place) => setState(() => _start = place),
              onShowRoute: () => setState(() => _index = 0),
              onDestinationChanged: (place) =>
                  setState(() => _destination = place),
            ),
            if (_index == 2)
              ReportsScreen(api: _api)
            else
              const SizedBox.shrink(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (index) => setState(() => _index = index),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.map_outlined), label: '지도'),
            NavigationDestination(
              icon: Icon(Icons.route_outlined),
              label: '길찾기',
            ),
            NavigationDestination(icon: Icon(Icons.flag_outlined), label: '제보'),
          ],
        ),
      ),
    );
  }
}
