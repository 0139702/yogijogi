class Report {
  Report.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      type = json['type'] as String,
      location = json['location'] as String,
      description = json['description'] as String,
      occurredAt = DateTime.parse(json['occurredAt'] as String),
      status = json['status'] as String,
      source = json['source'] as String,
      updatedAt = DateTime.parse(json['updatedAt'] as String);

  final String id;
  final String type;
  final String location;
  final String description;
  final DateTime occurredAt;
  final String status;
  final String source;
  final DateTime updatedAt;
}
