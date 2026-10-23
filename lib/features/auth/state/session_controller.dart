import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/dto/member_summary.dart';
import '../../../data/repositories/auth_repository.dart';

sealed class SessionState {
  const SessionState();
}

/// Reading the stored session at startup.
class SessionLoading extends SessionState {
  const SessionLoading();
}

class SignedOut extends SessionState {
  const SignedOut({this.reason});

  /// Shown on the login screen, e.g. after the server rejected the token.
  final String? reason;
}

class SignedIn extends SessionState {
  const SignedIn(this.member);

  final MemberSummary member;
}

/// App-wide auth state. The router listens to it for its guards.
class SessionController extends Notifier<SessionState> {
  bool _expiring = false;

  @override
  SessionState build() {
    _restore();
    return const SessionLoading();
  }

  Future<void> _restore() async {
    final member = await ref.read(authRepositoryProvider).restoreSession();
    state = member == null ? const SignedOut() : SignedIn(member);
  }

  void signedIn(MemberSummary member) => state = SignedIn(member);

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const SignedOut();
  }

  /// Called when an authenticated request returns 401. Several requests can
  /// fail together, so only the first one acts.
  Future<void> expire() async {
    if (_expiring || state is! SignedIn) return;
    _expiring = true;
    try {
      await ref.read(authRepositoryProvider).discardSession();
      state = const SignedOut(
        reason: 'Your session has ended. Please log in again.',
      );
    } finally {
      _expiring = false;
    }
  }
}

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);
