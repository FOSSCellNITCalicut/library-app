import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:library_nitc/cache/cache_policy.dart';
import 'package:library_nitc/cache/cache_store.dart';
import 'package:library_nitc/cache/cached_http_client.dart';
import 'package:library_nitc/globals.dart' show appCacheStore, kBackendBaseUrl;

const String kBaseUrl = kBackendBaseUrl;

class CurriculumService {
  final String baseUrl;
  late final CachedHttpClient _versionClient;
  late final CachedHttpClient _curriculumClient;

  CurriculumService({this.baseUrl = kBaseUrl, http.Client? httpClient, CacheStore? cacheStore}) {
    final store = cacheStore ?? appCacheStore;
    _versionClient = CachedHttpClient(
      namespace: 'curriculum_version',
      policy: CachePolicy.curriculumVersion,
      httpClient: httpClient,
      cacheStore: store,
    );
    _curriculumClient = CachedHttpClient(
      namespace: 'curriculum',
      policy: CachePolicy.curriculum,
      httpClient: httpClient,
      cacheStore: store,
    );
  }

  Future<String> fetchVersion() async {
    final uri = Uri.parse('$baseUrl/api/v1/curriculum/version');
    final response = await _versionClient.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch version: ${response.body}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['version'] as String;
  }

  Future<Map<String, dynamic>> fetchCurriculum() async {
    final uri = Uri.parse('$baseUrl/api/v1/curriculum');
    final response = await _curriculumClient.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch curriculum: ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
