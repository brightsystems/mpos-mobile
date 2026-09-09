import 'package:mpos_mobile/core/network/json_reader.dart';

class OrganizationModel {
  const OrganizationModel({
    required this.id,
    required this.name,
    required this.type,
    required this.tin,
    required this.legalName,
    required this.email,
    required this.phone,
    required this.region,
    required this.wereda,
    required this.vatNumber,
    this.city,
    this.houseNumber,
    this.locality,
    this.subCity,
    required this.settlementLevel,
    required this.platformFeePercent,
    required this.isActive,
  });

  factory OrganizationModel.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    String? opt(String key) {
      final value = reader.string(key);
      return value.isEmpty ? null : value;
    }

    return OrganizationModel(
      id: reader.string('id'),
      name: reader.string('name'),
      type: reader.string('type', fallback: 'Cafeteria'),
      tin: reader.string('tin'),
      legalName: reader.string('legalName', fallback: reader.string('name')),
      email: reader.string('email'),
      phone: reader.string('phone'),
      region: reader.string('region', fallback: '1'),
      wereda: reader.string('wereda'),
      vatNumber: reader.string('vatNumber'),
      city: opt('city'),
      houseNumber: opt('houseNumber'),
      locality: opt('locality'),
      subCity: opt('subCity'),
      settlementLevel: reader.string('settlementLevel', fallback: 'Organization'),
      platformFeePercent: reader.number('platformFeePercent'),
      isActive: reader.boolean('isActive', fallback: true),
    );
  }

  final String id;
  final String name;
  final String type;
  final String tin;
  final String legalName;
  final String email;
  final String phone;
  final String region;
  final String wereda;
  final String vatNumber;
  final String? city;
  final String? houseNumber;
  final String? locality;
  final String? subCity;
  final String settlementLevel;
  final double platformFeePercent;
  final bool isActive;
}

class BranchModel {
  const BranchModel({
    required this.id,
    required this.organizationId,
    required this.name,
    required this.address,
    required this.city,
    required this.phone,
    required this.timezone,
    required this.tin,
    required this.effectiveTin,
    required this.isActive,
  });

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return BranchModel(
      id: reader.string('id'),
      organizationId: reader.string('organizationId'),
      name: reader.string('name'),
      address: reader.string('address'),
      city: reader.string('city'),
      phone: reader.string('phone'),
      timezone: reader.string('timezone'),
      tin: reader.string('tin'),
      effectiveTin: reader.string('effectiveTin'),
      isActive: reader.boolean('isActive', fallback: true),
    );
  }

  final String id;
  final String organizationId;
  final String name;
  final String address;
  final String city;
  final String phone;
  final String timezone;
  final String tin;
  final String effectiveTin;
  final bool isActive;
}

class TaxModel {
  const TaxModel({
    required this.id,
    required this.name,
    required this.code,
    required this.ratePercent,
    required this.morTaxCode,
    required this.isActive,
    required this.sortOrder,
  });

  factory TaxModel.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    final mor = reader.string('morTaxCode');
    return TaxModel(
      id: reader.string('id'),
      name: reader.string('name'),
      code: reader.string('code'),
      ratePercent: reader.number('ratePercent'),
      morTaxCode: mor.isEmpty ? null : mor,
      isActive: reader.boolean('isActive', fallback: true),
      sortOrder: reader.integer('sortOrder'),
    );
  }

  final String id;
  final String name;
  final String code;
  final double ratePercent;
  final String? morTaxCode;
  final bool isActive;
  final int sortOrder;
}

class PaymentSettingsModel {
  const PaymentSettingsModel({
    required this.organizationId,
    required this.enableCash,
    required this.enableChapa,
    required this.enableTelebirr,
    required this.hasTelebirrCredentials,
    this.telebirrFabricAppId,
    this.telebirrMerchantAppId,
    this.telebirrMerchantCode,
    this.telebirrBaseUrl,
    this.telebirrWebBaseUrl,
  });

  factory PaymentSettingsModel.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    String? opt(String key) {
      final value = reader.string(key);
      return value.isEmpty ? null : value;
    }

    return PaymentSettingsModel(
      organizationId: reader.string('organizationId'),
      enableCash: reader.boolean('enableCash', fallback: true),
      enableChapa: reader.boolean('enableChapa'),
      enableTelebirr: reader.boolean('enableTelebirr'),
      hasTelebirrCredentials: reader.boolean('hasTelebirrCredentials'),
      telebirrFabricAppId: opt('telebirrFabricAppId'),
      telebirrMerchantAppId: opt('telebirrMerchantAppId'),
      telebirrMerchantCode: opt('telebirrMerchantCode'),
      telebirrBaseUrl: opt('telebirrBaseUrl'),
      telebirrWebBaseUrl: opt('telebirrWebBaseUrl'),
    );
  }

  final String organizationId;
  final bool enableCash;
  final bool enableChapa;
  final bool enableTelebirr;
  final bool hasTelebirrCredentials;
  final String? telebirrFabricAppId;
  final String? telebirrMerchantAppId;
  final String? telebirrMerchantCode;
  final String? telebirrBaseUrl;
  final String? telebirrWebBaseUrl;
}

