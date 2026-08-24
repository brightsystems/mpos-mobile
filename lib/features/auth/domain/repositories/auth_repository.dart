import 'package:mpos_mobile/core/common/result.dart';
import 'package:mpos_mobile/features/auth/domain/entities/auth_session_entity.dart';
import 'package:mpos_mobile/features/auth/domain/entities/otp_request_entity.dart';

abstract class AuthRepository {
  Future<Result<OtpRequestEntity>> requestOtp({required String phone});

  Future<Result<AuthSessionEntity>> verifyOtp({
    required String requestId,
    required String code,
    required String deviceId,
    String? deviceName,
  });

  Future<Result<AuthSessionEntity>> shiftLogin({required String token, required String deviceId, String? deviceName});

  Future<Result<AuthSessionEntity>> refresh({required String refreshToken, required String deviceId});

  Future<Result<AuthSessionEntity?>> loadSavedSession();

  Future<Result<void>> saveSession(AuthSessionEntity session);

  Future<Result<void>> logout();
}
