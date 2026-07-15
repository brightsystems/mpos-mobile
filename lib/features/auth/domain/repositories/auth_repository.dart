import 'package:mpos_mobile/core/common/result.dart';
import 'package:mpos_mobile/features/auth/domain/entities/auth_session_entity.dart';

abstract class AuthRepository {
  Future<Result<AuthSessionEntity>> shiftLogin({required String token, required String deviceId, String? deviceName});

  Future<Result<AuthSessionEntity?>> loadSavedSession();

  Future<Result<void>> logout();
}
