import 'dart:io' show SocketException;
import 'dart:async' show TimeoutException;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'cache_observer.dart';
import 'cache_policy.dart';
import 'cache_store.dart';
import 'http_cache.dart';

/// A drop-in replacement for `http.get` that applies a [CachePolicy].
///
/// - On cache HIT (fresh): returns cached response immediately.
/// - On cache HIT (stale) + [staleWhileRevalidate]: returns stale immediately,
///   then re-fetches in the background and logs any failure.
/// - On cache MISS: fetches from network, caches the result.
/// - On network error or non-2xx: caches with [failureTtl] then rethrows.
/// - Concurrent identical requests are deduplicated: only one network call
///   is in-flight at a time per URL.
class CachedHttpClient {
  final String namespace;
  final CachePolicy policy;
  late final CacheStore _cache;
  final http.Client _httpClient;
  final Future<bool> Function()? _connectivityChecker;

  // Request deduplication: maps URL key → in-flight Future.
  final Map<String, Future<http.Response>> _inflight = {};

  // Per-namespace operation counter for periodic metrics logging.
  final Map<String, int> _opCount = {};

  CachedHttpClient({
    required this.namespace,
    required this.policy,
    http.Client? httpClient,
    CacheStore? cacheStore,
    Future<bool> Function()? connectivityChecker,
  }) : _httpClient = httpClient ?? http.Client(),
       _connectivityChecker = connectivityChecker {
    _cache = cacheStore ?? HttpCache.instance;
  }

  /// Returns true when the device appears to be online.
  /// Defaults to optimistic (true) when no checker is provided.
  // ignore: unused_element
  Future<bool> _isConnected() async {
    if (_connectivityChecker != null) return _connectivityChecker();
    return true;
  }

  /// Returns true if [r] is the synthetic offline response produced when
  /// a network request fails with no connectivity and no stale entry.
  static bool isOfflineFallback(http.Response r) =>
      r.statusCode == 503 && r.body == 'offline';

  Future<http.Response> get(Uri uri, {Map<String, String>? headers}) {
    // Dev-mode bypass: skip all caching when disabled.
    if (!HttpCache.instance.enabled) {
      debugPrint('[CACHE OFF  ] $namespace | $uri');
      return _rawFetch(uri, headers: headers);
    }

    // Per-namespace operation counter; log metrics every 100th call.
    final opCount = (_opCount[namespace] ?? 0) + 1;
    _opCount[namespace] = opCount;
    if (opCount % 100 == 0 && kDebugMode) {
      final m = CacheObserver.instance.metrics(namespace);
      final total = m.hits + m.misses;
      final hitRate = total == 0 ? 0.0 : m.hits / total * 100;
      debugPrint(
        '[CACHE METRICS] $namespace | hits=${m.hits} misses=${m.misses} '
        'hitRate=${hitRate.toStringAsFixed(1)}%',
      );
    }

    final key = uri.toString();

    // ── Fresh cache HIT ──────────────────────────────────────────────────────
    final fresh = _cache.get(namespace, key, policy.ttl, policy.failureTtl);
    if (fresh != null) {
      if (fresh.isError) {
        debugPrint('[CACHE HIT  ] $namespace | $key (cached failure)');
        CacheObserver.instance.recordHit(namespace);
        return Future<http.Response>.error(
          Exception(_cachedFailureMessage(fresh.statusCode, fresh.body)),
        );
      }

      debugPrint('[CACHE HIT  ] $namespace | $key');
      CacheObserver.instance.recordHit(namespace);
      return SynchronousFuture(
        _syntheticResponse(fresh.statusCode, fresh.body),
      );
    }

    // ── Stale-while-revalidate ───────────────────────────────────────────────
    if (policy.staleWhileRevalidate) {
      final stale = _cache.getStale(namespace, key);
      if (stale != null && !stale.isError) {
        debugPrint(
          '[CACHE STALE] $namespace | $key (revalidating in background)',
        );
        // Background refresh with proper error logging — no more .ignore().
        _fetchAndCache(uri, key, headers: headers, staleEntry: stale).catchError((Object e) {
          debugPrint(
            '[CACHE SWR ERR] $namespace | $key background refresh failed: $e',
          );
          // Return a dummy response to satisfy the Future<http.Response> type.
          // The caller already has the stale value and won't see this.
          return http.Response('', 599);
        });
        CacheObserver.instance.recordHit(namespace);
        return SynchronousFuture(
          _syntheticResponse(stale.statusCode, stale.body),
        );
      }
    }

    // ── Cache MISS or expired: fetch from network (deduplicated) ─────────────
    // ── Cold-start stale: return stale immediately and refresh in background ──
    final coldStale = _cache.getStale(namespace, key);
    if (coldStale != null && !coldStale.isError) {
      debugPrint('[CACHE COLD ] $namespace | $key (cold-start stale, refreshing)');
      _fetchAndCache(uri, key, headers: headers, staleEntry: coldStale).catchError((Object e) {
        debugPrint('[CACHE COLD ERR] $namespace | $key background refresh failed: $e');
        return http.Response('', 599);
      });
      return SynchronousFuture(_syntheticResponse(coldStale.statusCode, coldStale.body));
    }

    debugPrint('[CACHE MISS ] $namespace | $key');
    CacheObserver.instance.recordMiss(namespace);
    return _deduplicated(uri, key, headers: headers);
  }

