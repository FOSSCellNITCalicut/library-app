import 'dart:convert';
import 'package:http/http.dart' as http;

const String kBaseUrl = 'http://localhost:8000';

class CurriculumService {
  final String baseUrl;
  CurriculumService({this.baseUrl = kBaseUrl});

  Future<String> fetchVersion() async {
    final uri = Uri.parse('$baseUrl/api/v1/curriculum/version');
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch version: ${response.body}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['version'] as String;
  }

  Future<Map<String, dynamic>> fetchCurriculum() async {
    final uri = Uri.parse('$baseUrl/api/v1/curriculum');
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch curriculum: ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
