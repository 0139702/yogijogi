import 'package:material_ui/material_ui.dart';

import 'core/app_colors.dart';
import 'core/app_config.dart';
import 'features/map/map_screen.dart';
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
      theme: ThemeData(
        colorSchemeSeed: AppColors.brand,
        scaffoldBackgroundColor: AppColors.background,
      ),
      home: Scaffold(
        appBar: AppBar(title: Text(_index == 0 ? '캠퍼스 지도' : '제보')),
        body: _index == 0 ? const MapScreen() : ReportsScreen(api: _api),
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
