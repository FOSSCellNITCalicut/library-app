import 'package:http/http.dart' as http;
import 'cache_policy.dart';
import 'http_cache.dart';

/// A drop-in replacement for `http.get` that applies a [CachePolicy].
///
/// Usage:
/// ```dart
/// final client = CachedHttpClient(namespace: 'books_browse', policy: CachePolicy.booksBrowse);
/// final response = await client.get(uri);
/// ```
///
/// - On cache HIT (fresh): returns cached response immediately.
/// - On cache HIT (stale) + [staleWhileRevalidate]: returns stale immediately,
///   then re-fetches in the background and updates the cache silently.
/// - On cache MISS: fetches from network, caches the result.
/// - On network error or non-2xx: caches with [failureTtl] so aggressive
///   retries don't hammer the backend, then rethrows to the caller.
class CachedHttpClient {
  final String namespace;
  final CachePolicy policy;
  final HttpCache _cache = HttpCache.instance;

  CachedHttpClient({required this.namespace, required this.policy});

  Future<http.Response> get(Uri uri, {Map<String, String>? headers}) async {
    final key = uri.toString();

    // ── Fresh cache HIT ──────────────────────────────────────────────────────
    final fresh = _cache.get(namespace, key, policy.ttl, policy.failureTtl);
    if (fresh != null && !fresh.isError) {
      return _syntheticResponse(fresh.statusCode, fresh.body);
    }

    // ── Stale-while-revalidate: return stale entry immediately, refresh async ─
    if (policy.staleWhileRevalidate) {
      final stale = _cache.getStale(namespace, key);
      if (stale != null && !stale.isError) {
        _fetchAndCache(uri, key, headers: headers).ignore();
        return _syntheticResponse(stale.statusCode, stale.body);
      }
    }

    // ── Cache MISS or expired: fetch from network ────────────────────────────
    return _fetchAndCache(uri, key, headers: headers);
  }

  Future<http.Response> _fetchAndCache(
    Uri uri,
    String key, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await http.get(uri, headers: headers);

      final isError = response.statusCode < 200 || response.statusCode >= 300;
      _cache.put(
        namespace,
        key,
        response.body,
        response.statusCode,
        isError: isError,
        maxEntries: policy.maxEntries,
      );

      if (isError) {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }

      return response;
    } catch (e) {
      final existing = _cache.get(namespace, key, policy.failureTtl, policy.failureTtl);
      if (existing == null) {
        _cache.put(
          namespace,
          key,
          e.toString(),
          0,
          isError: true,
          maxEntries: policy.maxEntries,
        );
      }
      rethrow;
    }
  }

  /// Builds a synthetic [http.Response] from cached data so callers get the
  /// same type they'd get from a real network call.
  http.Response _syntheticResponse(int statusCode, String body) {
    return http.Response(body, statusCode);
  }

  /// Removes a cached entry — use after mutations (e.g. renew, cancel hold).
  void invalidate(Uri uri) {
    _cache.invalidate(namespace, uri.toString());
  }

  /// Clears all entries in this client's namespace.
  void invalidateAll() {
    _cache.invalidateNamespace(namespace);
  }
}
