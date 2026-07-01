import 'dart:convert';
import 'package:library_nitc/cache/cache_policy.dart';
import 'package:library_nitc/cache/cached_http_client.dart';
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

  // P1 — 12-hr TTL + stale-while-revalidate (most expensive backend call).
  late final CachedHttpClient _client;

  OpacHomeService({this.baseUrl = _kBaseUrl}) {
    _client = CachedHttpClient(namespace: 'opac_home', policy: CachePolicy.opacHome);
  }

  Future<OpacHomeData> fetchHomeData() async {
    final uri = Uri.parse('$baseUrl/api/v1/opac/home');
    final response = await _client.get(uri);
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return OpacHomeData.fromJson(decoded);
  }

  /// Force a fresh fetch — e.g. on explicit pull-to-refresh.
  Future<OpacHomeData> fetchHomeDataFresh() async {
    _client.invalidateAll();
    return fetchHomeData();
  }
}
