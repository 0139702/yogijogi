import 'package:material_ui/material_ui.dart';

import '../../core/app_colors.dart';
import '../../core/app_config.dart';
import '../reports/report_category.dart';
import 'my_report.dart';
import 'my_reports_api.dart';
import 'my_reports_repository.dart';

/// 마이페이지: 내가 등록한 제보의 처리 상황을 확인한다.
///
/// 진행 중/완료 탭, 처리 단계(접수 → 담당자 확인 → 조치 중 → 완료),
/// 담당자 답변, 최근 완료된 제보를 보여준다.
class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key, this.repository, this.clock});

  /// 데이터 저장소. 지정하지 않으면 데모 데이터를 사용한다.
  final MyReportsRepository? repository;

  /// 현재 시각 공급자. 테스트에서 시각을 고정할 때 사용한다.
  final DateTime Function()? clock;

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  late final MyReportsRepository _repository =
      widget.repository ??
      createMyReportsRepository(AppConfig.apiBaseUrl, clock: widget.clock);
  late Future<MyReportsSnapshot> _snapshot;
  bool _showResolved = false;

  @override
  void initState() {
    super.initState();
    _snapshot = _repository.fetchMyReports();
  }

  @override
  void dispose() {
    // 외부에서 받은 저장소는 넘겨준 쪽에서 정리한다.
    if (widget.repository == null) _repository.close();
    super.dispose();
  }

  Future<void> _refresh() {
    final snapshot = _repository.fetchMyReports();
    // 화살표 함수로 쓰면 대입한 Future를 반환해 setState가 예외를 던진다.
    setState(() {
      _snapshot = snapshot;
    });
    return snapshot.then((_) {}, onError: (_) {});
  }

  void _notReady(String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$feature 기능은 준비 중이에요.')));
  }

  void _openDetail(MyReport report, Duration? utcOffset) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      // 시트는 별도 화면이라 캠퍼스 시간대 정보를 다시 전달한다.
      builder: (_) => _CampusTime(
        utcOffset: utcOffset,
        child: _ReportDetailSheet(report: report),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(
              onNotifications: () => _notReady('알림'),
              onProfile: () => _notReady('프로필'),
            ),
            Expanded(
              child: FutureBuilder<MyReportsSnapshot>(
                future: _snapshot,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('내 제보를 불러오지 못했습니다.'),
                          TextButton(
                            onPressed: _refresh,
                            child: const Text('다시 시도'),
                          ),
                        ],
                      ),
                    );
                  }
                  return _buildContent(snapshot.requireData);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(MyReportsSnapshot data) {
    final active = data.active;
    final resolved = data.resolved;
    void openDetail(MyReport report) => _openDetail(report, data.utcOffset);
    return _CampusTime(
      utcOffset: data.utcOffset,
      child: _buildList(data, active, resolved, openDetail),
    );
  }

  Widget _buildList(
    MyReportsSnapshot data,
    List<MyReport> active,
    List<MyReport> resolved,
    void Function(MyReport) openDetail,
  ) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          16,
          AppSpacing.screenPadding,
          24,
        ),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('내 제보 내역', style: AppTextStyles.title),
              ),
              _CircleIconButton(
                icon: Icons.history,
                tooltip: '지난 제보 기록',
                onPressed: () => _notReady('지난 제보 기록'),
              ),
            ],
          ),
          if (data.isDemo) ...[const SizedBox(height: 12), const _DemoNotice()],
          const SizedBox(height: 12),
          _StatusTabs(
            activeCount: active.length,
            resolvedCount: resolved.length,
            showResolved: _showResolved,
            onChanged: (value) => setState(() => _showResolved = value),
          ),
          const SizedBox(height: 16),
          if (_showResolved) ...[
            if (resolved.isEmpty)
              const _EmptyText('아직 처리 완료된 제보가 없어요.')
            else
              for (final report in resolved)
                _CompletedReportCard(
                  report: report,
                  onTap: () => openDetail(report),
                ),
          ] else ...[
            if (active.isEmpty)
              const _EmptyText('진행 중인 제보가 없어요.')
            else
              for (final report in active)
                _ActiveReportCard(
                  report: report,
                  onOpenDetail: () => openDetail(report),
                ),
            if (resolved.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('최근 완료된 제보', style: AppTextStyles.title),
              const SizedBox(height: 12),
              _CompletedReportCard(
                report: resolved.first,
                onTap: () => openDetail(resolved.first),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onNotifications, required this.onProfile});

  final VoidCallback onNotifications;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        12,
        AppSpacing.screenPadding,
        12,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.brandStrong,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.explore, color: Colors.white, size: 20),
          ),
          const SizedBox(width: AppSpacing.elementGapHorizontal),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '요기조기',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.brand,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Text('내 제보', style: AppTextStyles.title),
              ],
            ),
          ),
          _CircleIconButton(
            icon: Icons.notifications_none,
            tooltip: '알림',
            onPressed: onNotifications,
          ),
          const SizedBox(width: 8),
          _CircleIconButton(
            icon: Icons.person_outline,
            tooltip: '프로필',
            onPressed: onProfile,
            background: AppColors.surface,
            bordered: true,
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.background = AppColors.brandSoft,
    this.bordered = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color background;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 22),
      color: AppColors.brandStrong,
      style: IconButton.styleFrom(
        backgroundColor: background,
        minimumSize: const Size(44, 44),
        side: bordered ? const BorderSide(color: AppColors.border) : null,
      ),
    );
  }
}

