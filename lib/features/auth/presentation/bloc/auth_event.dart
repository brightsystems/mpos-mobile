import 'package:equatable/equatable.dart';

import 'package:mpos_mobile/features/auth/domain/entities/auth_session_entity.dart';
import 'package:mpos_mobile/features/auth/domain/entities/membership_entity.dart';
import 'package:mpos_mobile/features/auth/presentation/bloc/auth_state.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {
  const AuthStarted();
}

/// Daily sign-in with phone + password.
class AuthPasswordLoginRequested extends AuthEvent {
  const AuthPasswordLoginRequested({
    required this.phone,
    required this.password,
    required this.deviceId,
    this.deviceName,
  });

  final String phone;
  final String password;
  final String deviceId;
  final String? deviceName;

  @override
  List<Object?> get props => [phone, password, deviceId, deviceName];
}

/// Texts a code to set the first password or reset a forgotten one.
class AuthOtpRequested extends AuthEvent {
  const AuthOtpRequested(this.phone, {this.reason = PasswordSetupReason.reset});

  final String phone;
  final PasswordSetupReason reason;

  @override
  List<Object?> get props => [phone, reason];
}

/// The SMS code plus the new password; signs in on success.
class AuthPasswordSetSubmitted extends AuthEvent {
  const AuthPasswordSetSubmitted({
    required this.requestId,
    required this.code,
    required this.newPassword,
    required this.deviceId,
    this.deviceName,
  });

  final String requestId;
  final String code;
  final String newPassword;
  final String deviceId;
  final String? deviceName;

  @override
  List<Object?> get props => [requestId, code, newPassword, deviceId, deviceName];
}

class AuthShiftQrScanned extends AuthEvent {
  const AuthShiftQrScanned(this.rawPayload, this.deviceId, {this.deviceName});

  final String rawPayload;
  final String deviceId;
  final String? deviceName;

  @override
  List<Object?> get props => [rawPayload, deviceId, deviceName];
}

/// Emitted when a fresh session is obtained outside the bloc (onboarding
/// completion, org/branch switch) so routing reflects the new state.
class AuthSessionUpdated extends AuthEvent {
  const AuthSessionUpdated(this.session, {this.persist = true});

  final AuthSessionEntity session;
  final bool persist;

  @override
  List<Object?> get props => [session, persist];
}

class AuthBusinessSelected extends AuthEvent {
  const AuthBusinessSelected(this.membership);

  final MembershipEntity membership;

  @override
  List<Object?> get props => [membership];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}
