import 'package:mpos_mobile/core/mock/mock_fixtures.dart';
import 'package:mpos_mobile/core/network/api_response.dart';
import 'package:mpos_mobile/features/auth/data/datasources/auth_datasource.dart';
import 'package:mpos_mobile/features/auth/domain/entities/auth_session_entity.dart';

class FakeAuthDatasource implements AuthDatasource {
  @override
  Future<ApiResponse<AuthSessionEntity>> shiftLogin({
    required String token,
    required String deviceId,
    String? deviceName,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));

    if (token.trim().isEmpty) {
      return const ApiResponse(success: false, message: 'Invalid shift QR code.');
    }

    return ApiResponse(
      success: true,
      data: AuthSessionEntity(
        accessToken: 'mock-access-token',
        refreshToken: 'mock-refresh-token',
        expiresInSeconds: 86400,
        userId: MockFixtures.waiterUserId,
        userPhone: MockFixtures.waiterPhone,
        userName: MockFixtures.waiterName,
        organizationId: MockFixtures.organizationId,
        branchId: MockFixtures.branchId,
        organizationName: MockFixtures.organizationName,
        branchName: MockFixtures.branchName,
        role: 'Waiter',
        deviceId: deviceId,
      ),
    );
  }
}
