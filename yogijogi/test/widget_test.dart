import 'package:flutter_test/flutter_test.dart';
import 'package:yogijogi/app.dart';

void main() {
  testWidgets('asks to log in when opening the reports tab', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('캠퍼스 지도 준비 중'), findsOneWidget);

    await tester.tap(find.text('제보'));
    await tester.pumpAndSettle();

    expect(find.text('로그인하고 제보에 참여해요'), findsOneWidget);
  });
}
