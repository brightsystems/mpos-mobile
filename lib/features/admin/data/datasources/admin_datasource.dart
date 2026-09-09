import 'package:mpos_mobile/features/admin/data/models/admin_models.dart';

/// Grouped admin API surface mirroring the mpos-web admin services.
abstract class AdminDatasource {
  // Organizations.
  Future<List<OrganizationModel>> listOrganizations();
  Future<OrganizationModel> getOrganization(String orgId);
  Future<OrganizationModel> updateOrganization(String orgId, Map<String, dynamic> body);
  Future<BankAccountModel?> getBankAccount(String orgId);
  Future<BankAccountModel> upsertBankAccount(String orgId, Map<String, dynamic> body);

  // Taxes.
  Future<List<TaxModel>> listTaxes(String orgId);
  Future<TaxModel> createTax(String orgId, Map<String, dynamic> body);
  Future<TaxModel> updateTax(String orgId, String taxId, Map<String, dynamic> body);
  Future<void> deleteTax(String orgId, String taxId);

  // Payment settings.
  Future<PaymentSettingsModel> getPaymentSettings(String orgId);
  Future<PaymentSettingsModel> updatePaymentSettings(String orgId, Map<String, dynamic> body);

  // MOR e-invoice settings.
  Future<MorSettingsModel?> getMorSettings(String orgId);
  Future<MorSettingsModel> updateMorSettings(String orgId, Map<String, dynamic> body);

  // Branches.
  Future<List<BranchModel>> listBranches(String orgId);
  Future<BranchModel> getBranch(String branchId);
  Future<BranchModel> createBranch(String orgId, Map<String, dynamic> body);
  Future<BranchModel> updateBranch(String branchId, Map<String, dynamic> body);

  // Staff / members.
  Future<List<MemberModel>> listBranchMembers(String branchId);
  Future<List<MemberModel>> listOrgBranchMembers(String orgId, {String? branchId});
  Future<MemberModel> assignBranchMember(String branchId, {required String phone, required String roleDefinitionId});
  Future<MemberModel> assignOrgMember(String orgId, {required String phone, required String role});
  Future<ShiftQrModel> generateShiftQr(String branchId, String userId);

  // Roles.
  Future<PermissionCatalogModel> getPermissionCatalog();
  Future<List<OrganizationRoleModel>> listRoles(String orgId);
  Future<OrganizationRoleModel> createRole(String orgId, Map<String, dynamic> body);
  Future<OrganizationRoleModel> updateRole(String orgId, String roleId, Map<String, dynamic> body);
  Future<OrganizationRoleModel> setRolePermissions(String orgId, String roleId, List<String> permissions);
  Future<void> deleteRole(String orgId, String roleId);

  // Menu.
  Future<List<AdminMenuItemModel>> listBranchMenu(String branchId);
  Future<List<MenuCategoryModel>> listOrgCategories(String orgId);
  Future<List<MenuCategoryModel>> listBranchCategories(String branchId);
  Future<MenuCategoryModel> createOrgCategory(String orgId, Map<String, dynamic> body);
  Future<MenuCategoryModel> createBranchCategory(String branchId, Map<String, dynamic> body);
  Future<AdminMenuItemModel> createOrgItem(String orgId, Map<String, dynamic> body);
  Future<AdminMenuItemModel> createBranchItem(String branchId, Map<String, dynamic> body);
  Future<AdminMenuItemModel> updateItem(String itemId, Map<String, dynamic> body);

  // HSN codes (excise lookup).
  Future<List<HsnCodeModel>> listHsnCodes({bool activeOnly = true});

  // Orders.
  Future<PagedOrdersModel> listOrders(String branchId, Map<String, String> query);
  Future<OrderSummaryModel> getOrderSummary(String branchId);
  Future<OrderDetailModel> getOrder(String orderId);
}
