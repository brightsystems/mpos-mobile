import 'package:mpos_mobile/core/mock/mock_fixtures.dart';
import 'package:mpos_mobile/core/network/api_response.dart';
import 'package:mpos_mobile/features/auth/data/datasources/auth_datasource.dart';
import 'package:mpos_mobile/features/auth/domain/entities/auth_session_entity.dart';
import 'package:mpos_mobile/features/auth/domain/entities/membership_entity.dart';
import 'package:mpos_mobile/features/auth/domain/entities/mpos_roles.dart';
import 'package:mpos_mobile/features/auth/domain/entities/otp_request_entity.dart';
import 'package:mpos_mobile/features/auth/domain/entities/sign_in_result_entity.dart';

/// In-memory auth for `MPOS_MOCK_MODE=true`. Phone number decides the role so
/// every path (onboarding, org admin, manager, cashier, waiter) is testable.
class FakeAuthDatasource implements AuthDatasource {
  static const _devOtp = '123456';

  final Map<String, String> _requestPhones = {};

  @override
  Future<ApiResponse<OtpRequestEntity>> requestOtp({required String phone}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final requestId = 'mock-req-${DateTime.now().millisecondsSinceEpoch}';
    _requestPhones[requestId] = phone;

    return ApiResponse(
      success: true,
      data: OtpRequestEntity(requestId: requestId, expiresInSeconds: 300, devOtp: _devOtp),
    );
  }

  @override
  Future<ApiResponse<SignInResult>> verifyOtp({
    required String requestId,
    required String code,
    required String deviceId,
    String? deviceName,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));

    if (code.trim() != _devOtp) {
      return const ApiResponse(success: false, message: 'Invalid code. Use 123456 in demo mode.');
    }

    final phone = _requestPhones[requestId] ?? '0911000001';

    return ApiResponse(success: true, data: SignInResult.session(_sessionForPhone(phone, deviceId, LoginMethod.otp)));
  }

  @override
  Future<ApiResponse<SignInResult>> selectTenant({
    required String challengeId,
    required String tenantId,
    required String deviceId,
  }) async {
    return const ApiResponse(success: false, message: 'Demo mode has a single workspace.');
  }

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
      data: _sessionForRole(
        phone: MockFixtures.waiterPhone,
        userId: MockFixtures.waiterUserId,
        userName: MockFixtures.waiterName,
        branchRole: MposRoles.waiter,
        deviceId: deviceId,
        loginMethod: LoginMethod.shift,
      ),
    );
  }

  @override
  Future<ApiResponse<AuthSessionEntity>> refresh({required String refreshToken, required String deviceId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));

    return ApiResponse(success: true, data: _sessionForPhone('0911000001', deviceId, LoginMethod.otp));
  }

  AuthSessionEntity _sessionForPhone(String phone, String deviceId, LoginMethod loginMethod) {
    switch (phone) {
      case '0911000002':
        return _sessionForRole(
          phone: phone,
          userId: 'mock-manager',
          userName: 'Meaza Manager',
          branchRole: MposRoles.branchManager,
          deviceId: deviceId,
          loginMethod: loginMethod,
        );
      case '0911000003':
        return _sessionForRole(
          phone: phone,
          userId: 'mock-cashier',
          userName: 'Kebede Cashier',
          branchRole: MposRoles.cashier,
          deviceId: deviceId,
          loginMethod: loginMethod,
        );
      case '0911000004':
        return _sessionForRole(
          phone: phone,
          userId: MockFixtures.waiterUserId,
          userName: MockFixtures.waiterName,
          branchRole: MposRoles.waiter,
          deviceId: deviceId,
          loginMethod: loginMethod,
        );
      case '0911000001':
        return _sessionForRole(
          phone: phone,
          userId: 'mock-owner',
          userName: 'Sara Owner',
          organizationRole: MposRoles.owner,
          branchRole: MposRoles.branchManager,
          deviceId: deviceId,
          loginMethod: loginMethod,
        );
      default:
        // New phone -> no memberships -> onboarding flow.
        return AuthSessionEntity(
          accessToken: 'mock-access-token',
          refreshToken: 'mock-refresh-token',
          expiresInSeconds: 1800,
          userId: 'mock-new-user',
          userPhone: phone,
          deviceId: deviceId,
          loginMethod: loginMethod,
        );
    }
  }

  AuthSessionEntity _sessionForRole({
    required String phone,
    required String userId,
    required String userName,
    String? organizationRole,
    String? branchRole,
    required String deviceId,
    required LoginMethod loginMethod,
  }) {
    return AuthSessionEntity(
      accessToken: 'mock-access-token',
      refreshToken: 'mock-refresh-token',
      expiresInSeconds: 1800,
      userId: userId,
      userPhone: phone,
      userName: userName,
      organizationId: MockFixtures.organizationId,
      branchId: MockFixtures.branchId,
      organizationName: MockFixtures.organizationName,
      branchName: MockFixtures.branchName,
      organizationRole: organizationRole,
      role: branchRole,
      loginMethod: loginMethod,
      deviceId: deviceId,
      memberships: [
        MembershipEntity(
          organizationId: MockFixtures.organizationId,
          organizationName: MockFixtures.organizationName,
          organizationRole: organizationRole,
          branchId: MockFixtures.branchId,
          branchName: MockFixtures.branchName,
          branchRole: branchRole,
        ),
      ],
    );
  }
}
