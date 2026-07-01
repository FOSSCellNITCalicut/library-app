import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:library_nitc/cache/cache_policy.dart';
import 'package:library_nitc/cache/cached_http_client.dart';
import 'package:library_nitc/models/book_details.dart' show BookAvailability, BookDetail;

const String kBaseUrl = 'http://localhost:8000';

class BookService {
  final String baseUrl;

  // One CachedHttpClient per endpoint policy — each has its own namespace
  // and LRU store so policies don't interfere with each other.
  late final CachedHttpClient _browseClient;
  late final CachedHttpClient _searchClient;
  late final CachedHttpClient _detailClient;

  BookService({this.baseUrl = kBaseUrl}) {
    _browseClient = CachedHttpClient(namespace: 'books_browse', policy: CachePolicy.booksBrowse);
    _searchClient = CachedHttpClient(namespace: 'books_search', policy: CachePolicy.booksSearch);
    _detailClient = CachedHttpClient(namespace: 'book_detail', policy: CachePolicy.bookDetail);
  }

  // ── Browse ─────────────────────────────────────────────────────────────────

  /// P4 — cached 5 min, stale-while-revalidate.
  Future<http.Response> fetchBrowse(int page, int perPage) async {
    final uri = Uri.parse('$baseUrl/api/v1/books/browse').replace(
      queryParameters: {'page': '$page', 'per_page': '$perPage'},
    );
    return _browseClient.get(uri);
  }

  // ── Search ─────────────────────────────────────────────────────────────────

  /// P5 — cached 5 min per unique URL, LRU 50.
  Future<http.Response> fetchSearch(String query, int page, int perPage, {List<String>? categories}) async {
    final queryParams = <String, String>{
      'q': query,
      'page': '$page',
      'per_page': '$perPage',
    };
    final uri = Uri.parse('$baseUrl/api/v1/books/search').replace(
      queryParameters: queryParams,
    );

    // Add category parameters manually since Uri doesn't support multiple
    // values for the same key natively.
    if (categories != null && categories.isNotEmpty) {
      final categoryParams = categories
          .map((cat) => 'category=${Uri.encodeComponent(cat)}')
          .join('&');
      final finalUri = Uri.parse('$uri&$categoryParams');
      return _searchClient.get(finalUri);
    }

    return _searchClient.get(uri);
  }

  // ── Book detail ────────────────────────────────────────────────────────────

  /// P2 — cached 24 hr.
  Future<BookDetail> getBookDetail(int biblioId) async {
    final uri = Uri.parse('$baseUrl/api/v1/books/$biblioId');
    final res = await _detailClient.get(uri);
    if (res.statusCode == 200) {
      return BookDetail.fromJson(jsonDecode(res.body));
    } else {
      throw Exception('Detail failed: ${res.body}');
    }
  }

  // ── Availability (not cached — live check on demand) ──────────────────────

  Future<BookAvailability> checkAvailability(int biblioId) async {
    final uri = Uri.parse('$baseUrl/api/v1/books/$biblioId/availability');
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      return BookAvailability.fromJson(jsonDecode(res.body));
    } else {
      throw Exception('Availability check failed: ${res.body}');
    }
  }

  // ── Cache invalidation helpers ─────────────────────────────────────────────

  /// Call after any write that changes book data (e.g. admin edits).
  void invalidateBookDetail(int biblioId) {
    final uri = Uri.parse('$baseUrl/api/v1/books/$biblioId');
    _detailClient.invalidate(uri);
  }

  /// Clears all browse pages (e.g. after new arrivals are expected).
  void invalidateBrowse() {
    _browseClient.invalidateAll();
  }

  /// Clears all search results (e.g. after catalogue update).
  void invalidateSearch() {
    _searchClient.invalidateAll();
  }
}
