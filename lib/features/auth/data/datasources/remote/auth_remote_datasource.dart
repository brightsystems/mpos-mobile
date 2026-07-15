import 'package:mpos_mobile/core/network/api_response.dart';
import 'package:mpos_mobile/core/network/mpos_api_client.dart';
import 'package:mpos_mobile/features/auth/data/datasources/auth_datasource.dart';
import 'package:mpos_mobile/features/auth/domain/entities/auth_session_entity.dart';

class AuthRemoteDatasource implements AuthDatasource {
  AuthRemoteDatasource(this._client);

  final MposApiClient _client;

  Future<ApiResponse<AuthSessionEntity>> shiftLogin({
    required String token,
    required String deviceId,
    String? deviceName,
  }) {
    return _client.post(
      '/auth/shift/login',
      body: {'token': token, 'deviceId': deviceId, if (deviceName != null) 'deviceName': deviceName},
      fromJson: (json) => _mapAuthSession(json as Map<String, dynamic>, deviceId),
    );
  }

  AuthSessionEntity _mapAuthSession(Map<String, dynamic> json, String deviceId) {
    final user = (json['user'] ?? json['User']) as Map<String, dynamic>? ?? {};
    final memberships = (json['memberships'] as List<dynamic>?) ?? (json['Memberships'] as List<dynamic>?) ?? [];
    final membership = memberships.isNotEmpty ? Map<String, dynamic>.from(memberships.first as Map) : <String, dynamic>{};

    final organizationId = '${membership['organizationId'] ?? membership['OrganizationId'] ?? ''}';
    final branchId = '${membership['branchId'] ?? membership['BranchId'] ?? ''}';

    if (organizationId.isEmpty || organizationId == 'null' || branchId.isEmpty || branchId == 'null') {
      throw StateError('Shift login response missing organization or branch membership.');
    }

    return AuthSessionEntity(
      accessToken: json['accessToken'] as String? ?? json['AccessToken'] as String,
      refreshToken: json['refreshToken'] as String? ?? json['RefreshToken'] as String,
      expiresInSeconds: json['expiresInSeconds'] as int? ?? json['ExpiresInSeconds'] as int,
      userId: '${user['id'] ?? user['Id']}',
      userPhone: user['phone'] as String? ?? user['Phone'] as String? ?? '',
      userName: user['fullName'] as String? ?? user['FullName'] as String?,
      organizationId: organizationId,
      branchId: branchId,
      organizationName: membership['organizationName'] as String? ?? membership['OrganizationName'] as String?,
      branchName: membership['branchName'] as String? ?? membership['BranchName'] as String?,
      role: membership['branchRole'] as String? ?? membership['BranchRole'] as String?,
      deviceId: deviceId,
    );
  }
}