class _DemoNotice extends StatelessWidget {
  const _DemoNotice();

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
          const Icon(
            Icons.info_outline,
            size: 16,
            color: AppColors.brandStrong,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              // 좁은 화면에서 단어 중간에 줄이 바뀌지 않도록 문장 단위로 나눈다.
              '데모 데이터예요. 답변은 가상 예시예요.\n'
              '학교 부서에는 전달되지 않아요.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.brandStrong,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusTabs extends StatelessWidget {
  const _StatusTabs({
    required this.activeCount,
    required this.resolvedCount,
    required this.showResolved,
    required this.onChanged,
  });

  final int activeCount;
  final int resolvedCount;
  final bool showResolved;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.brandSoft,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              icon: Icons.autorenew,
              label: '진행 중',
              count: activeCount,
              selected: !showResolved,
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: _TabButton(
              icon: Icons.check_circle_outline,
              label: '완료',
              count: resolvedCount,
              selected: showResolved,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.icon,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : AppColors.textPrimary;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
    );
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.brandStrong : Colors.transparent,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: SizedBox(
            height: 44,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: foreground),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: AppTextStyles.body.copyWith(
                    color: foreground,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? Colors.white : AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.brandStrong,
                      fontWeight: FontWeight.w700,
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

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.foreground,
    required this.background,
    this.icon,
  });

  final String label;
  final Color foreground;
  final Color background;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final icon = this.icon;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// 카테고리 배지. 제보 피드와 같은 [ReportCategory] 아이콘·색을 사용한다.
class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge(this.type);

  final String type;

  @override
  Widget build(BuildContext context) {
    final category = ReportCategory.of(type);
    return _Badge(
      label: type,
      icon: category.icon,
      foreground: category.color == AppColors.textSecondary
          ? AppColors.textPrimary
          : category.color,
      background: category.background,
    );
  }
}

/// 답변 출처 배지. 가상 답변이면 데모임을 라벨로 밝힌다.
class _ResponseBadge extends StatelessWidget {
  const _ResponseBadge(this.report);

  final MyReport report;

  @override
  Widget build(BuildContext context) {
    final response = report.staffResponse;
    if (response == null) {
      return _Badge(
        label: reportSourceLabel(report.report.source),
        icon: Icons.person_outline,
        foreground: AppColors.textSecondary,
        background: AppColors.background,
      );
    }
    return _Badge(
      label: response.isDemo ? '가상 담당자 확인' : '담당자 확인',
      icon: Icons.verified_outlined,
      foreground: AppColors.resolved,
      background: AppColors.resolved.withValues(alpha: 0.12),
    );
  }
}

