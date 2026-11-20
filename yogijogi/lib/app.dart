import 'package:material_ui/material_ui.dart';

import 'core/app_config.dart';
import 'features/map/map_screen.dart';
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

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '요기조기',
      theme: ThemeData(colorSchemeSeed: Colors.teal),
      home: Scaffold(
        appBar: AppBar(title: Text(['캠퍼스 지도', '길찾기', '제보'][_index])),
        body: IndexedStack(
          index: _index,
          children: [
            MapScreen(onDirections: () => setState(() => _index = 1)),
            const RouteScreen(),
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