class MorSettingsModel {
  const MorSettingsModel({
    this.morClientId,
    this.morApiKey,
    required this.systemNumber,
    this.systemType,
    this.morBaseUrl,
    this.isConfigured = false,
  });

  factory MorSettingsModel.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    String? opt(String key) {
      final value = reader.string(key);
      return value.isEmpty ? null : value;
    }

    return MorSettingsModel(
      morClientId: opt('morClientId'),
      morApiKey: opt('morApiKey'),
      systemNumber: reader.string('systemNumber'),
      systemType: opt('systemType'),
      morBaseUrl: opt('morBaseUrl'),
      isConfigured: reader.boolean('isConfigured'),
    );
  }

  final String? morClientId;
  final String? morApiKey;
  final String systemNumber;
  final String? systemType;
  final String? morBaseUrl;
  final bool isConfigured;
}

class BankAccountModel {
  const BankAccountModel({
    required this.bankName,
    required this.accountNumber,
    required this.accountHolderName,
    this.branchCode,
  });

  factory BankAccountModel.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    final code = reader.string('branchCode');
    return BankAccountModel(
      bankName: reader.string('bankName'),
      accountNumber: reader.string('accountNumber'),
      accountHolderName: reader.string('accountHolderName'),
      branchCode: code.isEmpty ? null : code,
    );
  }

  final String bankName;
  final String accountNumber;
  final String accountHolderName;
  final String? branchCode;
}

class MemberModel {
  const MemberModel({
    required this.userId,
    required this.phone,
    required this.fullName,
    required this.role,
    required this.isActive,
    this.branchId,
    this.branchName,
    this.roleDefinitionId,
    this.permissions = const [],
  });

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    final branch = reader.string('branchId');
    final roleDef = reader.string('roleDefinitionId');
    final rawPermissions = json['permissions'] ?? json['Permissions'];
    final permissions = rawPermissions is List
        ? rawPermissions.map((e) => '$e').where((e) => e.isNotEmpty).toList()
        : const <String>[];
    return MemberModel(
      userId: reader.string('userId'),
      phone: reader.string('phone'),
      fullName: reader.string('fullName'),
      role: reader.string('role'),
      isActive: reader.boolean('isActive', fallback: true),
      branchId: branch.isEmpty ? null : branch,
      branchName: reader.string('branchName').isEmpty ? null : reader.string('branchName'),
      roleDefinitionId: roleDef.isEmpty ? null : roleDef,
      permissions: permissions,
    );
  }

  final String userId;
  final String phone;
  final String fullName;
  final String role;
  final bool isActive;
  final String? branchId;
  final String? branchName;
  final String? roleDefinitionId;
  final List<String> permissions;

  String get displayName => fullName.isNotEmpty ? fullName : phone;

  bool get canUseShiftQr =>
      permissions.any((p) => p.toLowerCase() == 'orders:create' || p.toLowerCase().startsWith('orders:pay:'));
}

class OrganizationRoleModel {
  const OrganizationRoleModel({
    required this.id,
    required this.organizationId,
    required this.name,
    required this.code,
    required this.scope,
    required this.isSystemSeed,
    required this.isActive,
    required this.sortOrder,
    required this.permissions,
    this.description,
  });

  factory OrganizationRoleModel.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    final rawPermissions = json['permissions'] ?? json['Permissions'];
    return OrganizationRoleModel(
      id: reader.string('id'),
      organizationId: reader.string('organizationId'),
      name: reader.string('name'),
      code: reader.string('code'),
      description: reader.string('description').isEmpty ? null : reader.string('description'),
      scope: reader.string('scope', fallback: 'Branch'),
      isSystemSeed: reader.boolean('isSystemSeed'),
      isActive: reader.boolean('isActive', fallback: true),
      sortOrder: reader.integer('sortOrder'),
      permissions: rawPermissions is List
          ? rawPermissions.map((e) => '$e').where((e) => e.isNotEmpty).toList()
          : const [],
    );
  }

  final String id;
  final String organizationId;
  final String name;
  final String code;
  final String? description;
  final String scope;
  final bool isSystemSeed;
  final bool isActive;
  final int sortOrder;
  final List<String> permissions;
}

class PermissionModuleModel {
  const PermissionModuleModel({
    required this.module,
    required this.label,
    required this.actions,
  });

