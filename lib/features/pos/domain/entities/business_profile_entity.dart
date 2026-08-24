import 'package:equatable/equatable.dart';

class BusinessTypeVocabulary extends Equatable {
  const BusinessTypeVocabulary({
    required this.menu,
    required this.product,
    required this.servicePoint,
    required this.ticket,
    required this.staffAssociate,
    required this.cashier,
    required this.walkIn,
    required this.openOrdersNav,
    required this.clientReference,
    required this.newOrderAction,
  });

  final String menu;
  final String product;
  final String servicePoint;
  final String ticket;
  final String staffAssociate;
  final String cashier;
  final String walkIn;
  final String openOrdersNav;
  final String clientReference;
  final String newOrderAction;

  factory BusinessTypeVocabulary.fromJson(Map<String, dynamic> json) {
    return BusinessTypeVocabulary(
      menu: (json['menu'] ?? json['Menu'] ?? 'Menu').toString(),
      product: (json['product'] ?? json['Product'] ?? 'Item').toString(),
      servicePoint: (json['servicePoint'] ?? json['ServicePoint'] ?? 'Table').toString(),
      ticket: (json['ticket'] ?? json['Ticket'] ?? 'Ticket').toString(),
      staffAssociate: (json['staffAssociate'] ?? json['StaffAssociate'] ?? 'Waiter').toString(),
      cashier: (json['cashier'] ?? json['Cashier'] ?? 'Cashier').toString(),
      walkIn: (json['walkIn'] ?? json['WalkIn'] ?? 'Walk-in').toString(),
      openOrdersNav: (json['openOrdersNav'] ?? json['OpenOrdersNav'] ?? 'Tables').toString(),
      clientReference: (json['clientReference'] ?? json['ClientReference'] ?? 'Reference').toString(),
      newOrderAction: (json['newOrderAction'] ?? json['NewOrderAction'] ?? 'New order').toString(),
    );
  }

  static const cafeteria = BusinessTypeVocabulary(
    menu: 'Menu',
    product: 'Item',
    servicePoint: 'Table',
    ticket: 'Ticket',
    staffAssociate: 'Waiter',
    cashier: 'Cashier',
    walkIn: 'Walk-in',
    openOrdersNav: 'Tables',
    clientReference: 'Reference',
    newOrderAction: 'Open table ticket',
  );

  @override
  List<Object?> get props => [
    menu,
    product,
    servicePoint,
    ticket,
    staffAssociate,
    cashier,
    walkIn,
    openOrdersNav,
    clientReference,
    newOrderAction,
  ];
}

class BusinessTypeFeatures extends Equatable {
  const BusinessTypeFeatures({
    required this.showServicePoints,
    required this.requireClientReference,
    required this.requireServicePoint,
    required this.selfOrderQrSuggested,
    required this.unitLabelsEnabled,
    required this.showAssignedStaffOnReceipt,
  });

  final bool showServicePoints;
  final bool requireClientReference;
  final bool requireServicePoint;
  final bool selfOrderQrSuggested;
  final bool unitLabelsEnabled;
  final bool showAssignedStaffOnReceipt;

  factory BusinessTypeFeatures.fromJson(Map<String, dynamic> json) {
    bool read(String a, String b, {bool fallback = false}) =>
        (json[a] ?? json[b] ?? fallback) == true;

    return BusinessTypeFeatures(
      showServicePoints: read('showServicePoints', 'ShowServicePoints', fallback: true),
      requireClientReference: read('requireClientReference', 'RequireClientReference'),
      requireServicePoint: read('requireServicePoint', 'RequireServicePoint'),
      selfOrderQrSuggested: read('selfOrderQrSuggested', 'SelfOrderQrSuggested'),
      unitLabelsEnabled: read('unitLabelsEnabled', 'UnitLabelsEnabled'),
      showAssignedStaffOnReceipt: read('showAssignedStaffOnReceipt', 'ShowAssignedStaffOnReceipt', fallback: true),
    );
  }

  static const cafeteria = BusinessTypeFeatures(
    showServicePoints: true,
    requireClientReference: false,
    requireServicePoint: false,
    selfOrderQrSuggested: true,
    unitLabelsEnabled: false,
    showAssignedStaffOnReceipt: true,
  );

  @override
  List<Object?> get props => [
    showServicePoints,
    requireClientReference,
    requireServicePoint,
    selfOrderQrSuggested,
    unitLabelsEnabled,
    showAssignedStaffOnReceipt,
  ];
}

class BusinessTypeReceipt extends Equatable {
  const BusinessTypeReceipt({
    required this.titleLabel,
    required this.showClientName,
    required this.showClientReference,
    required this.showServicePoint,
    required this.showAssignedStaff,
    required this.clientNameLabel,
    required this.clientReferenceLabel,
    required this.servicePointLabel,
    required this.assignedStaffLabel,
    required this.footerNote,
  });

