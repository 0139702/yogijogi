import 'package:flutter/widgets.dart';
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
    expect(find.text('안내받을 목적지를 선택해 주세요.'), findsOneWidget);
    expect(find.text('계단 없는 경로'), findsOneWidget);
  });

  testWidgets('searches building tags and clears recent place selections', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    final searchButton = find.text('건물·강의실 검색');
    await tester.tap(searchButton);
    await tester.pumpAndSettle();
    expect(find.text('최근 검색'), findsOneWidget);
    expect(find.text('빠른 검색'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), '미술');
    await tester.pumpAndSettle();
    await tester.tap(find.text('조형관'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('목적지로 설정'));
    await tester.pumpAndSettle();
    expect(find.text('조형관'), findsOneWidget);
    expect(find.text('이 경로로 안내 시작'), findsNothing);

    await tester.tap(find.text('지도'));
    await tester.pumpAndSettle();
    await tester.tap(searchButton);
    await tester.pumpAndSettle();
    expect(find.text('조형관'), findsOneWidget);
    await tester.tap(find.text('모두 지우기'));
    await tester.pumpAndSettle();
    expect(find.text('최근 검색이 없습니다.'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), '공학');
    await tester.pumpAndSettle();
    expect(find.text('프라임관'), findsOneWidget);
  });

  testWidgets('selects a room on the floor map as destination', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('603호'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('목적지로 설정'));
    await tester.pumpAndSettle();

    expect(find.text('6층 엘리베이터 앞'), findsOneWidget);
    expect(find.text('603호 프로그래밍 실습실 B'), findsOneWidget);

    await tester.tap(find.text('지도에서 경로 보기'));
    await tester.pumpAndSettle();

    expect(find.text('샘플 경로 · 엘리베이터 앞 → 603호'), findsOneWidget);
    await tester.tap(find.text('602호'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('목적지로 설정'));
    await tester.pumpAndSettle();

    expect(find.text('지도에서 경로 보기'), findsNothing);
    await tester.tap(find.text('지도'));
    await tester.pumpAndSettle();

    expect(find.text('샘플 경로 · 엘리베이터 앞 → 603호'), findsNothing);
  });

  testWidgets('asks to log in when opening the reports tab', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('프라임관 6층'), findsOneWidget);

    await tester.tap(find.text('제보'));
    await tester.pumpAndSettle();

    expect(find.text('로그인하고 제보에 참여해요'), findsOneWidget);
  });

  testWidgets('route options only display verified demo paths', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('603호'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('목적지로 설정'));
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

  testWidgets('confirms a search result, swaps endpoints and runs guidance', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('건물·강의실 검색'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), '603');
    await tester.pumpAndSettle();
    await tester.tap(find.text('603호 프로그래밍 실습실 B'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('목적지로 설정'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('출발지와 목적지 바꾸기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('이 경로로 안내 시작'));
    await tester.pumpAndSettle();

    expect(find.text('샘플 경로 · 603호 → 엘리베이터 앞'), findsOneWidget);
    expect(find.text('출발'), findsOneWidget);
    expect(find.text('도착'), findsOneWidget);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -350));
    await tester.pumpAndSettle();
    await tester.tap(find.text('수룡이 따라가기'));
    await tester.pumpAndSettle();
    expect(find.text('수룡이 따라가기 시점 선택됨 · 3D 적용 전'), findsOneWidget);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -150));
    await tester.pumpAndSettle();
    await tester.tap(find.text('다음 단계'));
    await tester.pumpAndSettle();
    expect(find.text('데모 안내 · 2/4'), findsOneWidget);
    final card = find.byKey(const ValueKey('guidance-step-card'));
    await tester.ensureVisible(card);
    await tester.fling(card, const Offset(-160, 0), 700);
    await tester.pumpAndSettle();
    expect(find.text('데모 안내 · 3/4'), findsOneWidget);
    final preview = find.text('안내도 확대');
    await tester.ensureVisible(preview);
    await tester.tap(preview);
    await tester.pumpAndSettle();
    expect(find.text('층 안내도 · 데모'), findsOneWidget);
    await tester.tap(find.text('닫기'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
    await tester.pumpAndSettle();
    await tester.tap(find.text('안내 종료'));
    await tester.pumpAndSettle();
    expect(find.text('출발지'), findsOneWidget);
  });
}
