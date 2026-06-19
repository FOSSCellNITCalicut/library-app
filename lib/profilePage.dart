import 'package:flutter/material.dart';
import 'package:library_nitc/auth_provider.dart';
import 'package:library_nitc/authScreen.dart';
import 'package:library_nitc/bookPage.dart';
import 'package:library_nitc/paymentPage.dart';
import 'package:library_nitc/user_provider.dart';
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

class _ProfileContent extends StatefulWidget {
  final AuthProvider auth;
  const _ProfileContent({required this.auth});

  @override
  State<_ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends State<_ProfileContent> {
  @override
  void initState() {
    super.initState();
    final token = widget.auth.accessToken;
    if (token != null) {
      context.read<UserProvider>().fetchProfile(token);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = widget.auth;

    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        final profile = userProvider.profile;

        if (userProvider.profileLoading && profile == null) {
          return const Padding(
            padding: EdgeInsets.all(48),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (userProvider.profileError != null && profile == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(userProvider.profileError!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      final token = auth.accessToken;
                      if (token != null) context.read<UserProvider>().fetchProfile(token);
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

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
                          profile?.name ?? auth.name ?? '',
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
                          Text(profile?.rollNo ?? auth.rollNo ?? '', style: const TextStyle(color: Colors.black87)),
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
                      leading: const Icon(Icons.monetization_on_outlined),
                      title: const Text("Payment of late dues"),
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
                    if (profile != null) ...[
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: BorrowedBooksIndicator(loanSummary: profile.loanSummary),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Text('Your Books', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      MyBooksList(books: profile.checkedOutBooks),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class BorrowedBooksIndicator extends StatelessWidget {
  final LoanSummary loanSummary;
  const BorrowedBooksIndicator({super.key, required this.loanSummary});

  @override
  Widget build(BuildContext context) {
    final ratio = loanSummary.loanLimit > 0
        ? (loanSummary.loanCount / loanSummary.loanLimit).clamp(0.0, 1.0)
        : 0.0;

    return FittedBox(
      child: Row(
        children: [
          SizedBox(
            height: 97,
            width: 97,
            child: CircularProgressIndicator(
              value: ratio.toDouble(),
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
                const Text("You have taken:", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                Text(
                  "${loanSummary.loanCount} out of ${loanSummary.loanLimit} books",
                  style: TextStyle(fontSize: 20),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class MyBooksList extends StatelessWidget {
  final List<CheckedOutBook> books;
  const MyBooksList({super.key, required this.books});

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text('No books currently borrowed.', style: TextStyle(color: Colors.black54)),
        ),
      );
    }

    return ListView.builder(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: books.length,
      itemBuilder: (BuildContext context, int index) {
        final book = books[index];
        return GestureDetector(
          onTap: () {
            pushScreenWithNavBar(context, BookPage(biblioId: book.biblioId));
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
                      child: Image.asset("assets/stats_book_temp.png"),
                    ),
                  ),
                  Flexible(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book.title,
                            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 22),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(book.author, maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text("Due date: ${book.dueDate}"),
                          Expanded(child: SizedBox()),
                          SizedBox(
                            width: MediaQuery.of(context).size.width - 183, // not a fan of this - 183 but eh whatever works
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
