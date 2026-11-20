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

  testWidgets('opens the reports tab without an API configuration', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('캠퍼스 지도 준비 중'), findsOneWidget);

    await tester.tap(find.text('제보'));
    await tester.pumpAndSettle();

    expect(find.text('제보를 보려면 API 주소를 설정해 주세요.'), findsOneWidget);
  });
}
