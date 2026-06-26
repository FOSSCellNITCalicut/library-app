import 'package:flutter/material.dart';

class BookCoverImage extends StatefulWidget {
  final String? coverUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  const BookCoverImage({
    super.key,
    required this.coverUrl,
    this.width,
    this.height,
    this.fit = BoxFit.fill,
  });

  @override
  State<BookCoverImage> createState() => _BookCoverImageState();
}

class _BookCoverImageState extends State<BookCoverImage> {
  static const int _maxRetries = 1;
  static const Duration _retryDelay = Duration(milliseconds: 350);

  int _retryAttempt = 0;
  bool _failed = false;
  bool _imageLoaded = false;
  bool _retryScheduled = false;

  String? get _normalizedUrl {
    final url = widget.coverUrl?.trim();
    if (url == null || url.isEmpty) {
      return null;
    }
    return url;
  }

  @override
  void didUpdateWidget(covariant BookCoverImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.coverUrl != widget.coverUrl) {
      setState(() {
        _retryAttempt = 0;
        _failed = false;
        _imageLoaded = false;
        _retryScheduled = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = _normalizedUrl;
    if (url == null || _failed) {
      return _buildPlaceholder();
    }

    final coverWidth = widget.width ?? 120;
    final coverHeight = widget.height ?? 180;
    final currentUrl = _urlForCurrentAttempt(url);

    return SizedBox(
      width: coverWidth,
      height: coverHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (!_imageLoaded)
            ShimmerWidget(width: coverWidth, height: coverHeight),
          Image.network(
            currentUrl,
            key: ValueKey(currentUrl),
            fit: widget.fit,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded || frame != null) {
                if (!_imageLoaded) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && !_imageLoaded) {
                      setState(() => _imageLoaded = true);
                    }
                  });
                }
                return child;
              }
              return const SizedBox.shrink();
            },
            errorBuilder: (context, error, stackTrace) {
              _handleLoadError();
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
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
    if (_retryScheduled || !mounted) {
      return;
    }

    _retryScheduled = true;
    final delay =
        _retryAttempt < _maxRetries ? _retryDelay : Duration.zero;

    Future.delayed(delay, () {
      _retryScheduled = false;
      if (!mounted) {
        return;
      }

      setState(() {
        _imageLoaded = false;
        if (_retryAttempt < _maxRetries) {
          _retryAttempt += 1;
        } else {
          _failed = true;
        }
      });
    });
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
