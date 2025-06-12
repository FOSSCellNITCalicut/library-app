import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:library_nitc/main.dart';

class AuthScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Color(0xFFF1EAF9),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SizedBox(
              height: 196,
              width: 196,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Image.asset("assets/main_logo.png"),
              ),
            ),
            SizedBox(height: 50,),
            SizedBox(
              height: 74,
              width: 250,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: TextButton(
                  onPressed: () {
                    // TODO : auth stuff
                    Navigator.of(context).pushReplacement(MaterialPageRoute(
                        builder: (_) => MainPage()
                    ));
                  },
                  style: ButtonStyle(
                    foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
                    backgroundColor: MaterialStateProperty.all<Color>(Colors.black),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: BorderSide(color: Colors.black)
                      )
                    )
                  ),
                  child: Text("LOGIN", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 40),),
                ),
              ),
            ),
            SizedBox(
              width: 77,
              height: 94,
              child: Image.asset("assets/nitc_logo.png"),
            ),

          ],
        ),
      )
    );
  }
}