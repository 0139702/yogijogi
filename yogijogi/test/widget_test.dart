import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yogijogi/app.dart';

void main() {
  const desktop = TargetPlatformVariant({TargetPlatform.windows});
  testWidgets('opens full-screen quick search and returns to the campus map', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MyApp());
    expect(find.byTooltip('알림'), findsOneWidget);
    expect(find.text('YogiJogi'), findsOneWidget);
    final filterCenter = tester.getCenter(find.text('전체'));
    for (final label in ['빈 강의실', '행사 2건', '벌레 주의']) {
      expect(tester.getCenter(find.text(label)).dy, filterCenter.dy);
    }
    final search = tester.getRect(find.text('건물명, 강의실, 또는 제보 검색'));
    final directions = tester.getCenter(find.byTooltip('길찾기 열기'));
    expect(directions.dx, greaterThan(search.right));
    expect(directions.dy, closeTo(search.center.dy, 1));
    await tester.tap(find.byTooltip('수룡이 위치로 이동'));
    await tester.tap(find.text('빈 강의실'));
    await tester.pumpAndSettle();
    expect(find.text('빈 강의실을 확인할 수 있는 시간표가 없습니다.'), findsOneWidget);
    await tester.tap(find.text('전체'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('건물명, 강의실, 또는 제보 검색').first);
    await tester.pumpAndSettle();

    expect(find.byTooltip('검색 닫기'), findsOneWidget);
    expect(find.text('지도'), findsOneWidget);
    expect(find.text('빠른 검색'), findsOneWidget);
    await tester.tap(find.text('빈 강의실'));
    await tester.pumpAndSettle();
    expect(find.text('빈 강의실을 확인할 수 있는 시간표가 없습니다.'), findsOneWidget);

    await tester.tap(find.byTooltip('검색 닫기'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('알림'), findsOneWidget);
    expect(find.text('YogiJogi'), findsOneWidget);
  }, variant: desktop);

  testWidgets('opens indoor route setup from the map tab', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.byTooltip('길찾기 열기'));
    await tester.pumpAndSettle();

    expect(find.text('프라임관 6층 · 도면 기준'), findsOneWidget);
    expect(find.text('출발지'), findsOneWidget);
    expect(find.text('목적지'), findsOneWidget);
    final startButton = find.widgetWithText(FilledButton, '이 경로로 안내 시작');
    expect(startButton.hitTestable(), findsOneWidget);
    expect(tester.widget<FilledButton>(startButton).onPressed, isNull);
    await tester.scrollUntilVisible(find.text('안내받을 목적지를 선택해 주세요.'), 150);
    await tester.pumpAndSettle();
    expect(find.text('안내받을 목적지를 선택해 주세요.'), findsOneWidget);
    expect(find.text('유니버셜 로드'), findsOneWidget);
    expect(find.byIcon(Icons.accessible), findsOneWidget);
    expect(find.text('추천'), findsNothing);
  }, variant: desktop);

  testWidgets('searches building tags and clears recent place selections', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    final searchButton = find.text('건물명, 강의실, 또는 제보 검색').first;
    await tester.tap(searchButton);
    await tester.pumpAndSettle();
    expect(find.text('최근 검색'), findsOneWidget);
    expect(find.text('빠른 검색'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), '미술');
    await tester.pumpAndSettle();
    await tester.tap(find.text('조형관'));
    await tester.pumpAndSettle();
    expect(find.text('조형관 · 미술대학'), findsOneWidget);
    expect(find.text('제보하기'), findsOneWidget);
    expect(find.text('강의실 찾기'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
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
  }, variant: desktop);

  testWidgets('selects a room on the floor map as destination', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('건물명, 강의실, 또는 제보 검색'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), '공학');
    await tester.pumpAndSettle();
    await tester.tap(find.text('프라임관'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('2D 층 안내도'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('603호'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('목적지로 설정'));
    await tester.pumpAndSettle();

    expect(find.text('6층 엘리베이터 앞'), findsOneWidget);
    expect(find.text('603호 프로그래밍 실습실 B'), findsOneWidget);

    await tester.tap(find.byTooltip('지도에서 경로 보기'));
    await tester.pumpAndSettle();

    expect(find.text('경로 · 엘리베이터 앞 → 603호'), findsOneWidget);
    await tester.tap(find.text('602호'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('목적지로 설정'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<IconButton>(
            find.ancestor(
              of: find.byTooltip('지도에서 경로 보기'),
              matching: find.byType(IconButton),
            ),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('지도'));
    await tester.pumpAndSettle();

    expect(find.text('경로 · 엘리베이터 앞 → 603호'), findsNothing);
  }, variant: desktop);

  testWidgets('asks to log in when opening the reports tab', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byTooltip('알림'), findsOneWidget);
    expect(find.text('YogiJogi'), findsOneWidget);

    await tester.tap(find.text('제보'));
    await tester.pumpAndSettle();

    expect(find.text('로그인하고 제보에 참여해요'), findsOneWidget);
  }, variant: desktop);

  testWidgets('requires login when reporting a building from the map', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('건물명, 강의실, 또는 제보 검색'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), '공학');
    await tester.pumpAndSettle();
    await tester.tap(find.text('프라임관'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('제보하기'));
    await tester.pumpAndSettle();
    expect(find.text('로그인하고 제보에 참여해요'), findsOneWidget);
  }, variant: desktop);

  testWidgets('route options only display verified demo paths', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('건물명, 강의실, 또는 제보 검색'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), '공학');
    await tester.pumpAndSettle();
    await tester.tap(find.text('프라임관'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('2D 층 안내도'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('603호'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('목적지로 설정'));
    await tester.pumpAndSettle();

    expect(find.text('추천'), findsOneWidget);
    final recommendation = tester.getRect(find.text('추천'));
    final title = tester.getRect(find.text('엘리베이터 우선'));
    final description = tester.getRect(find.text('엘리베이터를 우선하며 계단이 포함될 수 있음'));
    expect(recommendation.left, greaterThan(title.right));
    expect(recommendation.top, lessThan(description.top));
    final stepFree = find.text('유니버셜 로드');
    await tester.scrollUntilVisible(stepFree, 150);
    await tester.pumpAndSettle();
    await tester.tap(stepFree);
    await tester.pumpAndSettle();
    final unavailable = find.text('확인된 계단 없는 경로가 없습니다.');
    await tester.scrollUntilVisible(unavailable, 100);
    await tester.pumpAndSettle();
    expect(unavailable, findsOneWidget);

    await tester.tap(find.text('지도'));
    await tester.pumpAndSettle();
    expect(find.text('경로 · 엘리베이터 앞 → 603호'), findsNothing);

    await tester.tap(find.byTooltip('길찾기 열기'));
    await tester.pumpAndSettle();
    final elevator = find.text('엘리베이터 우선');
    await tester.scrollUntilVisible(elevator, -100);
    await tester.pumpAndSettle();
    await tester.tap(elevator);
    await tester.pumpAndSettle();
    final showRoute = find.byTooltip('지도에서 경로 보기');
    await tester.scrollUntilVisible(showRoute, -100);
    await tester.pumpAndSettle();
    await tester.tap(showRoute);
    await tester.pumpAndSettle();
    expect(find.text('경로 · 엘리베이터 앞 → 603호'), findsOneWidget);
  }, variant: desktop);

  testWidgets('confirms a search result, swaps endpoints and runs guidance', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('건물명, 강의실, 또는 제보 검색').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), '603');
    await tester.pumpAndSettle();
    await tester.tap(find.text('603호 프로그래밍 실습실 B'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('목적지로 설정'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('출발지와 목적지 바꾸기'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('이 경로로 안내 시작'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('이 경로로 안내 시작'));
    await tester.pumpAndSettle();

    expect(find.text('603호 프로그래밍 실습실 B'), findsOneWidget);
    expect(find.byTooltip('길찾기 열기'), findsNothing);
    expect(find.text('건물명, 강의실, 또는 제보 검색'), findsNothing);
    expect(find.text('이전 단계'), findsNothing);
    expect(find.text('다음 단계'), findsNothing);
    expect(find.text('출발'), findsOneWidget);
    expect(find.text('도착'), findsOneWidget);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -350));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -150));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('2단계로 이동'));
    await tester.pumpAndSettle();
    expect(find.text('안내 · 2/4'), findsOneWidget);
    final card = find.byKey(const ValueKey('guidance-step-card'));
    await tester.ensureVisible(card);
    await tester.fling(card, const Offset(-160, 0), 700);
    await tester.pumpAndSettle();
    expect(find.text('안내 · 3/4'), findsOneWidget);
    final preview = find.text('안내도 확대');
    await tester.ensureVisible(preview);
    await tester.tap(preview);
    await tester.pumpAndSettle();
    expect(find.text('층 안내도'), findsOneWidget);
    await tester.tap(find.text('닫기'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('안내 종료'));
    await tester.tap(find.byTooltip('안내 종료'));
    await tester.pumpAndSettle();
    expect(find.text('출발지'), findsOneWidget);
  }, variant: desktop);
}
