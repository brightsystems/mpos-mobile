import 'package:mpos_mobile/core/common/result.dart';
import 'package:mpos_mobile/core/storage/session_storage.dart';
import 'package:mpos_mobile/features/auth/data/datasources/auth_datasource.dart';
import 'package:mpos_mobile/features/auth/domain/entities/auth_session_entity.dart';
import 'package:mpos_mobile/features/auth/domain/entities/otp_request_entity.dart';
import 'package:mpos_mobile/features/auth/domain/entities/password_login_outcome.dart';
import 'package:mpos_mobile/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required AuthDatasource remoteDatasource, required SessionStorage sessionStorage})
    : _remoteDatasource = remoteDatasource,
      _sessionStorage = sessionStorage;

  final AuthDatasource _remoteDatasource;
  final SessionStorage _sessionStorage;

  @override
  Future<Result<OtpRequestEntity>> requestOtp({required String phone}) async {
    try {
      final response = await _remoteDatasource.requestOtp(phone: phone);

      if (!response.success || response.data == null) {
        return Result.failure(error: response.message ?? response.errors.join(', '));
      }

      return Result.success(data: response.data!);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<PasswordLoginOutcome>> loginWithPassword({
    required String phone,
    required String password,
    required String deviceId,
    String? deviceName,
  }) async {
    try {
      final response = await _remoteDatasource.loginWithPassword(
        phone: phone,
        password: password,
        deviceId: deviceId,
        deviceName: deviceName,
      );

      if (!response.success || response.data == null) {
        return Result.failure(error: response.message ?? response.errors.join(', '));
      }

      final session = response.data!.session;
      if (session != null) {
        await _sessionStorage.saveSession(session);
      }

      return Result.success(data: response.data!);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<AuthSessionEntity>> verifyLoginCode({
    required String challengeId,
    required String code,
    required String deviceId,
    String? deviceName,
  }) async {
    try {
      final response = await _remoteDatasource.verifyLoginCode(
        challengeId: challengeId,
        code: code,
        deviceId: deviceId,
        deviceName: deviceName,
      );

      if (!response.success || response.data == null) {
        return Result.failure(error: response.message ?? response.errors.join(', '));
      }

      await _sessionStorage.saveSession(response.data!);
      return Result.success(data: response.data!);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<LoginCodeChallenge>> resendLoginCode({required String challengeId}) async {
    try {
      final response = await _remoteDatasource.resendLoginCode(challengeId: challengeId);

      if (!response.success || response.data == null) {
        return Result.failure(error: response.message ?? response.errors.join(', '));
      }

      return Result.success(data: response.data!);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<AuthSessionEntity>> setPasswordWithOtp({
    required String requestId,
    required String code,
    required String newPassword,
    required String deviceId,
    String? deviceName,
  }) async {
    try {
      final response = await _remoteDatasource.setPasswordWithOtp(
        requestId: requestId,
        code: code,
        newPassword: newPassword,
        deviceId: deviceId,
        deviceName: deviceName,
      );

      if (!response.success || response.data == null) {
        return Result.failure(error: response.message ?? response.errors.join(', '));
      }

      await _sessionStorage.saveSession(response.data!);

      return Result.success(data: response.data!);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<AuthSessionEntity>> shiftLogin({
    required String token,
    required String deviceId,
    String? deviceName,
  }) async {
    try {
      final response = await _remoteDatasource.shiftLogin(token: token, deviceId: deviceId, deviceName: deviceName);

      if (!response.success || response.data == null) {
        return Result.failure(error: response.message ?? response.errors.join(', '));
      }

      await _sessionStorage.saveSession(response.data!);

      return Result.success(data: response.data!);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<AuthSessionEntity>> refresh({required String refreshToken, required String deviceId}) async {
    try {
      final response = await _remoteDatasource.refresh(refreshToken: refreshToken, deviceId: deviceId);

      if (!response.success || response.data == null) {
        return Result.failure(error: response.message ?? response.errors.join(', '));
      }

      await _sessionStorage.saveSession(response.data!);

      return Result.success(data: response.data!);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<AuthSessionEntity?>> loadSavedSession() async {
    try {
      final session = await _sessionStorage.loadSession();

      return Result.success(data: session);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> saveSession(AuthSessionEntity session) async {
    try {
      await _sessionStorage.saveSession(session);

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await _sessionStorage.clearSession();

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }
}
