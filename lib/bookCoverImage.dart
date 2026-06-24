import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class BookCoverImage extends StatefulWidget {
  final String? coverUrl;
  final List<String> isbn;
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
  static final Map<String, String?> _coverCache = {};

  String? _resolvedUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initResolution();
  }

  @override
  void didUpdateWidget(covariant BookCoverImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.coverUrl != widget.coverUrl ||
        !_isListEqual(oldWidget.isbn, widget.isbn)) {
      _initResolution();
    }
  }

  bool _isListEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  String _getCacheKey(String? coverUrl, List<String> isbns) {
    return '${coverUrl ?? ''}_${isbns.join(',')}';
  }

  void _initResolution() {
    final key = _getCacheKey(widget.coverUrl, widget.isbn);
    if (_coverCache.containsKey(key)) {
      setState(() {
        _resolvedUrl = _coverCache[key];
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = true;
        _resolvedUrl = null;
      });
      _resolveCover();
    }
  }

  Future<void> _resolveCover() async {
    final key = _getCacheKey(widget.coverUrl, widget.isbn);

    // Build candidate list in order of priority
    final candidates = <String>[];
    if (widget.coverUrl != null && widget.coverUrl!.trim().isNotEmpty) {
      candidates.add(widget.coverUrl!.trim());
    }

    final validIsbns = widget.isbn
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    for (final cleanIsbn in validIsbns) {
      candidates.add('https://covers.openlibrary.org/b/isbn/$cleanIsbn-M.jpg?default=false');
    }

    if (candidates.isEmpty) {
      _coverCache[key] = null;
      if (mounted) {
        setState(() {
          _resolvedUrl = null;
          _isLoading = false;
        });
      }
      return;
    }

    // Run parallel HEAD requests for all candidate URLs
    final futures = <Future<_CheckResult>>[];
    for (int i = 0; i < candidates.length; i++) {
      futures.add(_checkUrl(candidates[i], i));
    }

    final results = await Future.wait(futures);
    results.sort((a, b) => a.index.compareTo(b.index));

    String? bestUrl;
    for (final res in results) {
      if (res.isValid) {
        bestUrl = res.url;
        break;
      }
    }

    _coverCache[key] = bestUrl;

    if (mounted) {
      setState(() {
        _resolvedUrl = bestUrl;
        _isLoading = false;
      });
    }
  }

  Future<_CheckResult> _checkUrl(String url, int index) async {
    try {
      final uri = Uri.parse(url);
      final response = await http.head(uri).timeout(const Duration(seconds: 3));
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _CheckResult(index: index, isValid: true, url: url);
      }
      
      // Fallback to GET only if method is not allowed or supported
      if (response.statusCode == 405 || response.statusCode == 501) {
        final getResponse = await http.get(uri).timeout(const Duration(seconds: 3));
        if (getResponse.statusCode >= 200 && getResponse.statusCode < 300) {
          return _CheckResult(index: index, isValid: true, url: url);
        }
      }
      
      return _CheckResult(index: index, isValid: false, url: url);
    } catch (_) {
      return _CheckResult(index: index, isValid: false, url: url);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return ShimmerWidget(
        width: widget.width ?? 120,
        height: widget.height ?? 180,
      );
    }

    if (_resolvedUrl != null) {
      return Image.network(
        _resolvedUrl!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
        },
      );
    }

    return _buildPlaceholder();
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

class _CheckResult {
  final int index;
  final bool isValid;
  final String url;

  _CheckResult({required this.index, required this.isValid, required this.url});
}

class ShimmerWidget extends StatefulWidget {
  final double width;
  final double height;

  const ShimmerWidget({required this.width, required this.height, super.key});

  @override
  State<ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<ShimmerWidget> with SingleTickerProviderStateMixin {
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
              colors: [
                Colors.grey[300]!,
                Colors.grey[100]!,
                Colors.grey[300]!,
              ],
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
