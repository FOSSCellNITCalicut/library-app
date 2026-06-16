import 'package:date_field/date_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:library_nitc/globals.dart';
import 'package:library_nitc/homePage.dart';
import 'package:library_nitc/main.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';

class BookPage extends StatefulWidget {
  final int biblioId;
  const BookPage({required this.biblioId, super.key});



  @override
  State<StatefulWidget> createState() => _BookPageState();

}

class _BookPageState extends State<BookPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icon(Icons.arrow_back),
        ),
      ),

      body: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BookDetailCard(),
            SizedBox(height: 8,),
            Text("Holdings (n)", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),),
            SizedBox(height: 8,),
            Expanded(
              child: HoldingsList(),
            )
          ],
        ),
      )
    );
  }

}

class BookDetailCard extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _BookDetailCardState();

}

class _BookDetailCardState extends State<BookDetailCard> {
  var bookAvailable = true; // TODO : from backend
  var placeHoldAvailable = true; // TODO : from backend

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 222,
      child: Column(
        children: [
          Row( // TODO use dynamic data
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset("assets/stats_book_temp.png", height: 170, width: 128,),
              ),
              Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Heading", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),),
                    Text("Author", style: TextStyle(fontSize: 14, color: Colors.black54),),
                    RichText(
                        text: TextSpan(
                            children: [
                              TextSpan(text: "Status:", style: TextStyle(fontSize: 14, color: Colors.black54)),
                              TextSpan(
                                  text: bookAvailable ? "Available" : "Unavailable",
                                  style: TextStyle(color: bookAvailable ? Colors.green : Colors.red)
                              )
                            ]
                        )
                    )
                  ],
                ),
              )
            ],
          ),
          SizedBox(height: 12,),
          SizedBox(
            height: 32,
            child: Row(
              children: [
                OutlinedButton(
                  onPressed: () {},
                  style: ButtonStyle(
                      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      )
                    ),
                  ),
                  child: Text("Text", style: TextStyle(fontWeight: FontWeight.w500),),
                ),
                SizedBox(width: 8,),
                OutlinedButton(
                  onPressed: () {},
                  style: ButtonStyle(
                    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        )
                    ),
                  ),
                  child: Text("General Books", style: TextStyle(fontWeight: FontWeight.w500),),
                ),
                Spacer(),
                FilledButton.icon(
                  onPressed: placeHoldAvailable ? () {
                    pushWithNavBar(context, MaterialPageRoute(builder: (context) => PlaceHoldScreen()));
                    // pushScreenWithNavBar(context, PlaceHoldScreen());
                  } : null,
                  style: ButtonStyle(
                    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        )
                    ),
                  ),
                  icon: Icon(Icons.bookmark),
                  label: Text("Place Hold", style: TextStyle(fontWeight: FontWeight.w500),),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

}
class HoldingsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 7, // TODO backend
      itemBuilder: (BuildContext context, int index) {
        return Container(
          color: Colors.purple.shade50,
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text("General Books"),
                  Spacer(),
                  Text("SL NO")
                ],
              ),
              Text("Bar code: SOME CODE"),
              Text("Library | Status <Availability>"),
            ],
          ),
        );
      },
    );
  }

}

class PlaceHoldScreen extends StatefulWidget {
  const PlaceHoldScreen({super.key});

  @override
  State<StatefulWidget> createState() => _PlaceHoldScreenState();

}

class _PlaceHoldScreenState extends State<PlaceHoldScreen> {
  TextEditingController _dateController = TextEditingController();
  TextEditingController _timeController = TextEditingController();


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icon(Icons.arrow_back_outlined),
        ),
        title: Text("Place Hold"),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox(
              height: 222,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset("assets/stats_book_temp.png", height: 170, width: 128,),
                  ),
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Heading", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),),
                        Text("Author", style: TextStyle(fontSize: 14, color: Colors.black54),),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  decoration:InputDecoration(
                      labelText: 'Pickup date',
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Colors.black38, width: 1
                          )
                      ),
                      focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Colors.purple, width: 1
                          )
                      )
                  ),
                  onTap: () {
                    _selectDate();
                  },
                  controller: _dateController,
                ),
                SizedBox(height: 64,),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Pickup time',
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.black38, width: 1
                      )
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.purple, width: 1
                      )
                    )
                  ),
                  onTap: () {
                    _selectTime();
                  },
                  controller: _timeController,
                ),
                SizedBox(height: 16,),
                FilledButton(
                  onPressed: () {
                    final regex = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$'); // for time validation

                    final pickupDate = _dateController.text;
                    final pickupTime = _timeController.text;

                    if(DateTime.tryParse(pickupDate) == null || !regex.hasMatch(pickupTime)){
                      showDialog(
                          context: context,
                          builder: (BuildContext context) => AlertDialog(
                            title: const Text("Invalid date or time entered"),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  _dateController.text = '';
                                  _timeController.text = '';
                                },
                                child: const Text("OK"),
                              )
                            ],
                          )
                      );
                    } else {
                      print("$pickupTime, $pickupDate");
                      // TODO : send data to backend
  
                      pushScreenWithNavBar(context, ConfirmedBookingPage()); // not a huge fan of this method, ie creating a new screen
                      
                      // showDialog(
                      //   context: context,
                      //   builder: (BuildContext context) => AlertDialog(
                      //     title: const Text("Holding Confirmed"),
                      //     actions: [
                      //       TextButton(
                      //         onPressed: () {
                      //           print("sigma");
                      //           popAllScreensOfCurrentTab(context);
                      //         },
                      //         child: const Text("Return to home page"),
                      //       )
                      //     ],
                      //   )
                      // );
                    }

                  },
                  child: Text("Confirm booking"),
                )
              ],
            ),
          )
        ],
      )
    );
  }

  Future<void> _selectDate() async {
    DateTime? _picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 30))
    );

    if(_picked != null){
      setState(() {
        _dateController.text = _picked.toString().split(" ")[0];
      });
    }
    }

  String format24Hour(TimeOfDay time) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    return '$hours:$minutes'; 
  }

  Future<void> _selectTime() async {

    TimeOfDay? _pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      initialEntryMode: TimePickerEntryMode.dial,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      }
    );

    if(_pickedTime != null){
      setState(() {
        _timeController.text = format24Hour(_pickedTime);
      });
    }

  }

}

class ConfirmedBookingPage extends StatelessWidget {
  const ConfirmedBookingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icon(Icons.arrow_back_outlined),
        ),
        title: Text("Place Hold"),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox(
              height: 222,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset("assets/stats_book_temp.png", height: 170, width: 128,),
                  ),
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text("Heading", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),),
                        Text("Author", style: TextStyle(fontSize: 14, color: Colors.black54),),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          SizedBox(height: 16,),
          Text("Holding Confirmed!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),),
          SizedBox(height: 16,),
          FilledButton(
            onPressed: () {
              popAllScreensOfCurrentTab(context);
            },
            child: Text("Return to home page"),
          )
        ],
      ),
    );
  }

}

