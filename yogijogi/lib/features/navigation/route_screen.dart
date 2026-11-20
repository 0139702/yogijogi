import 'package:material_ui/material_ui.dart';

import '../../core/app_colors.dart';
import '../map/prime_floor.dart';
import 'route_option.dart';

class RouteScreen extends StatelessWidget {
  const RouteScreen({
    super.key,
    required this.start,
    required this.destination,
    required this.option,
    required this.hasDemoRoute,
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
  final bool hasDemoRoute;
  final ValueChanged<RouteOption> onOptionChanged;
  final ValueChanged<PrimePlace> onStartChanged;
  final ValueChanged<PrimePlace> onDestinationChanged;
  final VoidCallback onShowRoute;
  final VoidCallback onStartGuidance;
  final VoidCallback onSwap;

  Widget _placeField({
    required String label,
    required PrimePlace? value,
    required ValueChanged<PrimePlace> onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
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
              DropdownMenuItem(value: place, child: Text(place.label)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final end = destination;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        16,
        AppSpacing.screenPadding,
        24,
      ),
      children: [
        Text('프라임관 6층 · 도면 기반 데모', style: AppTextStyles.title),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _placeField(
                  label: '출발지',
                  value: start,
                  onChanged: onStartChanged,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip: '출발지와 목적지 바꾸기',
                    color: AppColors.brand,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.swap_vert),
                    onPressed: end == null ? null : onSwap,
                  ),
                ),
                _placeField(
                  label: '목적지',
                  value: end,
                  onChanged: onDestinationChanged,
                ),
                if (end == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '안내받을 목적지를 선택해 주세요.',
                      style: AppTextStyles.caption,
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (hasDemoRoute) ...[
          const SizedBox(height: 16),
          const _Notice(
            icon: Icons.info_outline,
            text: '이 구간은 같은 층이라 두 옵션 모두 같은 복도를 이용합니다.',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onShowRoute,
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('지도에서 경로 보기'),
                ),
              ),
              const SizedBox(width: AppSpacing.elementGapHorizontal),
              Expanded(
                child: FilledButton(
                  onPressed: onStartGuidance,
                  child: const Text('이 경로로 안내 시작'),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Text('어떤 길로 갈까요?', style: AppTextStyles.title),
        const SizedBox(height: 8),
        for (final candidate in RouteOption.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _OptionTile(
              option: candidate,
              selected: option == candidate,
              onTap: () => onOptionChanged(candidate),
            ),
          ),
        if (end == start)
          const _Notice(
            icon: Icons.error_outline,
            text: '출발지와 목적지를 다르게 선택해 주세요.',
          )
        else if (end != null && !hasDemoRoute)
          _Notice(
            icon: Icons.error_outline,
            text: option == RouteOption.stepFree
                ? '확인된 계단 없는 경로가 없습니다.'
                : '이 출발지와 목적지 조합의 샘플 경로가 없습니다.',
          ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final RouteOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.brandSoft : AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? AppColors.brand : AppColors.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        visualDensity: VisualDensity.compact,
        leading: Icon(
          selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
          color: selected ? AppColors.brandStrong : AppColors.textSecondary,
        ),
        title: Text(
          option.label,
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(option.description, style: AppTextStyles.caption),
        selected: selected,
        onTap: onTap,
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.brandSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.brandStrong),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
