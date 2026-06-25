class StackEntry {
  final String stack;
  final String callRange;

  StackEntry({required this.stack, required this.callRange});

  factory StackEntry.fromJson(Map<String, dynamic> json) {
    return StackEntry(
      stack: json['stack'] as String,
      callRange: json['call_range'] as String,
    );
  }
}