  factory PermissionModuleModel.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    final actions = (json['actions'] as List<dynamic>? ?? const [])
        .map((e) => PermissionActionModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return PermissionModuleModel(
      module: reader.string('module'),
      label: reader.string('label'),
      actions: actions,
    );
  }

  final String module;
  final String label;
  final List<PermissionActionModel> actions;
}

class PermissionActionModel {
  const PermissionActionModel({
    required this.code,
    required this.label,
    required this.description,
  });

  factory PermissionActionModel.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return PermissionActionModel(
      code: reader.string('code'),
      label: reader.string('label'),
      description: reader.string('description'),
    );
  }

  final String code;
  final String label;
  final String description;
}

class PermissionCatalogModel {
  const PermissionCatalogModel({required this.modules});

  factory PermissionCatalogModel.fromJson(Map<String, dynamic> json) {
    final modules = (json['modules'] as List<dynamic>? ?? const [])
        .map((e) => PermissionModuleModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return PermissionCatalogModel(modules: modules);
  }

  final List<PermissionModuleModel> modules;
}

class ShiftQrModel {
  const ShiftQrModel({
    required this.branchId,
    required this.userId,
    required this.qrPayload,
    required this.expiresAt,
    required this.memberName,
    required this.role,
  });

  factory ShiftQrModel.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return ShiftQrModel(
      branchId: reader.string('branchId'),
      userId: reader.string('userId'),
      qrPayload: reader.string('qrPayload'),
      expiresAt: reader.dateTime('expiresAt'),
      memberName: reader.string('memberName'),
      role: reader.string('role'),
    );
  }

  final String branchId;
  final String userId;
  final String qrPayload;
  final DateTime? expiresAt;
  final String memberName;
  final String role;
}

class MenuCategoryModel {
  const MenuCategoryModel({required this.id, required this.name, required this.sortOrder});

  factory MenuCategoryModel.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return MenuCategoryModel(
      id: reader.string('id'),
      name: reader.string('name'),
      sortOrder: reader.integer('sortOrder'),
    );
  }

  final String id;
  final String name;
  final int sortOrder;
}

class AdminMenuItemModel {
  const AdminMenuItemModel({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.name,
    required this.price,
    required this.description,
    required this.sku,
    required this.imageUrl,
    required this.taxIds,
    required this.trackInventory,
    required this.stockOnHand,
    required this.isAvailable,
    required this.sortOrder,
    this.harmonizationCode,
  });

  factory AdminMenuItemModel.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    final taxes = reader.listOfMaps('taxes').map((t) => JsonReader(t).string('id')).where((id) => id.isNotEmpty).toList();
    final taxIds = taxes.isNotEmpty
        ? taxes
        : ((json['taxIds'] as List<dynamic>?) ?? const []).map((e) => '$e').toList();
    final stock = reader.number('stockOnHand', fallback: -1);
    return AdminMenuItemModel(
      id: reader.string('id'),
      categoryId: reader.string('categoryId'),
      categoryName: reader.string('categoryName'),
      name: reader.string('name'),
      price: reader.number('price'),
      description: reader.string('description').isEmpty ? null : reader.string('description'),
      sku: reader.string('sku').isEmpty ? null : reader.string('sku'),
      imageUrl: reader.string('imageUrl').isEmpty ? null : reader.string('imageUrl'),
      taxIds: taxIds,
      trackInventory: reader.boolean('trackInventory'),
      stockOnHand: stock < 0 ? null : stock,
      isAvailable: reader.boolean('isAvailable', fallback: true),
      sortOrder: reader.integer('sortOrder'),
      harmonizationCode: reader.string('harmonizationCode').isEmpty ? null : reader.string('harmonizationCode'),
    );
  }

  final String id;
  final String categoryId;
  final String categoryName;
  final String name;
  final double price;
  final String? description;
  final String? sku;
  final String? imageUrl;
  final List<String> taxIds;
  final bool trackInventory;
  final double? stockOnHand;
  final bool isAvailable;
  final int sortOrder;
  final String? harmonizationCode;
}

/// Harmonization (HSN) code lookup entry with its excise rate.
class HsnCodeModel {
  const HsnCodeModel({
    required this.id,
    required this.code,
    required this.ratePercent,
    required this.description,
    required this.isActive,
  });

  factory HsnCodeModel.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return HsnCodeModel(
      id: reader.string('id'),
      code: reader.string('code'),
      ratePercent: reader.number('ratePercent'),
      description: reader.string('description').isEmpty ? null : reader.string('description'),
      isActive: reader.boolean('isActive', fallback: true),
    );
  }

  final String id;
  final String code;
  final double ratePercent;
  final String? description;
  final bool isActive;
}

class OrderSummaryModel {
  const OrderSummaryModel({
    required this.openDrafts,
    required this.paidTodayCount,
    required this.paidTodayRevenue,
  });

