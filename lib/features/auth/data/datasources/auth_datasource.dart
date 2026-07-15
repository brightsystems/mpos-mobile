import 'package:mpos_mobile/core/network/api_response.dart';
import 'package:mpos_mobile/features/auth/domain/entities/auth_session_entity.dart';

abstract class AuthDatasource {
  Future<ApiResponse<AuthSessionEntity>> shiftLogin({
    required String token,
    required String deviceId,
    String? deviceName,
  });
}
