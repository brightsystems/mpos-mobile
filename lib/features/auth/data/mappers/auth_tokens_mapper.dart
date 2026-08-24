import 'package:mpos_mobile/features/auth/domain/entities/auth_session_entity.dart';
import 'package:mpos_mobile/features/auth/domain/entities/membership_entity.dart';
import 'package:mpos_mobile/features/auth/domain/entities/mpos_roles.dart';

/// Maps an `AuthTokensResponseDto` (from `/auth/otp/verify`, `/auth/shift/login`,
/// `/auth/refresh`, and `/onboarding/business`) into an [AuthSessionEntity].
///
/// The active membership is chosen the same way mpos-web does: prefer an
/// organization-role membership, then a branch membership, then any org.
AuthSessionEntity mapAuthTokens(
  Map<String, dynamic> json, {
  required String deviceId,
  required LoginMethod loginMethod,
}) {
  final user = Map<String, dynamic>.from((json['user'] ?? json['User'] ?? const {}) as Map);

  final memberships = ((json['memberships'] ?? json['Memberships']) as List<dynamic>? ?? const [])
      .map((e) => MembershipEntity.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();

  final active = _selectActiveMembership(memberships);

  return AuthSessionEntity(
    accessToken: (json['accessToken'] ?? json['AccessToken']) as String,
    refreshToken: (json['refreshToken'] ?? json['RefreshToken']) as String,
    expiresInSeconds: (json['expiresInSeconds'] ?? json['ExpiresInSeconds'] ?? 1800) as int,
    userId: '${user['id'] ?? user['Id'] ?? ''}',
    userPhone: (user['phone'] ?? user['Phone'] ?? '') as String,
    userName: (user['fullName'] ?? user['FullName']) as String?,
    isPlatformAdmin: (user['isPlatformAdmin'] ?? user['IsPlatformAdmin'] ?? false) as bool,
    organizationId: active?.organizationId ?? '',
    branchId: active?.branchId ?? '',
    organizationName: active?.organizationName,
    branchName: active?.branchName,
    organizationRole: active?.organizationRole,
    role: active?.branchRole,
    roleDefinitionId: active?.roleDefinitionId,
    permissions: _mergePermissions(memberships),
    memberships: memberships,
    loginMethod: loginMethod,
    deviceId: deviceId,
  );
}

List<String> _mergePermissions(List<MembershipEntity> memberships) {
  final set = <String>{};
  for (final m in memberships) {
    set.addAll(m.permissions);
  }
  return set.toList();
}

MembershipEntity? _selectActiveMembership(List<MembershipEntity> memberships) {
  if (memberships.isEmpty) {
    return null;
  }

  for (final m in memberships) {
    if ((m.organizationRole ?? '').isNotEmpty && m.hasOrganization) {
      return m;
    }
  }

  for (final m in memberships) {
    if (m.hasBranch && m.hasOrganization) {
      return m;
    }
  }

  for (final m in memberships) {
    if (m.hasOrganization) {
      return m;
    }
  }

  return memberships.first;
}
