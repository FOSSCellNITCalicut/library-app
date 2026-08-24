import 'package:flutter/material.dart';
import 'package:library_nitc/theme/app_colors.dart';
import 'package:library_nitc/bookCoverImage.dart';
import 'package:library_nitc/bookPage.dart';
import 'package:library_nitc/globals.dart';
import 'package:library_nitc/models/book_details.dart';
import 'package:library_nitc/services/book_service.dart';

class CatalogBooksPage extends StatefulWidget {
  final String courseId;
  final String courseName;

  const CatalogBooksPage({
    required this.courseId,
    required this.courseName,
    super.key,
  });

  @override
  State<CatalogBooksPage> createState() => _CatalogBooksPageState();
}

class _CatalogBooksPageState extends State<CatalogBooksPage> {
  final BookService _service = BookService();
  List<BookDetail> _books = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchBooks();
  }

  Future<void> _fetchBooks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _service.fetchCatalogBooks(widget.courseId);
      if (mounted) {
        setState(() {
          _books = response.books;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.courseName),
        backgroundColor: context.cs.primary,
        foregroundColor: context.cs.surface,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: context.cs.outline),
            const SizedBox(height: 16),
            Text('Error: $_error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchBooks,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_books.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book, size: 64, color: context.cs.outline),
            SizedBox(height: 16),
            Text('No books available for this course'),
          ],
        ),
      );
    }

    final count = _books.length;

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: _books.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '$count book${count == 1 ? '' : 's'} found',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }

        final book = _books[index - 1];
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            Navigator.of(context).push(
              slideRoute(BookPage(biblioId: book.biblioId, book: book)),
            );
          },
          child: SizedBox(
            height: 178,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: BookCoverImage(
                      coverUrl: book.coverUrl,
                      width: 108,
                      height: 162,
                      fit: BoxFit.fill,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            book.authors.isNotEmpty ? book.authors[0] : '',
                          ),
                          const Expanded(child: SizedBox()),
                          Row(
                            children: [
                              Text(
                                book.availableCopies > 0
                                    ? 'Available'
                                    : 'Unavailable',
                                style: TextStyle(
                                  color: book.availableCopies > 0
                                      ? AppColors.available
                                      : AppColors.unavailable,
                                ),
                              ),
                              const Spacer(),
                              const Text('View More'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
