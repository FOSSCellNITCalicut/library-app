import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:library_nitc/models/book_details.dart' show BookAvailability, BookDetail;

const String kBaseUrl = 'http://localhost:8000';

class BookService {
  final String baseUrl;
  BookService({this.baseUrl = kBaseUrl});

  Future<http.Response> fetchBrowse(int page, int perPage) async {
    final uri = Uri.parse('$baseUrl/api/v1/books/browse').replace(
      queryParameters: {'page': '$page', 'per_page': '$perPage'},
    );
    final response = await http.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
    return response;
  }

  Future<http.Response> fetchSearch(String query, int page, int perPage, {List<String>? categories}) async {
    final queryParams = <String, String>{
      'q': query,
      'page': '$page',
      'per_page': '$perPage',
    };
    final uri = Uri.parse('$baseUrl/api/v1/books/search').replace(
      queryParameters: queryParams,
    );
    // Add category parameters manually since Uri doesn't support multiple values for same key
    if (categories != null && categories.isNotEmpty) {
      final categoryParams = categories.map((cat) => 'category=${Uri.encodeComponent(cat)}').join('&');
      final finalUri = Uri.parse('$uri&$categoryParams');
      final response = await http.get(finalUri);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
      return response;
    }
    final response = await http.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
    return response;
  }


  //BOOKDETAIL??

   Future<BookDetail> getBookDetail(int biblioId) async {
    final uri = Uri.parse('$baseUrl/api/v1/books/$biblioId');

    final res = await http.get(uri);

    if (res.statusCode == 200) {
      return BookDetail.fromJson(jsonDecode(res.body));
    } else {
      throw Exception('Detail failed: ${res.body}');
    }
  }

  Future<BookAvailability> checkAvailability(int biblioId) async {
    final uri = Uri.parse('$baseUrl/api/v1/books/$biblioId/availability');
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      return BookAvailability.fromJson(jsonDecode(res.body));
    } else {
      throw Exception('Availability check failed: ${res.body}');
    }
  }
}
