import 'package:equatable/equatable.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {
  const AuthStarted();
}

class AuthShiftQrScanned extends AuthEvent {
  const AuthShiftQrScanned(this.rawPayload, this.deviceId, {this.deviceName});

  final String rawPayload;
  final String deviceId;
  final String? deviceName;

  @override
  List<Object?> get props => [rawPayload, deviceId, deviceName];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}
