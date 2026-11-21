import 'package:material_ui/material_ui.dart';

import '../../core/app_colors.dart';
import 'report.dart';
import 'report_api.dart';
import 'report_category.dart';
import 'report_form_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, required this.api});

  final ReportApi api;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late Future<List<Report>> _reports;
  String? _filter;

  @override
  void initState() {
    super.initState();
    _reports = widget.api.baseUrl == null
        ? Future.value(const [])
        : widget.api.list();
  }

  Future<void> _refresh() {
    final reports = widget.api.list();
    setState(() => _reports = reports);
    return reports.then((_) {}, onError: (_) {});
  }

  Future<void> _edit([Report? report]) async {
    final saved = await Navigator.of(context).push<Report>(
      MaterialPageRoute(
        builder: (_) => ReportFormScreen(api: widget.api, report: report),
      ),
    );
    if (saved != null && mounted) _refresh();
  }

  void _showMap() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('지도 연동 후 이용할 수 있어요.')));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.api.baseUrl == null) {
      return const Center(child: Text('제보를 보려면 API 주소를 설정해 주세요.'));
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        backgroundColor: AppColors.brandStrong,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit_note),
        label: const Text('제보하기'),
      ),
      body: FutureBuilder<List<Report>>(
        future: _reports,
        builder: (context, snapshot) {
          final reports = snapshot.data ?? const <Report>[];
          return Column(
            children: [
              _FilterBar(
                reports: reports,
                selected: _filter,
                onSelected: (type) => setState(() => _filter = type),
              ),
              Expanded(child: _buildList(snapshot)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(AsyncSnapshot<List<Report>> snapshot) {
    final loading = snapshot.connectionState != ConnectionState.done;
    if (snapshot.hasError && !loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('제보를 불러오지 못했습니다.'),
            TextButton(onPressed: _refresh, child: const Text('다시 시도')),
          ],
        ),
      );
    }
    if (!snapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }
    final reports = snapshot.requireData
        .where((report) => _filter == null || report.type == _filter)
        .toList();
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          4,
          AppSpacing.screenPadding,
          96,
        ),
        children: [
          const _DemoNotice(),
          const SizedBox(height: 16),
          if (reports.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 80),
              child: Text(
                '아직 등록된 제보가 없어요.\n첫 제보를 남겨 주세요!',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          for (final report in reports)
            _ReportCard(
              report: report,
              onEdit: () => _edit(report),
              onShowMap: _showMap,
            ),
        ],
      ),
    );
  }
}

String _relativeTime(DateTime time) {
  final elapsed = DateTime.now().difference(time);
  if (elapsed.inMinutes < 1) return '방금 전';
  if (elapsed.inHours < 1) return '${elapsed.inMinutes}분 전';
  if (elapsed.inDays < 1) return '${elapsed.inHours}시간 전';
  if (elapsed.inDays < 7) return '${elapsed.inDays}일 전';
  return reportDateTime(time);
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
              '데모 단계예요. 제보는 학교 담당 부서에 전달되지 않아요.',
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

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.reports,
    required this.selected,
    required this.onSelected,
  });

  final List<Report> reports;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
          vertical: 10,
        ),
        children: [
          _FilterChip(
            label: '전체',
            icon: Icons.apps,
            iconColor: AppColors.brand,
            count: reports.length,
            selected: selected == null,
            onTap: () => onSelected(null),
          ),
          for (final category in ReportCategory.all)
            _FilterChip(
              label: category.type,
              icon: category.icon,
              iconColor: category.color,
              count: reports
                  .where((report) => report.type == category.type)
                  .length,
              selected: selected == category.type,
              onTap: () => onSelected(category.type),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: BorderSide(color: selected ? AppColors.brand : AppColors.border),
    );
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.elementGapHorizontal),
      child: Semantics(
        selected: selected,
        child: Material(
          color: selected ? AppColors.brandSoft : AppColors.surface,
          shape: shape,
          child: InkWell(
            customBorder: shape,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(icon, size: 16, color: iconColor),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: AppTextStyles.body.copyWith(
                      color: selected
                          ? AppColors.brandStrong
                          : AppColors.textPrimary,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$count',
                    style: AppTextStyles.caption.copyWith(
                      color: selected
                          ? AppColors.brandStrong
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.report,
    required this.onEdit,
    required this.onShowMap,
  });

  final Report report;
  final VoidCallback onEdit;
  final VoidCallback onShowMap;

  @override
  Widget build(BuildContext context) {
    final category = ReportCategory.of(report.type);
    final location = ReportLocation.parse(report.location);
    final edited =
        report.updatedAt.difference(report.occurredAt).inMinutes >= 1;
    final resolved = report.status == 'resolved';
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: category.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(category.icon, size: 14, color: category.color),
                    const SizedBox(width: 4),
                    Text(
                      report.type,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '${reportSourceLabel(report.source)} · '
                  '발생 ${_relativeTime(report.occurredAt)}'
                  '${edited ? ' · 수정됨' : ''}',
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text.rich(
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
          ),
          const SizedBox(height: 8),
          Text(
            report.description,
            style: AppTextStyles.body.copyWith(height: 1.5),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  resolved ? Icons.check_circle_outline : Icons.schedule,
                  size: 16,
                  color: resolved
                      ? AppColors.resolved
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '처리 상태: ${reportStatusLabel(report.status)}',
                    style: AppTextStyles.body,
                  ),
                ),
                Text(
                  '갱신 ${_relativeTime(report.updatedAt)}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onEdit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandStrong,
                    minimumSize: const Size.fromHeight(48),
                    shape: buttonShape,
                    textStyle: AppTextStyles.body,
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('제보 수정'),
                ),
              ),
              const SizedBox(width: AppSpacing.elementGapHorizontal),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onShowMap,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandSoft,
                    foregroundColor: AppColors.brandStrong,
                    minimumSize: const Size.fromHeight(48),
                    shape: buttonShape,
                    textStyle: AppTextStyles.body,
                  ),
                  icon: const Icon(Icons.near_me_outlined, size: 18),
                  label: const Text('스팟 지도 보기'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
