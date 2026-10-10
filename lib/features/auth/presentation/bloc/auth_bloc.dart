import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mpos_mobile/core/usecase/no_param.dart';
import 'package:mpos_mobile/core/utilities/phone_number.dart';
import 'package:mpos_mobile/features/auth/domain/entities/auth_session_entity.dart';
import 'package:mpos_mobile/features/auth/domain/entities/sign_in_result_entity.dart';
import 'package:mpos_mobile/features/auth/domain/usecases/auth_usecases.dart';
import 'package:mpos_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:mpos_mobile/features/auth/presentation/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required LoadSessionUsecase loadSessionUsecase,
    required RequestOtpUsecase requestOtpUsecase,
    required VerifyOtpUsecase verifyOtpUsecase,
    required SelectTenantUsecase selectTenantUsecase,
    required ShiftLoginUsecase shiftLoginUsecase,
    required SaveSessionUsecase saveSessionUsecase,
    required LogoutUsecase logoutUsecase,
  }) : _loadSessionUsecase = loadSessionUsecase,
       _requestOtpUsecase = requestOtpUsecase,
       _verifyOtpUsecase = verifyOtpUsecase,
       _selectTenantUsecase = selectTenantUsecase,
       _shiftLoginUsecase = shiftLoginUsecase,
       _saveSessionUsecase = saveSessionUsecase,
       _logoutUsecase = logoutUsecase,
       super(const AuthInitial()) {
    on<AuthStarted>(_onStarted);
    on<AuthOtpRequested>(_onOtpRequested);
    on<AuthOtpVerified>(_onOtpVerified);
    on<AuthTenantChosen>(_onTenantChosen);
    on<AuthShiftQrScanned>(_onShiftQrScanned);
    on<AuthSessionUpdated>(_onSessionUpdated);
    on<AuthBusinessSelected>(_onBusinessSelected);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  final LoadSessionUsecase _loadSessionUsecase;
  final RequestOtpUsecase _requestOtpUsecase;
  final VerifyOtpUsecase _verifyOtpUsecase;
  final SelectTenantUsecase _selectTenantUsecase;
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

  Future<void> _onOtpRequested(AuthOtpRequested event, Emitter<AuthState> emit) async {
    final validationError = PhoneNumber.validate(event.phone);
    if (validationError != null) {
      emit(AuthUnauthenticated(message: validationError));
      return;
    }

    emit(const AuthOtpSending());
    final normalized = PhoneNumber.normalize(event.phone);
    final result = await _requestOtpUsecase(normalized);

    if (result.isSuccess && result.data != null) {
      emit(
        AuthOtpSent(
          phone: normalized,
          requestId: result.data!.requestId,
          expiresInSeconds: result.data!.expiresInSeconds,
          devOtp: result.data!.devOtp,
        ),
      );
      return;
    }

    emit(AuthUnauthenticated(message: result.error?.toString() ?? 'Could not send the code. Try again.'));
  }

  Future<void> _onOtpVerified(AuthOtpVerified event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await _verifyOtpUsecase(
      VerifyOtpParams(
        requestId: event.requestId,
        code: event.code,
        deviceId: event.deviceId,
        deviceName: event.deviceName,
      ),
    );

    if (result.isSuccess && result.data != null) {
      await _emitForSignIn(result.data!, emit);
      return;
    }

    emit(AuthUnauthenticated(message: result.error?.toString() ?? 'Invalid code. Try again.'));
  }

  Future<void> _onTenantChosen(AuthTenantChosen event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await _selectTenantUsecase(
      SelectTenantParams(challengeId: event.challengeId, tenantId: event.tenantId, deviceId: event.deviceId),
    );

    if (result.isSuccess && result.data != null) {
      await _emitForSignIn(result.data!, emit);
      return;
    }

    emit(AuthUnauthenticated(message: result.error?.toString() ?? 'Could not sign in to that workspace. Try again.'));
  }

  Future<void> _emitForSignIn(SignInResult result, Emitter<AuthState> emit) async {
    final session = result.session;
    if (session == null) {
      emit(AuthNeedsTenantSelection(challengeId: result.tenantChallengeId ?? '', choices: result.tenantChoices));
      return;
    }

    await _emitForSession(session, emit);
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
