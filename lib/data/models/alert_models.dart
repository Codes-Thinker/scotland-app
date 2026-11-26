class ApiAlert {
  final String id;
  final String type;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime? readAt;

  const ApiAlert({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.readAt,
  });

  bool get isUnread => readAt == null;

  String get displayText => body.trim().isEmpty ? title : '$title — $body';

  factory ApiAlert.fromJson(Map<String, dynamic> json) => ApiAlert(
        id: '${json['id']}',
        type: '${json['type'] ?? ''}',
        title: '${json['title'] ?? ''}',
        body: '${json['body'] ?? ''}',
        createdAt: DateTime.tryParse('${json['createdAt']}') ?? DateTime.now().toUtc(),
        readAt: json['readAt'] != null ? DateTime.tryParse('${json['readAt']}') : null,
      );
}

class ApiAlertPage {
  final List<ApiAlert> data;
  final int page;
  final int pageSize;
  final int total;

  const ApiAlertPage({
    required this.data,
    required this.page,
    required this.pageSize,
    required this.total,
  });

  factory ApiAlertPage.fromJson(Map<String, dynamic> json) {
    final raw = json['data'];
    final list = raw is List
        ? raw
            .whereType<Map>()
            .map((e) => ApiAlert.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <ApiAlert>[];
    return ApiAlertPage(
      data: list,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 20,
      total: (json['total'] as num?)?.toInt() ?? list.length,
    );
  }
}
