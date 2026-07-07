import 'package:flutter/material.dart';
import 'package:library_nitc/auth_provider.dart';
import 'package:library_nitc/authScreen.dart';
import 'package:library_nitc/bookPage.dart';
import 'package:library_nitc/holdsPage.dart';
import 'package:library_nitc/paymentPage.dart';
import 'package:library_nitc/theme/app_colors.dart';
import 'package:library_nitc/user_provider.dart';
import 'package:library_nitc/bookCoverImage.dart';
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
            Icon(Icons.account_circle_outlined, size: 80, color: context.cs.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'Log in to view your profile, borrowed books, and fines.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: context.cs.onSurfaceVariant),
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
                  backgroundColor: context.cs.onSurface,
                  foregroundColor: context.cs.surface,
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
  bool _navigatingToLogin = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile(widget.auth.accessToken);
  }

  @override
  void didUpdateWidget(_ProfileContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldToken = oldWidget.auth.accessToken;
    final newToken = widget.auth.accessToken;
    if (newToken != null && newToken != oldToken) {
      _fetchProfile(newToken);
    }
  }

  void _fetchProfile(String? token) {
    if (token == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().fetchProfile(token, authProvider: widget.auth);
    });
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
          final isSessionExpired = userProvider.profileError!.contains('Session expired');
          if (isSessionExpired) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!_navigatingToLogin && mounted) {
                _navigatingToLogin = true;
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                );
              }
            });
          }
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(userProvider.profileError!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  if (!isSessionExpired)
                    ElevatedButton(
                      onPressed: () {
                        final token = auth.accessToken;
                        if (token != null) {
                          context.read<UserProvider>().fetchProfile(token, authProvider: auth);
                        }
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
              Padding(
                padding: const EdgeInsets.only(left: 30),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
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
                      padding: const EdgeInsets.all(50),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Roll no:', style: TextStyle(fontWeight: FontWeight.w700, color: context.cs.onSurface)),
                          Text(profile?.rollNo ?? auth.rollNo ?? '', style: TextStyle(color: context.cs.onSurface, fontSize:20)),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
                      tileColor: context.cs.surfaceContainerLow,
                      onTap: () async {
                        context.read<UserProvider>().clearUserData();
                        await context.read<AuthProvider>().logout();
                        // Consumer rebuilds automatically -- no navigation needed.
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.monetization_on_outlined),
                      title: const Text("Payment of late dues"),
                      tileColor: context.cs.surfaceContainerLow,
                      onTap: () {
                        pushScreenWithNavBar(context, PaymentPage());
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.monetization_on_outlined),
                      title: const Text('History of late dues'),
                      tileColor: context.cs.surfaceContainerLow,
                      onTap: () {
                        pushScreenWithNavBar(context, PaymentHistoryPage());
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.bookmark_outline),
                      title: const Text('Your Holds'),
                      tileColor: context.cs.surfaceContainerLow,
                      onTap: () {
                        pushScreenWithNavBar(context, HoldsPage());
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
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text('No books currently borrowed.', style: TextStyle(color: context.cs.onSurfaceVariant)),
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
          behavior: HitTestBehavior.translucent,
          onTap: () {
            pushScreenWithNavBar(context, BookPage(biblioId: book.biblioId));
          },
          child: SizedBox(
            height: 196,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: BookCoverImage(
                      coverUrl: book.coverUrl,
                      width: 108,
                      height: 162,
                      fit: BoxFit.fill,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 18,
                            ),
                          ),
                          Text(book.author, maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text("Due: ${book.dueDate}", maxLines: 1, overflow: TextOverflow.ellipsis),
                          const Expanded(child: SizedBox()),
                          Row(
                            children: [
                              _RenewButton(book: book),
                              const Spacer(),
                              const Text("View More"),
                              const Icon(Icons.arrow_right_outlined),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RenewButton extends StatefulWidget {
  final CheckedOutBook book;
  const _RenewButton({required this.book});

  @override
  State<_RenewButton> createState() => _RenewButtonState();
}

class _RenewButtonState extends State<_RenewButton> {
  bool _loading = false;

  String _renewalCountText() {
    final book = widget.book;
    if (book.renewalsAllowed > 0) {
      return "You have ${book.renewalsRemaining} of ${book.renewalsAllowed} renewals remaining.";
    } else if (book.renewalsRemaining > 0) {
      return "You have ${book.renewalsRemaining} renewal${book.renewalsRemaining == 1 ? '' : 's'} remaining.";
    } else {
      return "No renewals remaining.";
    }
  }

  Future<void> _onTap() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Renew book?"),
        content: Text(_renewalCountText()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text("Renew"),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final token = context.read<AuthProvider>().accessToken;
    if (token == null) return;

    setState(() => _loading = true);
    try {
      final result = await context.read<UserProvider>().renewBook(token, widget.book.issueId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not renew. Try again later.")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : OutlinedButton(
            onPressed: _onTap,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text("Renew"),
          );
  }
}
