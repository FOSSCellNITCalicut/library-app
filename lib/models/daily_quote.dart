class DailyQuote {
  final String text;
  final String? source;

  DailyQuote({required this.text, this.source});

  factory DailyQuote.fromJson(Map<String, dynamic> json) {
    return DailyQuote(
      text: json['text'] as String,
      source: json['source'] as String?,
    );
  }
}
