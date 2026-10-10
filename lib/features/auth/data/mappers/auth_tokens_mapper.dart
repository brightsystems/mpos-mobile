import 'package:mpos_mobile/features/auth/domain/entities/auth_session_entity.dart';
import 'package:mpos_mobile/features/auth/domain/entities/membership_entity.dart';
import 'package:mpos_mobile/features/auth/domain/entities/mpos_roles.dart';
import 'package:mpos_mobile/features/auth/domain/entities/sign_in_result_entity.dart';

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

/// Maps the response of `/auth/otp/verify` or `/auth/tenant/select`: tokens, or (when the phone is
/// known in several workspaces) the workspaces to choose from.
SignInResult mapSignInResult(Map<String, dynamic> json, {required String deviceId}) {
  if ((json['requiresTenantSelection'] ?? json['RequiresTenantSelection'] ?? false) == true) {
    return SignInResult.chooseTenant(
      tenantChallengeId: '${json['tenantChallengeId'] ?? json['TenantChallengeId'] ?? ''}',
      tenantChoices: ((json['tenantChoices'] ?? json['TenantChoices']) as List<dynamic>? ?? const [])
          .map((e) => TenantChoiceEntity.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  if ((json['requiresPin'] ?? json['RequiresPin'] ?? false) == true) {
    throw const PinSignInNotSupported();
  }

  return SignInResult.session(mapAuthTokens(json, deviceId: deviceId, loginMethod: LoginMethod.otp));
}

/// Privileged accounts with a PIN must finish sign-in with the PIN, which the app doesn't offer yet.
class PinSignInNotSupported implements Exception {
  const PinSignInNotSupported();

  @override
  String toString() => 'This account signs in with a PIN, which the app does not support yet. Sign in on the web.';
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
