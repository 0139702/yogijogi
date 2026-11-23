import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../core/app_config.dart';
import 'classroom.dart';
import 'classroom_api.dart';
import 'classroom_repository.dart';

const _primary = Color(0xFF3D7BF0);
const _green = Color(0xFF1E9E5A);
const _greenSoft = Color(0xFFE4F6EC);
const _surface = Color(0xFFF4F6F8);
const _textStrong = Color(0xFF1F2328);
const _textSub = Color(0xFF6B7280);
const _textHint = Color(0xFF9AA1AB);

/// 강의실 상세 화면.
///
/// 지도, 강의실 기본 정보, 시간표 기준 이용 상태, 공간 시설, 오늘의 시간표,
/// 최근 제보와 길찾기 버튼을 보여준다.
class ClassroomDetailScreen extends StatefulWidget {
  const ClassroomDetailScreen({
    super.key,
    this.classroomId = SampleClassroomRepository.sampleClassroomId,
    this.repository,
    this.clock,
    this.onDirections,
  });

  final String classroomId;

  /// 데이터 저장소. 지정하지 않으면 API 주소 설정에 따라
  /// 강의실 API 또는 샘플 데이터를 사용한다.
  final ClassroomRepository? repository;

  /// 현재 시각 공급자. 테스트에서 시각을 고정할 때 사용한다.
  final DateTime Function()? clock;

  /// 길찾기 버튼 동작. 길찾기 화면과 연결되기 전에는 비워 둔다.
  final ValueChanged<ClassroomDetail>? onDirections;

  @override
  State<ClassroomDetailScreen> createState() => _ClassroomDetailScreenState();
}

class _ClassroomDetailScreenState extends State<ClassroomDetailScreen> {
  late final ClassroomRepository _repository =
      widget.repository ??
      createClassroomRepository(AppConfig.apiBaseUrl, clock: widget.clock);
  late Future<ClassroomDetail> _detail;

  /// 화면을 띄워 둔 동안 시간표 상태(완료·지금·예정)를 다시 계산한다.
  Timer? _ticker;

  DateTime get _now => (widget.clock ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    _detail = _repository.fetchDetail(widget.classroomId);
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    // 외부에서 받은 저장소는 넘겨준 쪽에서 정리한다.
    if (widget.repository == null) _repository.close();
    super.dispose();
  }

  void _retry() =>
      setState(() => _detail = _repository.fetchDetail(widget.classroomId));

  void _startDirections(ClassroomDetail detail) {
    final onDirections = widget.onDirections;
    if (onDirections != null) {
      onDirections(detail);
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('길찾기 화면은 아직 연결되지 않았어요.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<ClassroomDetail>(
        future: _detail,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('강의실 정보를 불러오지 못했습니다.'),
                  const SizedBox(height: 12),
                  OutlinedButton(onPressed: _retry, child: const Text('다시 시도')),
                ],
              ),
            );
          }
          final detail = snapshot.requireData;
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Stack(
                    children: [
                      _MapPreview(
                        key: const ValueKey('classroom-map-preview'),
                        walkingMinutes: detail.walkingMinutes,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          top: _MapPreview.height - 20,
                        ),
                        child: _DetailSheet(detail: detail, now: _now),
                      ),
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onPressed: () => _startDirections(detail),
                    child: const Text('이 강의실로 길찾기'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 강의실 주변을 보여주는 간단한 샘플 지도.
///
/// 실제 지도 SDK가 연결되면 이 위젯을 교체한다.
class _MapPreview extends StatelessWidget {
  const _MapPreview({super.key, required this.walkingMinutes});

  static const height = 200.0;

  final int? walkingMinutes;

  @override
  Widget build(BuildContext context) {
    final minutes = walkingMinutes;
    // 너비를 지정하지 않으면 Stack이 뒤로 가기 버튼 영역 크기로 줄어들어
    // 지도 배경이 잘린다.
    return SizedBox(
      width: double.infinity,
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          return Stack(
            children: [
              const Positioned.fill(
                child: ColoredBox(color: Color(0xFFEAF3EE)),
              ),
              // 도로
              Positioned(
                left: w * 0.4,
                width: 22,
                top: 0,
                bottom: 0,
                child: const ColoredBox(color: Colors.white),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 112,
                height: 14,
                child: const ColoredBox(color: Color(0xFFF7FAF8)),
              ),
              // 건물
              Positioned(
                left: w * 0.56,
                top: 54,
                width: w * 0.32,
                height: 72,
                child: const _Building(
                  label: '중앙도서관',
                  color: Color(0xFFD9E6E1),
                ),
              ),
              Positioned(
                left: w * 0.08,
                top: 104,
                width: w * 0.2,
                height: 58,
                child: const _Building(label: 'IT관', color: Color(0xFFD7E3F7)),
              ),
              // 나무
              for (final x in [0.04, 0.24, 0.36, 0.6, 0.76, 0.92])
                Positioned(left: w * x, top: 172, child: const _Tree()),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        tooltip: '뒤로 가기',
                        icon: const Icon(Icons.chevron_left, size: 28),
                        color: _textStrong,
                        onPressed: () => Navigator.maybePop(context),
                      ),
                      if (minutes != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _LocationPill(minutes: minutes),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Building extends StatelessWidget {
  const _Building({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF3A4350),
        ),
      ),
    );
  }
}

class _Tree extends StatelessWidget {
  const _Tree();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: const BoxDecoration(
        color: Color(0xFFA9D8BC),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _LocationPill extends StatelessWidget {
  const _LocationPill({required this.minutes});

  final int minutes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.my_location, size: 14, color: _primary),
          const SizedBox(width: 6),
          Text(
            '현재 내 위치에서 도보 $minutes분',
            style: const TextStyle(fontSize: 12, color: _textStrong),
          ),
        ],
      ),
    );
  }
}

class _DetailSheet extends StatelessWidget {
  const _DetailSheet({required this.detail, required this.now});

  final ClassroomDetail detail;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final reports = detail.visibleReports(now);
    // 기기 시간대와 관계없이 캠퍼스 기준 시각으로 표시한다.
    String formatTime(DateTime time) => _formatClock(detail.toCampusTime(time));
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDE1E6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            detail.buildingName,
            style: const TextStyle(fontSize: 13, color: _textSub),
          ),
          const SizedBox(height: 4),
          Text(
            detail.roomName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _textStrong,
            ),
          ),
          const SizedBox(height: 14),
          _AvailabilityRow(
            availability: detail.availabilityAt(now),
            formatTime: formatTime,
          ),
          const SizedBox(height: 8),
          Text(
            '시간표 기준 안내로 실제 이용 여부와 다를 수 있어요.\n'
            '${detail.isSample ? '샘플 데이터 · ' : ''}'
            '${formatTime(detail.updatedAt)} 갱신',
            style: const TextStyle(fontSize: 11, color: _textHint, height: 1.4),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFE8EBEE)),
          const _SectionTitle('공간 시설'),
          _FacilityGrid(facilities: detail.facilities),
          const _SectionTitle('오늘의 시간표'),
          for (final session in detail.schedule)
            _SessionTile(
              session: session,
              status: session.statusAt(now),
              formatTime: formatTime,
            ),
          const _SectionTitle('이 공간의 최근 제보'),
          if (reports.isEmpty)
            const Text(
              '최근 24시간 동안 등록된 제보가 없어요.',
              style: TextStyle(fontSize: 13, color: _textSub),
            )
          else
            for (final report in reports) _ReportTile(report: report, now: now),
        ],
      ),
    );
  }
}

