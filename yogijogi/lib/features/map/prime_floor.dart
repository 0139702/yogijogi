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
  artsBuilding('조형1관', '조형1관'),
  artsBuilding2('조형2관', '조형2관'),
  musicHall('음악대학', '음악대학'),
  sungshinHall('성신관', '성신관'),
  scienceHall('과학관', '과학관'),
  nanhyangHall('난향관', '난향관'),
  sujeongHallA('수정관 A동', '수정관 A동'),
  sujeongHallB('수정관 B동', '수정관 B동'),
  sujeongHallC('수정관 C동', '수정관 C동'),
  centralLibrary('중앙도서관', '중앙도서관'),
  sungshinAnnex('성신별관', '성신별관');

  const PrimePlace(this.mapLabel, this.label, [this.bounds, this.door]);

  final String mapLabel;
  final String label;
  final Rect? bounds;
  final Offset? door;

  String get detail => bounds == null ? '수정캠퍼스 · 건물' : '프라임관 6층 · 층 안내도 기준';

  String get searchTerms => switch (this) {
    primeBuilding => '공학 과학 IT 프라임관 건물',
    artsBuilding || artsBuilding2 => '미술 디자인 조형관 미술대학',
    musicHall => '음악 음악관 음대',
    scienceHall => '공학 과학 자연과학',
    elevator => '프라임관 6층 엘리베이터 승강기',
    sungshinHall => '성신관 바퀴벌레 벌레 주의',
    _ => bounds == null ? label : '프라임관 6층 강의실 실습실',
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
