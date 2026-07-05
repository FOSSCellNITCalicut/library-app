import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

import 'cache_observer.dart';
import 'cache_store.dart';
// CacheEntry is re-exported from cache_store.dart via http_cache.dart.

/// Thrown when [SqliteCacheStore.open] fails to initialise the database.
class CacheStoreInitException implements Exception {
  final String message;
  final Object? cause;

  const CacheStoreInitException(this.message, {this.cause});

  @override
  String toString() =>
      'CacheStoreInitException: $message'
      '${cause != null ? ' (caused by: $cause)' : ''}';
}

// ---------------------------------------------------------------------------
// DDL constants
// ---------------------------------------------------------------------------

const _kCreateTable = '''
CREATE TABLE IF NOT EXISTS cache_entries (
  namespace        TEXT    NOT NULL,
  key              TEXT    NOT NULL,
  body             TEXT    NOT NULL,
  status_code      INTEGER NOT NULL,
  cached_at_ms     INTEGER NOT NULL,
  is_error         INTEGER NOT NULL DEFAULT 0,
  etag             TEXT,
  last_modified    TEXT,
  last_accessed_ms INTEGER NOT NULL,
  PRIMARY KEY (namespace, key)
)
''';

const _kCreateIndex = '''
CREATE INDEX IF NOT EXISTS idx_cache_namespace_accessed
  ON cache_entries (namespace, last_accessed_ms)
''';

// ---------------------------------------------------------------------------
// SqliteCacheStore
// ---------------------------------------------------------------------------

/// A [CacheStore] backed by SQLite (via `sqflite`).
///
/// Maintains an in-memory index ([_index]) that is populated at [open] time
/// so that [get] and [getStale] can remain synchronous — required by the
/// [SynchronousFuture] fast-path in [CachedHttpClient].
///
/// All mutating operations ([put], [touch], [invalidate], etc.) update both
/// the in-memory index and the underlying database.
class SqliteCacheStore implements CacheStore {
  final Database _db;
  final DateTime _openedAt;

  /// Within this window after [open], any stale SQLite entry triggers a
  /// background revalidation regardless of the policy's
  /// `staleWhileRevalidate` flag.
  static const Duration coldStartWindow = Duration(seconds: 30);

  // namespace → key → CacheEntry
  final Map<String, Map<String, CacheEntry>> _index = {};

  SqliteCacheStore._(this._db) : _openedAt = DateTime.now();

  // -------------------------------------------------------------------------
  // Factory
  // -------------------------------------------------------------------------

  /// Opens (or creates / migrates) the SQLite database and returns a fully
  /// initialised [SqliteCacheStore].
  ///
  /// Throws [CacheStoreInitException] on any failure so callers can fall back
  /// to the in-memory [HttpCache].
  static Future<SqliteCacheStore> open() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final path = join(dir.path, 'http_cache.db');

