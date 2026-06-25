class NewArrival {
  final int biblioId;
  final String title;
  final String? coverUrl;
  final List<String> authors;

  NewArrival({
    required this.biblioId,
    required this.title,
    this.coverUrl,
    this.authors = const [],
  });

  factory NewArrival.fromJson(Map<String, dynamic> json) {
    return NewArrival(
      biblioId: json['biblio_id'] as int,
      title: json['title'] as String,
      coverUrl: json['cover_url'] as String?,
      authors: (json['authors'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}
