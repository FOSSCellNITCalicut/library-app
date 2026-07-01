import 'dart:collection';

/// A single cached response entry.
class _CacheEntry {
  final String body;
  final int statusCode;
  final DateTime cachedAt;
  final bool isError;

  const _CacheEntry({
    required this.body,
    required this.statusCode,
    required this.cachedAt,
    required this.isError,
  });
}

/// In-memory HTTP response cache with TTL and optional LRU eviction.
///
/// This is a singleton — all service files share one cache store.
/// Keys are full URL strings (including query parameters).
class HttpCache {
  HttpCache._();
  static final HttpCache instance = HttpCache._();

  // Store per-policy namespace using a map of maps.
  // Each [_PolicyStore] holds its own LRU map and maxEntries limit.
  final Map<String, _PolicyStore> _stores = {};

  /// Returns the cached entry for [key] under [namespace] if it exists and
  /// has not exceeded [ttl] or [failureTtl]. Returns null on miss or expiry.
  _CacheEntry? get(String namespace, String key, Duration ttl, Duration failureTtl) {
    final store = _stores[namespace];
    if (store == null) return null;
    final entry = store.get(key);
    if (entry == null) return null;

    final age = DateTime.now().difference(entry.cachedAt);
    final maxAge = entry.isError ? failureTtl : ttl;
    if (age > maxAge) {
      store.remove(key);
      return null;
    }
    return entry;
  }

  /// Returns the cached entry regardless of TTL (for stale-while-revalidate).
  _CacheEntry? getStale(String namespace, String key) {
    return _stores[namespace]?.get(key);
  }

  /// Stores [body] / [statusCode] for [key] under [namespace].
  /// [maxEntries] of -1 means unlimited (no LRU eviction).
  void put(
    String namespace,
    String key,
    String body,
    int statusCode, {
    bool isError = false,
    int maxEntries = -1,
  }) {
    _stores.putIfAbsent(namespace, () => _PolicyStore(maxEntries: maxEntries));
    _stores[namespace]!.put(
      key,
      _CacheEntry(
        body: body,
        statusCode: statusCode,
        cachedAt: DateTime.now(),
        isError: isError,
      ),
    );
  }

  /// Removes a specific key (e.g. after a write/mutation).
  void invalidate(String namespace, String key) {
    _stores[namespace]?.remove(key);
  }

  /// Clears all entries in a namespace (e.g. after logout).
  void invalidateNamespace(String namespace) {
    _stores.remove(namespace);
  }

  /// Clears the entire cache (e.g. after logout).
  void clear() {
    _stores.clear();
  }
}

/// LRU-capable store backed by [LinkedHashMap].
/// When [maxEntries] > 0, the oldest entry is evicted on overflow.
class _PolicyStore {
  final int maxEntries;
  // LinkedHashMap preserves insertion order — we use it for LRU by moving
  // accessed entries to the end on get, then evicting from the front.
  final LinkedHashMap<String, _CacheEntry> _map = LinkedHashMap();

  _PolicyStore({required this.maxEntries});

  _CacheEntry? get(String key) {
    final entry = _map.remove(key);
    if (entry == null) return null;
    // Re-insert at end to mark as most-recently used.
    _map[key] = entry;
    return entry;
  }

  void put(String key, _CacheEntry entry) {
    // Remove existing entry first to update insertion order.
    _map.remove(key);
    _map[key] = entry;
    // Evict LRU entry if over capacity.
    if (maxEntries > 0 && _map.length > maxEntries) {
      _map.remove(_map.keys.first);
    }
  }

  void remove(String key) {
    _map.remove(key);
  }
}