  factory OrderSummaryModel.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return OrderSummaryModel(
      openDrafts: reader.integer('openDrafts'),
      paidTodayCount: reader.integer('paidTodayCount'),
      paidTodayRevenue: reader.number('paidTodayRevenue'),
    );
  }

  static const empty = OrderSummaryModel(openDrafts: 0, paidTodayCount: 0, paidTodayRevenue: 0);

  final int openDrafts;
  final int paidTodayCount;
  final double paidTodayRevenue;
}

class OrderListItemModel {
  const OrderListItemModel({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.createdAt,
    required this.createdById,
    required this.createdByName,
    required this.customerPhone,
    required this.totalAmount,
    required this.paidAmount,
    required this.paymentStatus,
    required this.paymentMethods,
  });

  factory OrderListItemModel.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return OrderListItemModel(
      id: reader.string('id'),
      orderNumber: reader.string('orderNumber'),
      status: reader.string('status'),
      createdAt: reader.dateTime('createdAt'),
      createdById: reader.string('createdById'),
      createdByName: reader.string('createdByName'),
      customerPhone: reader.string('customerPhone'),
      totalAmount: reader.number('totalAmount'),
      paidAmount: reader.number('paidAmount'),
      paymentStatus: reader.string('paymentStatus'),
      paymentMethods: ((json['paymentMethods'] as List<dynamic>?) ?? const []).map((e) => '$e').toList(),
    );
  }

  final String id;
  final String orderNumber;
  final String status;
  final DateTime? createdAt;
  final String createdById;
  final String createdByName;
  final String customerPhone;
  final double totalAmount;
  final double paidAmount;
  final String paymentStatus;
  final List<String> paymentMethods;
}

class OrderLineModel {
  const OrderLineModel({
    required this.id,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    required this.taxAmount,
    required this.lineTotal,
  });

  factory OrderLineModel.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return OrderLineModel(
      id: reader.string('id'),
      name: reader.string('name'),
      unitPrice: reader.number('unitPrice'),
      quantity: reader.number('quantity'),
      taxAmount: reader.number('taxAmount'),
      lineTotal: reader.number('lineTotal'),
    );
  }

  final String id;
  final String name;
  final double unitPrice;
  final double quantity;
  final double taxAmount;
  final double lineTotal;
}

class OrderPaymentModel {
  const OrderPaymentModel({
    required this.id,
    required this.method,
    required this.status,
    required this.amount,
    required this.paidAt,
  });

  factory OrderPaymentModel.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return OrderPaymentModel(
      id: reader.string('id'),
      method: reader.string('method'),
      status: reader.string('status'),
      amount: reader.number('amount'),
      paidAt: reader.dateTime('paidAt'),
    );
  }

  final String id;
  final String method;
  final String status;
  final double amount;
  final DateTime? paidAt;
}

class OrderDetailModel {
  const OrderDetailModel({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.customerName,
    required this.customerPhone,
    required this.subtotal,
    required this.taxAmount,
    required this.totalAmount,
    required this.createdByName,
    required this.createdAt,
    required this.lines,
    required this.payments,
  });

  factory OrderDetailModel.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return OrderDetailModel(
      id: reader.string('id'),
      orderNumber: reader.string('orderNumber'),
      status: reader.string('status'),
      customerName: reader.string('customerName'),
      customerPhone: reader.string('customerPhone'),
      subtotal: reader.number('subtotal'),
      taxAmount: reader.number('taxAmount'),
      totalAmount: reader.number('totalAmount'),
      createdByName: reader.string('createdByName'),
      createdAt: reader.dateTime('createdAt'),
      lines: reader.listOfMaps('lines').map(OrderLineModel.fromJson).toList(),
      payments: reader.listOfMaps('payments').map(OrderPaymentModel.fromJson).toList(),
    );
  }

  final String id;
  final String orderNumber;
  final String status;
  final String customerName;
  final String customerPhone;
  final double subtotal;
  final double taxAmount;
  final double totalAmount;
  final String createdByName;
  final DateTime? createdAt;
  final List<OrderLineModel> lines;
  final List<OrderPaymentModel> payments;
}

class PagedOrdersModel {
  const PagedOrdersModel({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.summary,
  });

  factory PagedOrdersModel.fromJson(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    final summaryJson = reader.map('summary');
    return PagedOrdersModel(
      items: reader.listOfMaps('items').map(OrderListItemModel.fromJson).toList(),
      page: reader.integer('page', fallback: 1),
      pageSize: reader.integer('pageSize', fallback: 20),
      totalCount: reader.integer('totalCount'),
      summary: summaryJson == null ? OrderSummaryModel.empty : OrderSummaryModel.fromJson(summaryJson),
    );
  }

  final List<OrderListItemModel> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final OrderSummaryModel summary;
}