  /// Returns the in-flight future for [key] if one exists, otherwise starts
  /// a new fetch. Cleans up the in-flight map when the fetch completes.
  Future<http.Response> _deduplicated(
    Uri uri,
    String key, {
    Map<String, String>? headers,
  }) {
    if (_inflight.containsKey(key)) {
      debugPrint('[CACHE DEDUP] $namespace | $key (joining in-flight request)');
      return _inflight[key]!;
    }

    final stale = _cache.getStale(namespace, key);
    final future = _fetchAndCache(uri, key, headers: headers, staleEntry: stale).then(
      (response) {
        _inflight.remove(key);
        return response;
      },
      onError: (Object error, StackTrace stackTrace) {
        _inflight.remove(key);
        Error.throwWithStackTrace(error, stackTrace);
      },
    );

    _inflight[key] = future;
    return future;
  }

  Future<http.Response> _fetchAndCache(
    Uri uri,
    String key, {
    Map<String, String>? headers,
    CacheEntry? staleEntry,
  }) async {
    // Build conditional headers from stale entry
    final requestHeaders = <String, String>{...?headers};
    if (staleEntry?.etag != null) {
      requestHeaders['If-None-Match'] = staleEntry!.etag!;
    } else if (staleEntry?.lastModified != null) {
      requestHeaders['If-Modified-Since'] = staleEntry!.lastModified!;
    }

    try {
      final response = await _rawFetch(
        uri,
        headers: requestHeaders.isEmpty ? headers : requestHeaders,
      );

      // Handle 304 Not Modified — refresh cachedAt and return stale body.
      if (response.statusCode == 304 && staleEntry != null) {
        await _cache.touch(namespace, key);
        return _syntheticResponse(staleEntry.statusCode, staleEntry.body);
      }

      final isError = response.statusCode < 200 || response.statusCode >= 300;

      // Extract ETag and Last-Modified from response headers.
      final etag = response.headers['etag'];
      final lastModified = response.headers['last-modified'];

      await _cache.put(
        namespace,
        key,
        response.body,
        response.statusCode,
        isError: isError,
        maxEntries: policy.maxEntries,
        etag: etag,
        lastModified: lastModified,
      );

      if (isError) {
        debugPrint(
          '[CACHE ERROR] $namespace | $key (HTTP ${response.statusCode}, '
          'cached for ${policy.failureTtl.inSeconds}s)',
        );
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }

      return response;
    } catch (e) {
      // Offline / network-level failure: serve stale entry if available.
      if (e is SocketException || e is TimeoutException) {
        final stale = _cache.getStale(namespace, key);
        if (stale != null) {
          debugPrint('[CACHE OFFLINE] $namespace | $key returning stale entry');
          return _syntheticResponse(stale.statusCode, stale.body);
        }
        debugPrint('[CACHE OFFLINE] $namespace | $key no stale entry — returning 503');
        return http.Response('offline', 503);
      }
      // Cache failures with a short TTL to absorb aggressive retries,
      // but only if there isn't already a fresh failure entry.
      final existing = _cache.get(
        namespace,
        key,
        policy.failureTtl,
        policy.failureTtl,
      );
      if (existing == null) {
        debugPrint(
          '[CACHE ERROR] $namespace | $key (network failure, '
          'cached for ${policy.failureTtl.inSeconds}s): $e',
        );
        await _cache.put(
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

  /// Raw HTTP GET with no caching — uses the injected [http.Client].
  Future<http.Response> _rawFetch(Uri uri, {Map<String, String>? headers}) {
    return _httpClient.get(uri, headers: headers);
  }

  /// Builds a synthetic [http.Response] from cached data.
  http.Response _syntheticResponse(int statusCode, String body) {
    return http.Response(body, statusCode);
  }

  String _cachedFailureMessage(int statusCode, String body) {
    if (statusCode == 0) {
      return body;
    }
    return 'HTTP $statusCode: $body';
  }

  /// Removes a cached entry — call after write mutations.
  void invalidate(Uri uri) {
    _cache.invalidate(namespace, uri.toString());
  }

  /// Clears all entries in this client's namespace.
  void invalidateAll() {
    _cache.invalidateNamespace(namespace);
  }
}
