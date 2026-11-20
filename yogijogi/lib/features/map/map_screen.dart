import 'package:material_ui/material_ui.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key, required this.onDirections});

  final VoidCallback onDirections;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.layers_outlined, size: 48),
          const SizedBox(height: 12),
          const Text('캠퍼스 지도 준비 중'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onDirections,
            icon: const Icon(Icons.turn_right),
            label: const Text('길찾기 열기'),
          ),
        ],
      ),
    );
  }
}
