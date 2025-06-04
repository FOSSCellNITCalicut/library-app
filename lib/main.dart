import 'package:flutter/material.dart';
import 'package:library_nitc/homePage.dart';
import 'package:library_nitc/loadingScreen.dart';
import 'package:library_nitc/profilePage.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';

import 'package:intl/intl_standalone.dart' if (dart.library.html) 'package:intl/intl_browser.dart';

import 'globals.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await findSystemLocale();
  // await initializeDateFormatting();
  runApp(const MyApp());
}

// void main() {
//   runApp(const MyApp());
// }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
      ),
      home: LoadingScreen(),
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
        // TODO : replace screen argument in each PersistentTabConfig to match required page
        PersistentTabConfig(
          screen: SafeArea(child: HomePage()),
          item: ItemConfig(icon: Icon(Icons.home_outlined), title: "HOME", activeForegroundColor: Colors.black)
        ),
        PersistentTabConfig(
            screen: SafeArea(child: HomePage()),
            item: ItemConfig(icon: Icon(Icons.chat_bubble_outline), title: "CHATBOT", activeForegroundColor: Colors.black)
        ),
        PersistentTabConfig(
            screen: SafeArea(child: HomePage()),
            item: ItemConfig(icon: Icon(Icons.info_outline), title: "ABOUT", activeForegroundColor: Colors.black)
        ),
        PersistentTabConfig(
            screen: SafeArea(child: ProfilePage()),
            item: ItemConfig(icon: Icon(Icons.account_circle_rounded), title: "PROFILE", activeForegroundColor: Colors.black)
        ),
      ],
      navBarBuilder: (navBarConfig) => Style7BottomNavBar(
        navBarConfig: navBarConfig,
        navBarDecoration: NavBarDecoration(
          color: Colors.purple.shade50,

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
  // body: <Widget>[ // TODO : Add remaining pages
  // SafeArea(child: HomePage())
  // ][currentPageIndex],
}