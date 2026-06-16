import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:library_nitc/bookPage.dart';
import 'package:library_nitc/bookSharingCornerPage.dart';
import 'package:library_nitc/models/book_summary.dart';
import 'package:library_nitc/notifPage.dart';
import 'package:library_nitc/services/book_service.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import 'package:library_nitc/browsePage.dart';
import 'package:library_nitc/browsePage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.all(12.0), child: HomeHeader()),
            Padding(padding: EdgeInsets.all(12.0), child: BookSharingCard()),
            Padding(padding: EdgeInsets.all(12), child: StatWidget()),
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                "New Arrivals",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                textAlign: TextAlign.start,
              ),
            ),
            Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(height: 250, child: BrowseCatalog()),
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
              padding: EdgeInsets.all(12),
              child: SizedBox(height: 250, child: HorizontalBookScroll()),
            ),
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

class StatWidget extends StatefulWidget {
  const StatWidget({super.key});

  @override
  State<StatefulWidget> createState() => _StatWidgetState();
}

class _StatWidgetState extends State<StatWidget> {
  @override
  Widget build(BuildContext context) {
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
                "You have taken 3 out of 5 books",
                style: TextStyle(fontSize: 14),
              ), // TODO : get from backend
              SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: 0.6, // TODO : process value from backend
                  minHeight: 8,
                  backgroundColor: Colors.purple.shade100,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                ),
              ),

              SizedBox(height: 16),
              Text(
                "You have to return",
                style: TextStyle(color: Colors.grey[700]),
              ),
              SizedBox(height: 4),
              Text(
                "Book 1", // TODO : data from backend
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 8),
              Text("due date", style: TextStyle(color: Colors.grey.shade700)),
              SizedBox(height: 12),
              Align(
                alignment: Alignment.bottomRight,
                child: TextButton(
                  onPressed: () {
                    // TODO : implement renew
                  },
                  child: Text("Renew", style: TextStyle(color: Colors.purple)),
                ),
              ),
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
  const HorizontalBookScroll({
    super.key,
  }); // TODO : add argument to take data from backend

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      // TODO : rewrite function to use backend data
      padding: EdgeInsets.zero,
      scrollDirection: Axis.horizontal,
      itemCount: 7,
      itemBuilder: (BuildContext context, int index) {
        return SizedBox(
          height: 120, // idk what changes this height value does
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
                      height: 201,
                      fit: BoxFit.fill,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Book $index",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
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
                    child: Image.asset(
                      'assets/stats_book_temp.png',
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
  const SearchResults({required this.query, super.key});

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            'Searched $_total results',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
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
          Expanded(
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
                            child: Image.asset('assets/stats_book_temp.png'),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  book.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 22,
                                  ),
                                ),
                                Text(
                                  book.authors.isNotEmpty
                                      ? book.authors[0]
                                      : '',
                                ),
                                const Expanded(child: SizedBox()),
                                SizedBox(
                                  width: MediaQuery.sizeOf(context).width - 183,
                                  child: Row(
                                    children: [
                                      Text(
                                        book.availableCopies > 0
                                            ? 'Available'
                                            : 'Unavailable',
                                        style: TextStyle(
                                          color:
                                              book.availableCopies > 0
                                                  ? Colors.green
                                                  : Colors.red,
                                        ),
                                      ),
                                      const Spacer(),
                                      const Text('View More'),
                                    ],
                                  ),
                                ),
                              ],
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
