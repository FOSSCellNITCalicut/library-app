import 'dart:async';

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

class _BrowsePageState extends State<BrowsePage> with SingleTickerProviderStateMixin {
  final TextEditingController searchController = TextEditingController();
  final FocusNode focusNode = FocusNode();

  SearchState currentState = SearchState.initial;

  int selectedFilter = 0;

  final List<String> filters = [
    "All",
    "Books",
    "eBooks",
    "Journals",
  ];

  late AnimationController _hintAnimController;

  int _currentHintIndex = 0;
  final List<String> _hints = [
    "Search Books, eBooks...",
    "Try 'Machine Learning'...",
    "Search by author...",
    "Search by ISBN...",
  ];

  Timer? _hintTimer;
  Timer? _debounceTimer;

  final List<String> _recentSearches = [];
  final List<String> _suggestions = [
    "Machine Learning",
    "Data Science",
    "Python Programming",
    "Artificial Intelligence",
    "Computer Networks",
    "Database Systems",
    "Operating Systems",
    "Algorithms",
  ];

  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();

    _hintAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    focusNode.addListener(_onFocusChange);
    searchController.addListener(_onSearchTextChanged);

    _startHintCycling();

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _debounceTimer?.cancel();
    _hintAnimController.dispose();
    focusNode.removeListener(_onFocusChange);
    searchController.removeListener(_onSearchTextChanged);
    focusNode.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _onSearchTextChanged() {
    setState(() => _showSuggestions = searchController.text.isNotEmpty && !focusNode.hasFocus);

    _debounceTimer?.cancel();
    final query = searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        currentState = SearchState.initial;
        _showSuggestions = false;
      });
      return;
    }
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      performSearch();
    });
  }

  void _onFocusChange() {
    setState(() {
      _showSuggestions = focusNode.hasFocus && searchController.text.isNotEmpty;
    });
  }

  void _selectSuggestion(String suggestion) {
    searchController.text = suggestion;
    searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: suggestion.length),
    );
    setState(() => _showSuggestions = false);
    if (!_recentSearches.contains(suggestion)) {
      _recentSearches.insert(0, suggestion);
      if (_recentSearches.length > 5) _recentSearches.removeLast();
    }
    performSearch();
  }

  List<String> _filteredSuggestions() {
    final query = searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _recentSearches.isNotEmpty ? _recentSearches : [];
    return _suggestions
        .where((s) => s.toLowerCase().contains(query))
        .take(5)
        .toList();
  }

  void _startHintCycling() {
    _hintTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!focusNode.hasFocus && searchController.text.isEmpty) {
        _hintAnimController.forward().then((_) {
          setState(() {
            _currentHintIndex = (_currentHintIndex + 1) % _hints.length;
          });
          _hintAnimController.reverse();
        });
      }
    });
  }

// future API integration
Future<List<int>> searchBooks(String searchTerm) async {
  await Future.delayed(const Duration(seconds: 1));
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
    _showSuggestions = false;
  });

  final results = await searchBooks(query);

  setState(() {
    currentState =
        results.isNotEmpty ? SearchState.results : SearchState.empty;
  });
}

  @override
  Widget build(BuildContext context) {
    final suggestions = _filteredSuggestions();

    return Scaffold(
      body: SafeArea(
        child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(
          children: [

            // Search Bar
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                color: focusNode.hasFocus
                    ? Theme.of(context).colorScheme.surfaceContainerHighest
                    : Theme.of(context).colorScheme.surfaceContainerLow,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: focusNode.hasFocus ? 0.12 : 0.08),
                    blurRadius: focusNode.hasFocus ? 16 : 8,
                    offset: Offset(0, focusNode.hasFocus ? 4 : 2),
                  ),
                ],
              ),
              child: TextField(
                controller: searchController,
                focusNode: focusNode,
                onSubmitted: (value) => performSearch(),
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: _hints[_currentHintIndex],
                  hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 16,
                  ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 4, right: 4),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => Navigator.of(context).pop(),
                            color: focusNode.hasFocus
                                ? const Color(0xFF6A1B9A)
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        child: searchController.text.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  searchController.clear();
                                  setState(() {
                                    currentState = SearchState.initial;
                                    _showSuggestions = false;
                                  });
                                  focusNode.requestFocus();
                                },
                                icon: Icon(
                                  Icons.close,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      IconButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("AI Search coming soon!")),
                          );
                        },
                        icon: const Icon(Icons.auto_awesome, color: Color(0xFF6A1B9A)),
                      ),
                    ],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: const BorderSide(color: Color(0xFF6A1B9A), width: 2),
                  ),
                  filled: true,
                  fillColor: focusNode.hasFocus
                      ? Theme.of(context).colorScheme.surfaceContainerHighest
                      : Theme.of(context).colorScheme.surfaceContainerLow,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),

            // Suggestions dropdown
            if (_showSuggestions && suggestions.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_recentSearches.isNotEmpty && searchController.text.trim().isEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Row(
                          children: [
                            Icon(Icons.history, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                            const SizedBox(width: 8),
                            Text("Recent", style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            )),
                          ],
                        ),
                      ),
                    ...suggestions.map((s) => ListTile(
                      dense: true,
                      leading: Icon(
                        _recentSearches.contains(s) ? Icons.history : Icons.search,
                        size: 20,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      title: Text(s, style: const TextStyle(fontSize: 14)),
                      onTap: () => _selectSuggestion(s),
                    )),
                  ],
                ),
              ),

            const SizedBox(height: 12),

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
                      onSelected: (value) => setState(() => selectedFilter = index),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: Builder(
                builder: (context) {

                  if (currentState == SearchState.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (currentState == SearchState.empty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset('assets/empty.png', height: 200),
                          Transform.translate(
                            offset: const Offset(0, -20),
                            child: const Column(
                              children: [
                                Text("No books found", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                                SizedBox(height: 4),
                                Text("Try another search", style: TextStyle(color: Colors.grey, fontSize: 16)),
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
                    );
                  }

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
