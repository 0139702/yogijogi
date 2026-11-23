class Report {
  Report.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      type = json['type'] as String,
      location = json['location'] as String,
      description = json['description'] as String,
      occurredAt = DateTime.parse(json['occurredAt'] as String),
      status = json['status'] as String,
      source = json['source'] as String,
      updatedAt = DateTime.parse(json['updatedAt'] as String),
      photos = [
        for (final photo in json['photos'] as List<dynamic>? ?? const [])
          ReportPhoto.fromJson(photo as Map<String, dynamic>),
      ];

  final String id;
  final String type;
  final String location;
  final String description;
  final DateTime occurredAt;
  final String status;
  final String source;
  final DateTime updatedAt;
  final List<ReportPhoto> photos;
}

class ReportPhoto {
  ReportPhoto.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      url = Uri.parse(json['url'] as String);

  final String id;

  /// 서버가 내려준 조회 주소. 시간이 지나면 만료되므로 목록을 새로 받으면 갱신된다.
  final Uri url;
}
