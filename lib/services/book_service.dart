import 'package:http/http.dart' as http;

const String kBaseUrl = 'http://10.0.2.2:8000';

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

  Future<http.Response> fetchSearch(String query, int page, int perPage) async {
    final uri = Uri.parse('$baseUrl/api/v1/books/search').replace(
      queryParameters: {'q': query, 'page': '$page', 'per_page': '$perPage'},
    );
    final response = await http.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
    return response;
  }
}
