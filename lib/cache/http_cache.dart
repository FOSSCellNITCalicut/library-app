import 'dart:collection';
import 'cache_observer.dart';
import 'cache_store.dart';

/// A single cached response entry.
class CacheEntry {
  final String body;
  final int statusCode;
  final DateTime cachedAt;
  final bool isError;

  /// Value of the ETag response header, if present.
  final String? etag;

  /// Value of the Last-Modified response header, if present.
  final String? lastModified;

  const CacheEntry({
    required this.body,
    required this.statusCode,
    required this.cachedAt,
    required this.isError,
    this.etag,
    this.lastModified,
  });
}

/// In-memory HTTP response cache with TTL and optional LRU eviction.
///
/// This is a singleton — all service files share one cache store.
/// Keys are full URL strings (including query parameters).
///
/// Set [enabled] to false during development to bypass all caching
/// without touching any policy or service code.
class HttpCache implements CacheStore {
  HttpCache._();
  static final HttpCache instance = HttpCache._();

  /// Dev-mode kill switch. Set to false to disable all caching.
  /// Defaults to true in release mode and can be toggled in debug mode.
  bool enabled = true;

  // Store per-policy namespace using a map of maps.
  // Each [_PolicyStore] holds its own LRU map and maxEntries limit.
  final Map<String, _PolicyStore> _stores = {};

  /// Returns the cached entry for [key] under [namespace] if it exists and
  /// has not exceeded [ttl] or [failureTtl]. Returns null on miss or expiry.
  @override
  CacheEntry? get(
    String namespace,
    String key,
    Duration ttl,
    Duration failureTtl,
  ) {
    final store = _stores[namespace];
    if (store == null) return null;
    final entry = store.get(key);
    if (entry == null) return null;

    final age = DateTime.now().difference(entry.cachedAt);
    final maxAge = entry.isError ? failureTtl : ttl;
    if (age > maxAge) {
      return null;
    }
    return entry;
  }

  /// Returns the cached entry regardless of TTL (for stale-while-revalidate).
  @override
  CacheEntry? getStale(String namespace, String key) {
    return _stores[namespace]?.get(key);
  }

  /// Updates [cachedAt] to now without changing any other fields (304 path).
  @override
  Future<void> touch(String namespace, String key) {
    final store = _stores[namespace];
    final entry = store?.get(key);
    if (entry != null) {
      store!.put(
        key,
        CacheEntry(
          body: entry.body,
          statusCode: entry.statusCode,
          cachedAt: DateTime.now(),
          isError: entry.isError,
          etag: entry.etag,
          lastModified: entry.lastModified,
        ),
      );
    }
    return Future.value();
  }

  /// Stores [body] / [statusCode] for [key] under [namespace].
  /// [maxEntries] of -1 means unlimited (no LRU eviction).
  /// Optional [etag] and [lastModified] are stored for conditional requests.
  @override
  Future<void> put(
    String namespace,
    String key,
    String body,
    int statusCode, {
    bool isError = false,
    int maxEntries = -1,
    String? etag,
    String? lastModified,
  }) {
    _stores.putIfAbsent(namespace, () => _PolicyStore(maxEntries: maxEntries, namespace: namespace));
    _stores[namespace]!.put(
      key,
      CacheEntry(
        body: body,
        statusCode: statusCode,
        cachedAt: DateTime.now(),
        isError: isError,
        etag: etag,
        lastModified: lastModified,
      ),
    );
    return Future.value();
  }

  /// Removes a specific key (e.g. after a write/mutation).
  @override
  void invalidate(String namespace, String key) {
    _stores[namespace]?.remove(key);
  }

  /// Clears all entries in a namespace (e.g. after logout).
  @override
  void invalidateNamespace(String namespace) {
    _stores.remove(namespace);
  }

  /// Clears the entire cache (e.g. after logout).
  @override
  void clear() {
    _stores.clear();
  }
}

/// LRU-capable store backed by [LinkedHashMap].
/// When [maxEntries] > 0, the oldest entry is evicted on overflow.
class _PolicyStore {
  final int maxEntries;
  final String namespace;
  // LinkedHashMap preserves insertion order — we use it for LRU by moving
  // accessed entries to the end on get, then evicting from the front.
  final LinkedHashMap<String, CacheEntry> _map = LinkedHashMap();

  _PolicyStore({required this.maxEntries, required this.namespace});

  CacheEntry? get(String key) {
    final entry = _map.remove(key);
    if (entry == null) return null;
    // Re-insert at end to mark as most-recently used.
    _map[key] = entry;
    return entry;
  }

  void put(String key, CacheEntry entry) {
    // Remove existing entry first to update insertion order.
    _map.remove(key);
    _map[key] = entry;
    // Evict LRU entry if over capacity.
    if (maxEntries > 0 && _map.length > maxEntries) {
      _map.remove(_map.keys.first);
      CacheObserver.instance.recordEviction(namespace);
    }
  }

  void remove(String key) {
    _map.remove(key);
  }
}
