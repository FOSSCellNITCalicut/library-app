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

  /// User fines outstanding balance — changes rarely, refresh every 5 min.
  static const userFines = CachePolicy(
    ttl: Duration(minutes: 5),
    failureTtl: Duration(minutes: 1),
    staleWhileRevalidate: false,
  );

  /// Fines history — essentially append-only, safe to cache for 10 min.
  static const userFinesHistory = CachePolicy(
    ttl: Duration(minutes: 10),
    failureTtl: Duration(minutes: 1),
    staleWhileRevalidate: false,
  );

  /// Active holds list — changes on hold placement/cancellation.
  /// Short TTL so mutations stay visible quickly.
  static const userHolds = CachePolicy(
    ttl: Duration(minutes: 3),
    failureTtl: Duration(minutes: 1),
    staleWhileRevalidate: false,
  );

  /// Per-book borrow status (is this user currently borrowing this book?).
  /// Short TTL — shown on BookDetailCard, needs to be fairly fresh.
  static const bookStatus = CachePolicy(
    ttl: Duration(minutes: 3),
    failureTtl: Duration(minutes: 1),
    staleWhileRevalidate: false,
    maxEntries: 30,
  );

  /// Hold form (is the book holdable? which pickup branches?).
  /// Can be cached for 10 min — branch list changes rarely.
  static const holdForm = CachePolicy(
    ttl: Duration(minutes: 10),
    failureTtl: Duration(minutes: 1),
    staleWhileRevalidate: false,
    maxEntries: 20,
  );

  /// Curriculum version tag — changes only on curriculum updates.
  /// Long TTL; version check is the first thing CurriculumProvider does.
  static const curriculumVersion = CachePolicy(
    ttl: Duration(hours: 6),
    failureTtl: Duration(minutes: 1),
    staleWhileRevalidate: false,
  );

  /// Full curriculum JSON — large payload, changes infrequently.
  static const curriculum = CachePolicy(
    ttl: Duration(hours: 6),
    failureTtl: Duration(minutes: 1),
    staleWhileRevalidate: false,
  );
}
