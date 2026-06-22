import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import 'package:library_nitc/services/book_service.dart';
import 'package:library_nitc/models/book_details.dart';

class BookPage extends StatefulWidget {
  final int biblioId;
  const BookPage({required this.biblioId, super.key});

  @override
  State<StatefulWidget> createState() => _BookPageState();
}

class _BookPageState extends State<BookPage> {

  

  final BookService _service = BookService();

  BookDetail? book;
  bool loading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
  try {
    setState(() {
      loading = true;
      hasError = false;
    });

    //await Future.delayed(const Duration(seconds: 2));  //to see loading page


    final data = await _service.getBookDetail(widget.biblioId);

    setState(() {
      book = data;
      loading = false;
    });
  } catch (e) {
    setState(() {
      loading = false;
      hasError = true;
    });
  }
}
  @override

  Widget build(BuildContext context) {

  //loading
  if (loading) {
  return Scaffold(
    appBar: AppBar(),
    body: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // BOOK HEADER SKELETON
          Row(
            children: [
              Container(
                height: 170,
                width: 128,
                color: Colors.grey.shade300,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 20, color: Colors.grey.shade300),
                    const SizedBox(height: 8),
                    Container(height: 14, width: 120, color: Colors.grey.shade300),
                    const SizedBox(height: 8),
                    Container(height: 14, width: 160, color: Colors.grey.shade300),
                  ],
                ),
              )
            ],
          ),

          const SizedBox(height: 20),

          // HOLDINGS TITLE
          Container(height: 18, width: 140, color: Colors.grey.shade300),

          const SizedBox(height: 10),

          // LIST SKELETON
          Expanded(
            child: ListView.builder(
              itemCount: 5,
              itemBuilder: (_, __) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                color: Colors.grey.shade200,
                height: 60,
              ),
            ),
          )
        ],
      ),
    ),
  );
}

  //error      not much ui is done later if needed
  if (hasError) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sentiment_dissatisfied,
                size: 80, color: Colors.grey),
            SizedBox(height: 12),
            Text("Failed to load book details"),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  loading = true;
                  hasError = false;
                });
                load();
              },
              child: Text("Retry"),
            )
          ],
        ),
      ),
    );
  }

  // success
  final b = book!;

  return Scaffold(
    appBar: AppBar(
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: Icon(Icons.arrow_back),
      ),
      title: Text(b.title, overflow: TextOverflow.ellipsis),
    ),

    // SingleChildScrollView (instead of a bare Column+Expanded) so the page
    // scrolls instead of overflowing when there's less vertical room --
    // e.g. landscape orientation, where BookDetailCard's fixed-height image
    // plus text easily exceeds the available height.
    body: SingleChildScrollView(
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BookDetailCard(book: b),

          SizedBox(height: 8),

          Text(
            "Holdings (${b.copies.length})",
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
          ),

          SizedBox(height: 8),

          HoldingsList(copies: b.copies),
        ],
      ),
    ),
  );
}

}



class BookDetailCard extends StatefulWidget {
  final BookDetail book;

  const BookDetailCard({super.key, required this.book});

  @override
  State<BookDetailCard> createState() => _BookDetailCardState();
}

class _BookDetailCardState extends State<BookDetailCard> {
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 14, color: Colors.black87),
          children: [
            TextSpan(
              text: "$label: ",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final available = book.isAvailable;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// TOP SECTION   book title author availability
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  "assets/stats_book_temp.png",
                  height: 160,
                  width: 120,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      book.authors.isNotEmpty
                          ? book.authors.join(", ")
                          : "Unknown author",
                      style: const TextStyle(color: Colors.black54),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      available ? "Available" : "Unavailable",
                      style: TextStyle(
                        color: available ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          /// OPTIONAL FIELDS (ONLY IF PRESENT) -publisher year edition isbn
          if (book.publisher != null && book.publisher!.isNotEmpty)
            _infoRow("Publisher", book.publisher!),

          if (book.publishedYear != null)
            _infoRow("Year", book.publishedYear.toString()),

          if (book.edition != null &&
              book.edition.toString().trim().isNotEmpty)
            _infoRow("Edition", book.edition.toString()),

          if (book.isbn != null && book.isbn!.isNotEmpty)
            _infoRow("ISBN", book.isbn!.join(", ")),

          /// CATEGORIES - like a box
          if (book.categories.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: book.categories
                  .map(
                    (c) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        c,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],

          const SizedBox(height: 12),

          /// ACTION BUTTONS
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text(
                    "Text",
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              SizedBox(width: 8),

              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text(
                    "General Books",
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              SizedBox(width: 8),

              Expanded(
                child: FilledButton(
                  onPressed: () {},
                  child: const Text(
                    "Confirm Availability",
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}


class HoldingsList extends StatelessWidget {
  final List<BookCopy> copies;
  const HoldingsList({super.key, required this.copies});

  @override
  Widget build(BuildContext context) {
    // shrinkWrap + NeverScrollableScrollPhysics: this list now sits inside
    // the page's own SingleChildScrollView, so it should size itself to its
    // content and let the outer scroll view handle scrolling, instead of
    // demanding bounded height from a parent Expanded.
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: copies.length,
      itemBuilder: (BuildContext context, int index) {
        final copy = copies[index];

        return Container(
          color: Colors.purple.shade50,
          padding: EdgeInsets.all(12),
          margin: EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(copy.branch),
                  Spacer(),
                  Text("SL NO: ${copy.itemId}"),
                ],
              ),
              Text("Call No: ${copy.callNumber ?? 'N/A'}"),
              Text("Status: ${copy.status}"),
            ],
          ),
        );
      },
    );
  }

}





