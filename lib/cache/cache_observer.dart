// Per-namespace hit/miss/eviction telemetry for the cache layer.

/// Immutable snapshot of cache metrics for a single namespace.
class CacheMetrics {
  final int hits;
  final int misses;
  final int evictions;

  const CacheMetrics({this.hits = 0, this.misses = 0, this.evictions = 0});

  /// Hit rate in [0.0, 1.0]. Returns 0.0 when no requests have been made.
  double get hitRate =>
      (hits + misses) == 0 ? 0.0 : hits / (hits + misses);

  CacheMetrics copyWith({int? hits, int? misses, int? evictions}) =>
      CacheMetrics(
        hits: hits ?? this.hits,
        misses: misses ?? this.misses,
        evictions: evictions ?? this.evictions,
      );
}

/// Mutable internal accumulator — not exposed outside this file.
class _MutableMetrics {
  int hits = 0;
  int misses = 0;
  int evictions = 0;
}

/// Singleton that records hit/miss/eviction events per cache namespace.
///
/// Usage:
/// ```dart
/// CacheObserver.instance.recordHit('books');
/// final metrics = CacheObserver.instance.metrics('books');
/// print(metrics.hitRate);
/// ```
class CacheObserver {
  CacheObserver._();
  static final CacheObserver instance = CacheObserver._();

  final Map<String, _MutableMetrics> _data = {};

  /// Records a cache hit for [namespace].
  void recordHit(String namespace) {
    _data.putIfAbsent(namespace, () => _MutableMetrics()).hits++;
  }

  /// Records a cache miss for [namespace].
  void recordMiss(String namespace) {
    _data.putIfAbsent(namespace, () => _MutableMetrics()).misses++;
  }

  /// Records an eviction for [namespace].
  void recordEviction(String namespace) {
    _data.putIfAbsent(namespace, () => _MutableMetrics()).evictions++;
  }

  /// Returns an immutable [CacheMetrics] snapshot for [namespace].
  /// Returns a zeroed instance if [namespace] has no recorded events.
  CacheMetrics metrics(String namespace) {
    final m = _data[namespace];
    if (m == null) return const CacheMetrics();
    return CacheMetrics(hits: m.hits, misses: m.misses, evictions: m.evictions);
  }

  /// Returns an unmodifiable map of snapshots for all tracked namespaces.
  Map<String, CacheMetrics> allMetrics() {
    return Map.unmodifiable(
      _data.map(
        (k, v) => MapEntry(
          k,
          CacheMetrics(hits: v.hits, misses: v.misses, evictions: v.evictions),
        ),
      ),
    );
  }

  /// Resets counters for [namespace], removing it from the tracking map.
  /// Does not affect other namespaces.
  void reset(String namespace) {
    _data.remove(namespace);
  }
}
