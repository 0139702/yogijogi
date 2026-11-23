import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/app_colors.dart';
import 'report.dart';
import 'report_api.dart';
import 'report_category.dart';

class ReportFormScreen extends StatefulWidget {
  const ReportFormScreen({
    super.key,
    required this.api,
    this.report,
    this.initialLocation,
  });

  final ReportApi api;
  final Report? report;
  final String? initialLocation;

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  static const _descriptionLimit = 200;
  static const _photoLimit = 3;

  late final _location = ReportLocation.parse(
    widget.report?.location ?? widget.initialLocation ?? '',
  );
  late String? _type = widget.report?.type;
  late String? _floor = _location.floor;
  late DateTime _occurredAt = (widget.report?.occurredAt ?? DateTime.now())
      .toLocal();
  late final _place = TextEditingController(text: _location.place);
  late final _description = TextEditingController(
    text: widget.report?.description,
  );
  final _placeFocus = FocusNode();
  bool _submitted = false;
  bool _saving = false;
  bool _failed = false;
  final _picker = ImagePicker();
  final _photos = <XFile>[];
  late final _keptPhotos = [...?widget.report?.photos];
  bool _photoGuideShown = false;
  String? _progress;

  int get _photoCount => _keptPhotos.length + _photos.length;

  @override
  void dispose() {
    _place.dispose();
    _description.dispose();
    _placeFocus.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final now = DateTime.now();
    final first = DateTime(now.year - 1);
    final date = await showDatePicker(
      context: context,
      initialDate: _occurredAt.isAfter(now) ? now : _occurredAt,
      firstDate: _occurredAt.isBefore(first) ? _occurredAt : first,
      lastDate: now,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_occurredAt),
    );
    if (time == null || !mounted) return;
    setState(() {
      _occurredAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _addPhoto() async {
    if (!_photoGuideShown) {
      final agreed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('사진을 올리기 전에 확인해 주세요'),
          content: const Text(
            '얼굴, 이름, 연락처, 차량 번호처럼 다른 사람을 알아볼 수 있는 정보가 '
            '찍히지 않게 해 주세요. 문제 상황이 보이는 범위만 담아 주세요.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('확인했어요'),
            ),
          ],
        ),
      );
      if (agreed != true || !mounted) return;
      _photoGuideShown = true;
    }
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('앨범에서 선택'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('카메라로 촬영'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    try {
      final photo = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 80,
      );
      if (photo != null && mounted) setState(() => _photos.add(photo));
    } on PlatformException {
      if (mounted) _showMessage('사진을 불러오지 못했어요. 카메라와 사진 접근 권한을 확인해 주세요.');
    }
  }

  /// 지운 기존 사진을 서버에서 삭제하고 새 사진을 올린다. 실패한 장수를 돌려준다.
  Future<int> _syncPhotos(Report saved, ValueChanged<Report> onUpdated) async {
    var failed = 0;
    final keptIds = {for (final photo in _keptPhotos) photo.id};
    for (final photo in saved.photos.where((p) => !keptIds.contains(p.id))) {
      try {
        onUpdated(await widget.api.deletePhoto(saved.id, photo.id));
      } on Exception {
        failed++;
      }
    }
    for (final (index, photo) in _photos.indexed) {
      if (mounted) {
        setState(() => _progress = '사진 올리는 중 (${index + 1}/${_photos.length})');
      }
      try {
        onUpdated(await widget.api.uploadPhoto(saved.id, File(photo.path)));
      } on Exception {
        failed++;
      }
    }
    return failed;
  }

