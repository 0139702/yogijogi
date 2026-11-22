import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_colors.dart';
import '../navigation/guidance.dart';
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
    required this.view,
    required this.onDirections,
    required this.onPlaceSelected,
    required this.onViewChanged,
    required this.onStepChanged,
    required this.onEndGuidance,
  });

  final List<Offset> demoRoute;
  final String? routeLabel;
  final PrimePlace start;
  final PrimePlace? destination;
  final int? guideStep;
  final GuidanceView view;
  final VoidCallback onDirections;
  final ValueChanged<PrimePlace> onPlaceSelected;
  final ValueChanged<GuidanceView> onViewChanged;
  final ValueChanged<int> onStepChanged;
  final VoidCallback onEndGuidance;

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
  final _mapTransform = TransformationController();

  @override
  void dispose() {
    _mapTransform.dispose();
    super.dispose();
  }

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
    if (!context.mounted) return;
    final place = await Navigator.of(context).push(
      MaterialPageRoute<PrimePlace>(
        builder: (_) => PlaceSearch(
          recent: _recent,
          onClearRecent: () {
            _recent.clear();
            _saveRecent();
          },
        ),
      ),
    );
    if (place == null || !context.mounted) return;
    _recent.remove(place);
    _recent.insert(0, place);
    if (_recent.length > 8) _recent.removeLast();
    _saveRecent();
    await _openPlace(context, place);
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
  Widget build(BuildContext context) {
    final step = widget.guideStep;
    if (step == null) return _buildHome(context);
    final destination = widget.destination;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        8,
        AppSpacing.screenPadding,
        24,
      ),
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            Text('프라임관 6층', style: AppTextStyles.title),
            Text('층 안내도 기반 데모', style: AppTextStyles.caption),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _SearchBar(onTap: () => _openSearch(context))),
            const SizedBox(width: AppSpacing.elementGapHorizontal),
            IconButton.filledTonal(
              tooltip: '길찾기 열기',
              onPressed: widget.onDirections,
              icon: const Icon(Icons.turn_right),
            ),
          ],
        ),
        const SizedBox(height: 12),
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
        const SizedBox(height: 8),
        if (widget.routeLabel != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _RouteBadge(label: widget.routeLabel!),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: PrimeFloorView(
              route: widget.demoRoute,
              guidePosition: widget.demoRoute[step],
              onPlaceSelected: (place) => _openPlace(context, place),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _GuidancePanel(
          step: step,
          lastStep: widget.demoRoute.length - 1,
          route: widget.demoRoute,
          view: widget.view,
          onViewChanged: widget.onViewChanged,
          onStepChanged: widget.onStepChanged,
          onEnd: widget.onEndGuidance,
        ),
      ],
    );
  }

  Widget _buildHome(BuildContext context) {
    const filters = {
      PlaceFilter.all: '전체',
      PlaceFilter.classrooms: '빈 강의실',
      PlaceFilter.events: '행사',
      PlaceFilter.reports: '벌레 주의',
    };

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: AppColors.background,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 132, 12, 72),
            child: InteractiveViewer(
              transformationController: _mapTransform,
              minScale: 1,
              maxScale: 3,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('프라임관 6층', style: AppTextStyles.title),
                    TextButton.icon(
                      icon: const Icon(Icons.view_in_ar_outlined),
                      label: const Text('캠퍼스 3D 지도'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const Campus3dScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('층 안내도 기반 데모', style: AppTextStyles.caption),
                    if (widget.routeLabel != null)
                      _RouteBadge(label: widget.routeLabel!),
                    const SizedBox(height: 8),
                    Flexible(
                      child: PrimeFloorView(
                        route: widget.demoRoute,
                        onPlaceSelected: (place) => _openPlace(context, place),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 16,
          left: 16,
          right: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _SearchBar(
                      onTap: () => _openSearch(context),
                      home: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  _MapControl(
                    tooltip: '길찾기 열기',
                    icon: Icons.turn_right,
                    color: Colors.black,
                    size: 54,
                    iconSize: 32,
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
                      Semantics(
                        selected: _filter == entry.key,
                        child: Material(
                          color: AppColors.surface,
                          shape: StadiumBorder(
                            side: BorderSide(
                              color: _filter == entry.key
                                  ? CampusHomeColors.blue
                                  : Colors.transparent,
                            ),
                          ),
                          child: InkWell(
                            customBorder: const StadiumBorder(),
                            onTap: () => setState(() => _filter = entry.key),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 40),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                child: Center(
                                  child: Text(
                                    entry.value,
                                    style: AppTextStyles.body.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (_filter != PlaceFilter.all)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _filter.emptyMessage,
                    style: AppTextStyles.caption,
                  ),
                ),
            ],
          ),
        ),
        Positioned(
          right: 16,
          bottom: 24,
          child: _MapControl(
            tooltip: '지도 중심으로 이동',
            icon: Icons.my_location,
            color: CampusHomeColors.blue,
            size: 48,
            iconSize: 24,
            onPressed: () => _mapTransform.value = Matrix4.identity(),
          ),
        ),
      ],
    );
  }
}

class _MapControl extends StatelessWidget {
  const _MapControl({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.size,
    required this.iconSize,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final Color color;
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
          backgroundColor: AppColors.surface,
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
  const _SearchBar({required this.onTap, this.home = false});

  final VoidCallback onTap;
  final bool home;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(home ? 20 : 16),
      side: home ? BorderSide.none : const BorderSide(color: AppColors.border),
    );
    return Material(
      color: AppColors.surface,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: home ? 54 : 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: home ? CampusHomeColors.blue : AppColors.brand,
                ),
                const SizedBox(width: AppSpacing.elementGapHorizontal),
                Expanded(
                  child: Text(
                    home ? '건물명, 강의실 검색' : '건물·강의실 검색',
                    semanticsLabel: '건물·강의실 검색',
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
    required this.view,
    required this.onViewChanged,
    required this.onStepChanged,
    required this.onEnd,
  });

  final int step;
  final int lastStep;
  final List<Offset> route;
  final GuidanceView view;
  final ValueChanged<GuidanceView> onViewChanged;
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          key: const ValueKey('guidance-step-card'),
          onHorizontalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;
            if (velocity < 0 && step < lastStep) onStepChanged(step + 1);
            if (velocity > 0 && step > 0) onStepChanged(step - 1);
          },
          child: Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                      '데모 안내 · ${step + 1}/${lastStep + 1}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.brandStrong,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(instruction, style: AppTextStyles.title),
                  const SizedBox(height: 8),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      for (var index = 0; index <= lastStep; index++)
                        IconButton(
                          tooltip: '${index + 1}단계로 이동',
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            index == step
                                ? Icons.circle
                                : Icons.circle_outlined,
                            size: 12,
                            color: index == step
                                ? AppColors.brand
                                : AppColors.border,
                          ),
                          onPressed: () => onStepChanged(index),
                        ),
                      TextButton.icon(
                        icon: const Icon(Icons.zoom_in),
                        label: const Text('안내도 확대'),
                        onPressed: () => showDialog<void>(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: const Text('층 안내도 · 데모'),
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
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: AppSpacing.elementGapHorizontal,
          children: [
            for (final candidate in GuidanceView.values)
              ChoiceChip(
                label: Text(candidate.label),
                showCheckmark: false,
                selected: view == candidate,
                onSelected: (_) => onViewChanged(candidate),
              ),
          ],
        ),
        if (view == GuidanceView.follow)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '수룡이 따라가기 시점 선택됨 · 3D 적용 전',
              style: AppTextStyles.caption,
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: step == 0 ? null : () => onStepChanged(step - 1),
                child: const Text('이전 단계'),
              ),
            ),
            const SizedBox(width: AppSpacing.elementGapHorizontal),
            Expanded(
              child: FilledButton(
                onPressed: step == lastStep
                    ? null
                    : () => onStepChanged(step + 1),
                child: const Text('다음 단계'),
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: onEnd,
          style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
          child: const Text('안내 종료'),
        ),
      ],
    );
  }
}
