class BookSummary {
  final int biblioId;
  final String title;
  final List<String> authors;
  final List<String> isbn;
  final int availableCopies;
  final int totalCopies;
  final String? coverUrl;
  final String? edition;
  final List<String> branches;

  const BookSummary({
    required this.biblioId,
    required this.title,
    required this.authors,
    required this.isbn,
    required this.availableCopies,
    required this.totalCopies,
    this.coverUrl,
    this.edition,
    required this.branches,
  });

  factory BookSummary.fromJson(Map<String, dynamic> json) {
    final biblioId = json['biblio_id'];
    final title = json['title'];
    final availableCopies = json['available_copies'];
    final totalCopies = json['total_copies'];
    if (biblioId == null ||
        title == null ||
        availableCopies == null ||
        totalCopies == null) {
      throw FormatException(
          'Missing required field in BookSummary JSON: $json');
    }
    return BookSummary(
      biblioId: biblioId as int,
      title: title as String,
      authors: (json['authors'] as List?)?.cast<String>() ?? [],
      isbn: (json['isbn'] as List?)?.cast<String>() ?? [],
      availableCopies: availableCopies as int,
      totalCopies: totalCopies as int,
      coverUrl: json['cover_url'] as String?,
      edition: json['edition'] as String?,
      branches: (json['branches'] as List?)?.cast<String>() ?? [],
    );
  }
}
