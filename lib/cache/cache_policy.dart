/// Centralised cache policy registry.
///
/// Each [CachePolicy] declares:
///   - [ttl]                   how long a fresh response is valid
///   - [failureTtl]            how long a failed/error response is cached
///                             (short, so the user can retry quickly)
///   - [staleWhileRevalidate]  whether to return the stale value immediately
///                             and refresh in the background
///   - [maxEntries]            for LRU policies; -1 = unlimited
class CachePolicy {
  final Duration ttl;
  final Duration failureTtl;
  final bool staleWhileRevalidate;
  final int maxEntries;

  const CachePolicy({
    required this.ttl,
    this.failureTtl = const Duration(minutes: 1),
    this.staleWhileRevalidate = false,
    this.maxEntries = -1,
  });

  // ── Predefined policies ────────────────────────────────────────────────────

  /// P1 — GET /opac/home
  /// Most expensive backend call (Koha scrape), shown on every app open.
  /// Return stale data immediately and refresh silently in the background.
  static const opacHome = CachePolicy(
    ttl: Duration(hours: 12),
    failureTtl: Duration(minutes: 1),
    staleWhileRevalidate: true,
  );

  /// P2 — GET /books/{id}
  /// User may open the same book detail page multiple times.
  /// 24-hr TTL; availability synced separately via the backend trigger.
  static const bookDetail = CachePolicy(
    ttl: Duration(hours: 24),
    failureTtl: Duration(minutes: 1),
    staleWhileRevalidate: false,
  );

  /// P3 — GET /user/me  (session-level, managed in UserProvider)
  /// Fetch once at login + on app foreground; no HTTP-level cache needed here
  /// because UserProvider holds the result in memory. Defined here for docs.
  static const userProfile = CachePolicy(
    ttl: Duration(hours: 1),
    failureTtl: Duration(minutes: 1),
    staleWhileRevalidate: false,
  );

  /// P4 — GET /books/browse
  /// High traffic, paginated. Cache first pages for 5 min.
  static const booksBrowse = CachePolicy(
    ttl: Duration(minutes: 5),
    failureTtl: Duration(minutes: 1),
    staleWhileRevalidate: true,
  );

  /// P5 — GET /books/search
  /// Very frequent, keyed by full URL (includes query + page).
  /// LRU 50 to cap memory usage.
  static const booksSearch = CachePolicy(
    ttl: Duration(minutes: 5),
    failureTtl: Duration(minutes: 1),
    staleWhileRevalidate: false,
    maxEntries: 50,
  );
}
