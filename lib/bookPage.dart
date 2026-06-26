import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:library_nitc/auth_provider.dart';
import 'package:library_nitc/globals.dart';
import 'package:library_nitc/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:library_nitc/main.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import 'package:library_nitc/services/book_service.dart';
import 'package:library_nitc/models/book_details.dart';
import 'package:library_nitc/bookCoverImage.dart';

// Public OPAC URL, matches the backend's default KOHA_OPAC_URL.
const String _opacBaseUrl = 'https://opac.nitc.ac.in';

class BookPage extends StatefulWidget {
  final int biblioId;
  final BookDetail? book;

  const BookPage({required this.biblioId, this.book, super.key});

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

    final data = widget.book ?? await _service.getBookDetail(widget.biblioId);

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
  final BookService _bookService = BookService();
  BookStatus? _bookStatus;
  bool _renewLoading = false;

  BookAvailability? _availabilityResult;
  bool _availabilityLoading = false;
  bool _availabilityError = false;

  @override
  void initState() {
    super.initState();
    _checkOwnership();
  }

  Future<void> _checkOwnership() async {
    final token = context.read<AuthProvider>().accessToken;
    if (token == null) return;
    try {
      final status = await context
          .read<UserProvider>()
          .fetchBookStatus(token, widget.book.biblioId);
      if (mounted) setState(() => _bookStatus = status);
    } catch (_) {
      // Leave _bookStatus null -- falls back to "Check Availability".
    }
  }

  Future<void> _checkAvailability() async {
    setState(() {
      _availabilityLoading = true;
      _availabilityError = false;
    });
    try {
      final result = await _bookService.checkAvailability(widget.book.biblioId);
      if (mounted) {
        setState(() {
          _availabilityResult = result;
          _availabilityLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _availabilityLoading = false;
          _availabilityError = true;
        });
      }
    }
  }

  String _renewalCountText() {
    final s = _bookStatus!;
    if (s.renewalsAllowed > 0) {
      return "You have ${s.renewalsRemaining} of ${s.renewalsAllowed} renewals remaining.";
    } else if (s.renewalsRemaining > 0) {
      return "You have ${s.renewalsRemaining} renewal${s.renewalsRemaining == 1 ? '' : 's'} remaining.";
    } else {
      return "No renewals remaining.";
    }
  }

  Future<void> _onRenewTap() async {
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

    setState(() => _renewLoading = true);
    try {
      final result = await context
          .read<UserProvider>()
          .renewBook(token, _bookStatus!.issueId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not renew. Try again later.")),
      );
    } finally {
      if (mounted) setState(() => _renewLoading = false);
    }
  }

  void _onPlaceHoldTap() {
    final book = widget.book;
    pushWithNavBar(
      context,
      MaterialPageRoute(
        builder: (context) => PlaceHoldScreen(
          biblioId: book.biblioId,
          title: book.title,
          author: book.authors.isNotEmpty
              ? book.authors.join(", ")
              : "Unknown author",
        ),
      ),
    );
  }

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
    final borrowed = _bookStatus?.borrowedByCurrentUser ?? false;
    final showPlaceHold = _availabilityResult?.available ?? false;

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
                child: BookCoverImage(
                  coverUrl: book.coverUrl,
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

              // Shows "Renew" if user has the book, "Check Availability" otherwise.
              // After availability check: if available, shows "Place Hold".
              Expanded(
                child: borrowed
                    ? FilledButton.icon(
                        onPressed: _renewLoading ? null : _onRenewTap,
                        icon: _renewLoading
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.redo),
                        label: const Text(
                          "Renew",
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    : showPlaceHold
                        ? FilledButton.icon(
                            onPressed: _onPlaceHoldTap,
                            icon: const Icon(Icons.bookmark),
                            label: const Text(
                              "Place Hold",
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                        : FilledButton.icon(
                            onPressed: _availabilityLoading ? null : _checkAvailability,
                            icon: _availabilityLoading
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.search),
                            label: Text(
                              _availabilityError
                                  ? "Failed to fetch\nlatest availability"
                                  : "Check\nAvailability",
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
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

class PlaceHoldScreen extends StatefulWidget {
  final int biblioId;
  final String title;
  final String author;

  const PlaceHoldScreen({
    required this.biblioId,
    required this.title,
    required this.author,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _PlaceHoldScreenState();
}

class _PlaceHoldScreenState extends State<PlaceHoldScreen> {
  HoldForm? _form;
  String? _selectedBranch;
  bool _loading = true;
  bool _submitting = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadForm();
  }

  Future<void> _loadForm() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    final token = context.read<AuthProvider>().accessToken;
    if (token == null) {
      setState(() {
        _loading = false;
        _loadError = 'You must be logged in to place a hold.';
      });
      return;
    }
    try {
      final form = await context.read<UserProvider>().fetchHoldForm(token, widget.biblioId);
      setState(() {
        _form = form;
        _selectedBranch = form.branches.firstWhere(
          (b) => b.isDefault,
          orElse: () => form.branches.isNotEmpty
              ? form.branches.first
              : PickupBranch(code: '', name: '', isDefault: false),
        ).code;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _loadError = 'Could not check hold availability for this item.';
      });
    }
  }

  Future<void> _confirmHold() async {
    final branch = _selectedBranch;
    if (branch == null || branch.isEmpty) return;

    setState(() => _submitting = true);
    final token = context.read<AuthProvider>().accessToken;
    if (token == null) {
      setState(() => _submitting = false);
      return;
    }
    try {
      final result = await context.read<UserProvider>().placeHold(token, widget.biblioId, branch);
      if (!mounted) return;
      setState(() => _submitting = false);
      _showResultDialog(success: result.success, message: result.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showResultDialog(success: false, message: 'Could not place hold. Try again later.');
    }
  }

  void _showResultDialog({required bool success, required String message}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(success ? 'Hold placed' : 'Could not place hold'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (success) Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _openOpacWebsite() {
    launchUrl(
      Uri.parse('$_opacBaseUrl/cgi-bin/koha/opac-reserve.pl?biblionumber=${widget.biblioId}'),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back_outlined),
        ),
        title: Text("Place Hold"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 170,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset("assets/stats_book_temp.png", height: 170, width: 128),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.author,
                            style: const TextStyle(fontSize: 14, color: Colors.black54),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final form = _form;
    if (_loadError != null || form == null || !form.holdable) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _loadError ?? "Holds aren't available for this item right now.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _openOpacWebsite,
              icon: const Icon(Icons.open_in_new),
              label: const Text("Try the OPAC website"),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Pickup location", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            children: form.branches
                .map((branch) => RadioListTile<String>(
                      title: Text(branch.name),
                      value: branch.code,
                      groupValue: _selectedBranch,
                      onChanged: (value) => setState(() => _selectedBranch = value),
                    ))
                .toList(),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _submitting ? null : _confirmHold,
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text("Confirm hold"),
          ),
        ),
      ],
    );
  }
}

