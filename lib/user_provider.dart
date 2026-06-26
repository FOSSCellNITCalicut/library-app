import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// Matches auth_provider.dart -- localhost alias for the Android emulator.
const String _backendBaseUrl = 'http://localhost:8000';

class CheckedOutBook {
  final int biblioId;
  final int issueId;
  final String title;
  final String author;
  final String dueDate;
  final int renewalsAllowed;
  final int renewalsRemaining;

  CheckedOutBook({
    required this.biblioId,
    required this.issueId,
    required this.title,
    required this.author,
    required this.dueDate,
    required this.renewalsAllowed,
    required this.renewalsRemaining,
  });

  factory CheckedOutBook.fromJson(Map<String, dynamic> json) {
    return CheckedOutBook(
      biblioId: json['biblio_id'] as int,
      issueId: json['issue_id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      author: json['author'] as String? ?? '',
      dueDate: json['due_date'] as String? ?? '',
      renewalsAllowed: json['renewals_allowed'] as int? ?? 0,
      renewalsRemaining: json['renewals_remaining'] as int? ?? 0,
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

class PickupBranch {
  final String code;
  final String name;
  final bool isDefault;

  PickupBranch({required this.code, required this.name, required this.isDefault});

  factory PickupBranch.fromJson(Map<String, dynamic> json) {
    return PickupBranch(
      code: json['code'] as String,
      name: json['name'] as String,
      isDefault: json['is_default'] as bool? ?? false,
    );
  }
}

class HoldForm {
  final bool holdable;
  final List<PickupBranch> branches;

  HoldForm({required this.holdable, required this.branches});

  factory HoldForm.fromJson(Map<String, dynamic> json) {
    return HoldForm(
      holdable: json['holdable'] as bool? ?? false,
      branches: (json['branches'] as List<dynamic>? ?? [])
          .map((e) => PickupBranch.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class HoldItem {
  final String reserveId;
  final int biblioId;
  final String title;
  final String branch;
  final String status;

  HoldItem({
    required this.reserveId,
    required this.biblioId,
    required this.title,
    required this.branch,
    required this.status,
  });

  factory HoldItem.fromJson(Map<String, dynamic> json) {
    return HoldItem(
      reserveId: json['reserve_id'] as String,
      biblioId: json['biblio_id'] as int,
      title: json['title'] as String? ?? '',
      branch: json['branch'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }
}

class CancelHoldResult {
  final bool success;
  final String message;

  CancelHoldResult({required this.success, required this.message});
}

class RenewResult {
  final bool success;
  final String message;

  RenewResult({required this.success, required this.message});
}

class PlaceHoldResult {
  final bool success;
  final String message;

  PlaceHoldResult({required this.success, required this.message});
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

  List<HoldItem>? holds;
  bool holdsLoading = false;
  String? holdsError;

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

  /// One-off lookup for PlaceHoldScreen: which pickup branches are offered
  /// and whether Koha will accept a hold on this book at all.
  /// Throws on any failure; callers should show a "try the OPAC website" state.
  Future<HoldForm> fetchHoldForm(String accessToken, int biblioId) async {
    final response = await http.get(
      Uri.parse('$_backendBaseUrl/api/v1/user/holds/$biblioId/form'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    if (response.statusCode != 200) {
      throw 'Server error (${response.statusCode})';
    }
    return HoldForm.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// Submits the hold. Never throws on a Koha-side rejection -- that comes
  /// back as PlaceHoldResult(success: false, message: ...) so the caller can
  /// show Koha's actual reason instead of a generic error.
  Future<PlaceHoldResult> placeHold(String accessToken, int biblioId, String branchCode) async {
    final response = await http.post(
      Uri.parse('$_backendBaseUrl/api/v1/user/holds/$biblioId'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'branch_code': branchCode}),
    );
    if (response.statusCode != 200) {
      throw 'Server error (${response.statusCode})';
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return PlaceHoldResult(
      success: data['success'] as bool? ?? false,
      message: data['message'] as String? ?? 'Could not place hold.',
    );
  }

  Future<void> fetchHolds(String accessToken) async {
    holdsLoading = true;
    holdsError = null;
    notifyListeners();
    try {
      final response = await http.get(
        Uri.parse('$_backendBaseUrl/api/v1/user/holds'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      if (response.statusCode != 200) {
        throw 'Server error (${response.statusCode})';
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      holds = (data['items'] as List<dynamic>? ?? [])
          .map((e) => HoldItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      holdsError = 'Could not load your holds.';
    } finally {
      holdsLoading = false;
      notifyListeners();
    }
  }

  /// Renews a checked-out book. On success, re-fetches the profile so the
  /// updated due date and remaining renewal count are reflected immediately.
  /// Never throws on a Koha-side rejection -- that comes back as
  /// RenewResult(success: false, message: ...).
  Future<RenewResult> renewBook(String accessToken, int issueId) async {
    final response = await http.post(
      Uri.parse('$_backendBaseUrl/api/v1/user/renew/$issueId'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    if (response.statusCode != 200) {
      throw 'Server error (${response.statusCode})';
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final result = RenewResult(
      success: data['success'] as bool? ?? false,
      message: data['message'] as String? ?? 'Could not renew.',
    );
    if (result.success) {
      await fetchProfile(accessToken);
    }
    return result;
  }

  /// Never throws on a Koha-side rejection -- comes back as
  /// CancelHoldResult(success: false, message: ...) so the caller can show
  /// Koha's actual reason. On success, removes the hold from the cached list
  /// so the screen updates without a full re-fetch.
  Future<CancelHoldResult> cancelHold(String accessToken, String reserveId) async {
    final response = await http.post(
      Uri.parse('$_backendBaseUrl/api/v1/user/holds/$reserveId/cancel'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    if (response.statusCode != 200) {
      throw 'Server error (${response.statusCode})';
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final result = CancelHoldResult(
      success: data['success'] as bool? ?? false,
      message: data['message'] as String? ?? 'Could not cancel hold.',
    );
    if (result.success) {
      holds = holds?.where((h) => h.reserveId != reserveId).toList();
      notifyListeners();
    }
    return result;
  }
}
