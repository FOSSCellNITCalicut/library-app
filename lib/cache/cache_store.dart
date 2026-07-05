// Re-export CacheEntry so callers only need to import cache_store.dart.
export 'http_cache.dart' show CacheEntry;

import 'http_cache.dart';

/// Abstract interface for HTTP response cache storage.
///
/// Implementations include [HttpCache] (in-memory) and
/// [SqliteCacheStore] (persistent, SQLite-backed).
abstract class CacheStore {
  /// Returns a fresh entry (within TTL) or null on miss / expiry.
  CacheEntry? get(
    String namespace,
    String key,
    Duration ttl,
    Duration failureTtl,
  );

  /// Persists the response. Returns a Future so SQLite can be async;
  /// [HttpCache] resolves the future synchronously via [Future.value].
  Future<void> put(
    String namespace,
    String key,
    String body,
    int statusCode, {
    bool isError = false,
    int maxEntries = -1,
    String? etag,
    String? lastModified,
  });

  /// Returns an entry regardless of TTL (stale-while-revalidate / offline).
  CacheEntry? getStale(String namespace, String key);

  /// Updates [cachedAt] to now without changing the body (304 response path).
  Future<void> touch(String namespace, String key);

  /// Removes one entry (post-mutation invalidation).
  void invalidate(String namespace, String key);

  /// Clears all entries in a namespace (e.g. after logout).
  void invalidateNamespace(String namespace);

  /// Clears the entire store.
  void clear();
}
