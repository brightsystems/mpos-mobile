import 'package:equatable/equatable.dart';

import 'package:mpos_mobile/features/auth/domain/entities/auth_session_entity.dart';

/// Administrators finish signing in with an SMS code sent after the password (MFA).
class LoginCodeChallenge extends Equatable {
  const LoginCodeChallenge({
    required this.challengeId,
    required this.phoneHint,
    required this.expiresInSeconds,
    this.devOtp,
  });

  final String challengeId;

  /// Masked phone the code went to, e.g. +251•••••0001.
  final String phoneHint;
  final int expiresInSeconds;
  final String? devOtp;

  @override
  List<Object?> get props => [challengeId, phoneHint, expiresInSeconds, devOtp];
}

/// Result of signing in with phone + password: a [session]; a [codeChallenge] (administrators
/// confirm with an SMS code); or, when the account has no password yet or the phone is new, a
/// request to verify the phone by SMS code and set one.
class PasswordLoginOutcome extends Equatable {
  const PasswordLoginOutcome.session(AuthSessionEntity this.session) : codeChallenge = null;

  const PasswordLoginOutcome.passwordSetupRequired() : session = null, codeChallenge = null;

  const PasswordLoginOutcome.codeRequired(LoginCodeChallenge this.codeChallenge) : session = null;

  final AuthSessionEntity? session;
  final LoginCodeChallenge? codeChallenge;

  bool get passwordSetupRequired => session == null && codeChallenge == null;

  @override
  List<Object?> get props => [session, codeChallenge];
}
