import 'package:flutter_test/flutter_test.dart';
import 'package:zoezidesk_member/core/utils/formatters.dart';
import 'package:zoezidesk_member/data/dto/dashboard_dto.dart';
import 'package:zoezidesk_member/features/dashboard/state/membership_status.dart';

void main() {
  test('no membership', () {
    final s = MembershipStatus.from(null);
    expect(s.state, MembershipState.none);
    expect(s.label, 'No active membership');
  });

  test('uses server state and whole days', () {
    final s = MembershipStatus.from(const MembershipInfo(
      state: 'expiring',
      daysRemaining: 3,
      expiresAtIso: '2026-10-26',
      planName: 'Monthly',
    ));
    expect(s.state, MembershipState.expiring);
    expect(s.label, 'Expires in 3 days');
    expect(s.expiresOn, DateTime(2026, 10, 26));
  });

  test('singular day and expires today', () {
    expect(
      MembershipStatus.from(const MembershipInfo(state: 'expiring', daysRemaining: 1)).label,
      'Expires in 1 day',
    );
    expect(
      MembershipStatus.from(const MembershipInfo(state: 'expiring', daysRemaining: 0)).label,
      'Expires today',
    );
  });

  group('older server without state', () {
    MembershipState stateFor(num daysLeft) =>
        MembershipStatus.from(MembershipInfo(daysLeft: daysLeft)).state;

    test('rounds fractional days up like a countdown', () {
      expect(MembershipStatus.from(const MembershipInfo(daysLeft: 12.2)).daysRemaining, 13);
    });

    test('derives state with the web thresholds', () {
      expect(stateFor(0), MembershipState.expired);
      expect(stateFor(0.3), MembershipState.expiring);
      expect(stateFor(7), MembershipState.expiring);
      expect(stateFor(7.5), MembershipState.active);
    });
  });

  test('formatters', () {
    final now = DateTime(2026, 10, 23, 10);
    expect(formatKes(4500), 'KES 4,500');
    expect(formatRelative(now.subtract(const Duration(seconds: 20)), now), 'just now');
    expect(formatRelative(now.subtract(const Duration(minutes: 5)), now), '5 min ago');
    expect(formatRelative(now.subtract(const Duration(hours: 3)), now), '3 h ago');
    expect(formatRelative(now.subtract(const Duration(hours: 30)), now), 'yesterday');
    expect(formatRelative(DateTime(2026, 10, 12), now), '12 Oct 2026');
  });
}
