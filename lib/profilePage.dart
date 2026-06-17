import 'package:flutter/material.dart';
import 'package:library_nitc/auth_provider.dart';
import 'package:library_nitc/authScreen.dart';
import 'package:library_nitc/paymentPage.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Your profile', textAlign: TextAlign.center),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (!auth.isLoggedIn) {
            return _LoginPrompt();
          }
          return _ProfileContent(auth: auth);
        },
      ),
    );
  }
}

class _LoginPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_circle_outlined, size: 80, color: Colors.black26),
            const SizedBox(height: 16),
            const Text(
              'Log in to view your profile, borrowed books, and fines.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('LOGIN', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final AuthProvider auth;
  const _ProfileContent({required this.auth});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          FittedBox(
            child: Row(
              children: [
                Column(
                  children: [
                    SizedBox(
                      height: 120,
                      width: 120,
                      child: ClipOval(child: Image.asset('assets/main_logo.png')),
                    ),
                    Text(
                      auth.name ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 20),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Roll no:', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black87)),
                      Text(auth.rollNo ?? '', style: const TextStyle(color: Colors.black87)),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Logout'),
                  tileColor: Colors.purple.shade50,
                  onTap: () async {
                    await context.read<AuthProvider>().logout();
                    // Consumer rebuilds automatically -- no navigation needed.
                  },
                ),
                ListTile(
                      leading: Icon(Icons.monetization_on_outlined),
                      title: Text("Payment of late dues"),
                      tileColor: Colors.purple.shade50,
                      onTap: () {
                        pushScreenWithNavBar(context, PaymentPage());
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.monetization_on_outlined),
                      title: const Text('History of late dues'),
                      tileColor: Colors.purple.shade50,
                      onTap: () {
                        pushScreenWithNavBar(context, PaymentHistoryPage());
                      },
                    ),
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: BorrowedBooksIndicator(),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Text('Your Books', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    MyBooksList(),
                  ],
                ),
              ),
            ],
          ),
        );
  }
}

class BorrowedBooksIndicator extends StatelessWidget {
  const BorrowedBooksIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      child: Row(
        children: [
          SizedBox(
            height: 97,
            width: 97,
            child: CircularProgressIndicator(
              value: 3/5,
              year2023: false,
              strokeWidth: 8.0,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("You have taken:", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),),
                Text("3 out of 5 books", style: TextStyle(fontSize: 20),)
              ],
            ),
          )
        ],
      ),
    );
  }

}

class MyBooksList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: 7,
      itemBuilder: (BuildContext context, int index) {
        return GestureDetector(
          onTap: () {
            pushScreenWithNavBar(context, BookRenewalPage());
          },
          child: SizedBox(
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
                        Text("Due date:"),
                        Expanded(child: SizedBox()),
                        SizedBox(width: MediaQuery.of(context).size.width -183, // not a fan of this - 183 but eh whatever works
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Spacer(),
                              Text("View More"),
                              Icon(Icons.arrow_right_outlined)
                            ],
                          ),
                        )

                      ],
                    ),
                  ),
                  )

                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class BookRenewalPage extends StatelessWidget {
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
              MyBookDetailCard(),
              SizedBox(height: 8,),
              Text("Your Holding(s)", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),),
              SizedBox(height: 8,),
              Expanded(
                child: MyHoldingsList(),
              )
            ],
          ),
        )
    );
  }
}

class MyBookDetailCard extends StatefulWidget{
  @override
  State<StatefulWidget> createState() => _MyBookDetailCard();
}

class _MyBookDetailCard extends State<MyBookDetailCard>{
  var renewAvailable = true;

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
                    Text("Due date: ", style: TextStyle(fontSize: 14, color: Colors.black54))
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
                  onPressed: renewAvailable ? () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text("Renew?"),
                          content: Text("Number of times you can renew: 0/1"),
                          actions: [
                            TextButton(
                              onPressed: () {Navigator.of(context).pop();},
                              child: Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () {
                                // TODO : do renewal stuff

                                setState(() {
                                  renewAvailable = false;
                                });
                                Navigator.of(context).pop();
                                showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: Text("Renew successful"),
                                        content: Text("Number of times you can renew: 1/1"),
                                        actions: [
                                          TextButton(onPressed: (){Navigator.of(context).pop();}, child: Text("Ok"))
                                        ],
                                      );
                                    },
                                );
                              },
                              child: Text("Renew"),
                            )
                          ],
                        );
                      }
                    );
                  } : null,
                  style: ButtonStyle(
                    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        )
                    ),
                  ),
                  icon: Icon(Icons.redo),
                  label: Text("Renew", style: TextStyle(fontWeight: FontWeight.w500),),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class MyHoldingsList extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 7, // TODO backend
      itemBuilder: (BuildContext context, int index) {
        return Container(
          color: Colors.purple.shade50,
          padding: EdgeInsets.all(12),
          height: 85,
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
              Text("Library | Due date"),
            ],
          ),
        );
      },
    );
  }
}