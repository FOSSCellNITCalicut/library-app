import 'package:flutter/material.dart';

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

  SearchState currentState = SearchState.initial;

  List<String> searchResults = [];

  int selectedFilter = 0;

  final List<String> filters = [
    "All",
    "Books",
    "eBooks",
    "Journals",
  ];

  Future<void> performSearch() async {
    setState(() {
      currentState = SearchState.loading;
    });

    await Future.delayed(
      const Duration(seconds: 2),
    );

    final query = searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      setState(() {
        currentState = SearchState.initial;
      });
      return;
    }

    if (query.contains("python") ||
        query.contains("java") ||
        query.contains("flutter")) {
      searchResults = [
        "Learning Python",
        "Java Programming",
        "Flutter Development",
      ];

      setState(() {
        currentState = SearchState.results;
      });
    } else {
      setState(() {
        currentState = SearchState.empty;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Browse"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Search Bar
            SearchBar(
              controller: searchController,
              leading: const Icon(Icons.search),
              hintText: "Search Books, eBooks...",
              padding: const WidgetStatePropertyAll<EdgeInsets>(
                EdgeInsets.symmetric(horizontal: 16.0),
              ),
              onSubmitted: (value) {
                performSearch();
              },
            ),

            const SizedBox(height: 16),

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

            const SizedBox(height: 24),

            const Text(
              "Browse Books",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: Builder(
                builder: (context) {

                  if (currentState == SearchState.loading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (currentState == SearchState.empty) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 60,
                          ),
                          SizedBox(height: 12),
                          Text(
                            "No books found",
                            style: TextStyle(
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (currentState == SearchState.results) {
                    return ListView.builder(
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: const Icon(Icons.book_outlined),
                            title: Text(searchResults[index]),
                            subtitle: const Text("Mock Search Result"),
                          ),
                        );
                      },
                    );
                  }

                  return ListView.builder(
                    itemCount: 10,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: const Icon(Icons.book_outlined),
                          title: Text("Mock Book ${index + 1}"),
                          subtitle: const Text("Author Name"),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}