import 'package:equatable/equatable.dart';

import 'package:mpos_mobile/features/auth/domain/entities/auth_session_entity.dart';

/// Result of signing in with phone + password: a [session], or (when the account has no password
/// yet, or the phone is new) a request to verify the phone by SMS code and set one.
class PasswordLoginOutcome extends Equatable {
  const PasswordLoginOutcome.session(AuthSessionEntity this.session);

  const PasswordLoginOutcome.passwordSetupRequired() : session = null;

  final AuthSessionEntity? session;

  bool get passwordSetupRequired => session == null;

  @override
  List<Object?> get props => [session];
}
