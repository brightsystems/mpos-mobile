import 'package:mpos_mobile/core/network/api_response.dart';
import 'package:mpos_mobile/features/auth/domain/entities/auth_session_entity.dart';
import 'package:mpos_mobile/features/auth/domain/entities/otp_request_entity.dart';

abstract class AuthDatasource {
  Future<ApiResponse<OtpRequestEntity>> requestOtp({required String phone});

  Future<ApiResponse<AuthSessionEntity>> verifyOtp({
    required String requestId,
    required String code,
    required String deviceId,
    String? deviceName,
  });

  Future<ApiResponse<AuthSessionEntity>> shiftLogin({
    required String token,
    required String deviceId,
    String? deviceName,
  });

  Future<ApiResponse<AuthSessionEntity>> refresh({required String refreshToken, required String deviceId});
}
