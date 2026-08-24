import 'package:mpos_mobile/core/common/result.dart';
import 'package:mpos_mobile/features/admin/data/datasources/admin_datasource.dart';
import 'package:mpos_mobile/features/admin/data/models/admin_models.dart';
import 'package:mpos_mobile/features/admin/domain/repositories/admin_repository.dart';

class AdminRepositoryImpl implements AdminRepository {
  AdminRepositoryImpl(this._datasource);

  final AdminDatasource _datasource;

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Result.success(data: await action());
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<List<OrganizationModel>>> listOrganizations() => _guard(_datasource.listOrganizations);

  @override
  Future<Result<OrganizationModel>> getOrganization(String orgId) => _guard(() => _datasource.getOrganization(orgId));

  @override
  Future<Result<OrganizationModel>> updateOrganization(String orgId, Map<String, dynamic> body) =>
      _guard(() => _datasource.updateOrganization(orgId, body));

  @override
  Future<Result<BankAccountModel?>> getBankAccount(String orgId) => _guard(() => _datasource.getBankAccount(orgId));

  @override
  Future<Result<BankAccountModel>> upsertBankAccount(String orgId, Map<String, dynamic> body) =>
      _guard(() => _datasource.upsertBankAccount(orgId, body));

  @override
  Future<Result<List<TaxModel>>> listTaxes(String orgId) => _guard(() => _datasource.listTaxes(orgId));

  @override
  Future<Result<TaxModel>> createTax(String orgId, Map<String, dynamic> body) =>
      _guard(() => _datasource.createTax(orgId, body));

  @override
  Future<Result<TaxModel>> updateTax(String orgId, String taxId, Map<String, dynamic> body) =>
      _guard(() => _datasource.updateTax(orgId, taxId, body));

  @override
  Future<Result<void>> deleteTax(String orgId, String taxId) => _guard(() => _datasource.deleteTax(orgId, taxId));

  @override
  Future<Result<PaymentSettingsModel>> getPaymentSettings(String orgId) =>
      _guard(() => _datasource.getPaymentSettings(orgId));

  @override
  Future<Result<PaymentSettingsModel>> updatePaymentSettings(String orgId, Map<String, dynamic> body) =>
      _guard(() => _datasource.updatePaymentSettings(orgId, body));

  @override
  Future<Result<MorSettingsModel?>> getMorSettings(String orgId) => _guard(() => _datasource.getMorSettings(orgId));

  @override
  Future<Result<MorSettingsModel>> updateMorSettings(String orgId, Map<String, dynamic> body) =>
      _guard(() => _datasource.updateMorSettings(orgId, body));

  @override
  Future<Result<List<BranchModel>>> listBranches(String orgId) => _guard(() => _datasource.listBranches(orgId));

  @override
  Future<Result<BranchModel>> getBranch(String branchId) => _guard(() => _datasource.getBranch(branchId));

  @override
  Future<Result<BranchModel>> createBranch(String orgId, Map<String, dynamic> body) =>
      _guard(() => _datasource.createBranch(orgId, body));

  @override
  Future<Result<BranchModel>> updateBranch(String branchId, Map<String, dynamic> body) =>
      _guard(() => _datasource.updateBranch(branchId, body));

  @override
  Future<Result<List<MemberModel>>> listBranchMembers(String branchId) =>
      _guard(() => _datasource.listBranchMembers(branchId));

  @override
  Future<Result<List<MemberModel>>> listOrgBranchMembers(String orgId, {String? branchId}) =>
      _guard(() => _datasource.listOrgBranchMembers(orgId, branchId: branchId));

  @override
  Future<Result<MemberModel>> assignBranchMember(String branchId, {required String phone, required String roleDefinitionId}) =>
      _guard(() => _datasource.assignBranchMember(branchId, phone: phone, roleDefinitionId: roleDefinitionId));

  @override
  Future<Result<MemberModel>> assignOrgMember(String orgId, {required String phone, required String role}) =>
      _guard(() => _datasource.assignOrgMember(orgId, phone: phone, role: role));

  @override
  Future<Result<ShiftQrModel>> generateShiftQr(String branchId, String userId) =>
      _guard(() => _datasource.generateShiftQr(branchId, userId));

  @override
  Future<Result<PermissionCatalogModel>> getPermissionCatalog() =>
      _guard(() => _datasource.getPermissionCatalog());

  @override
  Future<Result<List<OrganizationRoleModel>>> listRoles(String orgId) =>
      _guard(() => _datasource.listRoles(orgId));

  @override
  Future<Result<OrganizationRoleModel>> createRole(String orgId, Map<String, dynamic> body) =>
      _guard(() => _datasource.createRole(orgId, body));

  @override
  Future<Result<OrganizationRoleModel>> updateRole(String orgId, String roleId, Map<String, dynamic> body) =>
      _guard(() => _datasource.updateRole(orgId, roleId, body));

  @override
  Future<Result<OrganizationRoleModel>> setRolePermissions(String orgId, String roleId, List<String> permissions) =>
      _guard(() => _datasource.setRolePermissions(orgId, roleId, permissions));

  @override
  Future<Result<void>> deleteRole(String orgId, String roleId) =>
      _guard(() => _datasource.deleteRole(orgId, roleId));

  @override
  Future<Result<List<AdminMenuItemModel>>> listBranchMenu(String branchId) =>
      _guard(() => _datasource.listBranchMenu(branchId));

  @override
  Future<Result<List<MenuCategoryModel>>> listOrgCategories(String orgId) =>
      _guard(() => _datasource.listOrgCategories(orgId));

  @override
  Future<Result<List<MenuCategoryModel>>> listBranchCategories(String branchId) =>
      _guard(() => _datasource.listBranchCategories(branchId));

  @override
  Future<Result<MenuCategoryModel>> createOrgCategory(String orgId, Map<String, dynamic> body) =>
      _guard(() => _datasource.createOrgCategory(orgId, body));

  @override
  Future<Result<MenuCategoryModel>> createBranchCategory(String branchId, Map<String, dynamic> body) =>
      _guard(() => _datasource.createBranchCategory(branchId, body));

  @override
  Future<Result<AdminMenuItemModel>> createOrgItem(String orgId, Map<String, dynamic> body) =>
      _guard(() => _datasource.createOrgItem(orgId, body));

  @override
  Future<Result<AdminMenuItemModel>> createBranchItem(String branchId, Map<String, dynamic> body) =>
      _guard(() => _datasource.createBranchItem(branchId, body));

  @override
  Future<Result<AdminMenuItemModel>> updateItem(String itemId, Map<String, dynamic> body) =>
      _guard(() => _datasource.updateItem(itemId, body));

  @override
  Future<Result<PagedOrdersModel>> listOrders(String branchId, Map<String, String> query) =>
      _guard(() => _datasource.listOrders(branchId, query));

  @override
  Future<Result<OrderSummaryModel>> getOrderSummary(String branchId) =>
      _guard(() => _datasource.getOrderSummary(branchId));

  @override
  Future<Result<OrderDetailModel>> getOrder(String orderId) => _guard(() => _datasource.getOrder(orderId));
}
