import 'package:flutter_test/flutter_test.dart';
import 'package:yogijogi/app.dart';

void main() {
  testWidgets('opens indoor route setup from the map tab', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('길찾기 열기'));
    await tester.pumpAndSettle();

    expect(find.text('프라임관 6층 · 도면 기반 데모'), findsOneWidget);
    expect(find.text('출발지'), findsOneWidget);
    expect(find.text('목적지'), findsOneWidget);
    expect(find.text('계단 없는 경로'), findsOneWidget);
  });

  testWidgets('selects a room on the floor map as destination', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('603호'));
    await tester.pumpAndSettle();

    expect(find.text('6층 엘리베이터 앞'), findsOneWidget);
    expect(find.text('603호 프로그래밍 실습실 B'), findsOneWidget);

    await tester.tap(find.text('지도에서 경로 보기'));
    await tester.pumpAndSettle();

    expect(find.text('샘플 경로 · 엘리베이터 앞 → 603호'), findsOneWidget);
    await tester.tap(find.text('602호'));
    await tester.pumpAndSettle();

    expect(find.text('지도에서 경로 보기'), findsNothing);
    await tester.tap(find.text('지도'));
    await tester.pumpAndSettle();

    expect(find.text('샘플 경로 · 엘리베이터 앞 → 603호'), findsNothing);
  });

  testWidgets('opens the reports tab without an API configuration', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('프라임관 6층'), findsOneWidget);

    await tester.tap(find.text('제보'));
    await tester.pumpAndSettle();

    expect(find.text('제보를 보려면 API 주소를 설정해 주세요.'), findsOneWidget);
  });

  testWidgets('route options only display verified demo paths', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('603호'));
    await tester.pumpAndSettle();

    final stepFree = find.text('계단 없는 경로');
    await tester.scrollUntilVisible(stepFree, 150);
    await tester.tap(stepFree);
    await tester.pumpAndSettle();
    final unavailable = find.text('확인된 계단 없는 경로가 없습니다.');
    await tester.scrollUntilVisible(unavailable, 100);
    expect(unavailable, findsOneWidget);

    await tester.tap(find.text('지도'));
    await tester.pumpAndSettle();
    expect(find.text('샘플 경로 · 엘리베이터 앞 → 603호'), findsNothing);

    await tester.tap(find.text('길찾기 열기'));
    await tester.pumpAndSettle();
    final elevator = find.text('엘리베이터 우선');
    await tester.scrollUntilVisible(elevator, -100);
    await tester.tap(elevator);
    await tester.pumpAndSettle();
    final showRoute = find.text('지도에서 경로 보기');
    await tester.scrollUntilVisible(showRoute, -100);
    await tester.tap(showRoute);
    await tester.pumpAndSettle();
    expect(find.text('샘플 경로 · 엘리베이터 앞 → 603호'), findsOneWidget);
  });
}
