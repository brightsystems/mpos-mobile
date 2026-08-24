import 'package:equatable/equatable.dart';

import 'package:mpos_mobile/core/utilities/phone_number.dart';
import 'package:mpos_mobile/features/auth/domain/entities/membership_entity.dart';
import 'package:mpos_mobile/features/auth/domain/entities/mpos_roles.dart';

class AuthSessionEntity extends Equatable {
  const AuthSessionEntity({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresInSeconds,
    required this.userId,
    required this.userPhone,
    this.userName,
    this.isPlatformAdmin = false,
    this.organizationId = '',
    this.branchId = '',
    this.organizationName,
    this.branchName,
    this.organizationRole,
    this.role,
    this.roleDefinitionId,
    this.permissions = const [],
    this.memberships = const [],
    this.loginMethod = LoginMethod.otp,
    required this.deviceId,
  });

  factory AuthSessionEntity.fromJson(Map<String, dynamic> json) {
    final rawPermissions = json['permissions'];
    final permissions = rawPermissions is List
        ? rawPermissions.map((e) => '$e').where((e) => e.isNotEmpty).toList()
        : const <String>[];

    return AuthSessionEntity(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresInSeconds: json['expiresInSeconds'] as int,
      userId: json['userId'] as String,
      userPhone: json['userPhone'] as String,
      userName: json['userName'] as String?,
      isPlatformAdmin: json['isPlatformAdmin'] as bool? ?? false,
      organizationId: json['organizationId'] as String? ?? '',
      branchId: json['branchId'] as String? ?? '',
      organizationName: json['organizationName'] as String?,
      branchName: json['branchName'] as String?,
      organizationRole: json['organizationRole'] as String?,
      role: json['role'] as String?,
      roleDefinitionId: json['roleDefinitionId'] as String?,
      permissions: permissions,
      memberships:
          (json['memberships'] as List<dynamic>?)
              ?.map((e) => MembershipEntity.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      loginMethod: (json['loginMethod'] as String?) == 'shift' ? LoginMethod.shift : LoginMethod.otp,
      deviceId: json['deviceId'] as String,
    );
  }

  final String accessToken;
  final String refreshToken;
  final int expiresInSeconds;
  final String userId;
  final String userPhone;
  final String? userName;
  final bool isPlatformAdmin;
  final String organizationId;
  final String branchId;
  final String? organizationName;
  final String? branchName;
  final String? organizationRole;
  final String? role;
  final String? roleDefinitionId;
  final List<String> permissions;
  final List<MembershipEntity> memberships;
  final LoginMethod loginMethod;
  final String deviceId;

  String? get branchRole => role;

  bool get hasOrganization => PhoneNumber.isUsableId(organizationId);

  bool get hasBranch => PhoneNumber.isUsableId(branchId);

  List<MembershipEntity> get selectableBusinesses {
    final byOrg = <String, MembershipEntity>{};

    for (final membership in memberships.where((m) => m.hasOrganization)) {
      final existing = byOrg[membership.organizationId];
      if (existing == null) {
        byOrg[membership.organizationId] = membership;
        continue;
      }

      final preferOrgRole =
          (membership.organizationRole ?? '').isNotEmpty && (existing.organizationRole ?? '').isEmpty;
      final fillBranch = !existing.hasBranch && membership.hasBranch;

      if (preferOrgRole || fillBranch) {
        byOrg[membership.organizationId] = MembershipEntity(
          organizationId: membership.organizationId,
          organizationName: membership.organizationName ?? existing.organizationName,
          organizationRole: membership.organizationRole ?? existing.organizationRole,
          branchId: membership.branchId ?? existing.branchId,
          branchName: membership.branchName ?? existing.branchName,
          branchRole: membership.branchRole ?? existing.branchRole,
          roleDefinitionId: membership.roleDefinitionId ?? existing.roleDefinitionId,
          permissions: membership.permissions.isNotEmpty ? membership.permissions : existing.permissions,
        );
      }
    }

    return byOrg.values.toList()
      ..sort((a, b) => (a.organizationName ?? '').compareTo(b.organizationName ?? ''));
  }

  bool get needsOnboarding => selectableBusinesses.isEmpty;

  bool get needsBusinessSelection =>
      selectableBusinesses.length > 1 || (selectableBusinesses.isNotEmpty && !hasOrganization);

  bool get isOrgAdmin => MposRoles.isOrgAdminRole(organizationRole);

  bool hasPermission(String code) {
    if (isOrgAdmin) {
      return true;
    }
    return permissions.any((p) => p.toLowerCase() == code.toLowerCase());
  }

  bool get canManageBranch =>
      isOrgAdmin ||
      hasPermission('members:branch:manage') ||
      hasPermission('menu:branch:edit') ||
      MposRoles.isBranchManagerRole(role);

  bool get isFloorStaff => !isOrgAdmin && !canManageBranch;

  AuthSessionEntity selectMembership(MembershipEntity membership) {
    final merged = <String>{
      ...permissions,
      ...membership.permissions,
      for (final m in memberships.where((x) => x.organizationId == membership.organizationId))
        ...m.permissions,
    };

    return AuthSessionEntity(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresInSeconds: expiresInSeconds,
      userId: userId,
      userPhone: userPhone,
      userName: userName,
      isPlatformAdmin: isPlatformAdmin,
      organizationId: membership.organizationId,
      branchId: membership.branchId ?? '',
      organizationName: membership.organizationName,
      branchName: membership.branchName,
      organizationRole: membership.organizationRole,
      role: membership.branchRole,
      roleDefinitionId: membership.roleDefinitionId,
      permissions: merged.toList(),
      memberships: memberships,
      loginMethod: loginMethod,
      deviceId: deviceId,
    );
  }

  AuthSessionEntity copyWith({
    String? accessToken,
    String? refreshToken,
    int? expiresInSeconds,
    String? organizationId,
    String? branchId,
    String? organizationName,
    String? branchName,
    String? organizationRole,
    String? role,
    String? roleDefinitionId,
    List<String>? permissions,
    List<MembershipEntity>? memberships,
  }) {
    return AuthSessionEntity(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresInSeconds: expiresInSeconds ?? this.expiresInSeconds,
      userId: userId,
      userPhone: userPhone,
      userName: userName,
      isPlatformAdmin: isPlatformAdmin,
      organizationId: organizationId ?? this.organizationId,
      branchId: branchId ?? this.branchId,
      organizationName: organizationName ?? this.organizationName,
      branchName: branchName ?? this.branchName,
      organizationRole: organizationRole ?? this.organizationRole,
      role: role ?? this.role,
      roleDefinitionId: roleDefinitionId ?? this.roleDefinitionId,
      permissions: permissions ?? this.permissions,
      memberships: memberships ?? this.memberships,
      loginMethod: loginMethod,
      deviceId: deviceId,
    );
  }

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'expiresInSeconds': expiresInSeconds,
    'userId': userId,
    'userPhone': userPhone,
    'userName': userName,
    'isPlatformAdmin': isPlatformAdmin,
    'organizationId': organizationId,
    'branchId': branchId,
    'organizationName': organizationName,
    'branchName': branchName,
    'organizationRole': organizationRole,
    'role': role,
    'roleDefinitionId': roleDefinitionId,
    'permissions': permissions,
    'memberships': memberships.map((m) => m.toJson()).toList(),
    'loginMethod': loginMethod == LoginMethod.shift ? 'shift' : 'otp',
    'deviceId': deviceId,
  };

  @override
  List<Object?> get props => [userId, organizationId, branchId, accessToken, role, organizationRole, permissions];
}
