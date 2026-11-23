import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_colors.dart';
import '../../core/header_icon_button.dart';
import 'campus_3d_screen.dart';
import 'place_search.dart';
import 'prime_floor.dart';
import 'prime_floor_view.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
    required this.demoRoute,
    required this.routeLabel,
    required this.start,
    required this.destination,
    required this.guideStep,
    required this.onDirections,
    required this.onPlaceSelected,
    required this.onStepChanged,
    required this.onEndGuidance,
    required this.onReport,
    required this.active,
    required this.routePreview,
  });

  final List<Offset> demoRoute;
  final String? routeLabel;
  final PrimePlace start;
  final PrimePlace? destination;
  final int? guideStep;
  final VoidCallback onDirections;
  final ValueChanged<PrimePlace> onPlaceSelected;
  final ValueChanged<int> onStepChanged;
  final VoidCallback onEndGuidance;
  final ValueChanged<String> onReport;
  final bool active;
  final bool routePreview;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const _recentKey = 'campus.recent_places';
  late final _preferences = _openPreferences();
  final _recent = <PrimePlace>[];
  Future<void>? _recentLoaded;
  Future<void> _pendingSave = Future.value();
  PlaceFilter _filter = PlaceFilter.all;
  final _campus = GlobalKey<Campus3dScreenState>();
  bool _indoor = false;
  bool _searchOpen = false;
  bool _placeSheetOpen = false;

  SharedPreferencesAsync? _openPreferences() {
    try {
      return SharedPreferencesAsync();
    } on StateError {
      return null;
    }
  }

  Future<void> _loadRecent() async {
    try {
      final names = await _preferences?.getStringList(_recentKey) ?? [];
      final places = {for (final place in PrimePlace.values) place.name: place};
      _recent.addAll(
        names.map((name) => places[name]).whereType<PrimePlace>().take(8),
      );
    } on Exception catch (error) {
      debugPrint('Recent places could not be loaded: ${error.runtimeType}');
    }
  }

  void _saveRecent() {
    final names = _recent.map((place) => place.name).toList();
    _pendingSave = _pendingSave.then((_) async {
      try {
        await _preferences?.setStringList(_recentKey, names);
      } on Exception catch (error) {
        debugPrint('Recent places could not be saved: ${error.runtimeType}');
      }
    });
    unawaited(_pendingSave);
  }

  Future<void> _openSearch(BuildContext context) async {
    await (_recentLoaded ??= _loadRecent());
    if (context.mounted && widget.active) setState(() => _searchOpen = true);
  }

  void _closeSearch() => setState(() => _searchOpen = false);

  Future<void> _selectSearchResult(PrimePlace place) async {
    _recent.remove(place);
    _recent.insert(0, place);
    if (_recent.length > 8) _recent.removeLast();
    _saveRecent();
    setState(() {
      _searchOpen = false;
      if (!widget.routePreview && widget.guideStep == null) {
        _indoor = place.bounds != null;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.active) {
        _campus.currentState?.focusPlace(place.name);
      }
    });
    if (place.bounds == null && !widget.routePreview) {
      await _openBuilding(place.name);
    } else {
      await _openPlace(context, place);
    }
  }

  Future<void> _openPlace(BuildContext context, PrimePlace place) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            0,
            AppSpacing.screenPadding,
            16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(place.label, style: AppTextStyles.title),
              const SizedBox(height: 4),
              Text(place.detail, style: AppTextStyles.caption),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.pop(sheetContext, true),
                child: const Text('목적지로 설정'),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed == true && context.mounted) widget.onPlaceSelected(place);
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_searchOpen || !widget.active,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop && _searchOpen && widget.active) _closeSearch();
    },
    child: IndexedStack(
      index: _searchOpen ? 1 : 0,
      children: [
        _buildMap(context),
        if (_searchOpen)
          PlaceSearch(
            recent: _recent,
            onClearRecent: () {
              _recent.clear();
              _saveRecent();
            },
            onClose: _closeSearch,
            onSelect: _selectSearchResult,
          )
        else
          const SizedBox.shrink(),
      ],
    ),
  );

  Widget _buildMap(BuildContext context) {
    final step = widget.guideStep;
    if (step == null) return _buildHome(context);
    final destination = widget.destination;
    return ColoredBox(
      color: const Color(0xffeaf5f2),
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          MediaQuery.paddingOf(context).top + 12,
          AppSpacing.screenPadding,
          24,
        ),
        children: [
          if (destination != null)
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.trip_origin,
                      color: AppColors.brand,
                    ),
                    title: Text(widget.start.label, style: AppTextStyles.body),
                    subtitle: Text('출발', style: AppTextStyles.caption),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.place_outlined,
                      color: AppColors.brandStrong,
                    ),
                    title: Text(destination.label, style: AppTextStyles.body),
                    subtitle: Text('도착', style: AppTextStyles.caption),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          if (Campus3dScreen.isSupported)
            SizedBox(
              height: 290,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Campus3dScreen(
                  key: _campus,
                  indoor: true,
                  filter: PlaceFilter.all.name,
                  active: widget.active && !_searchOpen,
                  route: widget.demoRoute,
                  step: step,
                  onPlace: _selectScenePlace,
                ),
              ),
            )
          else
            PrimeFloorView(
              route: widget.demoRoute,
              guidePosition: widget.demoRoute[step],
              onPlaceSelected: (place) => _openPlace(context, place),
            ),
          const SizedBox(height: 16),
          _GuidancePanel(
            step: step,
            lastStep: widget.demoRoute.length - 1,
            route: widget.demoRoute,
            onStepChanged: widget.onStepChanged,
            onEnd: widget.onEndGuidance,
          ),
        ],
      ),
    );
  }

  static final _buildings = {
    for (final place in PrimePlace.values)
      if (place.bounds == null)
        place.name: place == PrimePlace.artsBuilding
            ? '조형관 · 미술대학'
            : place.label,
  };

  void _selectScenePlace(String id) {
    if (_placeSheetOpen) return;
    if (_buildings.containsKey(id)) {
      unawaited(_openBuilding(id));
      return;
    }
    for (final room in primeFloorPlaces) {
      if (room.name == id) unawaited(_openPlace(context, room));
    }
  }

  Future<void> _openBuilding(String id) async {
    final title = _buildings[id];
    if (title == null || _placeSheetOpen) return;
    final hasFloor = id == PrimePlace.primeBuilding.name;
    _placeSheetOpen = true;
    final action = await showModalBottomSheet<_BuildingAction>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black38,
      builder: (sheetContext) => SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SheetHandle(),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: Text(title, style: AppTextStyles.title)),
                  IconButton(
                    tooltip: '2D 층 안내도',
                    icon: const Icon(Icons.help_outline, size: 27),
                    onPressed: () =>
                        Navigator.pop(sheetContext, _BuildingAction.floor),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _BuildingButton(
                label: '제보하기',
                color: const Color(0xffff6f85),
                onPressed: () =>
                    Navigator.pop(sheetContext, _BuildingAction.report),
              ),
              const SizedBox(height: 10),
              _BuildingButton(
                label: '강의실 찾기',
                color: const Color(0xff777bf8),
                onPressed: () =>
                    Navigator.pop(sheetContext, _BuildingAction.rooms),
              ),
            ],
          ),
        ),
      ),
    );
    _placeSheetOpen = false;
    if (!mounted || action == null) return;
    switch (action) {
      case _BuildingAction.report:
        widget.onReport(title.split(' · ').first);
      case _BuildingAction.floor:
        if (hasFloor) {
          await _showFloor();
        } else {
          _showUnavailable(title);
        }
      case _BuildingAction.rooms:
        if (!hasFloor) {
          _showUnavailable(title);
        } else if (Campus3dScreen.isSupported) {
          setState(() => _indoor = true);
        } else {
          await _showFloor();
        }
    }
  }

  void _showUnavailable(String title) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$title 층 안내도는 아직 준비 중입니다.')));
  }

  Future<void> _showFloor() async {
    final place = await Navigator.of(context).push<PrimePlace>(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('프라임관 6층 · 2D 안내도')),
          body: Center(
            child: InteractiveViewer(
              maxScale: 3,
              child: PrimeFloorView(
                route: widget.demoRoute,
                onPlaceSelected: (place) => Navigator.pop(context, place),
              ),
            ),
          ),
        ),
      ),
    );
    if (mounted && place != null) await _openPlace(context, place);
  }

  Widget _buildHome(BuildContext context) {
    final showingFloor = _indoor || widget.routePreview;
    final supports3d = Campus3dScreen.isSupported;
    const filters = {
      PlaceFilter.all: '전체',
      PlaceFilter.classrooms: '빈 강의실',
      PlaceFilter.events: '행사 2건',
      PlaceFilter.reports: '벌레 주의',
    };

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: const Color(0xffeaf5f2),
          child: supports3d
              ? Campus3dScreen(
                  key: _campus,
                  indoor: showingFloor,
                  filter: _filter.name,
                  active: widget.active && !_searchOpen,
                  route: widget.routePreview ? widget.demoRoute : const [],
                  onPlace: _selectScenePlace,
                )
              : const Center(child: Text('3D 지도는 Android와 iOS에서 볼 수 있어요.')),
        ),
        if (widget.routePreview && !supports3d)
          ColoredBox(
            color: const Color(0xffeaf5f2),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 146, 16, 64),
              child: Column(
                children: [
                  if (widget.routeLabel != null)
                    _RouteBadge(label: widget.routeLabel!),
                  Expanded(
                    child: Center(
                      child: PrimeFloorView(
                        route: widget.demoRoute,
                        onPlaceSelected: (place) => _openPlace(context, place),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        SafeArea(
          bottom: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, showingFloor ? 14 : 80, 16, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showingFloor && supports3d)
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      child: ListTile(
                        leading: IconButton(
                          tooltip: '캠퍼스로 돌아가기',
                          icon: const Icon(Icons.chevron_left),
                          onPressed: widget.routePreview
                              ? widget.onDirections
                              : () => setState(() => _indoor = false),
                        ),
                        title: const Text('프라임관 6층 · 3D 안내도'),
                        subtitle: Text(
                          widget.routePreview && widget.routeLabel != null
                              ? widget.routeLabel!
                              : '층 안내도 기준',
                        ),
                        trailing: IconButton(
                          tooltip: '2D 층 안내도',
                          onPressed: _showFloor,
                          icon: const Icon(Icons.help_outline),
                        ),
                      ),
                    )
                  else ...[
                    Row(
                      children: [
                        Expanded(
                          child: _SearchBar(onTap: () => _openSearch(context)),
                        ),
                        const SizedBox(width: 10),
                        _MapControl(
                          tooltip: '길찾기 열기',
                          icon: Icons.turn_right,
                          color: AppColors.surface,
                          backgroundColor: AppColors.brandStrong,
                          size: 54,
                          iconSize: 29,
                          onPressed: widget.onDirections,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        spacing: 8,
                        children: [
                          for (final entry in filters.entries)
                            _FilterPill(
                              label: entry.value,
                              selected: _filter == entry.key,
                              color: switch (entry.key) {
                                PlaceFilter.classrooms => const Color(
                                  0xffff686d,
                                ),
                                PlaceFilter.events => const Color(0xfff3cd46),
                                PlaceFilter.reports => AppColors.hazard,
                                _ => AppColors.brandStrong,
                              },
                              outline: entry.key == PlaceFilter.classrooms,
                              darkSelection: entry.key == PlaceFilter.events,
                              onTap: () => setState(
                                () => _filter = _filter == entry.key
                                    ? PlaceFilter.all
                                    : entry.key,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (_filter == PlaceFilter.classrooms)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            child: Text(
                              '빈 강의실을 확인할 수 있는 시간표가 없습니다.',
                              style: AppTextStyles.caption,
                            ),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (!showingFloor)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _CampusHeader(
              onNotifications: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: const Text('알림')),
                    body: const Center(child: Text('받은 알림이 없습니다.')),
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          right: 16,
          bottom: 16,
          child: _MapControl(
            tooltip: '수룡이 위치로 이동',
            icon: Icons.my_location,
            color: AppColors.brandStrong,
            size: 48,
            iconSize: 24,
            onPressed: () => _campus.currentState?.focusMascot(),
          ),
        ),
      ],
    );
  }
}

class _CampusHeader extends StatelessWidget {
  const _CampusHeader({required this.onNotifications});

  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          spacing: 8,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.surface,
              child: Image.asset(
                'assets/images/logo.png',
                width: 28,
                height: 28,
                semanticLabel: '요기조기 로고',
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SUNGSHIN WOMEN’S UNIVERSITY',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.brandStrong,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'YogiJogi',
                    style: AppTextStyles.title,
                    semanticsLabel: '요기조기',
                  ),
                ],
              ),
            ),
            HeaderIconButton.notifications(onPressed: onNotifications),
          ],
        ),
      ),
    ),
  );
}

