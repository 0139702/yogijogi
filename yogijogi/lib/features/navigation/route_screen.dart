import 'package:material_ui/material_ui.dart';

import '../map/prime_floor.dart';
import 'route_option.dart';

class RouteScreen extends StatelessWidget {
  const RouteScreen({
    super.key,
    required this.start,
    required this.destination,
    required this.option,
    required this.hasDemoRoute,
    required this.onOptionChanged,
    required this.onStartChanged,
    required this.onDestinationChanged,
    required this.onShowRoute,
  });

  final PrimePlace start;
  final PrimePlace? destination;
  final RouteOption option;
  final bool hasDemoRoute;
  final ValueChanged<RouteOption> onOptionChanged;
  final ValueChanged<PrimePlace> onStartChanged;
  final ValueChanged<PrimePlace> onDestinationChanged;
  final VoidCallback onShowRoute;

  Widget _placeField({
    required String label,
    required PrimePlace? value,
    required ValueChanged<PrimePlace> onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<PrimePlace>(
          isExpanded: true,
          isDense: true,
          value: value,
          hint: const Text('장소 선택'),
          onChanged: (place) {
            if (place != null) onChanged(place);
          },
          items: [
            for (final place in PrimePlace.values)
              DropdownMenuItem(value: place, child: Text(place.label)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final end = destination;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '프라임관 6층 · 도면 기반 데모',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        _placeField(label: '출발지', value: start, onChanged: onStartChanged),
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            tooltip: '출발지와 목적지 바꾸기',
            icon: const Icon(Icons.swap_vert),
            onPressed: end == null
                ? null
                : () {
                    onDestinationChanged(start);
                    onStartChanged(end);
                  },
          ),
        ),
        _placeField(label: '목적지', value: end, onChanged: onDestinationChanged),
        if (hasDemoRoute) ...[
          const SizedBox(height: 16),
          const Text('이 구간은 같은 층이라 두 옵션 모두 같은 복도를 이용합니다.'),
          FilledButton.icon(
            onPressed: onShowRoute,
            icon: const Icon(Icons.map_outlined),
            label: const Text('지도에서 경로 보기'),
          ),
        ],
        const SizedBox(height: 24),
        Text('어떤 길로 갈까요?', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        for (final candidate in RouteOption.values)
          ListTile(
            leading: Icon(
              option == candidate
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
            ),
            title: Text(candidate.label),
            subtitle: Text(candidate.description),
            selected: option == candidate,
            onTap: () => onOptionChanged(candidate),
          ),
        const SizedBox(height: 8),
        if (end == start)
          const Text('출발지와 목적지를 다르게 선택해 주세요.')
        else if (end != null && !hasDemoRoute)
          Text(
            option == RouteOption.stepFree
                ? '확인된 계단 없는 경로가 없습니다.'
                : '이 출발지와 목적지 조합의 샘플 경로가 없습니다.',
          ),
      ],
    );
  }
}
