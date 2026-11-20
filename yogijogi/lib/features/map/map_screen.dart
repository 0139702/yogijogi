import 'package:material_ui/material_ui.dart';

import 'prime_floor.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({
    super.key,
    required this.onDirections,
    required this.onPlaceSelected,
  });

  final VoidCallback onDirections;
  final ValueChanged<PrimePlace> onPlaceSelected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('프라임관 6층', style: Theme.of(context).textTheme.headlineSmall),
        const Text('층 안내도 기반 데모 · 방을 눌러 목적지 선택'),
        OutlinedButton.icon(
          onPressed: onDirections,
          icon: const Icon(Icons.turn_right),
          label: const Text('길찾기 열기'),
        ),
        const SizedBox(height: 16),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: AspectRatio(
              aspectRatio: 1.45,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final height = constraints.maxHeight;
                  Rect scale(Rect bounds) => Rect.fromLTRB(
                    bounds.left * width,
                    bounds.top * height,
                    bounds.right * width,
                    bounds.bottom * height,
                  );
                  const passage = ColoredBox(color: Color(0xffe2e8e6));
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xfff3f6f5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fromRect(
                          rect: scale(primeHall),
                          child: passage,
                        ),
                        Positioned.fromRect(
                          rect: scale(primeCorridor),
                          child: const ColoredBox(
                            color: Color(0xffe2e8e6),
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: Text(
                                '중앙 복도',
                                style: TextStyle(fontSize: 11),
                              ),
                            ),
                          ),
                        ),
                        for (final stairs in primeStairs)
                          Positioned.fromRect(
                            rect: scale(stairs),
                            child: const ColoredBox(
                              color: Color(0xffe4e0ed),
                              child: Center(
                                child: Icon(
                                  Icons.stairs_outlined,
                                  semanticLabel: '계단',
                                ),
                              ),
                            ),
                          ),
                        for (final place in PrimePlace.values)
                          Positioned.fromRect(
                            rect: scale(place.bounds).deflate(1),
                            child: Semantics(
                              label: place.label,
                              button: true,
                              child: Tooltip(
                                message: place.label,
                                excludeFromSemantics: true,
                                child: Material(
                                  color: place == PrimePlace.elevator
                                      ? const Color(0xffcde6da)
                                      : const Color(0xffdae4f5),
                                  borderRadius: BorderRadius.circular(6),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(6),
                                    onTap: () => onPlaceSelected(place),
                                    child: Center(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: ExcludeSemantics(
                                          child: Text(place.mapLabel),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        for (final place in PrimePlace.values)
                          Positioned(
                            left: place.door.dx * width - 3,
                            top: place.door.dy * height - 3,
                            child: const IgnorePointer(
                              child: SizedBox.square(
                                dimension: 6,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Color(0xff50569a),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