  Future<void> _save() async {
    setState(() => _submitted = true);
    final type = _type;
    if (type == null ||
        _place.text.trim().isEmpty ||
        _description.text.trim().isEmpty) {
      return;
    }
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      var saved = await widget.api.save(
        id: widget.report?.id,
        type: type,
        location: ReportLocation(_place.text.trim(), _floor).encode(),
        description: _description.text.trim(),
        occurredAt: _occurredAt,
      );
      final failed = await _syncPhotos(saved, (report) => saved = report);
      if (!mounted) return;
      if (failed > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('제보는 저장됐지만 사진 $failed장을 처리하지 못했어요.')),
        );
      }
      Navigator.pop(context, saved);
    } on Exception {
      if (mounted) {
        setState(() {
          _saving = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.report != null;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          editing ? '제보 수정하기' : '새로운 제보 남기기',
          style: AppTextStyles.title,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          16,
          AppSpacing.screenPadding,
          32,
        ),
        children: [
          Row(
            children: [
              Expanded(child: Text('어떤 상황인가요?', style: AppTextStyles.title)),
              Text('필수 선택', style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.elementGapHorizontal,
            crossAxisSpacing: AppSpacing.elementGapHorizontal,
            childAspectRatio: 1.2,
            children: [
              for (final category in ReportCategory.all)
                _CategoryCard(
                  category: category,
                  selected: _type == category.type,
                  onTap: _saving
                      ? null
                      : () => setState(() => _type = category.type),
                ),
            ],
          ),
          if (_submitted && _type == null) const _ErrorText('어떤 상황인지 선택해 주세요.'),
          const _SectionTitle('제보 위치'),
          _Panel(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const _MapThumbnail(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _place,
                        focusNode: _placeFocus,
                        enabled: !_saving,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(
                            ReportLocation.maxPlaceLength,
                          ),
                        ],
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration.collapsed(
                          hintText: '건물과 구역을 입력해 주세요',
                          hintStyle: AppTextStyles.body.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(_floor ?? '층수 미선택', style: AppTextStyles.caption),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _saving ? null : _placeFocus.requestFocus,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.brandStrong,
                            visualDensity: VisualDensity.compact,
                            textStyle: AppTextStyles.body,
                          ),
                          child: const Text('위치 수정 ›'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_submitted && _place.text.trim().isEmpty)
            const _ErrorText('제보 위치를 입력해 주세요.'),
          const _SectionTitle('층수'),
          Wrap(
            spacing: AppSpacing.elementGapHorizontal,
            runSpacing: 8,
            children: [
              for (final floor in reportFloors)
                _FloorChip(
                  label: floor,
                  selected: _floor == floor,
                  onTap: _saving
                      ? null
                      : () => setState(
                          () => _floor = _floor == floor ? null : floor,
                        ),
                ),
            ],
          ),
          const _SectionTitle('발생 시각'),
          _Panel(
            child: ListTile(
              enabled: !_saving,
              onTap: _pickTime,
              leading: const Icon(Icons.schedule, color: AppColors.brand),
              title: Text(
                reportDateTime(_occurredAt),
                style: AppTextStyles.body,
              ),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
          const _SectionTitle('상세 내용'),
          TextField(
            controller: _description,
            enabled: !_saving,
            minLines: 3,
            maxLines: 6,
            maxLength: _descriptionLimit,
            style: AppTextStyles.body,
            onChanged: (_) => setState(() {}),
            buildCounter:
                (
                  context, {
                  required currentLength,
                  required isFocused,
                  maxLength,
                }) => Text(
                  '$currentLength / $maxLength자',
                  style: AppTextStyles.caption,
                ),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surface,
              hintText: '다른 학우들이 알면 좋을 내용을 적어주세요.\n예: 2호기 승강기 문이 덜컹거려요.',
              hintStyle: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
              contentPadding: const EdgeInsets.all(16),
              enabledBorder: _inputBorder(AppColors.border),
              disabledBorder: _inputBorder(AppColors.border),
              focusedBorder: _inputBorder(AppColors.brand),
            ),
          ),
          if (_submitted && _description.text.trim().isEmpty)
            const _ErrorText('상세 내용을 입력해 주세요.'),
          const _SectionTitle('사진 (선택)'),
          SizedBox(
            height: 88,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                if (_photoCount < _photoLimit)
                  _AddPhotoTile(
                    count: _photoCount,
                    limit: _photoLimit,
                    onTap: _saving ? null : _addPhoto,
                  ),
                for (final photo in _keptPhotos)
                  _PhotoThumbnail(
                    image: NetworkImage(photo.url.toString()),
                    onRemove: _saving
                        ? null
                        : () => setState(() => _keptPhotos.remove(photo)),
                  ),
                for (final photo in _photos)
                  _PhotoThumbnail(
                    image: FileImage(File(photo.path)),
                    onRemove: _saving
                        ? null
                        : () => setState(() => _photos.remove(photo)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.brandSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.privacy_tip_outlined,
                  size: 20,
                  color: AppColors.brandStrong,
                ),
                const SizedBox(width: AppSpacing.elementGapHorizontal),
                Expanded(
                  child: Text(
                    "제보는 '익명의 학우'로 공개돼요. 이름, 연락처, 얼굴, 차량 번호 같은 "
                    '개인정보나 특정인을 지목하는 내용은 적지 말아 주세요.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_failed) const _ErrorText('저장하지 못했습니다. API 상태를 확인해 주세요.'),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            8,
            AppSpacing.screenPadding,
            12,
          ),
          child: FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandStrong,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text(
              _saving
                  ? _progress ?? '저장 중'
                  : editing
                  ? '수정 완료'
                  : '제보 등록하기',
            ),
          ),
        ),
      ),
    );
  }
}

String reportDateTime(DateTime time) {
  final local = time.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${local.month}월 ${local.day}일 '
      '${two(local.hour)}:${two(local.minute)}';
}

OutlineInputBorder _inputBorder(Color color) => OutlineInputBorder(
  borderRadius: BorderRadius.circular(16),
  borderSide: BorderSide(color: color),
);

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(text, style: AppTextStyles.title),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          color: Theme.of(context).colorScheme.error,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.padding = EdgeInsets.zero});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final ReportCategory category;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    return Semantics(
      selected: selected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandSoft : AppColors.surface,
          borderRadius: radius,
          border: Border.all(
            color: selected ? AppColors.brand : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: category.background,
                        child: Icon(category.icon, color: category.color),
                      ),
                      const Spacer(),
                      Text(
                        category.type,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category.hint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                  if (selected)
                    const Positioned(
                      top: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.brand,
                        child: Icon(Icons.check, size: 16, color: Colors.white),
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

class _MapThumbnail extends StatelessWidget {
  const _MapThumbnail();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 108,
        height: 84,
        color: AppColors.brandSoft,
        child: const Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 36,
              height: 8,
              child: ColoredBox(color: AppColors.surface),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              left: 44,
              width: 8,
              child: ColoredBox(color: AppColors.surface),
            ),
            Positioned(
              left: 8,
              top: 8,
              child: _Block(color: Color(0x339CCDBB)),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: _Block(color: Color(0x33696FB8)),
            ),
            Center(
              child: Icon(
                Icons.location_on_outlined,
                color: AppColors.brandStrong,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({
    required this.count,
    required this.limit,
    required this.onTap,
  });

  final int count;
  final int limit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: AppColors.border),
    );
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.elementGapHorizontal),
      child: Material(
        color: AppColors.surface,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: SizedBox(
            width: 88,
            height: 88,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.add_photo_alternate_outlined,
                  color: AppColors.brand,
                ),
                const SizedBox(height: 4),
                Text('$count / $limit', style: AppTextStyles.caption),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  const _PhotoThumbnail({required this.image, required this.onRemove});

  final ImageProvider image;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.elementGapHorizontal),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image(
              image: image,
              width: 88,
              height: 88,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const SizedBox(
                width: 88,
                height: 88,
                child: ColoredBox(
                  color: AppColors.brandSoft,
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton.filled(
              tooltip: '사진 삭제',
              onPressed: onRemove,
              style: IconButton.styleFrom(
                backgroundColor: Colors.black54,
                foregroundColor: Colors.white,
                minimumSize: const Size(28, 28),
                fixedSize: const Size(28, 28),
                padding: EdgeInsets.zero,
              ),
              iconSize: 16,
              icon: const Icon(Icons.close),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloorChip extends StatelessWidget {
  const _FloorChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
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
          child: Container(
            width: 64,
            height: 44,
            alignment: Alignment.center,
            child: Text(
              label,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w700,
                color: selected
                    ? AppColors.brandStrong
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
