import 'package:material_ui/material_ui.dart';

import '../../core/app_colors.dart';

class ReportCategory {
  const ReportCategory({
    required this.type,
    required this.hint,
    required this.icon,
    required this.color,
  });

  final String type;
  final String hint;
  final IconData icon;
  final Color color;

  Color get background => color.withValues(alpha: 0.12);

  static const all = [
    ReportCategory(
      type: '벌레 몬스터',
      hint: '바퀴벌레, 날벌레, 모기 목격',
      icon: Icons.pest_control,
      color: AppColors.hazard,
    ),
    ReportCategory(
      type: '비흡연구역 흡연',
      hint: '흡연 흔적, 담배 냄새',
      icon: Icons.smoke_free,
      color: AppColors.smoking,
    ),
    ReportCategory(
      type: '시설 고장 / 파손',
      hint: '냉난방, 승강기, 조명',
      icon: Icons.build_outlined,
      color: AppColors.textSecondary,
    ),
    ReportCategory(
      type: '기타 불편 / 제안',
      hint: '소음, 적치물, 악취 등',
      icon: Icons.lightbulb_outline,
      color: AppColors.textSecondary,
    ),
  ];

  static ReportCategory of(String type) => all.firstWhere(
    (category) => category.type == type,
    orElse: () => all.last,
  );
}

String reportStatusLabel(String status) => switch (status) {
  'received' => '담당자 확인 전',
  _ => status,
};

String reportSourceLabel(String source) => switch (source) {
  'user_report' => '학생 제보',
  _ => source,
};

const reportFloors = ['B1', '1F', '2F', '3F', '4F', '5F'];

class ReportLocation {
  const ReportLocation(this.place, this.floor);

  factory ReportLocation.parse(String value) {
    final match = _pattern.firstMatch(value);
    if (match == null) return ReportLocation(value, null);
    return ReportLocation(match[1]!, match[2]);
  }

  static const maxPlaceLength = 100;
  static final _pattern = RegExp('^(.+) \\((${reportFloors.join('|')})\\)\$');

  final String place;
  final String? floor;

  String encode() => floor == null ? place : '$place ($floor)';
}