      final db = await openDatabase(
        path,
        version: 2,
        onCreate: (db, version) async {
          await db.execute(_kCreateTable);
          await db.execute(_kCreateIndex);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute(
              'ALTER TABLE cache_entries ADD COLUMN etag TEXT',
            );
            await db.execute(
              'ALTER TABLE cache_entries ADD COLUMN last_modified TEXT',
            );
            await db.execute(
              'ALTER TABLE cache_entries ADD COLUMN '
              'last_accessed_ms INTEGER NOT NULL DEFAULT 0',
            );
          }
        },
      );

      final store = SqliteCacheStore._(db);
      await store._loadIndex();
      return store;
    } catch (e) {
      throw CacheStoreInitException(
        'Failed to open cache database',
        cause: e,
      );
    }
  }

  /// Opens a [SqliteCacheStore] backed by an already-opened [Database].
  ///
  /// Intended for use in tests that supply an in-memory FFI database directly,
  /// avoiding the [path_provider] dependency.
  @visibleForTesting
  static Future<SqliteCacheStore> openWithDatabase(Database db) async {
    final store = SqliteCacheStore._(db);
    await store._loadIndex();
    return store;
  }

  // -------------------------------------------------------------------------
  // Internal helpers
  // -------------------------------------------------------------------------

  /// Loads all rows from the database into [_index].
  Future<void> _loadIndex() async {
    final rows = await _db.rawQuery('SELECT * FROM cache_entries');
    for (final row in rows) {
      final namespace = row['namespace'] as String;
      final key = row['key'] as String;
      _index.putIfAbsent(namespace, () => {})[key] = _rowToEntry(row);
    }
  }

  /// Converts a database row map to a [CacheEntry].
  CacheEntry _rowToEntry(Map<String, Object?> row) {
    return CacheEntry(
      body: row['body'] as String,
      statusCode: row['status_code'] as int,
      cachedAt: DateTime.fromMillisecondsSinceEpoch(row['cached_at_ms'] as int),
      isError: (row['is_error'] as int) != 0,
      etag: row['etag'] as String?,
      lastModified: row['last_modified'] as String?,
    );
  }

  // -------------------------------------------------------------------------
  // CacheStore interface
  // -------------------------------------------------------------------------

  /// Returns a fresh (within TTL) [CacheEntry] from the in-memory index, or
  /// null on miss / expiry.
  ///
  /// TTL check is performed synchronously from the index; a fire-and-forget
  /// background update of [last_accessed_ms] is issued to the DB.
  @override
  CacheEntry? get(
    String namespace,
    String key,
    Duration ttl,
    Duration failureTtl,
  ) {
    final entry = _index[namespace]?[key];
    if (entry == null) return null;

    final age = DateTime.now().difference(entry.cachedAt);
    final maxAge = entry.isError ? failureTtl : ttl;
    if (age > maxAge) return null;

    // Fire-and-forget: update last_accessed_ms in the background.
    _db.rawUpdate(
      'UPDATE cache_entries SET last_accessed_ms = ? '
      'WHERE namespace = ? AND key = ?',
      [DateTime.now().millisecondsSinceEpoch, namespace, key],
    );
    return entry;
  }

  /// Returns the entry from the in-memory index regardless of TTL.
  @override
  CacheEntry? getStale(String namespace, String key) {
    return _index[namespace]?[key];
  }

  /// Persists [body] / [statusCode] for [key] under [namespace].
  ///
  /// After inserting, evicts the least-recently-used entries if [maxEntries]
  /// would be exceeded.
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
  }) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    final entry = CacheEntry(
      body: body,
      statusCode: statusCode,
      cachedAt: DateTime.fromMillisecondsSinceEpoch(nowMs),
      isError: isError,
      etag: etag,
      lastModified: lastModified,
    );

    // Update in-memory index first.
    _index.putIfAbsent(namespace, () => {})[key] = entry;

    // Persist to database.
    await _db.rawInsert(
      '''
      INSERT OR REPLACE INTO cache_entries
        (namespace, key, body, status_code, cached_at_ms, is_error,
         etag, last_modified, last_accessed_ms)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        namespace,
        key,
        body,
        statusCode,
        nowMs,
        isError ? 1 : 0,
        etag,
        lastModified,
        nowMs,
      ],
    );

    // LRU eviction: remove excess entries when maxEntries is set.
    if (maxEntries > 0) {
      await _evictLruIfNeeded(namespace, maxEntries);
    }
  }

  /// Evicts LRU entries from both the DB and the in-memory index until the
  /// entry count for [namespace] is within [maxEntries].
  Future<void> _evictLruIfNeeded(String namespace, int maxEntries) async {
    final countResult = await _db.rawQuery(
      'SELECT COUNT(*) AS cnt FROM cache_entries WHERE namespace = ?',
      [namespace],
    );
    final count = Sqflite.firstIntValue(countResult) ?? 0;
    if (count <= maxEntries) return;

    final toDelete = count - maxEntries;

    // Fetch the keys of the LRU entries before deleting so we can remove them
    // from the in-memory index as well.
    final lruRows = await _db.rawQuery(
      '''
      SELECT key FROM cache_entries
      WHERE namespace = ?
      ORDER BY last_accessed_ms ASC
      LIMIT ?
      ''',
      [namespace, toDelete],
    );

    for (final row in lruRows) {
      final evictedKey = row['key'] as String;
      await _db.rawDelete(
        'DELETE FROM cache_entries WHERE namespace = ? AND key = ?',
        [namespace, evictedKey],
      );
      _index[namespace]?.remove(evictedKey);
      CacheObserver.instance.recordEviction(namespace);
    }
  }

  /// Updates [cachedAt] to now for the named entry (304 response path).
  @override
  Future<void> touch(String namespace, String key) async {
    final existing = _index[namespace]?[key];
    if (existing == null) return;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final updated = CacheEntry(
      body: existing.body,
      statusCode: existing.statusCode,
      cachedAt: DateTime.fromMillisecondsSinceEpoch(nowMs),
      isError: existing.isError,
      etag: existing.etag,
      lastModified: existing.lastModified,
    );

    // Update in-memory index.
    _index[namespace]![key] = updated;

    // Update database.
    await _db.rawUpdate(
      'UPDATE cache_entries SET cached_at_ms = ?, last_accessed_ms = ? '
      'WHERE namespace = ? AND key = ?',
      [nowMs, nowMs, namespace, key],
    );
  }

  /// Removes a single entry (fire-and-forget DB delete, synchronous index update).
  @override
  void invalidate(String namespace, String key) {
    _index[namespace]?.remove(key);
    _db.rawDelete(
      'DELETE FROM cache_entries WHERE namespace = ? AND key = ?',
      [namespace, key],
    );
  }

  /// Clears all entries for [namespace] (fire-and-forget DB delete).
  @override
  void invalidateNamespace(String namespace) {
    _index.remove(namespace);
    _db.rawDelete(
      'DELETE FROM cache_entries WHERE namespace = ?',
      [namespace],
    );
  }

  /// Clears the entire cache (fire-and-forget DB delete).
  @override
  void clear() {
    _index.clear();
    _db.rawDelete('DELETE FROM cache_entries');
  }

  // -------------------------------------------------------------------------
  // Cold-start helper
  // -------------------------------------------------------------------------

  /// True while the store is within [coldStartWindow] of [open] being called.
  bool get isInColdStartWindow =>
      DateTime.now().difference(_openedAt) < coldStartWindow;
}
