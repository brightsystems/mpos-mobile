import 'package:mpos_mobile/core/network/api_response.dart';
import 'package:mpos_mobile/core/network/mpos_api_client.dart';
import 'package:mpos_mobile/features/auth/data/datasources/auth_datasource.dart';
import 'package:mpos_mobile/features/auth/data/mappers/auth_tokens_mapper.dart';
import 'package:mpos_mobile/features/auth/domain/entities/auth_session_entity.dart';
import 'package:mpos_mobile/features/auth/domain/entities/mpos_roles.dart';
import 'package:mpos_mobile/features/auth/domain/entities/otp_request_entity.dart';
import 'package:mpos_mobile/features/auth/domain/entities/sign_in_result_entity.dart';

class AuthRemoteDatasource implements AuthDatasource {
  AuthRemoteDatasource(this._client);

  final MposApiClient _client;

  @override
  Future<ApiResponse<OtpRequestEntity>> requestOtp({required String phone}) {
    return _client.post(
      '/auth/otp/request',
      body: {'phone': phone},
      fromJson: (json) => OtpRequestEntity.fromJson(json as Map<String, dynamic>),
    );
  }

  @override
  Future<ApiResponse<SignInResult>> verifyOtp({
    required String requestId,
    required String code,
    required String deviceId,
    String? deviceName,
  }) {
    return _client.post(
      '/auth/otp/verify',
      body: {
        'requestId': requestId,
        'code': code,
        'deviceId': deviceId,
        if (deviceName != null) 'deviceName': deviceName,
      },
      fromJson: (json) => mapSignInResult(json as Map<String, dynamic>, deviceId: deviceId),
    );
  }

  @override
  Future<ApiResponse<SignInResult>> selectTenant({
    required String challengeId,
    required String tenantId,
    required String deviceId,
  }) {
    return _client.post(
      '/auth/tenant/select',
      body: {'challengeId': challengeId, 'tenantId': tenantId, 'deviceId': deviceId},
      fromJson: (json) => mapSignInResult(json as Map<String, dynamic>, deviceId: deviceId),
    );
  }

  @override
  Future<ApiResponse<AuthSessionEntity>> shiftLogin({
    required String token,
    required String deviceId,
    String? deviceName,
  }) {
    return _client.post(
      '/auth/shift/login',
      body: {'token': token, 'deviceId': deviceId, if (deviceName != null) 'deviceName': deviceName},
      fromJson: (json) =>
          mapAuthTokens(json as Map<String, dynamic>, deviceId: deviceId, loginMethod: LoginMethod.shift),
    );
  }

  @override
  Future<ApiResponse<AuthSessionEntity>> refresh({required String refreshToken, required String deviceId}) {
    return _client.post(
      '/auth/refresh',
      body: {'refreshToken': refreshToken, 'deviceId': deviceId},
      fromJson: (json) => mapAuthTokens(json as Map<String, dynamic>, deviceId: deviceId, loginMethod: LoginMethod.otp),
    );
  }
}
