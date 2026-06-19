import 'package:flutter/material.dart';

class BookCoverImage extends StatelessWidget {
  final String? coverUrl;
  final List<String> isbn;
  final double? width;
  final double? height;
  final BoxFit fit;

  const BookCoverImage({
    super.key,
    required this.coverUrl,
    required this.isbn,
    this.width,
    this.height,
    this.fit = BoxFit.fill,
  });

  @override
  Widget build(BuildContext context) {
    return _buildImage(0);
  }

  Widget _buildImage(int isbnIndex) {
    // 1. Try coverUrl first (only on index 0)
    if (isbnIndex == 0 && coverUrl != null && coverUrl!.trim().isNotEmpty) {
      return Image.network(
        coverUrl!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return _buildFromIsbnList(0);
        },
      );
    }

    return _buildFromIsbnList(isbnIndex);
  }

  Widget _buildFromIsbnList(int index) {
    // Filter out empty/invalid ISBNs
    final validIsbns = isbn.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    if (index < validIsbns.length) {
      final cleanIsbn = validIsbns[index];
      final url = 'https://covers.openlibrary.org/b/isbn/$cleanIsbn-M.jpg?default=false';
      return Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          // If this ISBN fails, recursively try the next one in the list
          return _buildFromIsbnList(index + 1);
        },
      );
    }

    // Fallback to placeholder if all fail/empty
    return Image.asset(
      'assets/stats_book_temp.png',
      width: width,
      height: height,
      fit: fit,
    );
  }
}
