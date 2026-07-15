import 'package:mpos_mobile/core/common/result.dart';
import 'package:mpos_mobile/core/storage/session_storage.dart';
import 'package:mpos_mobile/features/auth/data/datasources/auth_datasource.dart';
import 'package:mpos_mobile/features/auth/domain/entities/auth_session_entity.dart';
import 'package:mpos_mobile/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required AuthDatasource remoteDatasource, required SessionStorage sessionStorage})
    : _remoteDatasource = remoteDatasource,
      _sessionStorage = sessionStorage;

  final AuthDatasource _remoteDatasource;
  final SessionStorage _sessionStorage;

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

      final session = response.data!;

      await _sessionStorage.saveSession(session);

      return Result.success(data: session);
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
  Future<Result<void>> logout() async {
    try {
      await _sessionStorage.clearSession();

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }
}
