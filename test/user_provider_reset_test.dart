import 'package:flutter_test/flutter_test.dart';
import 'package:library_nitc/user_provider.dart';

/// Verifies that UserProvider.clearUserData() fully resets state on logout,
/// so one account's profile, fines, and holds can never leak into the next
/// account's session.
void main() {
  test('clearUserData() clears cached data, loading flags, and errors', () {
    final provider = UserProvider();

    // Simulate user A's data already loaded (as after fetchProfile/fetchFines/etc).
    provider.profile = UserProfile(
      rollNo: '1034',
      name: 'User A',
      loanSummary: LoanSummary(loanCount: 2, loanLimit: 5),
      checkedOutBooks: [
        CheckedOutBook(
          biblioId: 897,
          issueId: 1,
          title: 'Some Book',
          author: 'Author',
          dueDate: '2026-01-01',
          renewalsAllowed: 3,
          renewalsRemaining: 2,
        ),
      ],
    );
    provider.outstandingFine = 42.0;
    provider.fineHistory = [FineHistoryItem(amount: 10, date: '2026-01-01', status: 'paid')];
    provider.holds = [
      HoldItem(reserveId: 'r1', biblioId: 897, title: 'X', branch: 'LIB', status: 'pending'),
    ];
    // Also simulate leftover loading/error state from an in-flight or failed
    // fetch, which clearUserData() must reset too, not just the data fields.
    provider.profileLoading = true;
    provider.profileError = 'stale error';
    provider.finesLoading = true;
    provider.finesError = 'stale error';
    provider.historyLoading = true;
    provider.historyError = 'stale error';
    provider.holdsLoading = true;
    provider.holdsError = 'stale error';

    var notified = false;
    provider.addListener(() => notified = true);

    provider.clearUserData();

    expect(provider.profile, isNull);
    expect(provider.outstandingFine, isNull);
    expect(provider.fineHistory, isNull);
    expect(provider.holds, isNull);

    expect(provider.profileLoading, isFalse);
    expect(provider.profileError, isNull);
    expect(provider.finesLoading, isFalse);
    expect(provider.finesError, isNull);
    expect(provider.historyLoading, isFalse);
    expect(provider.historyError, isNull);
    expect(provider.holdsLoading, isFalse);
    expect(provider.holdsError, isNull);

    expect(notified, isTrue, reason: 'listeners must be notified so the UI rebuilds');
  });
}
