import 'dart:ui';

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
  );

  const PrimePlace(this.mapLabel, this.label, this.bounds, this.door);

  final String mapLabel;
  final String label;
  final Rect bounds;
  final Offset door;
}

const primeCorridor = Rect.fromLTWH(.21, .40, .73, .17);
const primeHall = Rect.fromLTWH(.05, .47, .17, .18);
const primeStairs = [
  Rect.fromLTWH(.05, .11, .18, .19),
  Rect.fromLTWH(.87, .11, .10, .29),
];
