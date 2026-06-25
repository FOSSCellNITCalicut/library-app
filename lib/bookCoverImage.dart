import 'package:flutter/material.dart';

class BookCoverImage extends StatefulWidget {
  final Object? isbn;
  final String? coverUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  const BookCoverImage({
    super.key,
    required this.coverUrl,
    required this.isbn,
    this.width,
    this.height,
    this.fit = BoxFit.fill,
  });

  @override
  State<BookCoverImage> createState() => _BookCoverImageState();
}

class _BookCoverImageState extends State<BookCoverImage> {
  static const int _maxRetriesPerCandidate = 1;
  static const Duration _retryDelay = Duration(milliseconds: 350);

  List<String> _candidates = const [];
  int _candidateIndex = 0;
  int _retryAttempt = 0;
  bool _advanceScheduled = false;
  bool _exhausted = false;

  @override
  void initState() {
    super.initState();
    _refreshCandidates(initialLoad: true);
  }

  @override
  void didUpdateWidget(covariant BookCoverImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.coverUrl != widget.coverUrl ||
        !_sameIsbnValue(oldWidget.isbn, widget.isbn)) {
      _refreshCandidates();
    }
  }

  bool _sameIsbnValue(Object? a, Object? b) {
    final left = _normalizeIsbnInput(a);
    final right = _normalizeIsbnInput(b);
    if (left.length != right.length) {
      return false;
    }
    for (var i = 0; i < left.length; i++) {
      if (left[i] != right[i]) {
        return false;
      }
    }
    return true;
  }

  void _refreshCandidates({bool initialLoad = false}) {
    final candidates = _buildOpenLibraryCoverCandidates(
      widget.coverUrl,
      _normalizeIsbnInput(widget.isbn),
    );

    if (initialLoad) {
      _candidates = candidates;
      _candidateIndex = 0;
      _retryAttempt = 0;
      _advanceScheduled = false;
      _exhausted = candidates.isEmpty;
      return;
    }

    setState(() {
      _candidates = candidates;
      _candidateIndex = 0;
      _retryAttempt = 0;
      _advanceScheduled = false;
      _exhausted = candidates.isEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_exhausted || _candidates.isEmpty) {
      return _buildPlaceholder();
    }

    final currentUrl = _urlForCurrentAttempt(_candidates[_candidateIndex]);
    final coverWidth = widget.width ?? 120;
    final coverHeight = widget.height ?? 180;

    return Image.network(
      currentUrl,
      key: ValueKey(currentUrl),
      width: coverWidth,
      height: coverHeight,
      fit: widget.fit,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          return child;
        }

        return _loadingFallback();
      },
      errorBuilder: (context, error, stackTrace) {
        _handleLoadError();
        return _loadingFallback();
      },
    );
  }

  String _urlForCurrentAttempt(String url) {
    if (_retryAttempt == 0) {
      return url;
    }

    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      return url;
    }

    return uri
        .replace(
          queryParameters: {
            ...uri.queryParameters,
            'cover_retry': '$_retryAttempt',
          },
        )
        .toString();
  }

  void _handleLoadError() {
    if (_advanceScheduled || !mounted) {
      return;
    }

    _advanceScheduled = true;
    final delay = _retryAttempt < _maxRetriesPerCandidate
        ? _retryDelay
        : Duration.zero;

    Future.delayed(delay, () {
      _advanceScheduled = false;
      if (!mounted) {
        return;
      }

      setState(() {
        if (_retryAttempt < _maxRetriesPerCandidate) {
          _retryAttempt += 1;
        } else if (_candidateIndex + 1 >= _candidates.length) {
          _exhausted = true;
        } else {
          _candidateIndex += 1;
          _retryAttempt = 0;
        }
      });
    });
  }

  Widget _loadingFallback() {
    return ShimmerWidget(
      width: widget.width ?? 120,
      height: widget.height ?? 180,
    );
  }

  Widget _buildPlaceholder() {
    return Image.asset(
      'assets/stats_book_temp.png',
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
    );
  }
}

