import 'package:mpos_mobile/core/common/result.dart';
import 'package:mpos_mobile/features/auth/domain/entities/auth_session_entity.dart';
import 'package:mpos_mobile/features/auth/domain/entities/sign_in_result_entity.dart';
import 'package:mpos_mobile/features/auth/domain/entities/otp_request_entity.dart';

abstract class AuthRepository {
  Future<Result<OtpRequestEntity>> requestOtp({required String phone});

  /// Signs in with the code; the result is a saved session or the workspaces to choose from.
  Future<Result<SignInResult>> verifyOtp({
    required String requestId,
    required String code,
    required String deviceId,
    String? deviceName,
  });

  Future<Result<SignInResult>> selectTenant({
    required String challengeId,
    required String tenantId,
    required String deviceId,
  });

  Future<Result<AuthSessionEntity>> shiftLogin({required String token, required String deviceId, String? deviceName});

  Future<Result<AuthSessionEntity>> refresh({required String refreshToken, required String deviceId});

  Future<Result<AuthSessionEntity?>> loadSavedSession();

  Future<Result<void>> saveSession(AuthSessionEntity session);

  Future<Result<void>> logout();
}
