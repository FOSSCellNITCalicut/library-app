import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:library_nitc/cache/cache_policy.dart';
import 'package:library_nitc/cache/cached_http_client.dart';
import 'package:library_nitc/cache/http_cache.dart';
import 'package:library_nitc/services/book_service.dart';
import 'package:library_nitc/services/curriculum_service.dart';
import 'package:library_nitc/user_provider.dart';

// ── Fixtures ──────────────────────────────────────────────────────────────────

const _versionFixture = '{"version":"v2024-01"}';
const _curriculumFixture =
    '{"semester":1,"courses":[{"code":"CS101","title":"Intro"}]}';
const _finesFixture = '{"outstanding_fine":0.0}';
const _holdsFixture = '{"items":[]}';
const _bookStatusFixture =
    '{"borrowed_by_current_user":false,"issue_id":0,"renewals_allowed":0,"renewals_remaining":0}';
const _holdFormFixture = '{"holdable":true,"branches":[]}';

// ── Test HTTP Client ──────────────────────────────────────────────────────────
//
// flutter_test uses a fake-async zone that gates microtask/event delivery.
// MockClient internally uses Stream.value + ByteConversionSink which rely on
// async event delivery that never fires under fakeAsync without pumpEventQueue.
//
// This client bypasses the stream machinery entirely: it builds the
// http.Response directly and returns it via a completed Future, which is
// safe under fakeAsync.

typedef _HandlerFn = Future<http.Response> Function(http.Request request);

class _SyncMockClient extends http.BaseClient {
  final _HandlerFn _handler;
  _SyncMockClient(this._handler);

  /// Override get() directly to bypass BaseClient._sendUnstreamed →
  /// Response.fromStream → stream.toBytes(), all of which use async stream
  /// delivery that hangs under flutter_test's fakeAsync scheduler.
  /// Returns a synchronously-completed Future to avoid scheduling on the
  /// flutter_test zone's microtask queue.
  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) {
    final req = http.Request('GET', url);
    if (headers != null) req.headers.addAll(headers);
    return _handler(req);
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw UnimplementedError('_SyncMockClient: use get() override instead');
  }
}

/// Shorthand: always returns [body]/[statusCode], increments [count] ref.
/// Returns Future.value (synchronously complete) to avoid zone scheduling issues.
_SyncMockClient _simpleMock(
  List<int> count,
  String body, {
  int statusCode = 200,
}) {
  return _SyncMockClient((_) {
    count[0]++;
    return Future.sync(() => http.Response(body, statusCode));
  });
}

/// A throwing mock that increments [count] then throws [error].
_SyncMockClient _throwingMock(List<int> count, Object error) {
  return _SyncMockClient((_) {
    count[0]++;
    return Future.error(error);
  });
}

/// A controllable mock backed by a Completer — overrides get() directly.
class _CompleterMock extends http.BaseClient {
  final List<int> callCount;
  final Completer<http.Response> completer;

  _CompleterMock(this.callCount, this.completer);

  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) {
    callCount[0]++;
    return completer.future;
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw UnimplementedError('_CompleterMock: use get() override instead');
  }
}

void _asyncTest(String description, Future<void> Function() body) {
  testWidgets(description, (tester) async {
    await tester.runAsync(body);
  });
}

