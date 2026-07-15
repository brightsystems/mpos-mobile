import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mpos_mobile/core/usecase/no_param.dart';
import 'package:mpos_mobile/features/auth/domain/usecases/auth_usecases.dart';
import 'package:mpos_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:mpos_mobile/features/auth/presentation/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required LoadSessionUsecase loadSessionUsecase,
    required ShiftLoginUsecase shiftLoginUsecase,
    required LogoutUsecase logoutUsecase,
  }) : _loadSessionUsecase = loadSessionUsecase,
       _shiftLoginUsecase = shiftLoginUsecase,
       _logoutUsecase = logoutUsecase,
       super(const AuthInitial()) {
    on<AuthStarted>(_onStarted);
    on<AuthShiftQrScanned>(_onShiftQrScanned);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  final LoadSessionUsecase _loadSessionUsecase;
  final ShiftLoginUsecase _shiftLoginUsecase;
  final LogoutUsecase _logoutUsecase;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());

    final result = await _loadSessionUsecase(NoParam());

    if (result.isSuccess && result.data != null) {
      emit(AuthAuthenticated(result.data!));

      return;
    }

    emit(const AuthUnauthenticated());
  }

  Future<void> _onShiftQrScanned(AuthShiftQrScanned event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());

    final token = _extractShiftToken(event.rawPayload);

    if (token == null) {
      emit(const AuthUnauthenticated(message: 'Invalid shift QR code.'));

      return;
    }

    final result = await _shiftLoginUsecase(
      ShiftLoginParams(token: token, deviceId: event.deviceId, deviceName: event.deviceName),
    );

    if (result.isSuccess && result.data != null) {
      emit(AuthAuthenticated(result.data!));

      return;
    }

    emit(AuthUnauthenticated(message: result.error?.toString() ?? 'Shift login failed.'));
  }

  Future<void> _onLogoutRequested(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    await _logoutUsecase(NoParam());
    emit(const AuthUnauthenticated());
  }

  String? _extractShiftToken(String rawPayload) {
    try {
      final decoded = jsonDecode(rawPayload) as Map<String, dynamic>;

      if (decoded['type'] == 'mpos_shift' && decoded['token'] is String) {
        return decoded['token'] as String;
      }
    } catch (_) {
      // Not JSON — treat entire payload as token fallback.
    }

    if (rawPayload.trim().isNotEmpty) {
      return rawPayload.trim();
    }

    return null;
  }
}