List<String> _normalizeIsbnInput(Object? value) {
  final results = <String>[];

  void addRaw(String raw) {
    final normalized = _normalizeIsbn(raw);
    if (normalized == null || results.contains(normalized)) {
      return;
    }

    results.add(normalized);

    final isbn13 = _isbn10To13(normalized);
    if (isbn13 != null && !results.contains(isbn13)) {
      results.add(isbn13);
    }

    final isbn10 = _isbn13To10(normalized);
    if (isbn10 != null && !results.contains(isbn10)) {
      results.add(isbn10);
    }
  }

  if (value is String) {
    addRaw(value);
  } else if (value is Iterable) {
    for (final item in value) {
      if (item is String) {
        addRaw(item);
      }
    }
  }

  return results;
}

List<String> _buildOpenLibraryCoverCandidates(
  String? coverUrl,
  List<String> isbns,
) {
  final candidates = <String>[];

  void addCandidate(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty || candidates.contains(trimmed)) {
      return;
    }
    candidates.add(trimmed);
  }

  if (coverUrl != null) {
    addCandidate(coverUrl);
  }

  for (final rawIsbn in isbns) {
    final normalized = _normalizeIsbn(rawIsbn);
    if (normalized == null) {
      continue;
    }

    for (final isbn in _isbnVariants(normalized)) {
      addCandidate(
        'https://covers.openlibrary.org/b/isbn/$isbn-M.jpg?default=false',
      );
    }
  }

  return candidates;
}

String? _normalizeIsbn(String value) {
  final cleaned = value.replaceAll(RegExp(r'[^0-9Xx]'), '').toUpperCase();
  if (cleaned.isEmpty) {
    return null;
  }

  if (_isValidIsbn10(cleaned) || _isValidIsbn13(cleaned)) {
    return cleaned;
  }

  return null;
}

Iterable<String> _isbnVariants(String isbn) sync* {
  yield isbn;

  final isbn13 = _isbn10To13(isbn);
  if (isbn13 != null) {
    yield isbn13;
  }

  final isbn10 = _isbn13To10(isbn);
  if (isbn10 != null) {
    yield isbn10;
  }
}

bool _isValidIsbn10(String isbn) {
  if (!RegExp(r'^\d{9}[\dX]$').hasMatch(isbn)) {
    return false;
  }

  var sum = 0;
  for (var i = 0; i < 9; i++) {
    sum += (i + 1) * (isbn.codeUnitAt(i) - 0x30);
  }

  final check = isbn[9] == 'X' ? 10 : isbn.codeUnitAt(9) - 0x30;
  sum += 10 * check;
  return sum % 11 == 0;
}

bool _isValidIsbn13(String isbn) {
  if (!RegExp(r'^\d{13}$').hasMatch(isbn)) {
    return false;
  }

  var sum = 0;
  for (var i = 0; i < 12; i++) {
    final digit = isbn.codeUnitAt(i) - 0x30;
    sum += i.isEven ? digit : digit * 3;
  }

  final check = (10 - (sum % 10)) % 10;
  return check == (isbn.codeUnitAt(12) - 0x30);
}

String? _isbn10To13(String isbn) {
  if (!_isValidIsbn10(isbn)) {
    return null;
  }

  final core = '978${isbn.substring(0, 9)}';
  var sum = 0;
  for (var i = 0; i < core.length; i++) {
    final digit = core.codeUnitAt(i) - 0x30;
    sum += i.isEven ? digit : digit * 3;
  }

  final check = (10 - (sum % 10)) % 10;
  return '$core$check';
}

String? _isbn13To10(String isbn) {
  if (!_isValidIsbn13(isbn) || !isbn.startsWith('978')) {
    return null;
  }

  final core = isbn.substring(3, 12);
  var sum = 0;
  for (var i = 0; i < 9; i++) {
    sum += (10 - i) * (core.codeUnitAt(i) - 0x30);
  }

  final remainder = 11 - (sum % 11);
  final check = switch (remainder) {
    10 => 'X',
    11 => '0',
    _ => remainder.toString(),
  };

  return '$core$check';
}

class ShimmerWidget extends StatefulWidget {
  final double width;
  final double height;

  const ShimmerWidget({required this.width, required this.height, super.key});

  @override
  State<ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              colors: [Colors.grey[300]!, Colors.grey[100]!, Colors.grey[300]!],
              stops: const [0.1, 0.5, 0.9],
              begin: Alignment(-1.0 + _controller.value * 2, -0.3),
              end: Alignment(1.0 + _controller.value * 2, 0.3),
            ),
          ),
        );
      },
    );
  }
}
