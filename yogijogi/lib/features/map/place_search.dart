import 'package:material_ui/material_ui.dart';

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
  });

  final List<PrimePlace> recent;
  final VoidCallback onClearRecent;

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
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .48,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    labelText: '건물명이나 호실 검색',
                    hintText: '예: 미술, 공학, 603',
                  ),
                  onChanged: (value) => setState(() {
                    _query = value.trim().toLowerCase();
                    _filter = PlaceFilter.all;
                  }),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    if (showSuggestions) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('최근 검색'),
                          if (widget.recent.isNotEmpty)
                            TextButton(
                              onPressed: () => setState(widget.onClearRecent),
                              child: const Text('모두 지우기'),
                            ),
                        ],
                      ),
                      if (widget.recent.isEmpty) const Text('최근 검색이 없습니다.'),
                      for (final place in widget.recent)
                        ListTile(
                          leading: const Icon(Icons.history),
                          title: Text(place.label),
                          onTap: () => Navigator.pop(context, place),
                        ),
                      const SizedBox(height: 12),
                      const Text('빠른 검색'),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final filter in PlaceFilter.values.skip(1))
                            ActionChip(
                              avatar: Icon(filter.icon, size: 18),
                              label: Text(filter.label),
                              onPressed: () => setState(() => _filter = filter),
                            ),
                        ],
                      ),
                    ] else ...[
                      if (_filter != PlaceFilter.all)
                        InputChip(
                          label: Text(_filter.label),
                          onDeleted: () =>
                              setState(() => _filter = PlaceFilter.all),
                        ),
                      if (places.isEmpty) Text(_filter.emptyMessage),
                      for (final place in places)
                        ListTile(
                          title: Text(place.label),
                          subtitle: Text(place.detail),
                          onTap: () => Navigator.pop(context, place),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
