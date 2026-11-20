import 'package:material_ui/material_ui.dart';

import '../map/prime_floor.dart';

enum _RouteOption {
  shortest('최단거리', '이동 거리가 가장 짧은 경로'),
  elevator('엘리베이터 우선', '엘리베이터를 우선하며 계단이 포함될 수 있음'),
  stepFree('계단 없는 경로', '계단을 제외한 연결만 이용');

  const _RouteOption(this.label, this.description);

  final String label;
  final String description;
}

class RouteScreen extends StatefulWidget {
  const RouteScreen({
    super.key,
    required this.destination,
    required this.onDestinationChanged,
  });

  final PrimePlace? destination;
  final ValueChanged<PrimePlace> onDestinationChanged;

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  PrimePlace _start = PrimePlace.elevator;
  _RouteOption _option = _RouteOption.shortest;

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
    final destination = widget.destination;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '프라임관 6층 · 도면 기반 데모',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        _placeField(
          label: '출발지',
          value: _start,
          onChanged: (place) => setState(() => _start = place),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            tooltip: '출발지와 목적지 바꾸기',
            icon: const Icon(Icons.swap_vert),
            onPressed: destination == null
                ? null
                : () {
                    widget.onDestinationChanged(_start);
                    setState(() => _start = destination);
                  },
          ),
        ),
        _placeField(
          label: '목적지',
          value: destination,
          onChanged: widget.onDestinationChanged,
        ),
        const SizedBox(height: 24),
        Text('어떤 길로 갈까요?', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        for (final option in _RouteOption.values)
          ListTile(
            leading: Icon(
              _option == option
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
            ),
            title: Text(option.label),
            subtitle: Text(option.description),
            selected: _option == option,
            onTap: () => setState(() => _option = option),
          ),
        const SizedBox(height: 8),
        if (destination == _start)
          const Text('출발지와 목적지를 다르게 선택해 주세요.')
        else if (destination != null)
          const Text('현재 데모에는 계산된 경로가 없습니다.'),
      ],
    );
  }
}
