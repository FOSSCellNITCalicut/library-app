import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:library_nitc/theme/app_colors.dart';

class BookCoverImage extends StatelessWidget {
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

  String? get _normalizedUrl {
    final url = coverUrl?.trim();
    return (url == null || url.isEmpty) ? null : url;
  }

  Widget _fallback() => Image.asset(
        'assets/stats_book_temp.png',
        width: width,
        height: height,
        fit: fit,
      );

  @override
  Widget build(BuildContext context) {
    final url = _normalizedUrl;
    if (url == null) return _fallback();

    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) =>
          ShimmerWidget(width: width ?? 120, height: height ?? 180),
      errorWidget: (context, url, error) => _fallback(),
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
              colors: [context.cs.outlineVariant, context.cs.surface, context.cs.outlineVariant],
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
