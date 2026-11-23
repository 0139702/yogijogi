import 'package:material_ui/material_ui.dart';

import '../../core/app_colors.dart';
import '../auth/auth_service.dart';
import 'report.dart';
import 'report_api.dart';
import 'report_category.dart';
import 'report_form_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, required this.api, this.auth});

  final ReportApi api;
  final AuthService? auth;

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

  void _comingSoon(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showProfile() {
    final auth = widget.auth;
    final user = auth?.currentUser;
    if (auth == null || user == null) {
      _comingSoon('마이 페이지는 준비 중이에요.');
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.brandSoft,
                child: Icon(Icons.person_outline, color: AppColors.brandStrong),
              ),
              title: Text(user.nickname ?? '', style: AppTextStyles.title),
              subtitle: Text(
                '@${user.username} · 학교 이메일 인증 완료',
                style: AppTextStyles.caption,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text('로그아웃', style: AppTextStyles.body),
              onTap: () {
                Navigator.pop(context);
                auth.signOut();
              },
            ),
          ],
        ),
      ),
    );
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
              _FeedHeader(onComingSoon: _comingSoon, onProfile: _showProfile),
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
              onShowMap: () => _comingSoon('지도 연동 후 이용할 수 있어요.'),
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

// 데모 값: 사용자·레벨 데이터가 생기면 서버 값으로 교체한다.
const _demoLevel = 'Lv.4 수호자';

class _FeedHeader extends StatelessWidget {
  const _FeedHeader({required this.onComingSoon, required this.onProfile});

  final ValueChanged<String> onComingSoon;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            8,
            AppSpacing.screenPadding,
            8,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brand.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/logo.png',
                  semanticLabel: '요기조기 로고',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "SUNGSHIN WOMEN'S CAMPUS",
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.brandStrong,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.brandSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _demoLevel,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.brandStrong,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: '알림',
                onPressed: () => onComingSoon('알림은 준비 중이에요.'),
                icon: const Icon(
                  Icons.notifications_none,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              IconButton.filled(
                tooltip: '마이',
                onPressed: onProfile,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.brandStrong,
                  foregroundColor: Colors.white,
                  fixedSize: const Size(48, 48),
                ),
                icon: const Icon(Icons.person_outline),
              ),
            ],
          ),
        ),
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

class _ReportPhotos extends StatelessWidget {
  const _ReportPhotos({required this.photos});

  final List<ReportPhoto> photos;

  void _open(BuildContext context, ReportPhoto photo) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Stack(
          children: [
            InteractiveViewer(
              child: Center(child: _NetworkPhoto(url: photo.url)),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton.filled(
                tooltip: '닫기',
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(backgroundColor: Colors.black54),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, ReportPhoto photo, double aspectRatio) {
    return Semantics(
      button: true,
      label: '제보 사진 크게 보기',
      child: GestureDetector(
        onTap: () => _open(context, photo),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: _NetworkPhoto(url: photo.url, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (photos.length == 1) return _tile(context, photos.single, 16 / 9);
    return Row(
      children: [
        for (final (index, photo) in photos.indexed) ...[
          if (index > 0) const SizedBox(width: 8),
          Expanded(child: _tile(context, photo, 1)),
        ],
      ],
    );
  }
}

class _NetworkPhoto extends StatelessWidget {
  const _NetworkPhoto({required this.url, this.fit = BoxFit.contain});

  final Uri url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url.toString(),
      fit: fit,
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : const ColoredBox(
              color: AppColors.brandSoft,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
      errorBuilder: (context, error, stackTrace) => const ColoredBox(
        color: AppColors.brandSoft,
        child: Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: AppColors.textSecondary,
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
          if (report.photos.isNotEmpty) ...[
            const SizedBox(height: 12),
            _ReportPhotos(photos: report.photos),
          ],
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
