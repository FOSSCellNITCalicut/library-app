import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// Matches auth_provider.dart -- localhost alias for the Android emulator.
const String _backendBaseUrl = 'http://localhost:8000';

class CheckedOutBook {
  final int biblioId;
  final String title;
  final String author;
  final String dueDate;

  CheckedOutBook({
    required this.biblioId,
    required this.title,
    required this.author,
    required this.dueDate,
  });

  factory CheckedOutBook.fromJson(Map<String, dynamic> json) {
    return CheckedOutBook(
      biblioId: json['biblio_id'] as int,
      title: json['title'] as String? ?? '',
      author: json['author'] as String? ?? '',
      dueDate: json['due_date'] as String? ?? '',
    );
  }
}

class LoanSummary {
  final int loanCount;
  final int loanLimit;

  LoanSummary({required this.loanCount, required this.loanLimit});

  factory LoanSummary.fromJson(Map<String, dynamic> json) {
    return LoanSummary(
      loanCount: json['loan_count'] as int? ?? 0,
      loanLimit: json['loan_limit'] as int? ?? 0,
    );
  }
}

class UserProfile {
  final String rollNo;
  final String name;
  final String? email;
  final LoanSummary loanSummary;
  final List<CheckedOutBook> checkedOutBooks;

  UserProfile({
    required this.rollNo,
    required this.name,
    this.email,
    required this.loanSummary,
    required this.checkedOutBooks,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      rollNo: json['roll_no'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      loanSummary: LoanSummary.fromJson(json['loan_summary'] as Map<String, dynamic>),
      checkedOutBooks: (json['checked_out_books'] as List<dynamic>? ?? [])
          .map((e) => CheckedOutBook.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class FineHistoryItem {
  final double amount;
  final String date;
  final String status;

  FineHistoryItem({required this.amount, required this.date, required this.status});

  factory FineHistoryItem.fromJson(Map<String, dynamic> json) {
    return FineHistoryItem(
      amount: (json['amount'] as num).toDouble(),
      date: json['date'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }
}

/// Fetches the data behind the Profile and Fines pages.
///
/// The three fetches (profile / fines / fines history) are independent --
/// each backs a different screen with its own loading state, so a failure in
/// one shouldn't block the others from showing.
class UserProvider extends ChangeNotifier {
  UserProfile? profile;
  bool profileLoading = false;
  String? profileError;

  double? outstandingFine;
  bool finesLoading = false;
  String? finesError;

  List<FineHistoryItem>? fineHistory;
  bool historyLoading = false;
  String? historyError;

  Future<void> fetchProfile(String accessToken) async {
    profileLoading = true;
    profileError = null;
    notifyListeners();
    try {
      final response = await http.get(
        Uri.parse('$_backendBaseUrl/api/v1/user/me'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      if (response.statusCode != 200) {
        throw 'Server error (${response.statusCode})';
      }
      profile = UserProfile.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } catch (e) {
      profileError = 'Could not load your profile.';
    } finally {
      profileLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchFines(String accessToken) async {
    finesLoading = true;
    finesError = null;
    notifyListeners();
    try {
      final response = await http.get(
        Uri.parse('$_backendBaseUrl/api/v1/user/fines'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      if (response.statusCode != 200) {
        throw 'Server error (${response.statusCode})';
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      outstandingFine = (data['outstanding_fine'] as num).toDouble();
    } catch (e) {
      finesError = 'Could not load your fine information.';
    } finally {
      finesLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchFinesHistory(String accessToken) async {
    historyLoading = true;
    historyError = null;
    notifyListeners();
    try {
      final response = await http.get(
        Uri.parse('$_backendBaseUrl/api/v1/user/fines/history'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      if (response.statusCode != 200) {
        throw 'Server error (${response.statusCode})';
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      fineHistory = (data['items'] as List<dynamic>? ?? [])
          .map((e) => FineHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      historyError = 'Could not load your fine history.';
    } finally {
      historyLoading = false;
      notifyListeners();
    }
  }

  /// One-off lookup, not cached on the provider -- used by BookDetailCard to
  /// decide whether to show Renew or Place Hold for a specific book.
  /// Throws on any failure; callers should treat that as "not borrowed".
  Future<bool> fetchBookStatus(String accessToken, int biblioId) async {
    final response = await http.get(
      Uri.parse('$_backendBaseUrl/api/v1/user/book-status/$biblioId'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    if (response.statusCode != 200) {
      throw 'Server error (${response.statusCode})';
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['borrowed_by_current_user'] as bool? ?? false;
  }
}