class _AvailabilityRow extends StatelessWidget {
  const _AvailabilityRow({
    required this.availability,
    required this.formatTime,
  });

  final RoomAvailability availability;
  final String Function(DateTime) formatTime;

  @override
  Widget build(BuildContext context) {
    final free = availability.isFree;
    final until = availability.until;
    final String hint;
    if (until == null) {
      hint = free ? '오늘 남은 수업 없음' : '수업 진행 중';
    } else {
      hint = free
          ? '${formatTime(until)}까지 자유 이용 가능'
          : '${formatTime(until)} 수업 종료 예정';
    }
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: free ? _greenSoft : const Color(0xFFFFF1E5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            free ? '현재 비어있음' : '현재 수업 중',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: free ? _green : const Color(0xFFD9730D),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            hint,
            style: const TextStyle(fontSize: 12, color: _textSub),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: _textStrong,
        ),
      ),
    );
  }
}

class _FacilityGrid extends StatelessWidget {
  const _FacilityGrid({required this.facilities});

  final List<String> facilities;

  static const _gap = 8.0;

  @override
  Widget build(BuildContext context) {
    // 너비를 직접 계산하지 않고 두 칸씩 Expanded로 나눠, 화면 너비가
    // 0인 첫 프레임에서도 음수 제약이 생기지 않게 한다.
    return Column(
      children: [
        for (var i = 0; i < facilities.length; i += 2)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : _gap),
            child: Row(
              children: [
                Expanded(child: _FacilityChip(facilities[i])),
                const SizedBox(width: _gap),
                Expanded(
                  child: i + 1 < facilities.length
                      ? _FacilityChip(facilities[i + 1])
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _FacilityChip extends StatelessWidget {
  const _FacilityChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _textStrong,
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.session,
    required this.status,
    required this.formatTime,
  });

  final ClassSession session;
  final SessionStatus status;
  final String Function(DateTime) formatTime;

  @override
  Widget build(BuildContext context) {
    final ongoing = status == SessionStatus.ongoing;
    final label = switch (status) {
      SessionStatus.done => '완료',
      SessionStatus.ongoing => '지금',
      SessionStatus.upcoming => '예정',
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: ongoing ? _greenSoft : _surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              '${formatTime(session.start)}–${formatTime(session.end)}',
              style: TextStyle(
                fontSize: 12,
                color: ongoing ? _green : _textSub,
                fontWeight: ongoing ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          Expanded(
            child: Text(
              session.title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _textStrong,
              ),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: ongoing ? _green : _textHint,
              fontWeight: ongoing ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({required this.report, required this.now});

  final SpaceReport report;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            report.description,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _textStrong,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_sourceLabel(report.source)} · '
            '${_relativeTime(report.reportedAt, now)} · '
            '${_statusLabel(report.status)}',
            style: const TextStyle(fontSize: 11, color: _textHint),
          ),
        ],
      ),
    );
  }
}

String _formatClock(DateTime time) =>
    '${time.hour.toString().padLeft(2, '0')}:'
    '${time.minute.toString().padLeft(2, '0')}';

String _relativeTime(DateTime time, DateTime now) {
  final diff = now.difference(time);
  if (diff.inMinutes < 1) return '방금 전';
  if (diff.inHours < 1) return '${diff.inMinutes}분 전';
  return '${diff.inHours}시간 전';
}

String _sourceLabel(String source) => switch (source) {
  'user_report' => '학생 제보',
  'staff_confirmed' => '학교 확인',
  _ => source,
};

String _statusLabel(String status) => switch (status) {
  'received' => '접수',
  'checking' => '확인 중',
  'in_progress' => '조치 중',
  'resolved' => '완료',
  _ => status,
};
