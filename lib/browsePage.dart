import 'package:flutter/material.dart';
import 'package:library_nitc/homePage.dart';

enum SearchState {
  initial,
  loading,
  results,
  empty,
}

class BrowsePage extends StatefulWidget {
  const BrowsePage({super.key});

  @override
  State<BrowsePage> createState() => _BrowsePageState();
}

class _BrowsePageState extends State<BrowsePage> {
  final SearchController searchController = SearchController();
  final FocusNode focusNode = FocusNode();

  SearchState currentState = SearchState.initial;

  int selectedFilter = 0;

  final List<String> filters = [
    "All",
    "Books",
    "eBooks",
    "Journals",
  ];

  @override
  void initState() {
    super.initState();
    focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    focusNode.removeListener(_onFocusChange);
    focusNode.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {});
  }

// future API integration
Future<List<int>> searchBooks(String searchTerm) async {
  // Future API request:
  // GET /opac-search.pl?q=<searchTerm>&format=rss2

  await Future.delayed(const Duration(seconds: 1));

  // Mock results for now (same 7 hardcoded books)
  return List.generate(7, (index) => index);
}

Future<void> performSearch() async {
  final query = searchController.text.trim();

  if (query.isEmpty) {
    setState(() {
      currentState = SearchState.initial;
    });
    return;
  }

  setState(() {
    currentState = SearchState.loading;
  });

  final results = await searchBooks(query);

  setState(() {
    currentState =
        results.isNotEmpty ? SearchState.results : SearchState.empty;
  });
}

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final keyboardIsOpen = focusNode.hasFocus;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text("Browse"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),

      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          focusNode.unfocus();
        },
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: isLandscape ? 8 : 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Search Bar + AI Button
              SearchBar(
                controller: searchController,
                focusNode: focusNode,
                leading: const Icon(Icons.search),
                hintText: "Search Books, eBooks...",
                padding: const WidgetStatePropertyAll<EdgeInsets>(
                  EdgeInsets.symmetric(horizontal: 16.0),
                ),
                trailing: [
                  IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("AI Search coming soon!"),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.auto_awesome,
                      color: Color(0xFF6A1B9A),
                    ),
                  ),
                ],
                onSubmitted: (value) {
                  performSearch();
                },
              ),

            if (!isLandscape || !keyboardIsOpen) ...[
              SizedBox(height: isLandscape ? 8 : 16),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(
                    filters.length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(filters[index]),
                        selected: selectedFilter == index,
                        onSelected: (value) {
                          setState(() {
                            selectedFilter = index;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],

            SizedBox(height: (isLandscape && keyboardIsOpen) ? 4 : (isLandscape ? 12 : 24)),

            if (!isLandscape) ...[
              const Text(
                "Browse Books",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
            ],

            Expanded(
              child: Builder(
                builder: (context) {

                  if (currentState == SearchState.loading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (currentState == SearchState.empty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/empty.png',
                            height: 200,
                          ),

                          Transform.translate(
                            offset: const Offset(0, -20),
                            child: const Column(
                              children: [
                                Text(
                                  "No books found",
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                SizedBox(height: 4),

                                Text(
                                  "Try another search",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (currentState == SearchState.results) {
                    return SearchResults(
                      query: searchController.text.trim(),
                      keyboardIsOpen: keyboardIsOpen,
                    );
                  }

                  // initial state — nothing searched yet
                  return const Center(
                    child: Text(
                      'Search for books above',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}