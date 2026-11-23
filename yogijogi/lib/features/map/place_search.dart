import 'package:material_ui/material_ui.dart';

import '../../core/app_colors.dart';
import 'prime_floor.dart';

enum PlaceFilter {
  all('전체', Icons.layers_outlined),
  classrooms('빈 강의실', Icons.meeting_room_outlined),
  elevator('엘리베이터', Icons.elevator_outlined),
  events('오늘의 행사', Icons.event_outlined),
  reports('불편 제보', Icons.warning_amber_outlined);

  const PlaceFilter(this.label, this.icon);

  final String label;
  final IconData icon;

  String get emptyMessage => switch (this) {
    classrooms => '빈 강의실을 확인할 수 있는 시간표가 없습니다.',
    events => '오늘 표시할 행사 정보가 없습니다.',
    reports => '이 층의 지도에 표시할 제보 정보가 없습니다.',
    _ => '검색 결과가 없습니다.',
  };

  bool includes(PrimePlace place) => switch (this) {
    all => true,
    elevator => place == PrimePlace.elevator,
    _ => false,
  };
}

class PlaceSearch extends StatefulWidget {
  const PlaceSearch({
    super.key,
    required this.recent,
    required this.onClearRecent,
    required this.onClose,
    required this.onSelect,
  });

  final List<PrimePlace> recent;
  final VoidCallback onClearRecent;
  final VoidCallback onClose;
  final ValueChanged<PrimePlace> onSelect;

  @override
  State<PlaceSearch> createState() => _PlaceSearchState();
}

class _PlaceSearchState extends State<PlaceSearch> {
  String _query = '';
  PlaceFilter _filter = PlaceFilter.all;

  @override
  Widget build(BuildContext context) {
    final showSuggestions = _query.isEmpty && _filter == PlaceFilter.all;
    final terms = _query.split(RegExp(r'\s+'));
    final places = PrimePlace.values.where((place) {
      final searchable = '${place.label} ${place.searchTerms}'.toLowerCase();
      return _filter.includes(place) && terms.every(searchable.contains);
    }).toList();
    return Material(
      color: AppColors.surface,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 26, 16, 36),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    height: 46,
                    child: IconButton(
                      tooltip: '검색 닫기',
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.chevron_left, size: 28),
                      style: IconButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        backgroundColor: AppColors.background,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x121b2438),
                            blurRadius: 20,
                            offset: Offset(0, 7),
                          ),
                        ],
                      ),
                      child: TextField(
                        style: AppTextStyles.body,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) {
                          if (places.length == 1) {
                            widget.onSelect(places.single);
                          }
                        },
                        decoration: const InputDecoration(
                          prefixIcon: Icon(
                            Icons.search,
                            color: AppColors.brandStrong,
                          ),
                          hintText: '건물명, 강의실, 또는 제보 검색',
                          hintStyle: TextStyle(color: AppColors.textSecondary),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 8,
                          ),
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                        onChanged: (value) =>
                            setState(() => _query = value.trim().toLowerCase()),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                children: [
                  if (showSuggestions) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text('최근 검색', style: AppTextStyles.title),
                        ),
                        TextButton(
                          onPressed: widget.recent.isEmpty
                              ? null
                              : () => setState(widget.onClearRecent),
                          child: Text('모두 지우기', style: AppTextStyles.caption),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (widget.recent.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Text(
                          '최근 검색이 없습니다.',
                          style: AppTextStyles.caption,
                        ),
                      ),
                    for (final place in widget.recent)
                      ListTile(
                        minTileHeight: 53,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        leading: const Icon(
                          Icons.schedule,
                          color: AppColors.textSecondary,
                        ),
                        title: Text(place.label, style: AppTextStyles.body),
                        onTap: () => widget.onSelect(place),
                      ),
                    const SizedBox(height: 30),
                    Text('빠른 검색', style: AppTextStyles.title),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        const gap = 8.0;
                        final width = (constraints.maxWidth - gap) / 2;
                        return Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: [
                            for (final filter in PlaceFilter.values.skip(1))
                              SizedBox(
                                width: width,
                                child: _QuickSearchButton(
                                  filter: filter,
                                  onTap: () => setState(() => _filter = filter),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ] else ...[
                    if (_filter != PlaceFilter.all)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: InputChip(
                          label: Text(_filter.label),
                          onDeleted: () =>
                              setState(() => _filter = PlaceFilter.all),
                        ),
                      ),
                    if (places.isEmpty)
                      Text(_filter.emptyMessage, style: AppTextStyles.caption),
                    for (final place in places)
                      ListTile(
                        leading: const Icon(Icons.place_outlined),
                        title: Text(place.label, style: AppTextStyles.body),
                        subtitle: Text(
                          place.detail,
                          style: AppTextStyles.caption,
                        ),
                        onTap: () => widget.onSelect(place),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickSearchButton extends StatelessWidget {
  const _QuickSearchButton({required this.filter, required this.onTap});

  final PlaceFilter filter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, color, background) = switch (filter) {
      PlaceFilter.classrooms => (
        Icons.menu_book_outlined,
        AppColors.brandStrong,
        AppColors.brandSoft,
      ),
      PlaceFilter.elevator => (
        Icons.elevator_outlined,
        AppColors.resolved,
        const Color(0xffe3f5ed),
      ),
      PlaceFilter.events => (
        Icons.calendar_month_outlined,
        AppColors.brand,
        AppColors.brandSoft,
      ),
      _ => (
        Icons.warning_amber_outlined,
        AppColors.hazard,
        const Color(0xffffefe7),
      ),
    };
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(44),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      onPressed: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              filter.label,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
