import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mpos_mobile/core/usecase/no_param.dart';
import 'package:mpos_mobile/core/utilities/phone_number.dart';
import 'package:mpos_mobile/features/auth/domain/entities/auth_session_entity.dart';
import 'package:mpos_mobile/features/auth/domain/usecases/auth_usecases.dart';
import 'package:mpos_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:mpos_mobile/features/auth/presentation/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required LoadSessionUsecase loadSessionUsecase,
    required RequestOtpUsecase requestOtpUsecase,
    required PasswordLoginUsecase passwordLoginUsecase,
    required SetPasswordWithOtpUsecase setPasswordWithOtpUsecase,
    required ShiftLoginUsecase shiftLoginUsecase,
    required SaveSessionUsecase saveSessionUsecase,
    required LogoutUsecase logoutUsecase,
  }) : _loadSessionUsecase = loadSessionUsecase,
       _requestOtpUsecase = requestOtpUsecase,
       _passwordLoginUsecase = passwordLoginUsecase,
       _setPasswordWithOtpUsecase = setPasswordWithOtpUsecase,
       _shiftLoginUsecase = shiftLoginUsecase,
       _saveSessionUsecase = saveSessionUsecase,
       _logoutUsecase = logoutUsecase,
       super(const AuthInitial()) {
    on<AuthStarted>(_onStarted);
    on<AuthPasswordLoginRequested>(_onPasswordLoginRequested);
    on<AuthOtpRequested>(_onOtpRequested);
    on<AuthPasswordSetSubmitted>(_onPasswordSetSubmitted);
    on<AuthShiftQrScanned>(_onShiftQrScanned);
    on<AuthSessionUpdated>(_onSessionUpdated);
    on<AuthBusinessSelected>(_onBusinessSelected);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  final LoadSessionUsecase _loadSessionUsecase;
  final RequestOtpUsecase _requestOtpUsecase;
  final PasswordLoginUsecase _passwordLoginUsecase;
  final SetPasswordWithOtpUsecase _setPasswordWithOtpUsecase;
  final ShiftLoginUsecase _shiftLoginUsecase;
  final SaveSessionUsecase _saveSessionUsecase;
  final LogoutUsecase _logoutUsecase;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await _loadSessionUsecase(NoParam());
    if (result.isSuccess && result.data != null) {
      await _emitForSession(result.data!, emit);
      return;
    }
    emit(const AuthUnauthenticated());
  }

  Future<void> _onPasswordLoginRequested(AuthPasswordLoginRequested event, Emitter<AuthState> emit) async {
    final validationError = PhoneNumber.validate(event.phone);
    if (validationError != null) {
      emit(AuthUnauthenticated(message: validationError));
      return;
    }

    if (event.password.isEmpty) {
      emit(const AuthUnauthenticated(message: 'Enter your password.'));
      return;
    }

    emit(const AuthLoading());
    final normalized = PhoneNumber.normalize(event.phone);
    final result = await _passwordLoginUsecase(
      PasswordLoginParams(
        phone: normalized,
        password: event.password,
        deviceId: event.deviceId,
        deviceName: event.deviceName,
      ),
    );

    if (!result.isSuccess || result.data == null) {
      emit(AuthUnauthenticated(message: result.error?.toString() ?? 'Sign-in failed. Try again.'));
      return;
    }

    final session = result.data!.session;
    if (session != null) {
      await _emitForSession(session, emit);
      return;
    }

    // No password yet: verify the phone by SMS code and set one.
    await _sendCode(normalized, PasswordSetupReason.firstTime, emit);
  }

  Future<void> _onOtpRequested(AuthOtpRequested event, Emitter<AuthState> emit) async {
    final validationError = PhoneNumber.validate(event.phone);
    if (validationError != null) {
      emit(AuthUnauthenticated(message: validationError));
      return;
    }

    await _sendCode(PhoneNumber.normalize(event.phone), event.reason, emit);
  }

  Future<void> _sendCode(String phone, PasswordSetupReason reason, Emitter<AuthState> emit) async {
    emit(const AuthOtpSending());
    final result = await _requestOtpUsecase(phone);

    if (result.isSuccess && result.data != null) {
      emit(
        AuthOtpSent(
          phone: phone,
          requestId: result.data!.requestId,
          expiresInSeconds: result.data!.expiresInSeconds,
          devOtp: result.data!.devOtp,
          reason: reason,
        ),
      );
      return;
    }

    emit(AuthUnauthenticated(message: result.error?.toString() ?? 'Could not send the code. Try again.'));
  }

  Future<void> _onPasswordSetSubmitted(AuthPasswordSetSubmitted event, Emitter<AuthState> emit) async {
    final problem = passwordProblem(event.newPassword);
    if (problem != null) {
      emit(AuthUnauthenticated(message: problem));
      return;
    }

    emit(const AuthLoading());
    final result = await _setPasswordWithOtpUsecase(
      SetPasswordWithOtpParams(
        requestId: event.requestId,
        code: event.code,
        newPassword: event.newPassword,
        deviceId: event.deviceId,
        deviceName: event.deviceName,
      ),
    );

    if (result.isSuccess && result.data != null) {
      await _emitForSession(result.data!, emit);
      return;
    }

    emit(AuthUnauthenticated(message: result.error?.toString() ?? 'Could not set the password. Try again.'));
  }

  /// Client-side copy of the API password policy; null when acceptable.
  static String? passwordProblem(String password) {
    if (password.length < 8) {
      return 'Password must be at least 8 characters.';
    }

    if (password.length > 128) {
      return 'Password must be at most 128 characters.';
    }

    if (!RegExp(r'\p{L}', unicode: true).hasMatch(password) || !RegExp(r'\d').hasMatch(password)) {
      return 'Password must contain at least one letter and one number.';
    }

    return null;
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
      await _emitForSession(result.data!, emit);
      return;
    }

    emit(AuthUnauthenticated(message: result.error?.toString() ?? 'Shift login failed.'));
  }

  Future<void> _onSessionUpdated(AuthSessionUpdated event, Emitter<AuthState> emit) async {
    if (event.persist) {
      await _saveSessionUsecase(event.session);
    }
    await _emitForSession(event.session, emit);
  }

  Future<void> _onBusinessSelected(AuthBusinessSelected event, Emitter<AuthState> emit) async {
    final current = state;
    final AuthSessionEntity? base = switch (current) {
      AuthAuthenticated(:final session) => session,
      AuthNeedsBusinessSelection(:final session) => session,
      AuthNeedsOnboarding(:final session) => session,
      _ => null,
    };
    if (base == null) return;

    final next = base.selectMembership(event.membership);
    await _saveSessionUsecase(next);
    emit(AuthAuthenticated(next));
  }

  Future<void> _onLogoutRequested(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    await _logoutUsecase(NoParam());
    emit(const AuthUnauthenticated());
  }

  Future<void> _emitForSession(AuthSessionEntity session, Emitter<AuthState> emit) async {
    if (session.needsOnboarding) {
      emit(AuthNeedsOnboarding(session));
      return;
    }

    if (session.selectableBusinesses.length == 1 && !session.hasOrganization) {
      final selected = session.selectMembership(session.selectableBusinesses.first);
      await _saveSessionUsecase(selected);
      emit(AuthAuthenticated(selected));
      return;
    }

    if (session.needsBusinessSelection) {
      emit(AuthNeedsBusinessSelection(session));
      return;
    }

    emit(AuthAuthenticated(session));
  }

  String? _extractShiftToken(String rawPayload) {
    try {
      final decoded = jsonDecode(rawPayload) as Map<String, dynamic>;
      if (decoded['type'] == 'mpos_shift' && decoded['token'] is String) {
        return decoded['token'] as String;
      }
    } catch (_) {}
    if (rawPayload.trim().isNotEmpty) return rawPayload.trim();
    return null;
  }
}
