/// Role name constants matching the mpos-api enums
/// (`OrganizationRole` and `BranchRole`). Role strings are compared
/// case-insensitively because the API returns enum names.
class MposRoles {
  MposRoles._();

  // Organization-level roles.
  static const String owner = 'Owner';
  static const String orgAdmin = 'OrgAdmin';

  // Branch-level roles.
  static const String branchManager = 'BranchManager';
  static const String cashier = 'Cashier';
  static const String waiter = 'Waiter';

  static bool isOrgAdminRole(String? role) {
    final normalized = role?.toLowerCase();
    return normalized == owner.toLowerCase() || normalized == orgAdmin.toLowerCase();
  }

  static bool isBranchManagerRole(String? role) => role?.toLowerCase() == branchManager.toLowerCase();

  static bool isCashierRole(String? role) => role?.toLowerCase() == cashier.toLowerCase();

  static bool isWaiterRole(String? role) => role?.toLowerCase() == waiter.toLowerCase();

  static bool isFloorRole(String? role) => isCashierRole(role) || isWaiterRole(role);
}

/// How the current session was established.
enum LoginMethod { otp, shift }
