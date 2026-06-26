import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:library_nitc/bookPage.dart';
import 'package:library_nitc/bookSharingCornerPage.dart';
import 'package:library_nitc/auth_provider.dart';
import 'package:library_nitc/models/book_summary.dart';
import 'package:library_nitc/models/daily_quote.dart';
import 'package:library_nitc/models/new_arrival.dart';
import 'package:library_nitc/notifPage.dart';
import 'package:library_nitc/services/book_service.dart';
import 'package:library_nitc/services/opac_home_service.dart';
import 'package:library_nitc/user_provider.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import 'package:provider/provider.dart';
import 'package:library_nitc/browsePage.dart';
import 'package:library_nitc/bookCoverImage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _opacService = OpacHomeService();
  OpacHomeData? _opacData;
  bool _opacLoading = true;
  String? _opacError;

  @override
  void initState() {
    super.initState();
    _fetchOpacData();
  }

  Future<void> _fetchOpacData() async {
    setState(() {
      _opacLoading = true;
      _opacError = null;
    });
    try {
      final data = await _opacService.fetchHomeData();
      setState(() {
        _opacData = data;
        _opacLoading = false;
      });
    } catch (e) {
      setState(() {
        _opacError = e.toString();
        _opacLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userProvider = context.watch<UserProvider>();
    final loggedIn = auth.isLoggedIn;

    if (loggedIn && userProvider.profile == null && !userProvider.profileLoading) {
      final token = auth.accessToken;
      if (token != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<UserProvider>().fetchProfile(token);
        });
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.all(12.0), child: HomeHeader()),
            _buildTopOpacSections(),
            Padding(padding: EdgeInsets.all(12.0), child: BookSharingCard()),
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                "New Arrivals",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                textAlign: TextAlign.start,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 12, bottom: 12),
              child: SizedBox(height: 250, child: OpacNewArrivals(data: _opacData?.newArrivals ?? [], loading: _opacLoading)),
            ),
            if (loggedIn) ...[
              Padding(
                padding: EdgeInsets.all(12),
                child: StatWidget(
                  loanSummary: userProvider.profile?.loanSummary,
                  checkedOutBooks: userProvider.profile?.checkedOutBooks,
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  "Your Items",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.start,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 12, bottom: 12),
                child: SizedBox(
                  height: 250,
                  child: HorizontalBookScroll(
                    checkedOutBooks: userProvider.profile?.checkedOutBooks,
                  ),
                ),
              ),
            ],

          ],
        ),
      ),
    );
  }

  Widget _buildTopOpacSections() {
    if (_opacLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          children: [
            _buildSkeletonCard(120),
            SizedBox(height: 12),
            _buildSkeletonCard(100),
            SizedBox(height: 12),
            _buildSkeletonCard(160),
          ],
        ),
      );
    }

    if (_opacError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Card(
          color: Colors.purple.shade50,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(child: Text('Could not load library info', style: TextStyle(color: Colors.grey[700]))),
                TextButton(
                  onPressed: _fetchOpacData,
                  child: Text('Retry', style: TextStyle(color: Colors.purple)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final data = _opacData!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (data.quote != null)
          Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: _QuoteCard(quote: data.quote!)),
        SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSkeletonCard(double height) {
    return Card(
      color: Colors.purple.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        height: height,
        width: double.infinity,
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 14, width: 120, decoration: BoxDecoration(color: Colors.purple.shade100, borderRadius: BorderRadius.circular(4))),
            SizedBox(height: 12),
            Container(height: 12, width: double.infinity, decoration: BoxDecoration(color: Colors.purple.shade100, borderRadius: BorderRadius.circular(4))),
            SizedBox(height: 8),
            Container(height: 12, width: 180, decoration: BoxDecoration(color: Colors.purple.shade100, borderRadius: BorderRadius.circular(4))),
          ],
        ),
      ),
    );
  }
}

class BookSharingCard extends StatelessWidget {
  BookSharingCard({super.key});

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
          onTap: () => pushScreenWithNavBar(context, BookSharingCornerPage()),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        "Book sharing center",
                        style: TextStyle(fontSize: 20),
                      ),
                      SizedBox(height: 8),
                      Text("Explore now", style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/book_sharing.jpg',
                    height: 80,
                    width: 80,
                    fit: BoxFit.fitHeight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            "NITC Library",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF6A1B9A),
            ),
          ),
        ),
        IconButton(
          onPressed: () {
            pushScreenWithNavBar(context, const Notifpage());
          },
          icon: const Icon(Icons.notifications_none_outlined, size: 28),
        ),
        IconButton(
          onPressed: () {
            pushScreenWithNavBar(context, const BrowsePage());
          },
          icon: const Icon(Icons.search, size: 28),
        ),
      ],
    );
  }
}

