import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class HomePage extends StatefulWidget{
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: MainSearchBar(),

          ),
          Padding(
              padding: EdgeInsets.all(12.0),
            child: Card(
              color: Colors.deepPurple.shade50,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)
              ),
              elevation: 1,
              child: Container(
                height: 100,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            "Book sharing center",
                            style: TextStyle(
                              fontSize: 20,
                            ),
                          ),
                          SizedBox(height: 8,),
                          Text(
                            "Explore now",
                            style: TextStyle(
                                fontSize: 16
                            ),
                          )
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
                        )
                    )
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(12),
            child: StatWidget(),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Text("New Arrivals", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500), textAlign: TextAlign.start,),
          ),
          Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox(
              height: 250,
              child: HorizontalBookScroll()
            )
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Text("Your Items", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500), textAlign: TextAlign.start,),
          ),
          Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                  height: 250,
                  child: HorizontalBookScroll()
              )
          ),
        ],
      ),
    );
  }
}

class MainSearchBar extends StatelessWidget {
  const MainSearchBar({
    super.key,
  });

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
          onTap: () {
            showSearch(context: context, delegate: BookSearchDelegate());
          },
          trailing: <Widget>[
            IconButton(
              onPressed: () {
                // TODO : implement notification
              },
              icon: Icon(Icons.notifications_none_outlined),
            )
          ],
        );
    
      },
      suggestionsBuilder: (context, controller) => [], // Doesnt look like proper usage
    );
  }
}

class StatWidget extends StatefulWidget {
  const StatWidget({super.key});

  @override
  State<StatefulWidget> createState() => _StatWidgetState();

}

class _StatWidgetState extends State<StatWidget>{
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 262,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Your stats:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),),
          SizedBox(height: 16,),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius: BorderRadius.circular(16)
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("You have taken 3 out of 5 books", style: TextStyle(fontSize: 14),), // TODO : get from backend
                SizedBox(height: 8,),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: 0.6, // TODO : process value from backend
                    minHeight: 8,
                    backgroundColor: Colors.deepPurple.shade100,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                  ),
                ),

                SizedBox(height: 16,),
                Text("You have to return",
                  style: TextStyle(color: Colors.grey[700]),
                ),
                SizedBox(height: 4,),
                Text("Book 1", // TODO : data from backend
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 8,),
                Text("due date", style: TextStyle(color: Colors.grey.shade700),),
                SizedBox(height: 12,),
                Align(
                  alignment: Alignment.bottomRight,
                  child: TextButton(
                    onPressed: () {
                      // TODO : implement renew
                    },
                    child: Text("Renew",
                    style: TextStyle(color: Colors.deepPurple),
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

}

class BookSearchDelegate extends SearchDelegate<String> {
  final List<String> searchList = [
    "abc", "def", "hij", "lmn"
  ]; // TODO: Replace this list with actual search history

  @override
  List<Widget>? buildActions(BuildContext context) {
    // Clear Button
    return [
      IconButton(onPressed: () {
        query = '';
      }, icon: Icon(Icons.clear))
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    // Back button
    return IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back)
    );

  }

  @override
  Widget buildResults(BuildContext context) {
    // TODO: implement buildResults
    final List<String> searchResults = searchList
        .where((item) => item.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return ListView.builder(
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(searchResults[index]),
          onTap: () {
            // Handle the selected search result.
            close(context, searchResults[index]);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // TODO: implement buildSuggestions
    final List<String> suggestionList = query.isEmpty
        ? []
        : searchList
        .where((item) => item.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: suggestionList.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(suggestionList[index]),
          onTap: () {
            query = suggestionList[index];
            // Show the search results based on the selected suggestion.
          },
        );
      },
    );
  }
}


class HorizontalBookScroll extends StatelessWidget{
  const HorizontalBookScroll({super.key});// TODO : add argument to take data from backend

  @override
  Widget build(BuildContext context) {
    return ListView.builder( // TODO : rewrite function to use backend data
        padding: EdgeInsets.zero,
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        itemBuilder: (BuildContext context, int index) {
          return SizedBox(
            height: 120, // idk what changes this height value does
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)
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
                      child: Image.asset("assets/stats_book_temp.png", width: 145, height: 201, fit: BoxFit.fill,),

                    ),
                    SizedBox(height: 8,),
                    Text("Book $index", textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        }
    );
  }

}