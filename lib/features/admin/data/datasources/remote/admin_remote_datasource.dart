import 'package:mpos_mobile/core/network/api_response.dart';
import 'package:mpos_mobile/core/network/json_reader.dart';
import 'package:mpos_mobile/core/network/mpos_api_client.dart';
import 'package:mpos_mobile/features/admin/data/datasources/admin_datasource.dart';
import 'package:mpos_mobile/features/admin/data/models/admin_models.dart';

class AdminRemoteDatasource implements AdminDatasource {
  AdminRemoteDatasource(this._client);

  final MposApiClient _client;

  T _unwrap<T>(ApiResponse<T> response) {
    if (!response.success || response.data == null) {
      throw response.message ?? (response.errors.isNotEmpty ? response.errors.join(', ') : 'Request failed.');
    }
    return response.data as T;
  }

  List<Map<String, dynamic>> _asList(Object? json) {
    if (json is List) {
      return json.whereType<Map<String, dynamic>>().toList();
    }
    if (json is Map<String, dynamic>) {
      return JsonReader(json).listOfMaps('items');
    }
    return const [];
  }

  // Organizations.

  @override
  Future<List<OrganizationModel>> listOrganizations() async {
    final response = await _client.get(
      '/organizations',
      authenticated: true,
      fromJson: (json) => _asList(json).map(OrganizationModel.fromJson).toList(),
    );
    return _unwrap(response);
  }

  @override
  Future<OrganizationModel> getOrganization(String orgId) async {
    final response = await _client.get(
      '/organizations/$orgId',
      authenticated: true,
      fromJson: (json) => OrganizationModel.fromJson(json as Map<String, dynamic>),
    );
    return _unwrap(response);
  }

  @override
  Future<OrganizationModel> updateOrganization(String orgId, Map<String, dynamic> body) async {
    final response = await _client.put(
      '/organizations/$orgId',
      body: body,
      authenticated: true,
      fromJson: (json) => OrganizationModel.fromJson(json as Map<String, dynamic>),
    );
    return _unwrap(response);
  }

  @override
  Future<BankAccountModel?> getBankAccount(String orgId) async {
    final response = await _client.get(
      '/organizations/$orgId/bank-account',
      authenticated: true,
      fromJson: (json) => json == null ? null : BankAccountModel.fromJson(json as Map<String, dynamic>),
    );
    if (!response.success) {
      throw response.message ?? 'Request failed.';
    }
    return response.data;
  }

  @override
  Future<BankAccountModel> upsertBankAccount(String orgId, Map<String, dynamic> body) async {
    final response = await _client.put(
      '/organizations/$orgId/bank-account',
      body: body,
      authenticated: true,
      fromJson: (json) => BankAccountModel.fromJson(json as Map<String, dynamic>),
    );
    return _unwrap(response);
  }

  // Taxes.

  @override
  Future<List<TaxModel>> listTaxes(String orgId) async {
    final response = await _client.get(
      '/organizations/$orgId/taxes',
      authenticated: true,
      fromJson: (json) => _asList(json).map(TaxModel.fromJson).toList(),
    );
    return _unwrap(response);
  }

  @override
  Future<TaxModel> createTax(String orgId, Map<String, dynamic> body) async {
    final response = await _client.post(
      '/organizations/$orgId/taxes',
      body: body,
      authenticated: true,
      fromJson: (json) => TaxModel.fromJson(json as Map<String, dynamic>),
    );
    return _unwrap(response);
  }

  @override
  Future<TaxModel> updateTax(String orgId, String taxId, Map<String, dynamic> body) async {
    final response = await _client.put(
      '/organizations/$orgId/taxes/$taxId',
      body: body,
      authenticated: true,
      fromJson: (json) => TaxModel.fromJson(json as Map<String, dynamic>),
    );
    return _unwrap(response);
  }

  @override
  Future<void> deleteTax(String orgId, String taxId) async {
    final response = await _client.delete('/organizations/$orgId/taxes/$taxId', authenticated: true);
    if (!response.success) {
      throw response.message ?? 'Request failed.';
    }
  }

  // Payment settings.

  @override
  Future<PaymentSettingsModel> getPaymentSettings(String orgId) async {
    final response = await _client.get(
      '/organizations/$orgId/payment-settings',
      authenticated: true,
      fromJson: (json) => PaymentSettingsModel.fromJson(json as Map<String, dynamic>),
    );
    return _unwrap(response);
  }

  @override
  Future<PaymentSettingsModel> updatePaymentSettings(String orgId, Map<String, dynamic> body) async {
    final response = await _client.put(
      '/organizations/$orgId/payment-settings',
      body: body,
      authenticated: true,
      fromJson: (json) => PaymentSettingsModel.fromJson(json as Map<String, dynamic>),
    );
    return _unwrap(response);
  }

  // MOR settings.

