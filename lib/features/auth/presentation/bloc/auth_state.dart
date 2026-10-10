import 'package:equatable/equatable.dart';

import 'package:mpos_mobile/features/auth/domain/entities/auth_session_entity.dart';
import 'package:mpos_mobile/features/auth/domain/entities/sign_in_result_entity.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

/// A one-time OTP request is in flight.
class AuthOtpSending extends AuthState {
  const AuthOtpSending();
}

/// OTP was sent; the phone-login screen moves to code entry.
class AuthOtpSent extends AuthState {
  const AuthOtpSent({required this.phone, required this.requestId, required this.expiresInSeconds, this.devOtp});

  final String phone;
  final String requestId;
  final int expiresInSeconds;
  final String? devOtp;

  @override
  List<Object?> get props => [phone, requestId, expiresInSeconds, devOtp];
}

/// The code was right but the phone is known in several workspaces -> choose one.
class AuthNeedsTenantSelection extends AuthState {
  const AuthNeedsTenantSelection({required this.challengeId, required this.choices});

  final String challengeId;
  final List<TenantChoiceEntity> choices;

  @override
  List<Object?> get props => [challengeId, choices];
}

/// Signed in and has an organization -> route by role.
class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.session);

  final AuthSessionEntity session;

  @override
  List<Object?> get props => [session];
}

/// Signed in but has no organization -> first-time business setup.
class AuthNeedsOnboarding extends AuthState {
  const AuthNeedsOnboarding(this.session);

  final AuthSessionEntity session;

  @override
  List<Object?> get props => [session];
}

/// Signed in with one or more businesses -> choose which to open.
class AuthNeedsBusinessSelection extends AuthState {
  const AuthNeedsBusinessSelection(this.session);

  final AuthSessionEntity session;

  @override
  List<Object?> get props => [session];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated({this.message});

  final String? message;

  @override
  List<Object?> get props => [message];
}