void main() {
  setUp(() {
    // Start each test with a clean cache.
    HttpCache.instance.enabled = true;
    HttpCache.instance.clear();
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Bug 1 exploration — uncached endpoints
  //
  // These tests are EXPECTED TO FAIL on unfixed code.
  // Each test calls an affected method twice and asserts the mock HTTP client
  // was called only once (cache hit on second call).  On unfixed code, the
  // services bypass CachedHttpClient entirely, so the count will be 2 instead
  // of 1 — proving the bug.
  //
  // **Validates: Requirements 1.1, 1.2, 1.3, 1.4, 1.5**
  // ══════════════════════════════════════════════════════════════════════════
  group('Bug 1 exploration — uncached endpoints', () {
    // ── CurriculumService.fetchVersion() ─────────────────────────────────
    _asyncTest(
      'fetchVersion() should only issue 1 network call on repeated invocations',
      () async {
        final count = [0];
        final mock = _simpleMock(count, _versionFixture);
        final service = CurriculumService(
          baseUrl: 'http://localhost:8000',
          httpClient: mock,
        );

        await service.fetchVersion();
        await service.fetchVersion();

        expect(
          count[0],
          1,
          reason:
              'fetchVersion() issued ${count[0]} http.get calls — '
              'expected 1 (cache hit on 2nd call). '
              'Counterexample: fetchVersion() issued 2 http.get calls — '
              'no caching observed.',
        );
      },
    );

    // ── CurriculumService.fetchCurriculum() ──────────────────────────────
    _asyncTest(
      'fetchCurriculum() should only issue 1 network call on repeated invocations',
      () async {
        final count = [0];
        final mock = _simpleMock(count, _curriculumFixture);
        final service = CurriculumService(
          baseUrl: 'http://localhost:8000',
          httpClient: mock,
        );

        await service.fetchCurriculum();
        await service.fetchCurriculum();

        expect(
          count[0],
          1,
          reason:
              'fetchCurriculum() issued ${count[0]} http.get calls — '
              'expected 1 (cache hit on 2nd call). '
              'Counterexample: fetchCurriculum() issued 2 http.get calls — '
              'no caching observed.',
        );
      },
    );

    // ── UserProvider.fetchFines() ─────────────────────────────────────────
    _asyncTest(
      'fetchFines() should only issue 1 network call on repeated invocations',
      () async {
        final count = [0];
        final mock = _simpleMock(count, _finesFixture);
        final provider = UserProvider(httpClient: mock);

        await provider.fetchFines('test-token');
        await provider.fetchFines('test-token');

        expect(
          count[0],
          1,
          reason:
              'fetchFines() issued ${count[0]} http.get calls — '
              'expected 1 (cache hit on 2nd call). '
              'Counterexample: fetchFines() issued 2 http.get calls — '
              'no caching observed.',
        );
      },
    );

    // ── UserProvider.fetchHolds() ─────────────────────────────────────────
    _asyncTest(
      'fetchHolds() should only issue 1 network call on repeated invocations',
      () async {
        final count = [0];
        final mock = _simpleMock(count, _holdsFixture);
        final provider = UserProvider(httpClient: mock);

        await provider.fetchHolds('test-token');
        await provider.fetchHolds('test-token');

        expect(
          count[0],
          1,
          reason:
              'fetchHolds() issued ${count[0]} http.get calls — '
              'expected 1 (cache hit on 2nd call). '
              'Counterexample: fetchHolds() issued 2 http.get calls — '
              'no caching observed.',
        );
      },
    );

    // ── UserProvider.fetchBookStatus() ────────────────────────────────────
    _asyncTest(
      'fetchBookStatus() should only issue 1 network call for the same biblioId',
      () async {
        final count = [0];
        final mock = _simpleMock(count, _bookStatusFixture);
        final provider = UserProvider(httpClient: mock);

        await provider.fetchBookStatus('test-token', 42);
        await provider.fetchBookStatus('test-token', 42);

        expect(
          count[0],
          1,
          reason:
              'fetchBookStatus(42) issued ${count[0]} http.get calls — '
              'expected 1 (cache hit on 2nd call for same biblioId). '
              'Counterexample: fetchBookStatus() issued 2 http.get calls — '
              'no caching observed.',
        );
      },
    );

    // ── UserProvider.fetchHoldForm() ──────────────────────────────────────
    _asyncTest(
      'fetchHoldForm() should only issue 1 network call for the same biblioId',
      () async {
        final count = [0];
        final mock = _simpleMock(count, _holdFormFixture);
        final provider = UserProvider(httpClient: mock);

        await provider.fetchHoldForm('test-token', 42);
        await provider.fetchHoldForm('test-token', 42);

        expect(
          count[0],
          1,
          reason:
              'fetchHoldForm(42) issued ${count[0]} http.get calls — '
              'expected 1 (cache hit on 2nd call for same biblioId). '
              'Counterexample: fetchHoldForm() issued 2 http.get calls — '
              'no caching observed.',
        );
      },
    );
  });

  group('HttpCache TTL', () {
    test('returns null on miss', () {
      final result = HttpCache.instance.get(
        'test',
        'http://example.com/a',
        const Duration(minutes: 5),
        const Duration(minutes: 1),
      );
      expect(result, isNull);
    });

    test('returns entry before TTL expires', () {
      HttpCache.instance.put(
        'test',
        'http://example.com/a',
        '{"ok":true}',
        200,
      );
      final result = HttpCache.instance.get(
        'test',
        'http://example.com/a',
        const Duration(minutes: 5),
        const Duration(minutes: 1),
      );
      expect(result, isNotNull);
      expect(result!.body, '{"ok":true}');
      expect(result.statusCode, 200);
    });

    test('error entries use failureTtl not ttl', () {
      HttpCache.instance.put(
        'test',
        'http://example.com/err',
        'error',
        500,
        isError: true,
      );
      // Should be found within failureTtl
      final hit = HttpCache.instance.get(
        'test',
        'http://example.com/err',
        const Duration(minutes: 5),
        const Duration(minutes: 1),
      );
      expect(hit, isNotNull);
      expect(hit!.isError, isTrue);
    });

    test('getStale returns entry regardless of age', () {
      HttpCache.instance.put('test', 'http://example.com/stale', 'stale', 200);
      final stale = HttpCache.instance.getStale(
        'test',
        'http://example.com/stale',
      );
      expect(stale, isNotNull);
      expect(stale!.body, 'stale');
    });

    test('invalidate removes specific key', () {
      HttpCache.instance.put('test', 'http://example.com/x', 'data', 200);
      HttpCache.instance.invalidate('test', 'http://example.com/x');
      final result = HttpCache.instance.get(
        'test',
        'http://example.com/x',
        const Duration(minutes: 5),
        const Duration(minutes: 1),
      );
      expect(result, isNull);
    });

    test('invalidateNamespace removes all keys in namespace', () {
      HttpCache.instance.put('ns1', 'http://example.com/1', 'a', 200);
      HttpCache.instance.put('ns1', 'http://example.com/2', 'b', 200);
      HttpCache.instance.put('ns2', 'http://example.com/3', 'c', 200);
      HttpCache.instance.invalidateNamespace('ns1');

      expect(
        HttpCache.instance.getStale('ns1', 'http://example.com/1'),
        isNull,
      );
      expect(
        HttpCache.instance.getStale('ns1', 'http://example.com/2'),
        isNull,
      );
      // ns2 should be untouched
      expect(
        HttpCache.instance.getStale('ns2', 'http://example.com/3'),
        isNotNull,
      );
    });
  });

  group('HttpCache LRU eviction', () {
    test('evicts oldest entry when maxEntries exceeded', () {
      for (int i = 0; i < 3; i++) {
        HttpCache.instance.put(
          'lru',
          'http://example.com/$i',
          'data$i',
          200,
          maxEntries: 3,
        );
      }
      // All 3 present
      expect(
        HttpCache.instance.getStale('lru', 'http://example.com/0'),
        isNotNull,
      );

      // Adding a 4th should evict entry 0 (oldest)
      // But entry 0 was accessed above so it moved to end -- let's add 4th without accessing 0 first
      HttpCache.instance.clear();
      for (int i = 0; i < 3; i++) {
        HttpCache.instance.put(
          'lru',
          'http://example.com/$i',
          'data$i',
          200,
          maxEntries: 3,
        );
      }
      // Don't access entry 0 -- it's the oldest
      HttpCache.instance.put(
        'lru',
        'http://example.com/3',
        'data3',
        200,
        maxEntries: 3,
      );
      // Entry 0 should have been evicted
      expect(
        HttpCache.instance.getStale('lru', 'http://example.com/0'),
        isNull,
      );
      // Entry 3 (newest) should be present
      expect(
        HttpCache.instance.getStale('lru', 'http://example.com/3'),
        isNotNull,
      );
    });

    test('accessing an entry promotes it (prevents eviction)', () {
      for (int i = 0; i < 3; i++) {
        HttpCache.instance.put(
          'lru',
          'http://example.com/$i',
          'data$i',
          200,
          maxEntries: 3,
        );
      }
      // Access entry 0 to promote it to most-recently-used
      HttpCache.instance.getStale('lru', 'http://example.com/0');

      // Add 4th entry -- should evict entry 1 (now the oldest), not entry 0
      HttpCache.instance.put(
        'lru',
        'http://example.com/3',
        'data3',
        200,
        maxEntries: 3,
      );
      expect(
        HttpCache.instance.getStale('lru', 'http://example.com/0'),
        isNotNull,
      );
      expect(
        HttpCache.instance.getStale('lru', 'http://example.com/1'),
        isNull,
      );
    });
  });

  group('CachePolicy constants', () {
    test('opacHome has 12-hr TTL and stale-while-revalidate', () {
      expect(CachePolicy.opacHome.ttl, const Duration(hours: 12));
      expect(CachePolicy.opacHome.staleWhileRevalidate, isTrue);
      expect(CachePolicy.opacHome.failureTtl, const Duration(minutes: 1));
    });

    test('bookDetail has 24-hr TTL', () {
      expect(CachePolicy.bookDetail.ttl, const Duration(hours: 24));
      expect(CachePolicy.bookDetail.staleWhileRevalidate, isFalse);
    });

    test('booksBrowse has 5-min TTL and stale-while-revalidate', () {
      expect(CachePolicy.booksBrowse.ttl, const Duration(minutes: 5));
      expect(CachePolicy.booksBrowse.staleWhileRevalidate, isTrue);
    });

    test('booksSearch has 5-min TTL and LRU 50', () {
      expect(CachePolicy.booksSearch.ttl, const Duration(minutes: 5));
      expect(CachePolicy.booksSearch.maxEntries, 50);
      expect(CachePolicy.booksSearch.staleWhileRevalidate, isFalse);
    });

    test('all policies have 1-min failure TTL', () {
      for (final policy in [
        CachePolicy.opacHome,
        CachePolicy.bookDetail,
        CachePolicy.booksBrowse,
        CachePolicy.booksSearch,
        CachePolicy.curriculumVersion,
        CachePolicy.curriculum,
      ]) {
        expect(policy.failureTtl, const Duration(minutes: 1));
      }
    });

    test('curriculum policies have 6-hour TTLs', () {
      expect(CachePolicy.curriculumVersion.ttl, const Duration(hours: 6));
      expect(CachePolicy.curriculumVersion.staleWhileRevalidate, isFalse);
      expect(CachePolicy.curriculum.ttl, const Duration(hours: 6));
      expect(CachePolicy.curriculum.staleWhileRevalidate, isFalse);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Preservation baseline
  //
  // These tests verify that EXISTING CachedHttpClient behaviors are unchanged.
  // All of these MUST PASS on both unfixed and fixed code — they are the
  // regression guard for behaviors that must not change.
  //
  // **Validates: Requirements 2.6, 2.7, 2.8, 3.1, 3.2, 3.3, 3.4, 3.5, 3.7**
  // ══════════════════════════════════════════════════════════════════════════
  group('Preservation baseline', () {
    const String ns = 'preservation_test';
    const String url = 'http://localhost:8000/api/v1/test';
    final Uri uri = Uri.parse(url);
    const String body = '{"preserved":true}';

    // ── req 3.1: BookService routing still cached ─────────────────────────
    _asyncTest(
      'req 3.1 — BookService.fetchBrowse() is cached: mock called once',
      () async {
        const browseBody = '{"items":[],"total":0,"page":1,"per_page":10}';
        final count = [0];
        final mock = _simpleMock(count, browseBody);

        final service = BookService(
          baseUrl: 'http://localhost:8000',
          httpClient: mock,
        );
        final first = await service.fetchBrowse(1, 10);
        final second = await service.fetchBrowse(1, 10);

        expect(
          count[0],
          1,
          reason:
              'BookService.fetchBrowse() should hit network once; second call '
              'must be served from cache (booksBrowse policy, 5-min TTL, SWR).',
        );
        expect(first.body, browseBody);
        expect(second.body, browseBody);
      },
    );

    // ── req 3.2: Fresh-hit short-circuit — mock is NOT called ─────────────
    _asyncTest(
      'req 3.2 — fresh cache hit short-circuits network call',
      () async {
        final count = [0];
        final mock = _simpleMock(count, '{"live":true}');

        HttpCache.instance.put(ns, url, body, 200);

        final client = CachedHttpClient(
          namespace: ns,
          policy: const CachePolicy(ttl: Duration(minutes: 5)),
          httpClient: mock,
        );

        final response = await client.get(uri);

        expect(
          count[0],
          0,
          reason: 'Network must NOT be called on a fresh cache hit.',
        );
        expect(response.body, body);
        expect(response.statusCode, 200);
      },
    );

    // ── req 3.4: Synchronous MISS fetch — mock IS called, result stored ───
    _asyncTest(
      'req 3.4 — cache MISS triggers network fetch and caches result',
      () async {
        final count = [0];
        final mock = _simpleMock(count, body);

        final client = CachedHttpClient(
          namespace: ns,
          policy: const CachePolicy(ttl: Duration(minutes: 5)),
          httpClient: mock,
        );

        await client.get(uri);

        expect(
          count[0],
          1,
          reason: 'Network must be called exactly once on a MISS.',
        );
        final stored = HttpCache.instance.getStale(ns, url);
        expect(
          stored,
          isNotNull,
          reason: 'Response must be stored in HttpCache after a MISS fetch.',
        );
        expect(stored!.body, body);
      },
    );

    // ── req 3.5: Invalidation — eviction forces re-fetch ──────────────────
    _asyncTest(
      'req 3.5 — invalidate() causes next get() to miss and re-fetch',
      () async {
        final count = [0];
        final mock = _simpleMock(count, body);

        final client = CachedHttpClient(
          namespace: ns,
          policy: const CachePolicy(ttl: Duration(minutes: 5)),
          httpClient: mock,
        );

        HttpCache.instance.put(ns, url, body, 200);
        client.invalidate(uri);
        await client.get(uri);

        expect(
          count[0],
          1,
          reason:
              'After invalidate(), the next get() must hit the network (cache miss).',
        );
      },
    );

    // ── req 3.7: Failure caching — 500 cached with failureTtl ─────────────
    _asyncTest(
      'req 3.7 — 500 response is cached; second call within failureTtl skips network',
      () async {
        final count = [0];
        final mock = _simpleMock(count, 'error body', statusCode: 500);

        final client = CachedHttpClient(
          namespace: ns,
          policy: const CachePolicy(
            ttl: Duration(minutes: 5),
            failureTtl: Duration(minutes: 1),
          ),
          httpClient: mock,
        );

        await expectLater(client.get(uri), throwsA(isA<Exception>()));
        expect(count[0], 1);

        await expectLater(client.get(uri), throwsA(isA<Exception>()));

        expect(
          count[0],
          1,
          reason:
              'Second call within failureTtl must serve the cached failure '
              'and NOT call the network again.',
        );
      },
    );

    // ── req 3.3: UserProvider.fetchProfile() in-memory cache unchanged ────
    // fetchProfile() uses its own _profileFetchedAt guard (direct http.get,
    // not CachedHttpClient). Use http.runWithClient with _SyncMockClient.
    _asyncTest(
      'req 3.3 — UserProvider.fetchProfile() in-memory guard: http called once',
      () async {
        const profileBody =
            '{"roll_no":"B20CS001","name":"Test User","email":"test@example.com",'
            '"loan_summary":{"loan_count":0,"loan_limit":5},'
            '"checked_out_books":[]}';
        final count = [0];
        final mock = _simpleMock(count, profileBody);

        final provider = UserProvider();

        await http.runWithClient(() async {
          await provider.fetchProfile('test-token');
          await provider.fetchProfile('test-token');
        }, () => mock);

        expect(
          count[0],
          1,
          reason:
              'UserProvider.fetchProfile() must use the _profileFetchedAt guard '
              'and call http only once within the 1-hour window.',
        );
      },
    );

    // ── req 2.6: SWR error logged, not propagated ─────────────────────────
    // Policy: staleWhileRevalidate=true, TTL=1ms so the inserted entry is
    // immediately stale. Background refresh mock throws. Inject MockClient
    // directly so the background future uses it reliably.
    _asyncTest(
      'req 2.6 — SWR background error is logged and not propagated',
      () async {
        final List<String> printedLines = [];
        final originalDebugPrint = debugPrint;
        debugPrint = (String? message, {int? wrapWidth}) {
          printedLines.add(message ?? '');
        };

        try {
          const swrNs = 'swr_preservation_test';
          const swrUrl = 'http://localhost:8000/api/v1/swr-test';
          final swrUri = Uri.parse(swrUrl);
          const staleBody = '{"stale":true}';

          // Insert entry, then wait for the 1ms TTL to expire.
          HttpCache.instance.put(swrNs, swrUrl, staleBody, 200);
          await Future<void>.delayed(const Duration(milliseconds: 5));

          final netCount = [0];
          final throwMock = _throwingMock(netCount, Exception('network down'));

          final swrClient = CachedHttpClient(
            namespace: swrNs,
            policy: const CachePolicy(
              ttl: Duration(milliseconds: 1),
              staleWhileRevalidate: true,
            ),
            httpClient: throwMock,
          );

          // Must not throw — stale value returned immediately.
          final response = await swrClient.get(swrUri);
          // Give the unawaited background future time to run and log.
          await Future<void>.delayed(const Duration(milliseconds: 20));

          expect(
            response.body,
            staleBody,
            reason: 'SWR must return the stale body to the caller.',
          );
          expect(response.statusCode, 200);
          expect(
            netCount[0],
            greaterThanOrEqualTo(1),
            reason: 'SWR must attempt a background refresh.',
          );
          expect(
            printedLines.any((l) => l.contains('[CACHE SWR ERR]')),
            isTrue,
            reason:
                'debugPrint must log [CACHE SWR ERR] when background refresh fails.',
          );
        } finally {
          debugPrint = originalDebugPrint;
        }
      },
    );

    // ── req 2.7: Deduplication PBT ─────────────────────────────────────────
    // Generate N (2–5) concurrent calls for a single URL; assert mock called
    // exactly once. MockClient injected directly into CachedHttpClient.
    _asyncTest(
      'req 2.7 — concurrent requests are deduplicated (PBT: N=2..5)',
      () async {
        final random = Random(42);

        for (int iteration = 0; iteration < 3; iteration++) {
          HttpCache.instance.clear();
          final int n = 2 + random.nextInt(4); // 2..5

          final count = [0];
          final completer = Completer<http.Response>();
          final mock = _CompleterMock(count, completer);

          final dedupNs = 'dedup_pbt_$iteration';
          final dedupUrl = 'http://localhost:8000/api/v1/dedup-test-$iteration';
          final dedupUri = Uri.parse(dedupUrl);

          final client = CachedHttpClient(
            namespace: dedupNs,
            policy: const CachePolicy(ttl: Duration(minutes: 5)),
            httpClient: mock,
          );

          // Fire N concurrent calls, then release the single in-flight request.
          final futures = List.generate(n, (_) => client.get(dedupUri));
          completer.complete(http.Response(body, 200));
          final results = await Future.wait(futures);

          expect(
            count[0],
            1,
            reason:
                'Iteration $iteration: $n concurrent calls for the same URL '
                'must result in exactly 1 network call (deduplication), '
                'but got ${count[0]}.',
          );
          for (int i = 0; i < results.length; i++) {
            expect(
              results[i].body,
              body,
              reason:
                  'Iteration $iteration: all $n callers must receive the same '
                  'response body (got "${results[i].body}" at index $i).',
            );
          }
        }
      },
    );

    // ── req 2.8: Dev bypass PBT ────────────────────────────────────────────
    // Randomly toggle HttpCache.instance.enabled; assert correct behavior.
    // MockClient injected directly.
    _asyncTest('req 2.8 — dev-mode bypass respects enabled flag (PBT)', () async {
      addTearDown(() {
        HttpCache.instance.enabled = true;
        HttpCache.instance.clear();
      });

      final random = Random(99);
      for (int iteration = 0; iteration < 3; iteration++) {
        HttpCache.instance.clear();
        HttpCache.instance.enabled = true;

        final bypassNs = 'bypass_pbt_$iteration';
        final bypassUrl = 'http://localhost:8000/api/v1/bypass-test-$iteration';
        final bypassUri = Uri.parse(bypassUrl);

        final count = [0];
        final mock = _simpleMock(count, body);

        final client = CachedHttpClient(
          namespace: bypassNs,
          policy: const CachePolicy(ttl: Duration(minutes: 5)),
          httpClient: mock,
        );

        final enabledThisRound = random.nextBool();
        HttpCache.instance.enabled = enabledThisRound;

        await client.get(bypassUri);

        if (!enabledThisRound) {
          expect(
            count[0],
            1,
            reason:
                'Iteration $iteration (enabled=false): network must be called '
                'when cache is disabled.',
          );
          final cached = HttpCache.instance.getStale(bypassNs, bypassUrl);
          expect(
            cached,
            isNull,
            reason:
                'Iteration $iteration (enabled=false): nothing must be written '
                'to the cache when bypass is active.',
          );
        } else {
          expect(
            count[0],
            1,
            reason:
                'Iteration $iteration (enabled=true): first call is a MISS; '
                'network must be called once.',
          );
          final cached = HttpCache.instance.getStale(bypassNs, bypassUrl);
          expect(
            cached,
            isNotNull,
            reason:
                'Iteration $iteration (enabled=true): result must be written '
                'to cache after a MISS fetch.',
          );
          // Second call must be a HIT — no extra network call.
          await client.get(bypassUri);
          expect(
            count[0],
            1,
            reason:
                'Iteration $iteration (enabled=true): second call for same URI '
                'must be served from cache (no extra network call).',
          );
        }
      }

      HttpCache.instance.enabled = true;
    });
  });

  group('SWR error handling', () {
    _asyncTest(
      'logs background refresh errors and returns stale response',
      () async {
        final printedLines = <String>[];
        final originalDebugPrint = debugPrint;
        debugPrint = (String? message, {int? wrapWidth}) {
          printedLines.add(message ?? '');
        };

        try {
          const ns = 'swr_error_handling';
          const url = 'http://localhost:8000/api/v1/swr-error';
          final uri = Uri.parse(url);
          const staleBody = '{"stale":true}';

          HttpCache.instance.put(ns, url, staleBody, 200);
          await Future<void>.delayed(const Duration(milliseconds: 5));

          final count = [0];
          final client = CachedHttpClient(
            namespace: ns,
            policy: const CachePolicy(
              ttl: Duration(milliseconds: 1),
              staleWhileRevalidate: true,
            ),
            httpClient: _throwingMock(count, Exception('network down')),
          );

          final response = await client.get(uri);
          await Future<void>.delayed(const Duration(milliseconds: 20));

          expect(response.statusCode, 200);
          expect(response.body, staleBody);
          expect(count[0], 1);
          expect(
            printedLines.any((line) => line.contains('[CACHE SWR ERR]')),
            isTrue,
          );
        } finally {
          debugPrint = originalDebugPrint;
        }
      },
    );
  });

  group('Request deduplication', () {
    _asyncTest('two concurrent calls share one network request', () async {
      final count = [0];
      final completer = Completer<http.Response>();
      final client = CachedHttpClient(
        namespace: 'request_dedup_single',
        policy: const CachePolicy(ttl: Duration(minutes: 5)),
        httpClient: _CompleterMock(count, completer),
      );
      final uri = Uri.parse('http://localhost:8000/api/v1/dedup-single');

      final futures = Future.wait([client.get(uri), client.get(uri)]);
      completer.complete(http.Response('{"ok":true}', 200));
      final responses = await futures;

      expect(count[0], 1);
      expect(responses[0].body, responses[1].body);

      client.invalidate(uri);
      await client.get(uri);
      expect(
        count[0],
        2,
        reason:
            'After completion and invalidation, the same URL must be able to '
            'start a fresh network call.',
      );
    });

    _asyncTest(
      'N concurrent calls share one network request for N in 2, 3, 5',
      () async {
        for (final n in [2, 3, 5]) {
          HttpCache.instance.clear();
          final count = [0];
          final completer = Completer<http.Response>();
          final client = CachedHttpClient(
            namespace: 'request_dedup_$n',
            policy: const CachePolicy(ttl: Duration(minutes: 5)),
            httpClient: _CompleterMock(count, completer),
          );
          final uri = Uri.parse('http://localhost:8000/api/v1/dedup-$n');

          final futures = List.generate(n, (_) => client.get(uri));
          completer.complete(http.Response('{"n":$n}', 200));
          final responses = await Future.wait(futures);

          expect(count[0], 1);
          for (final response in responses) {
            expect(response.body, '{"n":$n}');
          }
        }
      },
    );
  });

  group('Dev-mode cache bypass', () {
    tearDown(() {
      HttpCache.instance.enabled = true;
      HttpCache.instance.clear();
    });

    _asyncTest(
      'pre-populated entries are ignored when cache is disabled',
      () async {
        const ns = 'dev_bypass_prepopulated';
        const url = 'http://localhost:8000/api/v1/dev-bypass-prepopulated';
        final uri = Uri.parse(url);
        final count = [0];
        final client = CachedHttpClient(
          namespace: ns,
          policy: const CachePolicy(ttl: Duration(minutes: 5)),
          httpClient: _simpleMock(count, '{"live":true}'),
        );

        HttpCache.instance.put(ns, url, '{"cached":true}', 200);
        HttpCache.instance.enabled = false;

        final response = await client.get(uri);

        expect(count[0], 1);
        expect(response.body, '{"live":true}');
      },
    );

    _asyncTest(
      'disabled cache does not write results and repeated calls hit network',
      () async {
        const ns = 'dev_bypass_no_write';
        const url = 'http://localhost:8000/api/v1/dev-bypass-no-write';
        final uri = Uri.parse(url);
        final count = [0];
        final client = CachedHttpClient(
          namespace: ns,
          policy: const CachePolicy(ttl: Duration(minutes: 5)),
          httpClient: _simpleMock(count, '{"live":true}'),
        );

        HttpCache.instance.enabled = false;

        await client.get(uri);
        await client.get(uri);

        expect(count[0], 2);
        expect(HttpCache.instance.getStale(ns, url), isNull);
      },
    );

    _asyncTest(
      'toggle variant preserves bypass and enabled-cache behavior',
      () async {
        final random = Random(7);

        for (var i = 0; i < 10; i++) {
          HttpCache.instance.clear();
          final enabled = random.nextBool();
          HttpCache.instance.enabled = enabled;

          final ns = 'dev_bypass_toggle_$i';
          final url = 'http://localhost:8000/api/v1/dev-bypass-toggle-$i';
          final uri = Uri.parse(url);
          final count = [0];
          final client = CachedHttpClient(
            namespace: ns,
            policy: const CachePolicy(ttl: Duration(minutes: 5)),
            httpClient: _simpleMock(count, '{"iteration":$i}'),
          );

          await client.get(uri);
          await client.get(uri);

          if (enabled) {
            expect(count[0], 1);
            expect(HttpCache.instance.getStale(ns, url), isNotNull);
          } else {
            expect(count[0], 2);
            expect(HttpCache.instance.getStale(ns, url), isNull);
          }
        }
      },
    );
  });
}
