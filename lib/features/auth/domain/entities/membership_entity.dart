import 'package:equatable/equatable.dart';

import 'package:mpos_mobile/core/utilities/phone_number.dart';

/// A user's membership in an organization and/or a branch, returned by the API
/// on every auth response (`memberships[]`). Mirrors mpos-web `AuthMembership`.
class MembershipEntity extends Equatable {
  const MembershipEntity({
    required this.organizationId,
    this.organizationName,
    this.organizationRole,
    this.branchId,
    this.branchName,
    this.branchRole,
    this.roleDefinitionId,
    this.permissions = const [],
  });

  factory MembershipEntity.fromJson(Map<String, dynamic> json) {
    String? readString(String camel, String pascal) {
      final value = json[camel] ?? json[pascal];
      if (value == null) {
        return null;
      }
      final text = '$value'.trim();
      return text.isEmpty || text == 'null' || text == PhoneNumber.emptyGuid ? null : text;
    }

    final rawPermissions = json['permissions'] ?? json['Permissions'];
    final permissions = rawPermissions is List
        ? rawPermissions.map((e) => '$e').where((e) => e.isNotEmpty).toList()
        : const <String>[];

    return MembershipEntity(
      organizationId: readString('organizationId', 'OrganizationId') ?? '',
      organizationName: readString('organizationName', 'OrganizationName'),
      organizationRole: readString('organizationRole', 'OrganizationRole'),
      branchId: readString('branchId', 'BranchId'),
      branchName: readString('branchName', 'BranchName'),
      branchRole: readString('branchRole', 'BranchRole'),
      roleDefinitionId: readString('roleDefinitionId', 'RoleDefinitionId'),
      permissions: permissions,
    );
  }

  final String organizationId;
  final String? organizationName;
  final String? organizationRole;
  final String? branchId;
  final String? branchName;
  final String? branchRole;
  final String? roleDefinitionId;
  final List<String> permissions;

  bool get hasOrganization => PhoneNumber.isUsableId(organizationId);

  bool get hasBranch => PhoneNumber.isUsableId(branchId);

  Map<String, dynamic> toJson() => {
    'organizationId': organizationId,
    'organizationName': organizationName,
    'organizationRole': organizationRole,
    'branchId': branchId,
    'branchName': branchName,
    'branchRole': branchRole,
    'roleDefinitionId': roleDefinitionId,
    'permissions': permissions,
  };

  @override
  List<Object?> get props => [
    organizationId,
    organizationName,
    organizationRole,
    branchId,
    branchName,
    branchRole,
    roleDefinitionId,
    permissions,
  ];
}
