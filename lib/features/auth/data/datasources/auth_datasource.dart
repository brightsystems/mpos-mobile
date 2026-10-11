import 'package:mpos_mobile/core/network/api_response.dart';
import 'package:mpos_mobile/features/auth/domain/entities/auth_session_entity.dart';
import 'package:mpos_mobile/features/auth/domain/entities/otp_request_entity.dart';
import 'package:mpos_mobile/features/auth/domain/entities/password_login_outcome.dart';

abstract class AuthDatasource {
  Future<ApiResponse<OtpRequestEntity>> requestOtp({required String phone});

  /// Daily sign-in with phone + password.
  Future<ApiResponse<PasswordLoginOutcome>> loginWithPassword({
    required String phone,
    required String password,
    required String deviceId,
    String? deviceName,
  });

  /// First or forgotten password: SMS code from [requestOtp] + new password, then signed in.
  Future<ApiResponse<AuthSessionEntity>> setPasswordWithOtp({
    required String requestId,
    required String code,
    required String newPassword,
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
