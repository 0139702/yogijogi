import 'dart:ui';

import '../navigation/route_option.dart';

/// Approximate positions on the floor guide, in normalized map coordinates.
enum PrimePlace {
  elevator(
    '엘리베이터',
    '6층 엘리베이터 앞',
    Rect.fromLTWH(.05, .31, .16, .16),
    Offset(.21, .40),
  ),
  room601(
    '601호',
    '601호 네트워크보안 실습실',
    Rect.fromLTWH(.22, .57, .23, .30),
    Offset(.36, .57),
  ),
  room602(
    '602호',
    '602호 프로그래밍 실습실 A',
    Rect.fromLTWH(.45, .57, .23, .30),
    Offset(.56, .57),
  ),
  room603(
    '603호',
    '603호 프로그래밍 실습실 B',
    Rect.fromLTWH(.68, .57, .26, .30),
    Offset(.79, .57),
  ),
  room604(
    '604호',
    '604호 해킹실습실',
    Rect.fromLTWH(.58, .11, .29, .29),
    Offset(.74, .40),
  ),
  room605(
    '605호',
    '605호 디지털보안 실습실',
    Rect.fromLTWH(.27, .11, .31, .29),
    Offset(.43, .40),
  ),
  primeBuilding('프라임관', '프라임관'),
  artsBuilding('조형관', '조형관');

  const PrimePlace(this.mapLabel, this.label, [this.bounds, this.door]);

  final String mapLabel;
  final String label;
  final Rect? bounds;
  final Offset? door;

  String get detail => switch (this) {
    primeBuilding || artsBuilding => '수정캠퍼스 · 건물',
    _ => '프라임관 6층 · 층 안내도 기반 데모',
  };

  String get searchTerms => switch (this) {
    primeBuilding => '공학 IT 프라임관 건물',
    artsBuilding => '미술 디자인 조형관 조형1관 건물',
    elevator => '프라임관 6층 엘리베이터 승강기',
    _ => '프라임관 6층 강의실 실습실',
  };
}

final primeFloorPlaces = PrimePlace.values
    .where((place) => place.bounds != null)
    .toList(growable: false);

const primeCorridor = Rect.fromLTWH(.21, .40, .73, .17);

List<Offset> primeDemoRoute(
  PrimePlace start,
  PrimePlace? destination,
  RouteOption option,
) {
  // The floor guide does not confirm step-free access along the whole route.
  final forward =
      start == PrimePlace.elevator && destination == PrimePlace.room603;
  final reverse =
      start == PrimePlace.room603 && destination == PrimePlace.elevator;
  if (option == RouteOption.stepFree || (!forward && !reverse)) {
    return const [];
  }

  final entrance = PrimePlace.elevator.door!;
  final roomDoor = PrimePlace.room603.door!;
  final corridorY = primeCorridor.bottom - primeCorridor.height / 3;
  final points = [
    entrance,
    Offset(entrance.dx, corridorY),
    Offset(roomDoor.dx, corridorY),
    roomDoor,
  ];
  return reverse ? points.reversed.toList() : points;
}

const primeHall = Rect.fromLTWH(.05, .47, .17, .18);
const primeStairs = [
  Rect.fromLTWH(.05, .11, .18, .19),
  Rect.fromLTWH(.87, .11, .10, .29),
];
