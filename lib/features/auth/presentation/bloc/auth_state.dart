import 'package:equatable/equatable.dart';

import 'package:mpos_mobile/features/auth/domain/entities/auth_session_entity.dart';

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

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated({this.message});

  final String? message;

  @override
  List<Object?> get props => [message];
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.session);

  final AuthSessionEntity session;

  @override
  List<Object?> get props => [session];
}
