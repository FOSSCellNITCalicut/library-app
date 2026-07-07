import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:library_nitc/aboutPage.dart';
import 'package:library_nitc/cache/cache_store.dart';
import 'package:library_nitc/cache/sqlite_cache_store.dart';
import 'package:library_nitc/chatBotPage.dart';
import 'package:library_nitc/generated/intl/messages_all.dart';
import 'package:library_nitc/homePage.dart';
import 'package:library_nitc/loadingScreen.dart';
import 'package:library_nitc/notifPage.dart';
import 'package:library_nitc/profilePage.dart';
import 'package:library_nitc/theme/app_colors.dart';
import 'package:library_nitc/theme/app_theme.dart';
import 'package:library_nitc/theme/theme_provider.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';

import 'package:intl/intl_standalone.dart' if (dart.library.html) 'package:intl/intl_browser.dart';
import 'package:provider/provider.dart';

import 'auth_provider.dart';
import 'curriculum_provider.dart';
import 'globals.dart';
import 'user_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  await findSystemLocale();
  await initializeMessages('en');
  await initializeDateFormatting('en', null);

  // Initialise persistent cache store. Falls back to the in-memory HttpCache
  // singleton if SQLite cannot be opened (e.g. permission error on first run).
  CacheStore? persistentStore;
  try {
    persistentStore = await SqliteCacheStore.open();
    appCacheStore = persistentStore;
  } on CacheStoreInitException catch (e) {
    debugPrint('[CACHE INIT] SqliteCacheStore failed, falling back to in-memory: $e');
  } catch (e) {
    debugPrint('[CACHE INIT] Unexpected error opening SqliteCacheStore, falling back to in-memory: $e');
  }

  runApp(MyApp(cacheStore: persistentStore));
}



class MyApp extends StatelessWidget {
  final CacheStore? cacheStore;

  const MyApp({super.key, this.cacheStore});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider(cacheStore: cacheStore)),
        ChangeNotifierProvider(create: (_) => CurriculumProvider(cacheStore: cacheStore)),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) => MaterialApp(
          title: 'Flutter Demo',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: theme.mode,
          home: LoadingScreen(),
        ),
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<StatefulWidget> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return PersistentTabView(
      controller: persistentTabController,
      tabs: [
        PersistentTabConfig(
          screen: SafeArea(child: HomePage()),
          item: ItemConfig(icon: Icon(Icons.home_outlined), title: "HOME", activeForegroundColor: context.cs.onSurface, activeColorSecondary: AppColors.primary.withOpacity(0.15))
        ),
        PersistentTabConfig(
            screen: SafeArea(child: ChatBotPage()),
            item: ItemConfig(icon: Icon(Icons.chat_bubble_outline), title: "CHATBOT", activeForegroundColor: context.cs.onSurface)
        ),
        PersistentTabConfig(
            screen: SafeArea(child: AboutPage()),
            item: ItemConfig(icon: Icon(Icons.info_outline), title: "ABOUT", activeForegroundColor: context.cs.onSurface)
        ),
        PersistentTabConfig(
            screen: SafeArea(child: ProfilePage()),
            item: ItemConfig(icon: Icon(Icons.account_circle_rounded), title: "PROFILE", activeForegroundColor: context.cs.onSurface)
        ),
      ],
      navBarBuilder: (navBarConfig) => Style7BottomNavBar(
        navBarConfig: navBarConfig,
        navBarDecoration: NavBarDecoration(
          color: context.cs.surfaceContainerLow,

        ),
      ) ,
    );
  }

  // bottomNavigationBar: NavigationBar(
  // onDestinationSelected: (int index){
  // setState(() {
  // currentPageIndex = index;
  // });
  // },
  // selectedIndex: currentPageIndex,
  // destinations: const <Widget>[
  // NavigationDestination(icon: Icon(Icons.home_outlined), label: "HOME"),
  // NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: "CHATBOT"),
  // NavigationDestination(icon: Icon(Icons.info_outline), label: "ABOUT"),
  // NavigationDestination(icon: Icon(Icons.account_circle_rounded), label: "PROFILE")
  // ],
  // ),
  // body: <Widget>[
  // SafeArea(child: HomePage())
  // ][currentPageIndex],
}