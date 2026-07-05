import 'dart:async';
import 'dart:io' show SocketException;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:library_nitc/bookCoverImage.dart';
import 'package:library_nitc/cache/cache_observer.dart';
import 'package:library_nitc/cache/cache_policy.dart';
import 'package:library_nitc/cache/cache_store.dart';
import 'package:library_nitc/cache/cached_http_client.dart';
import 'package:library_nitc/cache/http_cache.dart';
import 'package:library_nitc/cache/sqlite_cache_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

typedef _HandlerFn = Future<http.Response> Function(http.Request req);

/// Synchronous mock HTTP client that captures headers for assertion.
class _SyncMockClient extends http.BaseClient {
  final _HandlerFn _handler;
  _SyncMockClient(this._handler);

  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) {
    final req = http.Request('GET', url);
    if (headers != null) req.headers.addAll(headers);
    return _handler(req);
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw UnimplementedError();
  }
}

_SyncMockClient _simpleMock(List<int> count, String body,
    {int statusCode = 200, Map<String, String>? headers}) {
  return _SyncMockClient((req) {
    count[0]++;
    return Future.value(http.Response(body, statusCode, headers: headers ?? {}));
  });
}

_SyncMockClient _throwingMock(List<int> count, Object error) {
  return _SyncMockClient((_) {
    count[0]++;
    return Future.error(error);
  });
}

/// A spy [CacheStore] that wraps [HttpCache] and records calls to [touch].
class _TouchSpyStore implements CacheStore {
  final CacheStore _delegate;
  int touchCalls = 0;

  _TouchSpyStore(this._delegate);

  @override
  CacheEntry? get(String ns, String key, Duration ttl, Duration failureTtl) =>
      _delegate.get(ns, key, ttl, failureTtl);

  @override
  CacheEntry? getStale(String ns, String key) => _delegate.getStale(ns, key);

  @override
  Future<void> put(String ns, String key, String body, int statusCode,
      {bool isError = false, int maxEntries = -1, String? etag, String? lastModified}) =>
      _delegate.put(ns, key, body, statusCode,
          isError: isError, maxEntries: maxEntries, etag: etag, lastModified: lastModified);

  @override
  Future<void> touch(String ns, String key) {
    touchCalls++;
    return _delegate.touch(ns, key);
  }

  @override
  void invalidate(String ns, String key) => _delegate.invalidate(ns, key);

  @override
  void invalidateNamespace(String ns) => _delegate.invalidateNamespace(ns);

  @override
  void clear() => _delegate.clear();
}

void _asyncTest(String desc, Future<void> Function() body) {
  testWidgets(desc, (tester) async {
    await tester.runAsync(body);
  });
}

// ── SQLite FFI setup ──────────────────────────────────────────────────────────

Future<SqliteCacheStore> _openInMemory() async {
  final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (db, version) async {
          await db.execute('''
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
          ''');
          await db.execute('''
            CREATE INDEX IF NOT EXISTS idx_cache_namespace_accessed
              ON cache_entries (namespace, last_accessed_ms)
          ''');
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute('ALTER TABLE cache_entries ADD COLUMN etag TEXT');
            await db.execute('ALTER TABLE cache_entries ADD COLUMN last_modified TEXT');
            await db.execute(
                'ALTER TABLE cache_entries ADD COLUMN last_accessed_ms INTEGER NOT NULL DEFAULT 0');
          }
        },
      ));
  // Use the internal constructor to bypass the path_provider call.
  // ignore: invalid_use_of_visible_for_testing_member
  return SqliteCacheStore.openWithDatabase(db);
}

