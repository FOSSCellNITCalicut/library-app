class BookDetail {
  final int biblioId;
  final String title;
  final List<String> authors;
  final List<String> isbn;
  final String publisher;
  final int publishedYear;
  final String? edition;
  final String? description;
  final String? coverUrl;
  final List<String> categories;

  final int totalCopies;
  final int availableCopies;
  final int libCopies;
  final int matCopies;

  final DateTime? availabilitySyncedAt;
  final List<BookCopy> copies;

  BookDetail({
    required this.biblioId,
    required this.title,
    required this.authors,
    required this.isbn,
    required this.publisher,
    required this.publishedYear,
    required this.edition,
    required this.description,
    required this.coverUrl,
    required this.categories,
    required this.totalCopies,
    required this.availableCopies,
    required this.libCopies,
    required this.matCopies,
    required this.availabilitySyncedAt,
    required this.copies,
  });

  factory BookDetail.fromJson(Map<String, dynamic> json) {
    return BookDetail(
      biblioId: (json['biblio_id'] ?? 0) as int,
      title: json['title'] ?? '',

      authors: List<String>.from(json['authors'] ?? []),

      isbn: (json['isbn'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList(),

      publisher: json['publisher'] ?? '',
      publishedYear: (json['published_year'] ?? 0) as int,

      edition: json['edition'],
      description: json['description'],
      coverUrl: json['cover_url'],

      categories: List<String>.from(json['categories'] ?? []),

      totalCopies: (json['total_copies'] ?? 0) as int,
      availableCopies: (json['available_copies'] ?? 0) as int,
      libCopies: (json['lib_copies'] ?? 0) as int,
      matCopies: (json['mat_copies'] ?? 0) as int,

      availabilitySyncedAt:
          DateTime.tryParse(json['availability_synced_at'] ?? ''),

      copies: (json['copies'] as List<dynamic>? ?? [])
          .map((e) => BookCopy.fromJson(e))
          .toList(),
    );
  }

  bool get isAvailable => availableCopies > 0;
}



class BookCopy {
  final int itemId;
  final String branch;
  final String callNumber;
  final String status;
  final String acquisitionDate;

  BookCopy({
    required this.itemId,
    required this.branch,
    required this.callNumber,
    required this.status,
    required this.acquisitionDate,
  });

  factory BookCopy.fromJson(Map<String, dynamic> json) {
    return BookCopy(
      itemId: json['item_id'],
      branch: json['branch'] ?? '',
      callNumber: json['callnumber'] ?? '',
      status: json['status'] ?? '',
      acquisitionDate: json['acquisition_date'] ?? '',
    );
  }
}