enum _BuildingAction { report, rooms, floor }

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 48,
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0xffdae3eb),
        borderRadius: BorderRadius.circular(4),
      ),
    ),
  );
}

class _BuildingButton extends StatelessWidget {
  const _BuildingButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(48),
      backgroundColor: color,
      foregroundColor: Colors.white,
    ),
    child: Row(
      children: [
        const Icon(Icons.add, size: 26),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.color,
    required this.outline,
    required this.darkSelection,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final bool outline;
  final bool darkSelection;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    child: Material(
      color: selected ? color : Colors.white,
      shape: StadiumBorder(
        side: BorderSide(color: outline ? color : Colors.transparent),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Container(
          alignment: Alignment.center,
          constraints: const BoxConstraints(minHeight: 40, minWidth: 48),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            label,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w700,
              color: selected && !darkSelection
                  ? Colors.white
                  : const Color(0xff172d47),
            ),
          ),
        ),
      ),
    ),
  );
}

class _MapControl extends StatelessWidget {
  const _MapControl({
    required this.tooltip,
    required this.icon,
    required this.color,
    this.backgroundColor = AppColors.surface,
    required this.size,
    required this.iconSize,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final double size;
  final double iconSize;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, size: iconSize),
        style: IconButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    );
    return Material(
      color: AppColors.surface,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 54),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                Icon(Icons.search, color: AppColors.brandStrong),
                const SizedBox(width: AppSpacing.elementGapHorizontal),
                Expanded(
                  child: Text(
                    '건물명, 강의실, 또는 제보 검색',
                    semanticsLabel: '건물명, 강의실, 또는 제보 검색',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RouteBadge extends StatelessWidget {
  const _RouteBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.brandSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.route, size: 16, color: AppColors.brandStrong),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.body.copyWith(color: AppColors.brandStrong),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuidancePanel extends StatelessWidget {
  const _GuidancePanel({
    required this.step,
    required this.lastStep,
    required this.route,
    required this.onStepChanged,
    required this.onEnd,
  });

  final int step;
  final int lastStep;
  final List<Offset> route;
  final ValueChanged<int> onStepChanged;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final instruction = switch (step) {
      0 => '출발지에서 중앙 복도로 이동하세요.',
      1 => '중앙 복도를 따라 이동하세요.',
      _ when step == lastStep => '목적지에 도착했습니다.',
      _ => '복도에서 목적지 출입문으로 이동하세요.',
    };
    return GestureDetector(
      key: const ValueKey('guidance-step-card'),
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity < 0 && step < lastStep) onStepChanged(step + 1);
        if (velocity > 0 && step > 0) onStepChanged(step - 1);
      },
      child: Card(
        color: AppColors.brandStrong,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.brandSoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '안내 · ${step + 1}/${lastStep + 1}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.brandStrong,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: '안내 종료',
                    icon: const Icon(Icons.close),
                    color: AppColors.surface,
                    onPressed: onEnd,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                instruction,
                style: AppTextStyles.title.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (var index = 0; index <= lastStep; index++)
                    IconButton(
                      tooltip: '${index + 1}단계로 이동',
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        index == step ? Icons.circle : Icons.circle_outlined,
                        size: 12,
                        color: index == step
                            ? Colors.white
                            : AppColors.brandSoft,
                      ),
                      onPressed: () => onStepChanged(index),
                    ),
                  TextButton.icon(
                    icon: const Icon(Icons.zoom_in),
                    label: const Text('안내도 확대'),
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('층 안내도'),
                        content: SizedBox(
                          width: 480,
                          child: IgnorePointer(
                            child: PrimeFloorView(
                              route: route,
                              guidePosition: route[step],
                              onPlaceSelected: (_) {},
                            ),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('닫기'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
