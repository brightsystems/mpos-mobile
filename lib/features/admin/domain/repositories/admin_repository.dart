import 'package:mpos_mobile/core/common/result.dart';
import 'package:mpos_mobile/features/admin/data/models/admin_models.dart';

abstract class AdminRepository {
  Future<Result<List<OrganizationModel>>> listOrganizations();
  Future<Result<OrganizationModel>> getOrganization(String orgId);
  Future<Result<OrganizationModel>> updateOrganization(String orgId, Map<String, dynamic> body);
  Future<Result<BankAccountModel?>> getBankAccount(String orgId);
  Future<Result<BankAccountModel>> upsertBankAccount(String orgId, Map<String, dynamic> body);

  Future<Result<List<TaxModel>>> listTaxes(String orgId);
  Future<Result<TaxModel>> createTax(String orgId, Map<String, dynamic> body);
  Future<Result<TaxModel>> updateTax(String orgId, String taxId, Map<String, dynamic> body);
  Future<Result<void>> deleteTax(String orgId, String taxId);

  Future<Result<PaymentSettingsModel>> getPaymentSettings(String orgId);
  Future<Result<PaymentSettingsModel>> updatePaymentSettings(String orgId, Map<String, dynamic> body);

  Future<Result<MorSettingsModel?>> getMorSettings(String orgId);
  Future<Result<MorSettingsModel>> updateMorSettings(String orgId, Map<String, dynamic> body);

  Future<Result<List<BranchModel>>> listBranches(String orgId);
  Future<Result<BranchModel>> getBranch(String branchId);
  Future<Result<BranchModel>> createBranch(String orgId, Map<String, dynamic> body);
  Future<Result<BranchModel>> updateBranch(String branchId, Map<String, dynamic> body);

  Future<Result<List<MemberModel>>> listBranchMembers(String branchId);
  Future<Result<List<MemberModel>>> listOrgBranchMembers(String orgId, {String? branchId});
  Future<Result<MemberModel>> assignBranchMember(String branchId, {required String phone, required String roleDefinitionId});
  Future<Result<MemberModel>> assignOrgMember(String orgId, {required String phone, required String role});
  Future<Result<ShiftQrModel>> generateShiftQr(String branchId, String userId);

  Future<Result<PermissionCatalogModel>> getPermissionCatalog();
  Future<Result<List<OrganizationRoleModel>>> listRoles(String orgId);
  Future<Result<OrganizationRoleModel>> createRole(String orgId, Map<String, dynamic> body);
  Future<Result<OrganizationRoleModel>> updateRole(String orgId, String roleId, Map<String, dynamic> body);
  Future<Result<OrganizationRoleModel>> setRolePermissions(String orgId, String roleId, List<String> permissions);
  Future<Result<void>> deleteRole(String orgId, String roleId);

  Future<Result<List<AdminMenuItemModel>>> listBranchMenu(String branchId);
  Future<Result<List<MenuCategoryModel>>> listOrgCategories(String orgId);
  Future<Result<List<MenuCategoryModel>>> listBranchCategories(String branchId);
  Future<Result<MenuCategoryModel>> createOrgCategory(String orgId, Map<String, dynamic> body);
  Future<Result<MenuCategoryModel>> createBranchCategory(String branchId, Map<String, dynamic> body);
  Future<Result<AdminMenuItemModel>> createOrgItem(String orgId, Map<String, dynamic> body);
  Future<Result<AdminMenuItemModel>> createBranchItem(String branchId, Map<String, dynamic> body);
  Future<Result<AdminMenuItemModel>> updateItem(String itemId, Map<String, dynamic> body);

  Future<Result<PagedOrdersModel>> listOrders(String branchId, Map<String, String> query);
  Future<Result<OrderSummaryModel>> getOrderSummary(String branchId);
  Future<Result<OrderDetailModel>> getOrder(String orderId);
}