  @override
  Future<MorSettingsModel?> getMorSettings(String orgId) async {
    final response = await _client.get(
      '/organizations/$orgId/mor-settings',
      authenticated: true,
      fromJson: (json) => json == null ? null : MorSettingsModel.fromJson(json as Map<String, dynamic>),
    );
    if (!response.success) {
      throw response.message ?? 'Request failed.';
    }
    return response.data;
  }

  @override
  Future<MorSettingsModel> updateMorSettings(String orgId, Map<String, dynamic> body) async {
    final response = await _client.put(
      '/organizations/$orgId/mor-settings',
      body: body,
      authenticated: true,
      fromJson: (json) => MorSettingsModel.fromJson(json as Map<String, dynamic>),
    );
    return _unwrap(response);
  }

  // Branches.

  @override
  Future<List<BranchModel>> listBranches(String orgId) async {
    final response = await _client.get(
      '/organizations/$orgId/branches',
      authenticated: true,
      fromJson: (json) => _asList(json).map(BranchModel.fromJson).toList(),
    );
    return _unwrap(response);
  }

  @override
  Future<BranchModel> getBranch(String branchId) async {
    final response = await _client.get(
      '/branches/$branchId',
      authenticated: true,
      fromJson: (json) => BranchModel.fromJson(json as Map<String, dynamic>),
    );
    return _unwrap(response);
  }

  @override
  Future<BranchModel> createBranch(String orgId, Map<String, dynamic> body) async {
    final response = await _client.post(
      '/organizations/$orgId/branches',
      body: body,
      authenticated: true,
      fromJson: (json) => BranchModel.fromJson(json as Map<String, dynamic>),
    );
    return _unwrap(response);
  }

  @override
  Future<BranchModel> updateBranch(String branchId, Map<String, dynamic> body) async {
    final response = await _client.put(
      '/branches/$branchId',
      body: body,
      authenticated: true,
      fromJson: (json) => BranchModel.fromJson(json as Map<String, dynamic>),
    );
    return _unwrap(response);
  }

  // Staff / members.

  @override
  Future<List<MemberModel>> listBranchMembers(String branchId) async {
    final response = await _client.get(
      '/branches/$branchId/members',
      authenticated: true,
      fromJson: (json) => _asList(json).map(MemberModel.fromJson).toList(),
    );
    return _unwrap(response);
  }

  @override
  Future<List<MemberModel>> listOrgBranchMembers(String orgId, {String? branchId}) async {
    final query = branchId == null ? '' : '?branchId=$branchId';
    final response = await _client.get(
      '/organizations/$orgId/branch-members$query',
      authenticated: true,
      fromJson: (json) => _asList(json).map(MemberModel.fromJson).toList(),
    );
    return _unwrap(response);
  }

  @override
  Future<MemberModel> assignBranchMember(String branchId, {required String phone, required String roleDefinitionId}) async {
    final response = await _client.post(
      '/branches/$branchId/members',
      body: {'phone': phone, 'roleDefinitionId': roleDefinitionId},
      authenticated: true,
      fromJson: (json) => MemberModel.fromJson(json as Map<String, dynamic>),
    );
    return _unwrap(response);
  }

  @override
  Future<MemberModel> assignOrgMember(String orgId, {required String phone, required String role}) async {
    final response = await _client.post(
      '/organizations/$orgId/members',
      body: {'phone': phone, 'role': role},
      authenticated: true,
      fromJson: (json) => MemberModel.fromJson(json as Map<String, dynamic>),
    );
    return _unwrap(response);
  }

  @override
  Future<ShiftQrModel> generateShiftQr(String branchId, String userId) async {
    final response = await _client.post(
      '/branches/$branchId/members/$userId/shift-qr',
      body: const {},
      authenticated: true,
      fromJson: (json) => ShiftQrModel.fromJson(json as Map<String, dynamic>),
    );
    return _unwrap(response);
  }

  @override
  Future<PermissionCatalogModel> getPermissionCatalog() async {
    final response = await _client.get(
      '/permissions/catalog',
      authenticated: true,
      fromJson: (json) => PermissionCatalogModel.fromJson(json as Map<String, dynamic>),
    );
    return _unwrap(response);
  }

  @override
  Future<List<OrganizationRoleModel>> listRoles(String orgId) async {
    final response = await _client.get(
      '/organizations/$orgId/roles',
      authenticated: true,
      fromJson: (json) => _asList(json).map(OrganizationRoleModel.fromJson).toList(),
    );
    return _unwrap(response);
  }

  @override
  Future<OrganizationRoleModel> createRole(String orgId, Map<String, dynamic> body) async {
    final response = await _client.post(
      '/organizations/$orgId/roles',
      body: body,
      authenticated: true,
      fromJson: (json) => OrganizationRoleModel.fromJson(json as Map<String, dynamic>),
    );
    return _unwrap(response);
  }

