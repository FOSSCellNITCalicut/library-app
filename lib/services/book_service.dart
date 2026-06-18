import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:library_nitc/models/book_details.dart';

const String kBaseUrl = 'http://192.168.1.44:8000';

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
}
