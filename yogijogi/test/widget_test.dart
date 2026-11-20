import 'package:flutter_test/flutter_test.dart';
import 'package:yogijogi/app.dart';

void main() {
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
