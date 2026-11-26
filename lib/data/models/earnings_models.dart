class DriverEarningsDay {
  final String day;
  final int trips;
  final int grossPence;

  const DriverEarningsDay({
    required this.day,
    required this.trips,
    required this.grossPence,
  });

  double get grossPounds => grossPence / 100.0;

  factory DriverEarningsDay.fromJson(Map<String, dynamic> json) => DriverEarningsDay(
        day: '${json['day']}',
        trips: (json['trips'] as num?)?.toInt() ?? 0,
        grossPence: (json['grossPence'] as num?)?.toInt() ?? 0,
      );
}

class DriverEarningsReport {
  final String from;
  final String to;
  final int trips;
  final int grossPence;
  final List<DriverEarningsDay> days;

  const DriverEarningsReport({
    required this.from,
    required this.to,
    required this.trips,
    required this.grossPence,
    required this.days,
  });

  double get grossPounds => grossPence / 100.0;

  factory DriverEarningsReport.fromJson(Map<String, dynamic> json) {
    final range = json['range'] as Map<String, dynamic>? ?? {};
    final rawDays = json['days'];
    final days = rawDays is List
        ? rawDays
            .whereType<Map>()
            .map((e) => DriverEarningsDay.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <DriverEarningsDay>[];
    return DriverEarningsReport(
      from: '${range['from'] ?? ''}',
      to: '${range['to'] ?? ''}',
      trips: (json['trips'] as num?)?.toInt() ?? 0,
      grossPence: (json['grossPence'] as num?)?.toInt() ?? 0,
      days: days,
    );
  }
}
