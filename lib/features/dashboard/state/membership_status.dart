import '../../../data/dto/dashboard_dto.dart';

enum MembershipState { active, expiring, expired, none }

/// What the dashboard shows about the membership, with the same rules as the
/// web portal: expired at 0 days, "expiring soon" within 7 days.
class MembershipStatus {
  const MembershipStatus({
    required this.state,
    this.planName,
    this.expiresOn,
    this.daysRemaining = 0,
    this.expiryPercent,
  });

  static const expiringSoonDays = 7;

  factory MembershipStatus.from(MembershipInfo? info) {
    if (info == null) return const MembershipStatus(state: MembershipState.none);

    final days = info.daysRemaining ?? info.daysLeft?.ceil() ?? 0;
    final state = switch (info.state) {
      'active' => MembershipState.active,
      'expiring' => MembershipState.expiring,
      'expired' => MembershipState.expired,
      // Older servers send no state: derive it like the web dashboard.
      _ => days <= 0
          ? MembershipState.expired
          : days <= expiringSoonDays
              ? MembershipState.expiring
              : MembershipState.active,
    };

    return MembershipStatus(
      state: state,
      planName: info.planName,
      expiresOn: DateTime.tryParse(info.expiresAtIso ?? ''),
      daysRemaining: days < 0 ? 0 : days,
      expiryPercent: info.expiryPercent,
    );
  }

  final MembershipState state;
  final String? planName;
  final DateTime? expiresOn;
  final int daysRemaining;
  final int? expiryPercent;

  String get label => switch (state) {
        MembershipState.active => 'Active',
        MembershipState.expiring => daysRemaining == 0
            ? 'Expires today'
            : 'Expires in $daysRemaining day${daysRemaining == 1 ? '' : 's'}',
        MembershipState.expired => 'Expired',
        MembershipState.none => 'No active membership',
      };
}
