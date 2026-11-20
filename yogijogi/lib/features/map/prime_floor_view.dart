import 'package:material_ui/material_ui.dart';

import 'prime_floor.dart';

class PrimeFloorView extends StatelessWidget {
  const PrimeFloorView({
    super.key,
    required this.route,
    required this.onPlaceSelected,
    this.guidePosition,
    this.highlightedPlace,
  });
  final List<Offset> route;
  final ValueChanged<PrimePlace> onPlaceSelected;
  final Offset? guidePosition;
  final PrimePlace? highlightedPlace;

  @override
  Widget build(BuildContext context) {
    final position = guidePosition;
    return Center(
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
                    Positioned.fromRect(rect: scale(primeHall), child: passage),
                    Positioned.fromRect(
                      rect: scale(primeCorridor),
                      child: const ColoredBox(
                        color: Color(0xffe2e8e6),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Text('중앙 복도', style: TextStyle(fontSize: 11)),
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
                    for (final place in primeFloorPlaces)
                      Positioned.fromRect(
                        rect: scale(place.bounds!).deflate(1),
                        child: Semantics(
                          label: place.label,
                          button: true,
                          child: Tooltip(
                            message: place.label,
                            excludeFromSemantics: true,
                            child: Material(
                              color: place == highlightedPlace
                                  ? const Color(0xffa3d5bd)
                                  : place == PrimePlace.elevator
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
                    for (final place in primeFloorPlaces)
                      Positioned(
                        left: place.door!.dx * width - 3,
                        top: place.door!.dy * height - 3,
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
                    if (route.isNotEmpty)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(painter: _DemoRoutePainter(route)),
                        ),
                      ),
                    if (position != null)
                      Positioned(
                        left: position.dx * width - 12,
                        top: position.dy * height - 12,
                        child: const IgnorePointer(
                          child: Icon(
                            Icons.navigation,
                            color: Color(0xff50569a),
                            semanticLabel: '??? ?? ??',
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
    );
  }
}

class _DemoRoutePainter extends CustomPainter {
  const _DemoRoutePainter(this.points);

  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    Offset scale(Offset point) =>
        Offset(point.dx * size.width, point.dy * size.height);

    final start = scale(points.first);
    final end = scale(points.last);
    final path = Path()..moveTo(start.dx, start.dy);
    for (final point in points.skip(1)) {
      final position = scale(point);
      path.lineTo(position.dx, position.dy);
    }

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 7
      ..color = const Color(0xffffffff);
    canvas.drawPath(path, stroke);
    stroke
      ..strokeWidth = 4
      ..color = const Color(0xff00695c);
    canvas.drawPath(path, stroke);

    final marker = Paint()..color = const Color(0xffffffff);
    canvas.drawCircle(start, 5, marker);
    canvas.drawCircle(end, 6, marker);
    marker.color = stroke.color;
    canvas.drawCircle(start, 3, marker);
    canvas.drawCircle(end, 4, marker);
  }

  @override
  bool shouldRepaint(_DemoRoutePainter oldDelegate) =>
      oldDelegate.points != points;
}