class _ActiveReportCard extends StatelessWidget {
  const _ActiveReportCard({required this.report, required this.onOpenDetail});

  final MyReport report;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final response = report.staffResponse;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CategoryBadge(report.report.type),
              _ResponseBadge(report),
            ],
          ),
          const SizedBox(height: 12),
          _LocationTitle(report.report.location),
          const SizedBox(height: 4),
          Text(
            '등록 ${_monthDay(context, report.report.occurredAt)} · '
            '${_clock(context, report.report.occurredAt)}',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 20),
          _StageProgress(current: report.stage),
          const SizedBox(height: 8),
          Text(
            '${report.stage.label} 단계로 변경 · '
            '${_monthDay(context, report.stageChangedAt)} '
            '${_clock(context, report.stageChangedAt)}',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 16),
          if (response != null)
            _ResponseBox(response: response)
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '아직 담당자 답변이 없어요.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onOpenDetail,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.brandStrong,
                textStyle: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('처리 상황 상세 보기 ›'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletedReportCard extends StatelessWidget {
  const _CompletedReportCard({required this.report, required this.onTap});

  final MyReport report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final response = report.staffResponse;
    final resolvedAt = report.stageChangedAt;
    return _Card(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _CategoryBadge(report.report.type),
              const Spacer(),
              _Badge(
                label: '조치 완료',
                icon: Icons.check_circle_outline,
                foreground: AppColors.resolved,
                background: AppColors.resolved.withValues(alpha: 0.12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _LocationTitle(report.report.location),
          const SizedBox(height: 4),
          Text(
            '${_monthDay(context, resolvedAt)} ${_clock(context, resolvedAt)}'
            '${response == null ? '' : ' · ${response.department} 답변 확인'}'
            '${response?.isDemo ?? false ? ' (가상)' : ''}',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: AppColors.border),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.surface,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    );
  }
}

/// 제보 피드와 같은 방식으로 장소명과 층을 표시한다.
class _LocationTitle extends StatelessWidget {
  const _LocationTitle(this.encoded);

  final String encoded;

  @override
  Widget build(BuildContext context) {
    final location = ReportLocation.parse(encoded);
    return Text.rich(
      TextSpan(
        text: location.place,
        children: [
          if (location.floor != null)
            TextSpan(
              text: '  ${location.floor}',
              style: AppTextStyles.body.copyWith(
                color: AppColors.brandStrong,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
      style: AppTextStyles.title,
    );
  }
}

/// 접수 → 담당자 확인 → 조치 중 → 완료 단계 표시.
class _StageProgress extends StatelessWidget {
  const _StageProgress({required this.current});

  final ReportStage current;

  @override
  Widget build(BuildContext context) {
    const stages = ReportStage.values;
    // 단계마다 같은 너비의 칸을 두고 점과 라벨을 칸 가운데에 놓아
    // 라벨이 항상 점 바로 아래에 오게 한다. 연결선은 칸의 좌우 절반에 그린다.
    return Semantics(
      label: '처리 단계 ${current.index + 1}/${stages.length}, ${current.label}',
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < stages.length; i++)
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StageLine(
                            visible: i > 0,
                            reached: i <= current.index,
                          ),
                        ),
                        _StageDot(index: i, current: current.index),
                        Expanded(
                          child: _StageLine(
                            visible: i < stages.length - 1,
                            reached: i < current.index,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      stages[i].label,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(
                        color: i == current.index
                            ? AppColors.brandStrong
                            : i < current.index
                            ? AppColors.brand
                            : AppColors.textSecondary,
                        fontWeight: i == current.index
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StageLine extends StatelessWidget {
  const _StageLine({required this.visible, required this.reached});

  final bool visible;
  final bool reached;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 3,
      color: !visible
          ? Colors.transparent
          : reached
          ? AppColors.brand
          : AppColors.border,
    );
  }
}

class _StageDot extends StatelessWidget {
  const _StageDot({required this.index, required this.current});

  final int index;
  final int current;

  @override
  Widget build(BuildContext context) {
    final done = index < current;
    final isCurrent = index == current;
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: done || isCurrent ? AppColors.brand : AppColors.border,
        shape: BoxShape.circle,
        border: isCurrent
            ? Border.all(color: AppColors.brandSoft, width: 3)
            : null,
      ),
      child: done
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : isCurrent
          ? Center(
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
    );
  }
}

class _ResponseBox extends StatelessWidget {
  const _ResponseBox({required this.response});

  final StaffResponse response;

  @override
  Widget build(BuildContext context) {
    final plan = response.plan;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.brandSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${response.department} · 담당자 답변',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.brandStrong,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (response.isDemo)
                const _Badge(
                  label: '데모',
                  foreground: AppColors.brandStrong,
                  background: AppColors.surface,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(response.message, style: AppTextStyles.body),
          if (plan != null) ...[
            const SizedBox(height: 4),
            Text(plan, style: AppTextStyles.caption),
          ],
          const SizedBox(height: 4),
          Text(
            '답변 ${_monthDay(context, response.respondedAt)} '
            '${_clock(context, response.respondedAt)}',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

/// 처리 단계별 변경 시각과 담당자 답변을 모아 보여 주는 상세 시트.
class _ReportDetailSheet extends StatelessWidget {
  const _ReportDetailSheet({required this.report});

  final MyReport report;

  @override
  Widget build(BuildContext context) {
    final response = report.staffResponse;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          12,
          AppSpacing.screenPadding,
          16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _CategoryBadge(report.report.type),
            const SizedBox(height: 12),
            _LocationTitle(report.report.location),
            const SizedBox(height: 8),
            Text(report.report.description, style: AppTextStyles.body),
            const SizedBox(height: 20),
            const Text('처리 상황', style: AppTextStyles.title),
            const SizedBox(height: 12),
            for (final stage in ReportStage.values)
              _HistoryRow(stage: stage, report: report),
            if (response != null) ...[
              const SizedBox(height: 12),
              _ResponseBox(response: response),
            ],
          ],
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.stage, required this.report});

  final ReportStage stage;
  final MyReport report;

  @override
  Widget build(BuildContext context) {
    StageChange? change;
    for (final item in report.history) {
      if (item.stage == stage) change = item;
    }
    final reached = stage.index <= report.stage.index;
    final changedAt = change?.changedAt;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            reached ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: reached ? AppColors.brand : AppColors.border,
          ),
          const SizedBox(width: AppSpacing.elementGapHorizontal),
          Expanded(
            child: Text(
              stage.label,
              style: AppTextStyles.body.copyWith(
                color: reached
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            changedAt != null
                ? '${_monthDay(context, changedAt)} ${_clock(context, changedAt)}'
                : reached
                ? '기록 없음'
                : '대기',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

class _EmptyText extends StatelessWidget {
  const _EmptyText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

String _two(int value) => value.toString().padLeft(2, '0');

/// 캠퍼스 기준 시간대를 하위 위젯에 전달한다.
/// 기기 시간대와 관계없이 캠퍼스 시각으로 표시하기 위해 사용한다.
class _CampusTime extends InheritedWidget {
  const _CampusTime({required this.utcOffset, required super.child});

  final Duration? utcOffset;

  static DateTime convert(BuildContext context, DateTime time) {
    final offset = context
        .dependOnInheritedWidgetOfExactType<_CampusTime>()
        ?.utcOffset;
    return offset == null ? time.toLocal() : time.toUtc().add(offset);
  }

  @override
  bool updateShouldNotify(_CampusTime oldWidget) =>
      utcOffset != oldWidget.utcOffset;
}

String _monthDay(BuildContext context, DateTime time) {
  final local = _CampusTime.convert(context, time);
  return '${_two(local.month)}.${_two(local.day)}';
}

String _clock(BuildContext context, DateTime time) {
  final local = _CampusTime.convert(context, time);
  return '${_two(local.hour)}:${_two(local.minute)}';
}
