import 'package:mpos_mobile/features/auth/domain/entities/auth_session_entity.dart';

/// Capability checks. Owner/OrgAdmin keep full access; other staff use permission claims.
extension AuthSessionRbac on AuthSessionEntity {
  bool get canManageOrganization => isOrgAdmin || hasPermission('org:manage');

  bool get canManageBranchResources => canManageBranch;

  bool get canViewOrdersHistory => canManageBranch || hasPermission('orders:view');

  bool get canManageStaff => canManageBranch || hasPermission('members:branch:manage');

  bool get canManageMenu => canManageBranch || hasPermission('menu:branch:edit') || hasPermission('menu:org:edit');

  bool get canCreateBranch => isOrgAdmin || hasPermission('branches:manage');

  bool get canManageSettings => isOrgAdmin || hasPermission('org:manage');

  bool get canManageRoles => isOrgAdmin || hasPermission('roles:manage');

  bool get canPayCash => hasPermission('orders:pay:cash');

  bool get canPayChapa => hasPermission('orders:pay:chapa');

  bool get canPayTelebirr => hasPermission('orders:pay:telebirr');

  bool get canCollectPayment => canPayCash || canPayChapa || canPayTelebirr;

  bool get canCreateOrders => hasPermission('orders:create');

  /// Admin shell for org admins or anyone with manage-style permissions.
  bool get usesAdminShell =>
      isOrgAdmin ||
      canManageBranch ||
      hasPermission('roles:manage') ||
      hasPermission('branches:manage') ||
      hasPermission('org:manage') ||
      hasPermission('members:org:manage') ||
      hasPermission('menu:org:edit');

  String get roleLabel {
    if (isOrgAdmin) {
      return organizationRole ?? 'Org Admin';
    }
    if (role != null && role!.isNotEmpty) {
      return role!;
    }
    return 'Staff';
  }
}