class MainSearchBar extends StatelessWidget {
  const MainSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SearchAnchor(
      builder: (BuildContext context, SearchController controller) {
        return SearchBar(
          controller: controller,
          leading: const Icon(Icons.search),
          hintText: "Search Books, eBooks...",
          padding: const WidgetStatePropertyAll<EdgeInsets>(
            EdgeInsets.symmetric(horizontal: 16.0),
          ),

          //navigate to browse page
          onTap: () {
            pushScreenWithNavBar(context, const BrowsePage());
          },

          trailing: <Widget>[
            IconButton(
              onPressed: () {
                pushScreenWithNavBar(context, Notifpage());
              },
              icon: Icon(Icons.notifications_none_outlined),
            ),
          ],
        );
      },
      suggestionsBuilder:
          (context, controller) => [], // Doesnt look like proper usage
    );
  }
}

class StatWidget extends StatelessWidget {
  final LoanSummary? loanSummary;
  final List<CheckedOutBook>? checkedOutBooks;

  const StatWidget({super.key, this.loanSummary, this.checkedOutBooks});

  @override
  Widget build(BuildContext context) {
    final count = loanSummary?.loanCount ?? 0;
    final limit = loanSummary?.loanLimit ?? 0;
    final progress = limit > 0 ? count / limit : 0.0;
    final firstBook = checkedOutBooks?.isNotEmpty == true ? checkedOutBooks!.first : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Your stats:",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "You have taken $count out of $limit books",
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.purple.shade100,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                ),
              ),
              SizedBox(height: 16),
              Text(
                firstBook != null ? "You have to return" : "No books checked out",
                style: TextStyle(color: Colors.grey[700]),
              ),
              if (firstBook != null) ...[
                SizedBox(height: 4),
                Text(
                  firstBook.title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 8),
                Text(
                  firstBook.dueDate,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                SizedBox(height: 12),
                Align(
                  alignment: Alignment.bottomRight,
                  child: TextButton(
                    onPressed: () {
                      pushWithNavBar(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookPage(biblioId: firstBook.biblioId),
                        ),
                      );
                    },
                    child: Text("View", style: TextStyle(color: Colors.purple)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class BookSearchDelegate extends SearchDelegate<String> {
  final List<String> searchList = [
    "abc",
    "def",
    "hij",
    "lmn",
  ]; // TODO: Replace this list with actual search terms

  @override
  List<Widget>? buildActions(BuildContext context) {
    // Clear Button
    return [
      IconButton(
        onPressed: () {
          query = '';
        },
        icon: Icon(Icons.clear),
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    // Back button
    return IconButton(
      onPressed: () => Navigator.of(context).pop(),
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.all(4), child: BookJournalToggle()),
          Expanded(child: SearchResults(query: query)),
        ],
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // TODO: implement buildSuggestions
    final List<String> suggestionList =
        query.isEmpty
            ? []
            : searchList
                .where(
                  (item) => item.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();

    return ListView.builder(
      itemCount: suggestionList.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(suggestionList[index]),
          onTap: () {
            query = suggestionList[index];
            // Show the search results based on the selected suggestion.
            close(context, query);
          },
        );
      },
    );
  }
}

class HorizontalBookScroll extends StatelessWidget {
  final List<CheckedOutBook>? checkedOutBooks;

  const HorizontalBookScroll({super.key, this.checkedOutBooks});

  @override
  Widget build(BuildContext context) {
    final books = checkedOutBooks ?? [];

    if (books.isEmpty) {
      return Center(
        child: Text(
          "No items checked out",
          style: TextStyle(color: Colors.grey[500], fontSize: 14),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      scrollDirection: Axis.horizontal,
      itemCount: books.length,
      itemBuilder: (BuildContext context, int index) {
        final book = books[index];
        return GestureDetector(
          onTap: () {
            pushWithNavBar(
              context,
              MaterialPageRoute(
                builder: (_) => BookPage(biblioId: book.biblioId),
              ),
            );
          },
          child: SizedBox(
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 0,
              color: Theme.of(context).canvasColor,
              child: Container(
                width: 145,
                padding: EdgeInsets.zero,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.asset(
                        "assets/stats_book_temp.png",
                        width: 145,
                        height: 160,
                        fit: BoxFit.fill,
                      ),
                    ),
                    SizedBox(height: 8),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        book.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      book.dueDate,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class BookJournalToggle extends StatefulWidget {
  const BookJournalToggle({super.key});

  @override
  _BookJournalToggleState createState() => _BookJournalToggleState();
}

class _BookJournalToggleState extends State<BookJournalToggle> {
  bool isBooksSelected = true;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      child: Container(
        padding: EdgeInsets.zero,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400, width: 2),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Books | eBooks
            GestureDetector(
              onTap: () => setState(() => isBooksSelected = true),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  color:
                      isBooksSelected ? Colors.purple[100] : Colors.transparent,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    bottomLeft: Radius.circular(30),
                  ),
                ),
                child: Row(
                  children: [
                    if (isBooksSelected)
                      Icon(Icons.check, size: 16, color: Colors.black),
                    if (isBooksSelected) SizedBox(width: 4),
                    Text(
                      'Books | eBooks',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // E-Journals
            GestureDetector(
              onTap: () => setState(() => isBooksSelected = false),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  color:
                      !isBooksSelected
                          ? Colors.purple[100]
                          : Colors.transparent,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Row(
                  children: [
                    if (!isBooksSelected)
                      Icon(Icons.check, size: 16, color: Colors.black),
                    if (!isBooksSelected) SizedBox(width: 4),
                    Text(
                      'E-Journals',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  final DailyQuote quote;
  const _QuoteCard({required this.quote});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.purple.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 5, color: Colors.purple.shade300),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(14, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.format_quote, color: Colors.purple, size: 18),
                        SizedBox(width: 6),
                        Text(
                          "Quote of the day",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.purple.shade400,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      "\u201C${quote.text}\u201D",
                      style: TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: Colors.black87,
                        height: 1.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    if (quote.source != null) ...[
                      SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 16,
                              height: 1,
                              color: Colors.purple.shade300,
                            ),
                            SizedBox(width: 8),
                            Text(
                              quote.source!,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.purple.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OpacNewArrivals extends StatelessWidget {
  final List<NewArrival> data;
  final bool loading;

  const OpacNewArrivals({super.key, required this.data, required this.loading});

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return ListView(
        scrollDirection: Axis.horizontal,
        children: List.generate(6, (_) => const SkeletonCard()),
      );
    }
    if (data.isEmpty) {
      return const Center(child: Text('No new arrivals'));
    }
    return ListView.builder(
      padding: EdgeInsets.zero,
      scrollDirection: Axis.horizontal,
      itemCount: data.length,
      itemBuilder: (context, index) {
        final book = data[index];
        return GestureDetector(
          onTap: () => pushWithNavBar(
            context,
            MaterialPageRoute(builder: (_) => BookPage(biblioId: book.biblioId)),
          ),
          child: SizedBox(
            width: 145,
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 0,
              color: Theme.of(context).canvasColor,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: SizedBox(
                      width: 145,
                      height: 185,
                      child: book.coverUrl != null
                          ? Image.network(
                              book.coverUrl!,
                              width: 145,
                              height: 185,
                              fit: BoxFit.fill,
                              errorBuilder: (_, __, ___) => Image.asset(
                                'assets/stats_book_temp.png',
                                fit: BoxFit.fill,
                              ),
                            )
                          : Image.asset(
                              'assets/stats_book_temp.png',
                              fit: BoxFit.fill,
                            ),
                    ),
                  ),
                  SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      book.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                    ),
                  ),
                  SizedBox(height: 4),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 145,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 0,
        color: Theme.of(context).canvasColor,
        child: Opacity(
          opacity: 0.35,
          child: Image.asset(
            'assets/stats_book_temp.png',
            width: 145,
            height: 185,
            fit: BoxFit.fill,
          ),
        ),
      ),
    );
  }
}

class BrowseCatalog extends StatefulWidget {
  const BrowseCatalog({super.key});

  @override
  State<BrowseCatalog> createState() => _BrowseCatalogState();
}

class _BrowseCatalogState extends State<BrowseCatalog> {
  final _service = BookService();
  final _scrollController = ScrollController();
  final List<BookSummary> _books = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _isFetchingMore = false;
  bool _hasMore = true;
  String? _error;
  static const _perPage = 20;

  @override
  void initState() {
    super.initState();
    _fetchPage(1);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent * 0.7 &&
        !_isFetchingMore &&
        _hasMore &&
        _error == null) {
      _fetchPage(_currentPage + 1);
    }
  }

  Future<void> _fetchPage(int page) async {
    if (page == 1) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    } else {
      setState(() {
        _isFetchingMore = true;
        _error = null;
      });
    }
    try {
      final response = await _service.fetchBrowse(page, _perPage);
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final items =
          (decoded['items'] as List)
              .map((e) => BookSummary.fromJson(e as Map<String, dynamic>))
              .toList();
      setState(() {
        _books.addAll(items);
        _currentPage = page;
        if (items.length < _perPage) _hasMore = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
        _isFetchingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _books.isEmpty) {
      return ListView(
        scrollDirection: Axis.horizontal,
        children: List.generate(6, (_) => const SkeletonCard()),
      );
    }
    if (_books.isEmpty && !_isLoading && _error == null) {
      return const Center(child: Text('No books available'));
    }
    if (_error != null && _books.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error'),
            TextButton(
              onPressed: () => _fetchPage(1),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    final itemCount =
        _books.length + (_isFetchingMore ? 1 : 0) + (_error != null ? 1 : 0);
    return ListView.builder(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index == _books.length && _isFetchingMore) {
          return const SizedBox(
            width: 80,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (index == _books.length && _error != null) {
          return SizedBox(
            width: 160,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error', style: const TextStyle(fontSize: 12)),
                TextButton(
                  onPressed: () => _fetchPage(_currentPage + 1),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        final book = _books[index];
        return GestureDetector(
          onTap:
              () => pushWithNavBar(
                context,
                MaterialPageRoute(
                  builder: (_) => BookPage(biblioId: book.biblioId),
                ),
              ),
          child: SizedBox(
            width: 145,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 0,
              color: Theme.of(context).canvasColor,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(15),
                    ),
                    child: BookCoverImage(
                      coverUrl: book.coverUrl,
                      width: 145,
                      height: 185,
                      fit: BoxFit.fill,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      book.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class SearchResults extends StatefulWidget {
  final String query;
  final bool keyboardIsOpen;
  const SearchResults({required this.query, this.keyboardIsOpen = false, super.key});

  @override
  State<SearchResults> createState() => _SearchResultsState();
}

class _SearchResultsState extends State<SearchResults> {
  final _service = BookService();
  final _scrollController = ScrollController();
  final List<BookSummary> _books = [];
  int _currentPage = 1;
  int _total = 0;
  bool _isLoading = false;
  bool _isFetchingMore = false;
  bool _hasMore = true;
  String? _error;
  static const _perPage = 20;

  @override
  void initState() {
    super.initState();
    _fetchPage(1);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent * 0.7 &&
        !_isFetchingMore &&
        _hasMore &&
        _error == null) {
      _fetchPage(_currentPage + 1);
    }
  }

  Future<void> _fetchPage(int page) async {
    if (page == 1) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    } else {
      setState(() {
        _isFetchingMore = true;
        _error = null;
      });
    }
    try {
      final response = await _service.fetchSearch(widget.query, page, _perPage);
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final items =
          (decoded['items'] as List)
              .map((e) => BookSummary.fromJson(e as Map<String, dynamic>))
              .toList();
      final total = decoded['total'] as int? ?? _total;
      setState(() {
        if (page == 1) _books.clear();
        _books.addAll(items);
        _total = total;
        _currentPage = page;
        if (items.length < _perPage) _hasMore = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
        _isFetchingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final keyboardIsOpen = widget.keyboardIsOpen;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isLandscape || !keyboardIsOpen)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: isLandscape ? 4 : 12,
            ),
            child: Text(
              'Searched $_total results',
              style: TextStyle(
                fontSize: isLandscape ? 16 : 22,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        if (_isLoading && _books.isEmpty)
          const Center(child: CircularProgressIndicator()),
        if (_books.isEmpty && !_isLoading && _error == null)
          const Center(child: Text('No results found')),
        if (_error != null && _books.isEmpty)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: $_error'),
                TextButton(
                  onPressed: () => _fetchPage(1),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        if (_books.isNotEmpty || _isFetchingMore)
          Flexible(
            child: ListView.builder(
              controller: _scrollController,
              itemCount:
                  _books.length +
                  (_isFetchingMore ? 1 : 0) +
                  (_error != null ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _books.length && _isFetchingMore) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (index == _books.length && _error != null) {
                  return Column(
                    children: [
                      Text('Error: $_error'),
                      TextButton(
                        onPressed: () => _fetchPage(_currentPage + 1),
                        child: const Text('Retry'),
                      ),
                    ],
                  );
                }
                final book = _books[index];
                return GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    pushWithNavBar(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookPage(biblioId: book.biblioId),
                      ),
                    );
                  },
                  child: SizedBox(
                    height: 178,
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
                                  Text(book.authors.isNotEmpty ? book.authors[0] : ''),
                                  const Expanded(child: SizedBox()),
                                  Row(
                                    children: [
                                      Text(
                                        book.availableCopies > 0
                                            ? 'Available'
                                            : 'Unavailable',
                                        style: TextStyle(
                                          color: book.availableCopies > 0
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ),
                                      const Spacer(),
                                      const Text('View More'),
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
            ),
          ),
      ],
    );
  }
}