import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:library_nitc/homePage.dart';
import 'package:library_nitc/main.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<StatefulWidget> createState() => _LoadingScreenState();

}

class _LoadingScreenState extends State<LoadingScreen> with SingleTickerProviderStateMixin{


  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    Future.delayed(Duration(seconds: 2), () { // TODO : replace this with inititalizing db or whatever
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => MainPage()
      ));
    });

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
        decoration: BoxDecoration(
          color: Color(0xFF6C4EB4)
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SizedBox(
              height: 310,
              width: 310,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Image.asset("assets/main_logo.png"),
              ),
            ),
            CircularProgressIndicator(value: null, valueColor: AlwaysStoppedAnimation<Color>(Colors.white),),
            SizedBox(
              height: 147,
              width: 124,
              child: Image.asset("assets/nitc_logo_white.png"),
            )
          ],
        ),
      ),
    );
  }


}