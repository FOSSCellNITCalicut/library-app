import 'package:date_field/date_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:library_nitc/globals.dart';

import 'package:library_nitc/main.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import 'package:library_nitc/services/book_service.dart';
import 'package:library_nitc/models/book_details.dart';

class BookPage extends StatefulWidget {
  final int biblioId;
  const BookPage({required this.biblioId, super.key});

  @override
  State<StatefulWidget> createState() => _BookPageState();
}

class _BookPageState extends State<BookPage> {

  

  final BookService _service = BookService();

  BookDetail? book;
  bool loading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
  try {
    setState(() {
      loading = true;
      hasError = false;
    });

    //await Future.delayed(const Duration(seconds: 2));  //to see loading page


    final data = await _service.getBookDetail(widget.biblioId);

    setState(() {
      book = data;
      loading = false;
    });
  } catch (e) {
    setState(() {
      loading = false;
      hasError = true;
    });
  }
}
  @override

  Widget build(BuildContext context) {

  //loading
  if (loading) {
  return Scaffold(
    appBar: AppBar(),
    body: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // BOOK HEADER SKELETON
          Row(
            children: [
              Container(
                height: 170,
                width: 128,
                color: Colors.grey.shade300,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 20, color: Colors.grey.shade300),
                    const SizedBox(height: 8),
                    Container(height: 14, width: 120, color: Colors.grey.shade300),
                    const SizedBox(height: 8),
                    Container(height: 14, width: 160, color: Colors.grey.shade300),
                  ],
                ),
              )
            ],
          ),

          const SizedBox(height: 20),

          // HOLDINGS TITLE
          Container(height: 18, width: 140, color: Colors.grey.shade300),

          const SizedBox(height: 10),

          // LIST SKELETON
          Expanded(
            child: ListView.builder(
              itemCount: 5,
              itemBuilder: (_, __) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                color: Colors.grey.shade200,
                height: 60,
              ),
            ),
          )
        ],
      ),
    ),
  );
}

  //error      not much ui is done later if needed
  if (hasError) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sentiment_dissatisfied,
                size: 80, color: Colors.grey),
            SizedBox(height: 12),
            Text("Failed to load book details"),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  loading = true;
                  hasError = false;
                });
                load();
              },
              child: Text("Retry"),
            )
          ],
        ),
      ),
    );
  }

  // success
  final b = book!;

  return Scaffold(
    appBar: AppBar(
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: Icon(Icons.arrow_back),
      ),
    ),

    body: Padding(
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BookDetailCard(book: b),

          SizedBox(height: 8),

          Text(
            "Holdings (${b.copies.length})",
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
          ),

          SizedBox(height: 8),

          Expanded(
            child: HoldingsList(copies: b.copies),
          )
        ],
      ),
    ),
  );
}

}



class BookDetailCard extends StatelessWidget {
  final BookDetail book;

  const BookDetailCard({super.key, required this.book});

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 14, color: Colors.black87),
          children: [
            TextSpan(
              text: "$label: ",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final available = book.isAvailable;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// TOP SECTION   book title author availability
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  "assets/stats_book_temp.png",
                  height: 160,
                  width: 120,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      book.authors.isNotEmpty
                          ? book.authors.join(", ")
                          : "Unknown author",
                      style: const TextStyle(color: Colors.black54),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      available ? "Available" : "Unavailable",
                      style: TextStyle(
                        color: available ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          /// OPTIONAL FIELDS (ONLY IF PRESENT) -publisher year edition isbn
          if (book.publisher != null && book.publisher!.isNotEmpty)
            _infoRow("Publisher", book.publisher!),

          if (book.publishedYear != null)
            _infoRow("Year", book.publishedYear.toString()),

          if (book.edition != null &&
              book.edition.toString().trim().isNotEmpty)
            _infoRow("Edition", book.edition.toString()),

          if (book.isbn != null && book.isbn!.isNotEmpty)
            _infoRow("ISBN", book.isbn!.join(", ")),

          /// CATEGORIES - like a box
          if (book.categories.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: book.categories
                  .map(
                    (c) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        c,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}
class HoldingsList extends StatelessWidget {
  final List<BookCopy> copies;
  const HoldingsList({super.key, required this.copies});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: copies.length, 
      itemBuilder: (BuildContext context, int index) {
        final copy = copies[index];

        return Container(
          color: Colors.purple.shade50,
          padding: EdgeInsets.all(12),
          margin: EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(copy.branch),
                  Spacer(),
                  Text("SL NO: ${copy.itemId}"),
                ],
              ),
              Text("Call No: ${copy.callNumber ?? 'N/A'}"),
              Text("Status: ${copy.status}"),
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

