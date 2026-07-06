import 'package:flutter/material.dart';
import 'package:library_nitc/cache/cache_store.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';

PersistentTabController persistentTabController = PersistentTabController(initialIndex: 0);

/// The app-wide persistent cache store, initialised in [main] once
/// [SqliteCacheStore.open] completes. Services created in widget state classes
/// (where constructor injection is impractical) read this global so they
/// automatically benefit from SQLite persistence without changing their call
/// sites.
///
/// Remains null only when SQLite failed to open at startup; in that case
/// services fall back to the in-memory [HttpCache] singleton.
CacheStore? appCacheStore;

/// Backend base URL. Override at build time with:
///   flutter run --dart-define=BACKEND_URL=http://192.168.x.x:8000
const String kBackendBaseUrl = String.fromEnvironment(
  'BACKEND_URL',
  defaultValue: 'http://localhost:8000',
);

Route slideRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1, 0);
      const end = Offset.zero;
      const curve = Curves.easeOutCubic;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}