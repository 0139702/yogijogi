enum RouteOption {
  shortest('최단거리', '이동 거리가 가장 짧은 경로'),
  elevator('엘리베이터 우선', '엘리베이터를 우선하며 계단이 포함될 수 있음'),
  stepFree('계단 없는 경로', '계단을 제외한 연결만 이용');

  const RouteOption(this.label, this.description);

  final String label;
  final String description;
}
