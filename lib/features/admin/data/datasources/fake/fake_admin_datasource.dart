import 'package:mpos_mobile/core/mock/mock_fixtures.dart';
import 'package:mpos_mobile/features/admin/data/datasources/admin_datasource.dart';
import 'package:mpos_mobile/features/admin/data/models/admin_models.dart';
import 'package:mpos_mobile/features/auth/domain/entities/mpos_roles.dart';

/// In-memory admin data for `MPOS_MOCK_MODE=true`.
class FakeAdminDatasource implements AdminDatasource {
  OrganizationModel _org = const OrganizationModel(
    id: MockFixtures.organizationId,
    name: MockFixtures.organizationName,
    type: 'Cafeteria',
    tin: '0000123456',
    legalName: MockFixtures.organizationName,
    email: 'demo@mpos.local',
    phone: '+251911000000',
    region: '1',
    wereda: 'Bole',
    vatNumber: 'VAT-DEMO-001',
    city: 'Addis Ababa',
    settlementLevel: 'Organization',
    platformFeePercent: 0,
    isActive: true,
  );

  BankAccountModel? _bank;

  final List<TaxModel> _taxes = [
    const TaxModel(
      id: '99999999-9999-9999-9999-999999999901',
      name: 'VAT 15%',
      code: 'VAT15',
      ratePercent: 15,
      morTaxCode: 'VAT15',
      isActive: true,
      sortOrder: 1,
    ),
    const TaxModel(
      id: '99999999-9999-9999-9999-999999999902',
      name: 'Exempt',
      code: 'EXEMPT',
      ratePercent: 0,
      morTaxCode: 'EXEMPT',
      isActive: true,
      sortOrder: 2,
    ),
  ];

  PaymentSettingsModel _payment = const PaymentSettingsModel(
    organizationId: MockFixtures.organizationId,
    enableCash: true,
    enableChapa: true,
    enableTelebirr: false,
    hasTelebirrCredentials: false,
  );

  MorSettingsModel? _mor;

  final List<BranchModel> _branches = [
    const BranchModel(
      id: MockFixtures.branchId,
      organizationId: MockFixtures.organizationId,
      name: MockFixtures.branchName,
      address: 'Bole Road',
      city: 'Addis Ababa',
      phone: '0911000001',
      timezone: 'Africa/Addis_Ababa',
      tin: '0000123456',
      effectiveTin: '0000123456',
      isActive: true,
    ),
  ];

  final List<MemberModel> _members = [
    const MemberModel(
      userId: 'mock-owner',
      phone: '0911000001',
      fullName: 'Sara Owner',
      role: MposRoles.branchManager,
      isActive: true,
      branchId: MockFixtures.branchId,
      branchName: MockFixtures.branchName,
    ),
    const MemberModel(
      userId: 'mock-cashier',
      phone: '0911000003',
      fullName: 'Kebede Cashier',
      role: MposRoles.cashier,
      isActive: true,
      branchId: MockFixtures.branchId,
      branchName: MockFixtures.branchName,
    ),
    MemberModel(
      userId: MockFixtures.waiterUserId,
      phone: MockFixtures.waiterPhone,
      fullName: MockFixtures.waiterName,
      role: MposRoles.waiter,
      isActive: true,
      branchId: MockFixtures.branchId,
      branchName: MockFixtures.branchName,
    ),
  ];

  final List<MenuCategoryModel> _categories = const [
    MenuCategoryModel(id: MockFixtures.foodCategoryId, name: 'Food', sortOrder: 1),
    MenuCategoryModel(id: MockFixtures.drinksCategoryId, name: 'Drinks', sortOrder: 2),
    MenuCategoryModel(id: MockFixtures.dessertsCategoryId, name: 'Desserts', sortOrder: 3),
    MenuCategoryModel(id: MockFixtures.snacksCategoryId, name: 'Snacks', sortOrder: 4),
  ];

