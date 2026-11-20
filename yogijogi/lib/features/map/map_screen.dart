import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../navigation/guidance.dart';
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
    final place = await showModalBottomSheet<PrimePlace>(
      context: context,
      isScrollControlled: true,
      builder: (_) => PlaceSearch(
        recent: _recent,
        onClearRecent: () {
          _recent.clear();
          _saveRecent();
        },
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
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                place.label,
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              Text(place.detail),
              const SizedBox(height: 16),
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
    final destination = widget.destination;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('프라임관 6층', style: Theme.of(context).textTheme.headlineSmall),
        const Text('층 안내도 기반 데모'),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => _openSearch(context),
              icon: const Icon(Icons.search),
              label: const Text('건물·강의실 검색'),
            ),
            OutlinedButton.icon(
              onPressed: widget.onDirections,
              icon: const Icon(Icons.turn_right),
              label: const Text('길찾기 열기'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (step != null && destination != null)
          Card(
            child: Column(
              children: [
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.trip_origin),
                  title: Text(widget.start.label),
                  subtitle: const Text('출발'),
                ),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.place_outlined),
                  title: Text(destination.label),
                  subtitle: const Text('도착'),
                ),
              ],
            ),
          )
        else ...[
          Wrap(
            spacing: 8,
            children: [
              for (final filter in PlaceFilter.values)
                FilterChip(
                  label: Text(filter.label),
                  selected: _filter == filter,
                  onSelected: (_) => setState(() => _filter = filter),
                ),
            ],
          ),
          if (_filter != PlaceFilter.all && _filter != PlaceFilter.elevator)
            Text(_filter.emptyMessage),
        ],
        if (widget.routeLabel != null) Text(widget.routeLabel!),
        PrimeFloorView(
          route: widget.demoRoute,
          highlightedPlace: _filter == PlaceFilter.elevator
              ? PrimePlace.elevator
              : null,
          guidePosition: step == null ? null : widget.demoRoute[step],
          onPlaceSelected: (place) => _openPlace(context, place),
        ),
        if (step != null) ...[
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
      ],
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          key: const ValueKey('guidance-step-card'),
          onHorizontalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;
            if (velocity < 0 && step < lastStep) onStepChanged(step + 1);
            if (velocity > 0 && step > 0) onStepChanged(step - 1);
          },
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('데모 안내 · ${step + 1}/${lastStep + 1}'),
                  Text(
                    instruction,
                    style: Theme.of(context).textTheme.titleMedium,
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
                  Row(
                    children: [
                      for (var index = 0; index <= lastStep; index++)
                        IconButton(
                          tooltip: '${index + 1}단계로 이동',
                          icon: Icon(
                            index == step
                                ? Icons.circle
                                : Icons.circle_outlined,
                            size: 12,
                          ),
                          onPressed: () => onStepChanged(index),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          children: [
            for (final candidate in GuidanceView.values)
              ChoiceChip(
                label: Text(candidate.label),
                selected: view == candidate,
                onSelected: (_) => onViewChanged(candidate),
              ),
          ],
        ),
        if (view == GuidanceView.follow)
          const Text('수룡이 따라가기 시점 선택됨 · 3D 적용 전'),
        Wrap(
          spacing: 8,
          children: [
            TextButton(
              onPressed: step == 0 ? null : () => onStepChanged(step - 1),
              child: const Text('이전 단계'),
            ),
            FilledButton(
              onPressed: step == lastStep
                  ? null
                  : () => onStepChanged(step + 1),
              child: const Text('다음 단계'),
            ),
            TextButton(onPressed: onEnd, child: const Text('안내 종료')),
          ],
        ),
      ],
    );
  }
}
