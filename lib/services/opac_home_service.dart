import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:library_nitc/models/book_arrangement.dart';
import 'package:library_nitc/models/business_hours.dart';
import 'package:library_nitc/models/daily_quote.dart';
import 'package:library_nitc/models/new_arrival.dart';

const String _kBaseUrl = 'http://localhost:8000';

class OpacHomeData {
  final DailyQuote? quote;
  final List<HourEntry> businessHours;
  final List<StackEntry> bookArrangement;
  final List<NewArrival> newArrivals;

  OpacHomeData({
    this.quote,
    this.businessHours = const [],
    this.bookArrangement = const [],
    this.newArrivals = const [],
  });

  factory OpacHomeData.fromJson(Map<String, dynamic> json) {
    return OpacHomeData(
      quote: json['quote'] != null
          ? DailyQuote.fromJson(json['quote'] as Map<String, dynamic>)
          : null,
      businessHours: (json['business_hours'] as List<dynamic>?)
              ?.map((e) => HourEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      bookArrangement: (json['book_arrangement'] as List<dynamic>?)
              ?.map((e) => StackEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      newArrivals: (json['new_arrivals'] as List<dynamic>?)
              ?.map((e) => NewArrival.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class OpacHomeService {
  final String baseUrl;

  OpacHomeService({this.baseUrl = _kBaseUrl});

  Future<OpacHomeData> fetchHomeData() async {
    final uri = Uri.parse('$baseUrl/api/v1/opac/home');
    final response = await http.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return OpacHomeData.fromJson(decoded);
  }
}
