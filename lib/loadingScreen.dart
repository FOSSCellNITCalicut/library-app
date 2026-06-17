import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:library_nitc/auth_provider.dart';
import 'package:library_nitc/main.dart';
import 'package:provider/provider.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<StatefulWidget> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    _init();
  }

  Future<void> _init() async {
    // Run the splash delay and the silent token refresh at the same time.
    // We go to MainPage when BOTH finish -- so the splash is never shorter
    // than 2s, but also never blocks longer than the network needs.
    await Future.wait([
      Future.delayed(const Duration(seconds: 2)),
      context.read<AuthProvider>().tryRefresh(),
    ]);

    if (!mounted) return;

    // Always go to MainPage. If tryRefresh() succeeded, AuthProvider.isLoggedIn
    // is true and the profile tab will show user data. If it failed, the user
    // is unauthenticated and can browse publicly; login is available in profile.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainPage()),
    );
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(color: Color(0xFF6C4EB4)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SizedBox(
              height: 310,
              width: 310,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Image.asset('assets/main_logo.png'),
              ),
            ),
            const CircularProgressIndicator(
              value: null,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(
              height: 147,
              width: 124,
              child: Image.asset('assets/nitc_logo_white.png'),
            ),
          ],
        ),
      ),
    );
  }
}