  final String titleLabel;
  final bool showClientName;
  final bool showClientReference;
  final bool showServicePoint;
  final bool showAssignedStaff;
  final String clientNameLabel;
  final String clientReferenceLabel;
  final String servicePointLabel;
  final String assignedStaffLabel;
  final String footerNote;

  factory BusinessTypeReceipt.fromJson(Map<String, dynamic> json) {
    bool readBool(String a, String b, {bool fallback = false}) =>
        (json[a] ?? json[b] ?? fallback) == true;

    return BusinessTypeReceipt(
      titleLabel: (json['titleLabel'] ?? json['TitleLabel'] ?? 'Receipt').toString(),
      showClientName: readBool('showClientName', 'ShowClientName', fallback: true),
      showClientReference: readBool('showClientReference', 'ShowClientReference'),
      showServicePoint: readBool('showServicePoint', 'ShowServicePoint', fallback: true),
      showAssignedStaff: readBool('showAssignedStaff', 'ShowAssignedStaff', fallback: true),
      clientNameLabel: (json['clientNameLabel'] ?? json['ClientNameLabel'] ?? 'Customer').toString(),
      clientReferenceLabel: (json['clientReferenceLabel'] ?? json['ClientReferenceLabel'] ?? 'Reference')
          .toString(),
      servicePointLabel: (json['servicePointLabel'] ?? json['ServicePointLabel'] ?? 'Table').toString(),
      assignedStaffLabel: (json['assignedStaffLabel'] ?? json['AssignedStaffLabel'] ?? 'Staff').toString(),
      footerNote: (json['footerNote'] ?? json['FooterNote'] ?? 'Thank you.').toString(),
    );
  }

  static const cafeteria = BusinessTypeReceipt(
    titleLabel: 'Order',
    showClientName: true,
    showClientReference: false,
    showServicePoint: true,
    showAssignedStaff: true,
    clientNameLabel: 'Customer',
    clientReferenceLabel: 'Reference',
    servicePointLabel: 'Table',
    assignedStaffLabel: 'Waiter',
    footerNote: 'Thank you for dining with us.',
  );

  @override
  List<Object?> get props => [
    titleLabel,
    showClientName,
    showClientReference,
    showServicePoint,
    showAssignedStaff,
    clientNameLabel,
    clientReferenceLabel,
    servicePointLabel,
    assignedStaffLabel,
    footerNote,
  ];
}

class BusinessProfileEntity extends Equatable {
  const BusinessProfileEntity({
    required this.code,
    required this.displayName,
    required this.description,
    required this.floorMode,
    required this.defaultWorkflowTemplate,
    required this.vocabulary,
    required this.features,
    required this.receipt,
  });

  final String code;
  final String displayName;
  final String description;
  final String floorMode;
  final String defaultWorkflowTemplate;
  final BusinessTypeVocabulary vocabulary;
  final BusinessTypeFeatures features;
  final BusinessTypeReceipt receipt;

  bool get showServicePoints => features.showServicePoints && floorMode != 'None';

  factory BusinessProfileEntity.fromJson(Map<String, dynamic> json) {
    final profileJson = json['profile'] is Map
        ? Map<String, dynamic>.from(json['profile'] as Map)
        : json;

    return BusinessProfileEntity(
      code: (profileJson['code'] ?? profileJson['Code'] ?? 'Cafeteria').toString(),
      displayName: (profileJson['displayName'] ?? profileJson['DisplayName'] ?? 'Cafeteria').toString(),
      description: (profileJson['description'] ?? profileJson['Description'] ?? '').toString(),
      floorMode: (profileJson['floorMode'] ?? profileJson['FloorMode'] ?? 'Tables').toString(),
      defaultWorkflowTemplate:
          (profileJson['defaultWorkflowTemplate'] ?? profileJson['DefaultWorkflowTemplate'] ?? 'DirectPos')
              .toString(),
      vocabulary: BusinessTypeVocabulary.fromJson(
        Map<String, dynamic>.from((profileJson['vocabulary'] ?? profileJson['Vocabulary'] ?? {}) as Map),
      ),
      features: BusinessTypeFeatures.fromJson(
        Map<String, dynamic>.from((profileJson['features'] ?? profileJson['Features'] ?? {}) as Map),
      ),
      receipt: BusinessTypeReceipt.fromJson(
        Map<String, dynamic>.from((profileJson['receipt'] ?? profileJson['Receipt'] ?? {}) as Map),
      ),
    );
  }

  static const cafeteria = BusinessProfileEntity(
    code: 'Cafeteria',
    displayName: 'Cafeteria',
    description: 'Food service with tables, tickets, and a quick pay flow.',
    floorMode: 'Tables',
    defaultWorkflowTemplate: 'DirectPos',
    vocabulary: BusinessTypeVocabulary.cafeteria,
    features: BusinessTypeFeatures.cafeteria,
    receipt: BusinessTypeReceipt.cafeteria,
  );

  @override
  List<Object?> get props => [
    code,
    displayName,
    description,
    floorMode,
    defaultWorkflowTemplate,
    vocabulary,
    features,
    receipt,
  ];
}
