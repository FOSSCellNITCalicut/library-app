import 'package:flutter/material.dart';
import 'package:library_nitc/homePage.dart';

class SimilarBooksPage extends StatelessWidget {
  final String query;

  const SimilarBooksPage({required this.query, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Similar Books'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
      ),
      body: SearchResults(query: query),
    );
  }
}
