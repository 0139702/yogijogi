import 'package:material_ui/material_ui.dart';

import '../../core/app_colors.dart';
import '../map/prime_floor.dart';
import '../map/prime_floor_view.dart';
import 'route_option.dart';

class RouteScreen extends StatelessWidget {
  const RouteScreen({
    super.key,
    required this.start,
    required this.destination,
    required this.option,
    required this.route,
    required this.onOptionChanged,
    required this.onStartChanged,
    required this.onDestinationChanged,
    required this.onShowRoute,
    required this.onStartGuidance,
    required this.onSwap,
  });

  final PrimePlace start;
  final PrimePlace? destination;
  final RouteOption option;
  final List<Offset> route;
  bool get hasDemoRoute => route.isNotEmpty;
  final ValueChanged<RouteOption> onOptionChanged;
  final ValueChanged<PrimePlace> onStartChanged;
  final ValueChanged<PrimePlace> onDestinationChanged;
  final VoidCallback onShowRoute;
  final VoidCallback onStartGuidance;
  final VoidCallback onSwap;

  Widget _placeField({
    required String label,
    required Color color,
    required PrimePlace? value,
    required ValueChanged<PrimePlace> onChanged,
  }) {
    return Row(
      children: [
        Icon(Icons.circle, size: 12, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<PrimePlace>(
              isExpanded: true,
              isDense: true,
              value: value,
              hint: const Text('장소 선택'),
              onChanged: (place) {
                if (place != null) onChanged(place);
              },
              items: [
                for (final place in PrimePlace.values)
                  DropdownMenuItem(
                    value: place,
                    child: Text(
                      place.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        DecoratedBox(
          decoration: BoxDecoration(
            color: color.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: label == '출발지'
                    ? AppColors.brandStrong
                    : AppColors.hazard,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final end = destination;
    final recommendElevator = primeDemoRoute(
      start,
      end,
      RouteOption.elevator,
    ).isNotEmpty;
    return ColoredBox(
      color: const Color(0xffeaf5f2),
      child: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) => Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(top: 12),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x101b2438),
                              blurRadius: 18,
                              offset: Offset(0, 7),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 13,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    _placeField(
                                      label: '출발지',
                                      color: AppColors.brand,
                                      value: start,
                                      onChanged: onStartChanged,
                                    ),
                                    const SizedBox(height: 12),
                                    _placeField(
                                      label: '목적지',
                                      color: AppColors.hazard,
                                      value: end,
                                      onChanged: onDestinationChanged,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              IconButton.filledTonal(
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.brandSoft,
                                  foregroundColor: AppColors.brandStrong,
                                ),
                                tooltip: '출발지와 목적지 바꾸기',
                                icon: const Icon(Icons.swap_vert),
                                onPressed: end == null ? null : onSwap,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: (constraints.maxHeight - 485).clamp(174.0, 360.0),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                            child: IgnorePointer(
                              child: PrimeFloorView(
                                route: route,
                                onPlaceSelected: (_) {},
                              ),
                            ),
                          ),
                          Positioned(
                            top: 12,
                            right: 16,
                            child: IconButton.filled(
                              tooltip: '지도에서 경로 보기',
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.surface,
                                foregroundColor: AppColors.brandStrong,
                                disabledBackgroundColor: AppColors.surface,
                              ),
                              icon: const Icon(Icons.view_in_ar_outlined),
                              onPressed: hasDemoRoute ? onShowRoute : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DecoratedBox(
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Container(
                                width: 54,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: AppColors.border,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              '어떤 길로 갈까요?',
                              style: AppTextStyles.title.copyWith(fontSize: 23),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '프라임관 6층 · 도면 기준',
                              style: AppTextStyles.caption,
                            ),
                            const SizedBox(height: 16),
                            for (final (index, candidate)
                                in RouteOption.values.indexed)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _OptionTile(
                                  index: index,
                                  option: candidate,
                                  selected: option == candidate,
                                  recommended:
                                      recommendElevator &&
                                      candidate == RouteOption.elevator,
                                  onTap: () => onOptionChanged(candidate),
                                ),
                              ),
                            if (end == null)
                              const _Notice('안내받을 목적지를 선택해 주세요.')
                            else if (end == start)
                              const _Notice('출발지와 목적지를 다르게 선택해 주세요.')
                            else if (!hasDemoRoute)
                              _Notice(
                                option == RouteOption.stepFree
                                    ? '확인된 계단 없는 경로가 없습니다.'
                                    : '안내할 수 있는 경로가 없습니다.',
                              ),
                            if (hasDemoRoute)
                              const _Notice(
                                '이 구간은 같은 층이라 두 옵션 모두 같은 복도를 이용합니다.',
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ColoredBox(
                color: AppColors.surface,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brandStrong,
                        disabledBackgroundColor: AppColors.brandSoft,
                        disabledForegroundColor: AppColors.textSecondary,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: hasDemoRoute ? onStartGuidance : null,
                      child: const Text('이 경로로 안내 시작'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.index,
    required this.option,
    required this.selected,
    required this.recommended,
    required this.onTap,
  });

  final int index;
  final RouteOption option;
  final bool selected;
  final bool recommended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
      side: BorderSide(color: selected ? AppColors.brand : AppColors.border),
    );
    return Semantics(
      selected: selected,
      child: Material(
        color: selected ? AppColors.brandSoft : AppColors.surface,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: selected
                      ? AppColors.brandStrong
                      : AppColors.background,
                  foregroundColor: selected
                      ? AppColors.surface
                      : AppColors.textPrimary,
                  child: selected
                      ? const Icon(Icons.check, size: 16)
                      : Text(
                          '${index + 1}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  option.label,
                                  style: AppTextStyles.body.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (option == RouteOption.stepFree)
                                  const Icon(
                                    Icons.accessible,
                                    size: 18,
                                    color: AppColors.brandStrong,
                                  ),
                              ],
                            ),
                          ),
                          if (recommended) ...[
                            const SizedBox(width: 8),
                            Text(
                              '추천',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.brandStrong,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(option.description, style: AppTextStyles.caption),
                    ],
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

class _Notice extends StatelessWidget {
  const _Notice(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 5),
    child: Text(text, style: AppTextStyles.caption),
  );
}