  late final List<AdminMenuItemModel> _items = MockFixtures.menuItems
      .map(
        (item) => AdminMenuItemModel(
          id: item.id,
          categoryId: item.categoryId,
          categoryName: item.categoryName,
          name: item.name,
          price: item.price,
          description: item.description,
          sku: item.sku,
          imageUrl: item.imageUrl,
          taxIds: item.taxes.map((t) => t.id).toList(),
          trackInventory: item.trackInventory,
          stockOnHand: item.stockOnHand,
          isAvailable: item.isAvailable,
          sortOrder: item.sortOrder,
        ),
      )
      .toList();

  Future<T> _delay<T>(T value) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return value;
  }

  @override
  Future<List<OrganizationModel>> listOrganizations() => _delay([_org]);

  @override
  Future<OrganizationModel> getOrganization(String orgId) => _delay(_org);

  @override
  Future<OrganizationModel> updateOrganization(String orgId, Map<String, dynamic> body) {
    _org = OrganizationModel(
      id: _org.id,
      name: (body['name'] as String?) ?? _org.name,
      type: (body['type'] as String?) ?? _org.type,
      tin: (body['tin'] as String?) ?? _org.tin,
      legalName: (body['legalName'] as String?) ?? _org.legalName,
      email: (body['email'] as String?) ?? _org.email,
      phone: (body['phone'] as String?) ?? _org.phone,
      region: (body['region'] as String?) ?? _org.region,
      wereda: (body['wereda'] as String?) ?? _org.wereda,
      vatNumber: (body['vatNumber'] as String?) ?? _org.vatNumber,
      city: body['city'] as String? ?? _org.city,
      houseNumber: body['houseNumber'] as String? ?? _org.houseNumber,
      locality: body['locality'] as String? ?? _org.locality,
      subCity: body['subCity'] as String? ?? _org.subCity,
      settlementLevel: (body['settlementLevel'] as String?) ?? _org.settlementLevel,
      platformFeePercent: _org.platformFeePercent,
      isActive: _org.isActive,
    );
    return _delay(_org);
  }

  @override
  Future<BankAccountModel?> getBankAccount(String orgId) => _delay(_bank);

  @override
  Future<BankAccountModel> upsertBankAccount(String orgId, Map<String, dynamic> body) {
    _bank = BankAccountModel(
      bankName: (body['bankName'] as String?) ?? '',
      accountNumber: (body['accountNumber'] as String?) ?? '',
      accountHolderName: (body['accountHolderName'] as String?) ?? '',
      branchCode: body['branchCode'] as String?,
    );
    return _delay(_bank!);
  }

  @override
  Future<List<TaxModel>> listTaxes(String orgId) => _delay(List.of(_taxes));

  @override
  Future<TaxModel> createTax(String orgId, Map<String, dynamic> body) {
    final tax = TaxModel(
      id: 'tax-${DateTime.now().millisecondsSinceEpoch}',
      name: (body['name'] as String?) ?? '',
      code: (body['code'] as String?) ?? '',
      ratePercent: (body['ratePercent'] as num?)?.toDouble() ?? 0,
      morTaxCode: body['morTaxCode'] as String?,
      isActive: true,
      sortOrder: (body['sortOrder'] as int?) ?? _taxes.length + 1,
    );
    _taxes.add(tax);
    return _delay(tax);
  }

  @override
  Future<TaxModel> updateTax(String orgId, String taxId, Map<String, dynamic> body) {
    final index = _taxes.indexWhere((t) => t.id == taxId);
    final updated = TaxModel(
      id: taxId,
      name: (body['name'] as String?) ?? '',
      code: (body['code'] as String?) ?? '',
      ratePercent: (body['ratePercent'] as num?)?.toDouble() ?? 0,
      morTaxCode: body['morTaxCode'] as String?,
      isActive: (body['isActive'] as bool?) ?? true,
      sortOrder: (body['sortOrder'] as int?) ?? 0,
    );
    if (index >= 0) {
      _taxes[index] = updated;
    }
    return _delay(updated);
  }

  @override
  Future<void> deleteTax(String orgId, String taxId) {
    _taxes.removeWhere((t) => t.id == taxId);
    return _delay(null);
  }

  @override
  Future<PaymentSettingsModel> getPaymentSettings(String orgId) => _delay(_payment);

  @override
  Future<PaymentSettingsModel> updatePaymentSettings(String orgId, Map<String, dynamic> body) {
    _payment = PaymentSettingsModel(
      organizationId: _payment.organizationId,
      enableCash: (body['enableCash'] as bool?) ?? _payment.enableCash,
      enableChapa: (body['enableChapa'] as bool?) ?? _payment.enableChapa,
      enableTelebirr: (body['enableTelebirr'] as bool?) ?? _payment.enableTelebirr,
      hasTelebirrCredentials: _payment.hasTelebirrCredentials,
      telebirrMerchantCode: body['telebirrMerchantCode'] as String? ?? _payment.telebirrMerchantCode,
      telebirrBaseUrl: body['telebirrBaseUrl'] as String? ?? _payment.telebirrBaseUrl,
      telebirrWebBaseUrl: body['telebirrWebBaseUrl'] as String? ?? _payment.telebirrWebBaseUrl,
    );
    return _delay(_payment);
  }

  @override
  Future<MorSettingsModel?> getMorSettings(String orgId) => _delay(_mor);

  @override
  Future<MorSettingsModel> updateMorSettings(String orgId, Map<String, dynamic> body) {
    _mor = MorSettingsModel(
      systemNumber: (body['systemNumber'] as String?) ?? '',
      systemType: body['systemType'] as String?,
      morBaseUrl: body['morBaseUrl'] as String?,
      morClientId: body['morClientId'] as String?,
      morApiKey: body['morApiKey'] as String?,
      isConfigured: true,
    );
    return _delay(_mor!);
  }

  @override
  Future<List<BranchModel>> listBranches(String orgId) => _delay(List.of(_branches));

  @override
  Future<BranchModel> getBranch(String branchId) =>
      _delay(_branches.firstWhere((b) => b.id == branchId, orElse: () => _branches.first));

  @override
  Future<BranchModel> createBranch(String orgId, Map<String, dynamic> body) {
    final branch = BranchModel(
      id: 'branch-${DateTime.now().millisecondsSinceEpoch}',
      organizationId: orgId,
      name: (body['name'] as String?) ?? '',
      address: (body['address'] as String?) ?? '',
      city: (body['city'] as String?) ?? '',
      phone: (body['phone'] as String?) ?? '',
      timezone: (body['timezone'] as String?) ?? 'Africa/Addis_Ababa',
      tin: (body['tin'] as String?) ?? '',
      effectiveTin: (body['tin'] as String?) ?? _org.tin,
      isActive: true,
    );
    _branches.add(branch);
    return _delay(branch);
  }

  @override
  Future<BranchModel> updateBranch(String branchId, Map<String, dynamic> body) {
    final index = _branches.indexWhere((b) => b.id == branchId);
    final existing = index >= 0 ? _branches[index] : _branches.first;
    final updated = BranchModel(
      id: existing.id,
      organizationId: existing.organizationId,
      name: (body['name'] as String?) ?? existing.name,
      address: (body['address'] as String?) ?? existing.address,
      city: (body['city'] as String?) ?? existing.city,
      phone: (body['phone'] as String?) ?? existing.phone,
      timezone: (body['timezone'] as String?) ?? existing.timezone,
      tin: (body['tin'] as String?) ?? existing.tin,
      effectiveTin: (body['tin'] as String?) ?? existing.effectiveTin,
      isActive: (body['isActive'] as bool?) ?? existing.isActive,
    );
    if (index >= 0) {
      _branches[index] = updated;
    }
    return _delay(updated);
  }

  @override
  Future<List<MemberModel>> listBranchMembers(String branchId) =>
      _delay(_members.where((m) => m.branchId == branchId).toList());

  @override
  Future<List<MemberModel>> listOrgBranchMembers(String orgId, {String? branchId}) =>
      _delay(branchId == null ? List.of(_members) : _members.where((m) => m.branchId == branchId).toList());

  @override
  Future<MemberModel> assignBranchMember(String branchId, {required String phone, required String roleDefinitionId}) {
    final member = MemberModel(
      userId: 'user-${DateTime.now().millisecondsSinceEpoch}',
      phone: phone,
      fullName: '',
      role: 'Custom',
      isActive: true,
      branchId: branchId,
      branchName: _branches.firstWhere((b) => b.id == branchId, orElse: () => _branches.first).name,
      roleDefinitionId: roleDefinitionId,
      permissions: const ['orders:view', 'orders:create', 'orders:submit'],
    );
    _members.add(member);
    return _delay(member);
  }

  @override
  Future<MemberModel> assignOrgMember(String orgId, {required String phone, required String role}) {
    final member = MemberModel(
      userId: 'user-${DateTime.now().millisecondsSinceEpoch}',
      phone: phone,
      fullName: '',
      role: role,
      isActive: true,
    );
    _members.add(member);
    return _delay(member);
  }

  @override
  Future<ShiftQrModel> generateShiftQr(String branchId, String userId) {
    final member = _members.firstWhere((m) => m.userId == userId, orElse: () => _members.first);
    return _delay(
      ShiftQrModel(
        branchId: branchId,
        userId: userId,
        qrPayload: '{"type":"mpos_shift","v":1,"token":"${MockFixtures.mockShiftToken}"}',
        expiresAt: DateTime.now().add(const Duration(hours: 8)),
        memberName: member.displayName,
        role: member.role,
      ),
    );
  }

  @override
  Future<PermissionCatalogModel> getPermissionCatalog() => _delay(
    const PermissionCatalogModel(
      modules: [
        PermissionModuleModel(
          module: 'orders',
          label: 'Orders',
          actions: [
            PermissionActionModel(code: 'orders:view', label: 'View', description: 'View orders'),
            PermissionActionModel(code: 'orders:create', label: 'Create', description: 'Create orders'),
            PermissionActionModel(code: 'orders:pay:cash', label: 'Pay cash', description: 'Collect cash'),
          ],
        ),
      ],
    ),
  );

  final _roles = <OrganizationRoleModel>[
    const OrganizationRoleModel(
      id: 'role-waiter',
      organizationId: 'org-1',
      name: 'Waiter',
      code: 'waiter',
      scope: 'Branch',
      isSystemSeed: true,
      isActive: true,
      sortOrder: 1,
      permissions: ['orders:view', 'orders:create', 'orders:submit'],
    ),
    const OrganizationRoleModel(
      id: 'role-cashier',
      organizationId: 'org-1',
      name: 'Cashier',
      code: 'cashier',
      scope: 'Branch',
      isSystemSeed: true,
      isActive: true,
      sortOrder: 2,
      permissions: ['orders:view', 'orders:accept', 'orders:pay:cash'],
    ),
  ];

  @override
  Future<List<OrganizationRoleModel>> listRoles(String orgId) => _delay(List.of(_roles));

  @override
  Future<OrganizationRoleModel> createRole(String orgId, Map<String, dynamic> body) {
    final role = OrganizationRoleModel(
      id: 'role-${DateTime.now().millisecondsSinceEpoch}',
      organizationId: orgId,
      name: '${body['name']}',
      code: '${body['code'] ?? body['name']}'.toLowerCase().replaceAll(' ', '_'),
      description: body['description'] as String?,
      scope: '${body['scope'] ?? 'Branch'}',
      isSystemSeed: false,
      isActive: true,
      sortOrder: 100,
      permissions: ((body['permissions'] as List?) ?? const []).map((e) => '$e').toList(),
    );
    _roles.add(role);
    return _delay(role);
  }

  @override
  Future<OrganizationRoleModel> updateRole(String orgId, String roleId, Map<String, dynamic> body) {
    final index = _roles.indexWhere((r) => r.id == roleId);
    final current = _roles[index];
    final updated = OrganizationRoleModel(
      id: current.id,
      organizationId: current.organizationId,
      name: '${body['name'] ?? current.name}',
      code: current.code,
      description: body['description'] as String? ?? current.description,
      scope: '${body['scope'] ?? current.scope}',
      isSystemSeed: current.isSystemSeed,
      isActive: body['isActive'] as bool? ?? current.isActive,
      sortOrder: (body['sortOrder'] as num?)?.toInt() ?? current.sortOrder,
      permissions: current.permissions,
    );
    _roles[index] = updated;
    return _delay(updated);
  }

  @override
  Future<OrganizationRoleModel> setRolePermissions(String orgId, String roleId, List<String> permissions) {
    final index = _roles.indexWhere((r) => r.id == roleId);
    final current = _roles[index];
    final updated = OrganizationRoleModel(
      id: current.id,
      organizationId: current.organizationId,
      name: current.name,
      code: current.code,
      description: current.description,
      scope: current.scope,
      isSystemSeed: current.isSystemSeed,
      isActive: current.isActive,
      sortOrder: current.sortOrder,
      permissions: permissions,
    );
    _roles[index] = updated;
    return _delay(updated);
  }

  @override
  Future<void> deleteRole(String orgId, String roleId) {
    _roles.removeWhere((r) => r.id == roleId);
    return _delay(null);
  }

  @override
  Future<List<AdminMenuItemModel>> listBranchMenu(String branchId) => _delay(List.of(_items));

  @override
  Future<List<MenuCategoryModel>> listOrgCategories(String orgId) => _delay(List.of(_categories));

  @override
  Future<List<MenuCategoryModel>> listBranchCategories(String branchId) => _delay(List.of(_categories));

  @override
  Future<MenuCategoryModel> createOrgCategory(String orgId, Map<String, dynamic> body) => _createCategory(body);

  @override
  Future<MenuCategoryModel> createBranchCategory(String branchId, Map<String, dynamic> body) => _createCategory(body);

  Future<MenuCategoryModel> _createCategory(Map<String, dynamic> body) {
    final category = MenuCategoryModel(
      id: 'cat-${DateTime.now().millisecondsSinceEpoch}',
      name: (body['name'] as String?) ?? '',
      sortOrder: (body['sortOrder'] as int?) ?? _categories.length + 1,
    );
    _categories.add(category);
    return _delay(category);
  }

  @override
  Future<AdminMenuItemModel> createOrgItem(String orgId, Map<String, dynamic> body) => _createItem(body);

  @override
  Future<AdminMenuItemModel> createBranchItem(String branchId, Map<String, dynamic> body) => _createItem(body);

  Future<AdminMenuItemModel> _createItem(Map<String, dynamic> body) {
    final categoryId = (body['categoryId'] as String?) ?? '';
    final item = AdminMenuItemModel(
      id: 'item-${DateTime.now().millisecondsSinceEpoch}',
      categoryId: categoryId,
      categoryName: _categories.firstWhere((c) => c.id == categoryId, orElse: () => _categories.first).name,
      name: (body['name'] as String?) ?? '',
      price: (body['price'] as num?)?.toDouble() ?? 0,
      description: body['description'] as String?,
      sku: body['sku'] as String?,
      imageUrl: body['imageUrl'] as String?,
      taxIds: ((body['taxIds'] as List<dynamic>?) ?? const []).map((e) => '$e').toList(),
      trackInventory: (body['trackInventory'] as bool?) ?? false,
      stockOnHand: (body['initialStock'] as num?)?.toDouble(),
      isAvailable: true,
      sortOrder: _items.length + 1,
    );
    _items.add(item);
    return _delay(item);
  }

  @override
  Future<AdminMenuItemModel> updateItem(String itemId, Map<String, dynamic> body) {
    final index = _items.indexWhere((i) => i.id == itemId);
    final existing = index >= 0 ? _items[index] : _items.first;
    final categoryId = (body['categoryId'] as String?) ?? existing.categoryId;
    final updated = AdminMenuItemModel(
      id: existing.id,
      categoryId: categoryId,
      categoryName: _categories.firstWhere((c) => c.id == categoryId, orElse: () => _categories.first).name,
      name: (body['name'] as String?) ?? existing.name,
      price: (body['price'] as num?)?.toDouble() ?? existing.price,
      description: body['description'] as String? ?? existing.description,
      sku: body['sku'] as String? ?? existing.sku,
      imageUrl: body['imageUrl'] as String? ?? existing.imageUrl,
      taxIds: ((body['taxIds'] as List<dynamic>?)?.map((e) => '$e').toList()) ?? existing.taxIds,
      trackInventory: (body['trackInventory'] as bool?) ?? existing.trackInventory,
      stockOnHand: existing.stockOnHand,
      isAvailable: (body['isActive'] as bool?) ?? existing.isAvailable,
      sortOrder: existing.sortOrder,
    );
    if (index >= 0) {
      _items[index] = updated;
    }
    return _delay(updated);
  }

  @override
  Future<PagedOrdersModel> listOrders(String branchId, Map<String, String> query) {
    final items = MockFixtures.recentOrders
        .map(
          (o) => OrderListItemModel(
            id: o.orderNumber,
            orderNumber: o.orderNumber,
            status: o.status,
            createdAt: DateTime.now(),
            createdById: '',
            createdByName: 'Demo Staff',
            customerPhone: o.customerPhone ?? '',
            totalAmount: o.totalAmount,
            paidAmount: o.totalAmount,
            paymentStatus: 'Paid',
            paymentMethods: [o.paymentMethod],
          ),
        )
        .toList();
    return _delay(
      PagedOrdersModel(
        items: items,
        page: 1,
        pageSize: items.length,
        totalCount: items.length,
        summary: OrderSummaryModel(
          openDrafts: 2,
          paidTodayCount: items.length,
          paidTodayRevenue: items.fold<double>(0, (sum, o) => sum + o.totalAmount),
        ),
      ),
    );
  }

  @override
  Future<OrderSummaryModel> getOrderSummary(String branchId) async {
    final paged = await listOrders(branchId, const {});
    return paged.summary;
  }

  @override
  Future<OrderDetailModel> getOrder(String orderId) {
    final match = MockFixtures.recentOrders.where((o) => o.orderNumber == orderId);
    final order = match.isNotEmpty ? match.first : MockFixtures.recentOrders.first;
    return _delay(
      OrderDetailModel(
        id: order.orderNumber,
        orderNumber: order.orderNumber,
        status: order.status,
        customerName: '',
        customerPhone: order.customerPhone ?? '',
        subtotal: order.totalAmount,
        taxAmount: 0,
        totalAmount: order.totalAmount,
        createdByName: 'Demo Staff',
        createdAt: DateTime.now(),
        lines: [
          OrderLineModel(
            id: 'line-1',
            name: 'Demo item',
            unitPrice: order.totalAmount,
            quantity: 1,
            taxAmount: 0,
            lineTotal: order.totalAmount,
          ),
        ],
        payments: [
          OrderPaymentModel(
            id: 'pay-1',
            method: order.paymentMethod,
            status: 'Paid',
            amount: order.totalAmount,
            paidAt: DateTime.now(),
          ),
        ],
      ),
    );
  }
}
