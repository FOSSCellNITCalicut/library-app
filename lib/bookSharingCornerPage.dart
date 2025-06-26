import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';

class BookSharingCornerPage extends StatelessWidget {
  const BookSharingCornerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(onPressed: () => Navigator.of(context).pop(), icon: Icon(Icons.arrow_back),),
        title: Column(
          children: [
            Text("Book Sharing Corner"),
            Text("Open Library Initiative", style: TextStyle(fontSize: 10),)
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DonateBooksCard(),
            SizedBox(height: 8,),
            const Text("Latest Donations", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),),
            LatestDonationList()
          ],
        )
      ),
    );
  }
}

class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class DonateBooksCard extends StatelessWidget {
  DonateBooksCard({super.key});

  final BorderRadius _borderRadius = BorderRadius.circular(16);
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.purple.shade50,
      shape: RoundedRectangleBorder(borderRadius: _borderRadius),
      elevation: 1,
      child: Material(
        color: Colors.transparent,
        borderRadius: _borderRadius,
        child: InkWell(
          borderRadius: _borderRadius,
          onTap: () => pushScreenWithNavBar(context, BookDonationScreen()),
          child: Flexible(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.groups_2_outlined, size: 40,),
                  SizedBox(width: 8,),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text("Donate unused books", style: TextStyle(fontSize: 18),),
                        Text("Help build a shared knowledge space", style: TextStyle(fontSize: 12),)
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class BookDonationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(onPressed: () => Navigator.of(context).pop(), icon: Icon(Icons.arrow_back),),
        title: Column(
          children: [
            Text("Book Sharing Corner"),
            Text("Open Library Initiative", style: TextStyle(fontSize: 10),)
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              children: const [
                Text("Every book you donate could become the stepping stone to someone's success.", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),),
                
              ],
            ),
            Wrap(
              children: [
                const Text('''The Open Library initiative at NIT Calicut is a student-friendly space created to foster shared learning and provide free, open access to books for all.
We have been receiving many enquiries from students interested in donating books to the library, and we truly appreciate this spirit of contribution.

We invite you to contribute by voluntarily donating books you  no longer need. Your academic or inspirational books could significantly support and make a meaningful difference in someone’s learning journey.
Donation Guidelines:
• Preferred categories: Textbooks, competitive exam books and self-help books
• Books should be in good, readable condition.
Where to donate: Central Library – Nalanda Digital Library
When: During regular library hours.
Let’s work together to build a shared knowledge space.

Thank you for your generosity and support!''')
              ],
            ), 
            Divider(),
            BookDonationForm()
          ],
        ),
      ),
    );
  }
}

class LatestDonationList extends StatelessWidget {
  const LatestDonationList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: 7, //! TEMPORARY
      itemBuilder: (context, index) {
        return SizedBox(
            height: 178,
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Row(
                children: [
                  Flexible(
                    child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset("assets/stats_book_temp.png"), // TODO build dynamically from search results
                  ),
                  ),
                  Flexible(
                    child:  Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Heading", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 22),),
                        Text("Author"),
                    
                      ],
                    ),
                  ),
                  )

                ],
              ),
            ),
          );
      },
    );
  }
}

class BookDonationForm extends StatefulWidget {
  const BookDonationForm({super.key});

  @override
  State<BookDonationForm> createState() => _BookDonationFormState();
}

class _BookDonationFormState extends State<BookDonationForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _yearController = TextEditingController();

  bool isGoodConditionChecked = false;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              label: Text('Book Title')
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter some text';
              }
              return null;
            },
          ),
          SizedBox(height: 12,),
          TextFormField(
            controller: _authorController,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              label: Text('Author')
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter some text';
              }
              return null;
            },
          ),
          SizedBox(height: 12,),
          TextFormField(
            controller: _yearController,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              label: Text('Year of publication')
            ),
            validator: (value) { // maybe make the validator a bti more strict? 
              if (value == null || value.isEmpty) {
                return 'Please enter a year';
              }
              final int? year = int.tryParse(value);
              if(year == null) {
                return 'Please enter a valid year';
              } 
              return null;
            },
          ),
          SizedBox(height: 12,),
          Row(
            children: [
              Checkbox(
                value: isGoodConditionChecked,
                onChanged: (value) {
                  setState(() {
                    isGoodConditionChecked = value!;
                  });
                },
              ),
              Text("The book is in good and readable condition")
            ],
          ),
          SizedBox(height: 12,),
          FilledButton.icon(
            onPressed: isGoodConditionChecked ? () {
              if(_formKey.currentState!.validate()) {
                //TODO send data to backend
              }
            } : null,
            label: Text("Submit"),
            icon: Icon(Icons.send_outlined),
          )
        ],
      ),
    );
  }
}