  @override
  Future<OrganizationRoleModel> updateRole(String orgId, String roleId, Map<String, dynamic> body) async {
    final response = await _client.put(
      '/organizations/$orgId/roles/$roleId',
      body: body,
      authenticated: true,
      fromJson: (json) => OrganizationRoleModel.fromJson(json as Map<String, dynamic>),
    );
    return _unwrap(response);
  }

  @override
  Future<OrganizationRoleModel> setRolePermissions(String orgId, String roleId, List<String> permissions) async {
    final response = await _client.put(
      '/organizations/$orgId/roles/$roleId/permissions',
      body: {'permissions': permissions},
      authenticated: true,
      fromJson: (json) => OrganizationRoleModel.fromJson(json as Map<String, dynamic>),
    );
    return _unwrap(response);
  }

  @override
  Future<void> deleteRole(String orgId, String roleId) async {
    final response = await _client.delete(
      '/organizations/$orgId/roles/$roleId',
      authenticated: true,
      fromJson: (_) => null,
    );
    _unwrap(response);
  }

  // Menu.

  @override
  Future<List<AdminMenuItemModel>> listBranchMenu(String branchId) async {
    final response = await _client.get(
      '/branches/$branchId/menu',
      authenticated: true,
      fromJson: (json) => JsonReader(json as Map<String, dynamic>).listOfMaps('items').map(AdminMenuItemModel.fromJson).toList(),
    );
    return _unwrap(response);
  }

  @override
  Future<List<MenuCategoryModel>> listOrgCategories(String orgId) async {
    final response = await _client.get(
      '/organizations/$orgId/menu/categories',
      authenticated: true,
      fromJson: (json) => _asList(json).map(MenuCategoryModel.fromJson).toList(),
    );
    return _unwrap(response);
  }

  @override
  Future<List<MenuCategoryModel>> listBranchCategories(String branchId) async {
    final response = await _client.get(
      '/branches/$branchId/menu/categories',
      authenticated: true,
      fromJson: (json) => _asList(json).map(MenuCategoryModel.fromJson).toList(),
    );
    return _unwrap(response);
  }

  @override
  Future<MenuCategoryModel> createOrgCategory(String orgId, Map<String, dynamic> body) async {
    final response = await _client.post(
      '/organizations/$orgId/menu/categories',
      body: body,
      authenticated: true,
      fromJson: (json) => MenuCategoryModel.fromJson(json as Map<String, dynamic>),
    );
    return _unwrap(response);
  }

  @override
  Future<MenuCategoryModel> createBranchCategory(String branchId, Map<String, dynamic> body) async {
    final response = await _client.post(
      '/branches/$branchId/menu/categories',
      body: body,
      authenticated: true,
      fromJson: (json) => MenuCategoryModel.fromJson(json as Map<String, dynamic>),
    );
    return _unwrap(response);
  }

  @override
  Future<AdminMenuItemModel> createOrgItem(String orgId, Map<String, dynamic> body) async {
    final response = await _client.post(
      '/organizations/$orgId/menu/items',
      body: body,
      authenticated: true,
      fromJson: (json) => AdminMenuItemModel.fromJson(json as Map<String, dynamic>),
    );
    return _unwrap(response);
  }

  @override
  Future<AdminMenuItemModel> createBranchItem(String branchId, Map<String, dynamic> body) async {
    final response = await _client.post(
      '/branches/$branchId/menu/items',
      body: body,
      authenticated: true,
      fromJson: (json) => AdminMenuItemModel.fromJson(json as Map<String, dynamic>),
    );
    return _unwrap(response);
  }

  @override
  Future<AdminMenuItemModel> updateItem(String itemId, Map<String, dynamic> body) async {
    final response = await _client.put(
      '/menu/items/$itemId',
      body: body,
      authenticated: true,
      fromJson: (json) => AdminMenuItemModel.fromJson(json as Map<String, dynamic>),
    );
    return _unwrap(response);
  }

  // Orders.

  @override
  Future<PagedOrdersModel> listOrders(String branchId, Map<String, String> query) async {
    final queryString = query.isEmpty
        ? ''
        : '?${query.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&')}';
    final response = await _client.get(
      '/branches/$branchId/orders$queryString',
      authenticated: true,
      fromJson: (json) => PagedOrdersModel.fromJson(json as Map<String, dynamic>),
    );
    return _unwrap(response);
  }

  @override
  Future<OrderSummaryModel> getOrderSummary(String branchId) async {
    final paged = await listOrders(branchId, {
      'status': 'all',
      'page': '1',
      'pageSize': '1',
      'includeSummary': 'true',
    });
    return paged.summary;
  }

  @override
  Future<OrderDetailModel> getOrder(String orderId) async {
    final response = await _client.get(
      '/orders/$orderId',
      authenticated: true,
      fromJson: (json) => OrderDetailModel.fromJson(json as Map<String, dynamic>),
    );
    return _unwrap(response);
  }
}
