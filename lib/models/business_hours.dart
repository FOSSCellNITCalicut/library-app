class HourEntry {
  final String area;
  final String schedule;

  HourEntry({required this.area, required this.schedule});

  factory HourEntry.fromJson(Map<String, dynamic> json) {
    return HourEntry(
      area: json['area'] as String,
      schedule: json['schedule'] as String,
    );
  }
}
