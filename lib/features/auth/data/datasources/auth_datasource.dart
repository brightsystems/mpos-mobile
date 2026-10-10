import 'package:mpos_mobile/core/network/api_response.dart';
import 'package:mpos_mobile/features/auth/domain/entities/auth_session_entity.dart';
import 'package:mpos_mobile/features/auth/domain/entities/otp_request_entity.dart';
import 'package:mpos_mobile/features/auth/domain/entities/sign_in_result_entity.dart';

abstract class AuthDatasource {
  Future<ApiResponse<OtpRequestEntity>> requestOtp({required String phone});

  Future<ApiResponse<SignInResult>> verifyOtp({
    required String requestId,
    required String code,
    required String deviceId,
    String? deviceName,
  });

  /// Picks the workspace after [verifyOtp] answered with a tenant choice.
  Future<ApiResponse<SignInResult>> selectTenant({
    required String challengeId,
    required String tenantId,
    required String deviceId,
  });

  Future<ApiResponse<AuthSessionEntity>> shiftLogin({
    required String token,
    required String deviceId,
    String? deviceName,
  });

  Future<ApiResponse<AuthSessionEntity>> refresh({required String refreshToken, required String deviceId});
}
