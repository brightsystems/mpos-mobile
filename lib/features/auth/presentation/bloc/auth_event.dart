import 'package:equatable/equatable.dart';

import 'package:mpos_mobile/features/auth/domain/entities/auth_session_entity.dart';
import 'package:mpos_mobile/features/auth/domain/entities/membership_entity.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {
  const AuthStarted();
}

class AuthOtpRequested extends AuthEvent {
  const AuthOtpRequested(this.phone);

  final String phone;

  @override
  List<Object?> get props => [phone];
}

class AuthOtpVerified extends AuthEvent {
  const AuthOtpVerified({required this.requestId, required this.code, required this.deviceId, this.deviceName});

  final String requestId;
  final String code;
  final String deviceId;
  final String? deviceName;

  @override
  List<Object?> get props => [requestId, code, deviceId, deviceName];
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