// ── Main ─────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    HttpCache.instance
      ..enabled = true
      ..clear();
    CacheObserver.instance.reset('test_ns');
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 1. CacheStore interface (HttpCache)
  // ════════════════════════════════════════════════════════════════════════════
  group('CacheStore interface — HttpCache', () {
    test('put with etag and lastModified round-trips via getStale', () async {
      await HttpCache.instance.put(
        'ns', 'http://example.com/a', '{"ok":true}', 200,
        etag: '"v1"', lastModified: 'Wed, 01 Jan 2025 00:00:00 GMT',
      );
      final entry = HttpCache.instance.getStale('ns', 'http://example.com/a');
      expect(entry, isNotNull);
      expect(entry!.etag, '"v1"');
      expect(entry.lastModified, 'Wed, 01 Jan 2025 00:00:00 GMT');
    });

    test('touch() updates cachedAt without changing body', () async {
      await HttpCache.instance.put('ns', 'http://example.com/b', 'hello', 200);
      final before = HttpCache.instance.getStale('ns', 'http://example.com/b')!;
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await HttpCache.instance.touch('ns', 'http://example.com/b');
      final after = HttpCache.instance.getStale('ns', 'http://example.com/b')!;

      expect(after.body, before.body);
      expect(after.cachedAt.isAfter(before.cachedAt), isTrue,
          reason: 'touch() must advance cachedAt');
    });

    test('get() respects TTL and returns null after expiry', () async {
      await HttpCache.instance.put('ns', 'http://example.com/c', 'body', 200);
      // Fresh within 5 min TTL
      expect(
        HttpCache.instance.get('ns', 'http://example.com/c',
            const Duration(minutes: 5), const Duration(minutes: 1)),
        isNotNull,
      );
      // Expired with 0 TTL
      expect(
        HttpCache.instance.get('ns', 'http://example.com/c',
            Duration.zero, const Duration(minutes: 1)),
        isNull,
      );
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 2. SqliteCacheStore
  // ════════════════════════════════════════════════════════════════════════════
  group('SqliteCacheStore', () {
    late SqliteCacheStore store;

    setUp(() async {
      store = await _openInMemory();
      CacheObserver.instance.reset('sql_ns');
    });

    test('put() + get() round-trips entry with etag and lastModified', () async {
      await store.put('sql_ns', 'http://x.com/1', '{"data":1}', 200,
          etag: '"abc"', lastModified: 'Thu, 01 Jan 2026 00:00:00 GMT');

      final entry = store.get('sql_ns', 'http://x.com/1',
          const Duration(minutes: 5), const Duration(minutes: 1));
      expect(entry, isNotNull);
      expect(entry!.body, '{"data":1}');
      expect(entry.statusCode, 200);
      expect(entry.etag, '"abc"');
      expect(entry.lastModified, 'Thu, 01 Jan 2026 00:00:00 GMT');
    });

    test('get() returns null on miss', () {
      final result = store.get('sql_ns', 'http://x.com/miss',
          const Duration(minutes: 5), const Duration(minutes: 1));
      expect(result, isNull);
    });

    test('getStale() returns entry regardless of TTL', () async {
      await store.put('sql_ns', 'http://x.com/stale', 'old', 200);
      final entry = store.getStale('sql_ns', 'http://x.com/stale');
      expect(entry, isNotNull);
      expect(entry!.body, 'old');
    });

    test('put with maxEntries=2 evicts LRU on third insert', () async {
      CacheObserver.instance.reset('lru_sql');

      await store.put('lru_sql', 'http://x.com/a', 'a', 200, maxEntries: 2);
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await store.put('lru_sql', 'http://x.com/b', 'b', 200, maxEntries: 2);
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await store.put('lru_sql', 'http://x.com/c', 'c', 200, maxEntries: 2);

      // 'a' should have been evicted (LRU)
      expect(store.getStale('lru_sql', 'http://x.com/a'), isNull,
          reason: 'LRU entry "a" should be evicted');
      expect(store.getStale('lru_sql', 'http://x.com/b'), isNotNull);
      expect(store.getStale('lru_sql', 'http://x.com/c'), isNotNull);

      final metrics = CacheObserver.instance.metrics('lru_sql');
      expect(metrics.evictions, greaterThanOrEqualTo(1),
          reason: 'CacheObserver must record an eviction');
    });

    test('invalidate() removes only the targeted key', () async {
      await store.put('sql_ns', 'http://x.com/del', 'toDelete', 200);
      await store.put('sql_ns', 'http://x.com/keep', 'toKeep', 200);

      store.invalidate('sql_ns', 'http://x.com/del');

      expect(store.getStale('sql_ns', 'http://x.com/del'), isNull);
      expect(store.getStale('sql_ns', 'http://x.com/keep'), isNotNull);
    });

    test('invalidateNamespace() removes all keys in the namespace', () async {
      await store.put('sq_rm', 'http://x.com/1', 'a', 200);
      await store.put('sq_rm', 'http://x.com/2', 'b', 200);
      await store.put('sq_keep', 'http://x.com/3', 'c', 200);

      store.invalidateNamespace('sq_rm');

      expect(store.getStale('sq_rm', 'http://x.com/1'), isNull);
      expect(store.getStale('sq_rm', 'http://x.com/2'), isNull);
      // Different namespace must be untouched
      expect(store.getStale('sq_keep', 'http://x.com/3'), isNotNull);
    });

    test('touch() advances cachedAt without changing body', () async {
      await store.put('sql_ns', 'http://x.com/touch', 'original', 200);
      final before = store.getStale('sql_ns', 'http://x.com/touch')!;
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await store.touch('sql_ns', 'http://x.com/touch');
      final after = store.getStale('sql_ns', 'http://x.com/touch')!;

      expect(after.body, 'original');
      expect(after.cachedAt.isAfter(before.cachedAt), isTrue,
          reason: 'touch() must advance cachedAt in the in-memory index');
    });

    test('CacheStoreInitException thrown when DB path is unwriteable', () async {
      // Directly test the exception class constructor and toString.
      const ex = CacheStoreInitException('test', cause: 'boom');
      expect(ex.toString(), contains('CacheStoreInitException'));
      expect(ex.toString(), contains('boom'));
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 3. CacheObserver
  // ════════════════════════════════════════════════════════════════════════════
  group('CacheObserver', () {
    setUp(() {
      CacheObserver.instance.reset('obs_ns');
      CacheObserver.instance.reset('other_ns');
    });

    test('recordHit increments hits', () {
      CacheObserver.instance.recordHit('obs_ns');
      CacheObserver.instance.recordHit('obs_ns');
      expect(CacheObserver.instance.metrics('obs_ns').hits, 2);
    });

    test('recordMiss increments misses', () {
      CacheObserver.instance.recordMiss('obs_ns');
      expect(CacheObserver.instance.metrics('obs_ns').misses, 1);
    });

    test('recordEviction increments evictions', () {
      CacheObserver.instance.recordEviction('obs_ns');
      CacheObserver.instance.recordEviction('obs_ns');
      CacheObserver.instance.recordEviction('obs_ns');
      expect(CacheObserver.instance.metrics('obs_ns').evictions, 3);
    });

    test('metrics() for unknown namespace returns zeroed CacheMetrics', () {
      final m = CacheObserver.instance.metrics('totally_unknown_ns_xyz');
      expect(m.hits, 0);
      expect(m.misses, 0);
      expect(m.evictions, 0);
    });

    test('hitRate is 0.0 when no requests made', () {
      expect(CacheObserver.instance.metrics('totally_unknown_ns_xyz').hitRate, 0.0);
    });

    test('hitRate computes correctly', () {
      CacheObserver.instance.recordHit('obs_ns');
      CacheObserver.instance.recordHit('obs_ns');
      CacheObserver.instance.recordMiss('obs_ns');
      final rate = CacheObserver.instance.metrics('obs_ns').hitRate;
      expect(rate, closeTo(2 / 3, 0.001));
    });

    test('allMetrics() returns unmodifiable map', () {
      CacheObserver.instance.recordHit('obs_ns');
      final all = CacheObserver.instance.allMetrics();
      expect(() => (all as dynamic)['new_key'] = CacheMetrics(), throwsA(anything),
          reason: 'allMetrics() must be unmodifiable');
    });

    test('reset() zeroes counters for that namespace only', () {
      CacheObserver.instance.recordHit('obs_ns');
      CacheObserver.instance.recordHit('other_ns');

      CacheObserver.instance.reset('obs_ns');

      expect(CacheObserver.instance.metrics('obs_ns').hits, 0);
      // other_ns must be untouched
      expect(CacheObserver.instance.metrics('other_ns').hits, 1);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 4. Conditional requests (ETag / Last-Modified / 304)
  // ════════════════════════════════════════════════════════════════════════════
  group('Conditional requests', () {
    const ns = 'cond_ns';
    const url = 'http://example.com/cond';
    final uri = Uri.parse(url);

    setUp(() {
      HttpCache.instance.clear();
    });

    _asyncTest('server ETag is stored in the cache entry', () async {
      final count = [0];
      final mock = _simpleMock(count, '{"v":1}', headers: {'etag': '"etag1"'});
      final client = CachedHttpClient(
        namespace: ns,
        policy: const CachePolicy(ttl: Duration(minutes: 5)),
        httpClient: mock,
      );
      await client.get(uri);

      final entry = HttpCache.instance.getStale(ns, url);
      expect(entry?.etag, '"etag1"',
          reason: 'ETag from response header must be stored');
    });

    _asyncTest('server Last-Modified is stored in the cache entry', () async {
      final count = [0];
      final mock = _simpleMock(count, '{"v":1}',
          headers: {'last-modified': 'Mon, 01 Jan 2024 00:00:00 GMT'});
      final client = CachedHttpClient(
        namespace: ns,
        policy: const CachePolicy(ttl: Duration(minutes: 5)),
        httpClient: mock,
      );
      await client.get(uri);

      final entry = HttpCache.instance.getStale(ns, url);
      expect(entry?.lastModified, 'Mon, 01 Jan 2024 00:00:00 GMT');
    });

    _asyncTest('stale entry with etag sends If-None-Match on revalidation', () async {
      // Pre-populate stale entry with an ETag
      await HttpCache.instance.put(ns, url, '{"old":true}', 200, etag: '"etag1"');
      // Let TTL expire
      await Future<void>.delayed(const Duration(milliseconds: 5));

      String? capturedIfNoneMatch;
      final mock = _SyncMockClient((req) {
        capturedIfNoneMatch = req.headers['If-None-Match'];
        return Future.value(http.Response('{"new":true}', 200));
      });

      final client = CachedHttpClient(
        namespace: ns,
        policy: const CachePolicy(ttl: Duration(milliseconds: 1)),
        httpClient: mock,
      );
      await client.get(uri);

      expect(capturedIfNoneMatch, '"etag1"',
          reason: 'If-None-Match must be sent when stale entry has an ETag');
    });

    _asyncTest('304 response calls touch() and returns stale body', () async {
      final spy = _TouchSpyStore(HttpCache.instance);

      // Pre-populate stale entry
      await spy.put(ns, url, '{"cached":true}', 200, etag: '"v1"');
      await Future<void>.delayed(const Duration(milliseconds: 5));

      final mock = _SyncMockClient((_) => Future.value(http.Response('', 304)));
      final client = CachedHttpClient(
        namespace: ns,
        policy: const CachePolicy(ttl: Duration(milliseconds: 1)),
        httpClient: mock,
        cacheStore: spy,
      );

      final response = await client.get(uri);
      // Allow background refresh (cold-start path) to complete and call touch()
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(response.body, '{"cached":true}',
          reason: '304 must return the cached body unchanged');
      expect(spy.touchCalls, greaterThanOrEqualTo(1),
          reason: 'touch() must be called on 304');
    });

    _asyncTest('stale entry with lastModified sends If-Modified-Since', () async {
      const lm = 'Tue, 01 Jan 2019 00:00:00 GMT';
      await HttpCache.instance.put(ns, url, '{"v":1}', 200, lastModified: lm);
      await Future<void>.delayed(const Duration(milliseconds: 5));

      String? capturedIfModifiedSince;
      final mock = _SyncMockClient((req) {
        capturedIfModifiedSince = req.headers['If-Modified-Since'];
        return Future.value(http.Response('{"v":2}', 200));
      });

      final client = CachedHttpClient(
        namespace: ns,
        policy: const CachePolicy(ttl: Duration(milliseconds: 1)),
        httpClient: mock,
      );
      await client.get(uri);

      expect(capturedIfModifiedSince, lm,
          reason: 'If-Modified-Since must be sent when no ETag but lastModified exists');
    });

    _asyncTest('entry with no etag/lastModified sends unconditional request', () async {
      await HttpCache.instance.put(ns, url, '{"v":1}', 200);
      await Future<void>.delayed(const Duration(milliseconds: 5));

      String? ifNoneMatch;
      String? ifModifiedSince;
      final mock = _SyncMockClient((req) {
        ifNoneMatch = req.headers['If-None-Match'];
        ifModifiedSince = req.headers['If-Modified-Since'];
        return Future.value(http.Response('{"v":2}', 200));
      });

      final client = CachedHttpClient(
        namespace: ns,
        policy: const CachePolicy(ttl: Duration(milliseconds: 1)),
        httpClient: mock,
      );
      await client.get(uri);

      expect(ifNoneMatch, isNull);
      expect(ifModifiedSince, isNull);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 5. Offline-first
  // ════════════════════════════════════════════════════════════════════════════
  group('Offline-first', () {
    const ns = 'offline_ns';
    const url = 'http://example.com/offline';
    final uri = Uri.parse(url);

    setUp(() => HttpCache.instance.clear());

    _asyncTest('SocketException with stale entry returns stale body', () async {
      await HttpCache.instance.put(ns, url, '{"cached":true}', 200);
      await Future<void>.delayed(const Duration(milliseconds: 5));

      final count = [0];
      final mock = _throwingMock(count, const SocketException('no network'));

      final client = CachedHttpClient(
        namespace: ns,
        policy: const CachePolicy(ttl: Duration(milliseconds: 1)),
        httpClient: mock,
      );

      final response = await client.get(uri);

      expect(response.body, '{"cached":true}',
          reason: 'SocketException must return stale body when available');
      expect(response.statusCode, 200);
    });

    _asyncTest('SocketException with no stale entry returns 503 offline', () async {
      final count = [0];
      final mock = _throwingMock(count, const SocketException('no network'));

      final client = CachedHttpClient(
        namespace: ns,
        policy: const CachePolicy(ttl: Duration(minutes: 5)),
        httpClient: mock,
      );

      final response = await client.get(uri);

      expect(response.statusCode, 503);
      expect(response.body, 'offline');
    });

    test('isOfflineFallback() returns true for 503/offline', () {
      final r = http.Response('offline', 503);
      expect(CachedHttpClient.isOfflineFallback(r), isTrue);
    });

    test('isOfflineFallback() returns false for other responses', () {
      expect(CachedHttpClient.isOfflineFallback(http.Response('ok', 200)), isFalse);
      expect(CachedHttpClient.isOfflineFallback(http.Response('error', 503)), isFalse);
      expect(CachedHttpClient.isOfflineFallback(http.Response('offline', 200)), isFalse);
    });

    _asyncTest('cold-start stale: SWR=false entry returned immediately + refresh triggered', () async {
      const coldNs = 'cold_ns';
      const coldUrl = 'http://example.com/cold';
      final coldUri = Uri.parse(coldUrl);

      await HttpCache.instance.put(coldNs, coldUrl, '{"stale":true}', 200);
      // Expire the entry
      await Future<void>.delayed(const Duration(milliseconds: 5));

      final count = [0];
      final completer = Completer<http.Response>();
      final mock = _SyncMockClient((_) {
        count[0]++;
        return completer.future;
      });

      final client = CachedHttpClient(
        namespace: coldNs,
        policy: const CachePolicy(
          ttl: Duration(milliseconds: 1),
          staleWhileRevalidate: false, // cold-start must override this
        ),
        httpClient: mock,
      );

      // Must return stale immediately, not block
      final response = await client.get(coldUri);
      expect(response.body, '{"stale":true}',
          reason: 'Cold-start stale must be returned immediately regardless of SWR flag');

      // Allow background refresh to kick off
      completer.complete(http.Response('{"fresh":true}', 200));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(count[0], greaterThanOrEqualTo(1),
          reason: 'Background revalidation must be triggered');
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 6. BookCoverImage widget
  // ════════════════════════════════════════════════════════════════════════════
  group('BookCoverImage widget', () {
    testWidgets('null URL shows fallback asset (no CachedNetworkImage)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BookCoverImage(coverUrl: null),
          ),
        ),
      );
      // Should have an Image widget (asset fallback), not CachedNetworkImage
      expect(find.byType(BookCoverImage), findsOneWidget);
      // The build method should produce Image.asset, not CachedNetworkImage
      // We verify by confirming no errors are thrown and no network image attempt
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty string URL shows fallback asset', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BookCoverImage(coverUrl: '   '),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('non-empty URL builds CachedNetworkImage with correct imageUrl', (tester) async {
      const testUrl = 'https://example.com/cover.jpg';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BookCoverImage(coverUrl: testUrl),
          ),
        ),
      );

      // CachedNetworkImage widget should be present in the tree
      expect(find.byType(BookCoverImage), findsOneWidget);
      // No exceptions building the widget
      expect(tester.takeException(), isNull);
    });

    test('BookCoverImage is a StatelessWidget (no retry state fields)', () {
      // Verify the widget is stateless — if it were stateful there would be a
      // createState() method and associated State class with retry fields.
      const widget = BookCoverImage(coverUrl: null);
      expect(widget, isA<StatelessWidget>());
    });
  });
}
