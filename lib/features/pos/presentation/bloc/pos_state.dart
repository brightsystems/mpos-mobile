import 'package:equatable/equatable.dart';

import 'package:mpos_mobile/features/pos/domain/entities/business_profile_entity.dart';
import 'package:mpos_mobile/features/pos/domain/entities/dining_table_entity.dart';
import 'package:mpos_mobile/features/pos/domain/entities/fiscal_invoice_entity.dart';
import 'package:mpos_mobile/features/pos/domain/entities/menu_item_entity.dart';
import 'package:mpos_mobile/features/pos/domain/entities/order_entity.dart';
import 'package:mpos_mobile/features/pos/domain/entities/order_workflow_settings_entity.dart';
import 'package:mpos_mobile/features/pos/domain/entities/pos_client.dart';

enum PosStatus { initial, loading, ready, checkingOut, success, failure }

class PosState extends Equatable {
  const PosState({
    this.status = PosStatus.initial,
    this.menuItems = const [],
    this.filteredItems = const [],
    this.searchQuery = '',
    this.openOrders = const [],
    this.activeTicketId,
    this.isPanelExpanded = false,
    this.errorMessage,
    this.lastOrder,
    this.lastInvoice,
    this.focusedTableNumber,
    this.enableCash = true,
    this.enableChapa = true,
    this.enableTelebirr = false,
    this.workflowSettings,
    this.businessProfile,
    this.pendingClient,
    this.ticketClients = const {},
    this.staffName,
  });

  final PosStatus status;
  final List<MenuItemEntity> menuItems;
  final List<MenuItemEntity> filteredItems;
  final String searchQuery;
  final List<OrderEntity> openOrders;
  final String? activeTicketId;
  final bool isPanelExpanded;
  final String? errorMessage;
  final OrderEntity? lastOrder;
  final FiscalInvoiceEntity? lastInvoice;
  final String? focusedTableNumber;
  final bool enableCash;
  final bool enableChapa;
  final bool enableTelebirr;
  final OrderWorkflowSettingsEntity? workflowSettings;
  final BusinessProfileEntity? businessProfile;

  /// The client chosen for the next sale (before its ticket exists).
  final PosClient? pendingClient;

  /// Client details kept per open ticket (name and phone are only sent to the API at submit).
  final Map<String, PosClient> ticketClients;

  /// The signed-in user (shown as the clinician / associate serving).
  final String? staffName;

  BusinessTypePos get pos => businessProfile?.pos ?? const BusinessTypePos(startWith: 'ServicePoint');

  /// Who the current sale is for: the active ticket's client, else the one picked for the next sale.
  PosClient? get activeClient {
    final ticket = activeTicket;
    if (ticket == null) {
      return pendingClient;
    }
    final fromOrder = PosClient.fromOrder(ticket);
    final kept = ticketClients[ticket.id];
    final client = kept == null ? fromOrder : kept.mergedWith(fromOrder);
    return client.isEmpty ? null : client;
  }

  /// "Patient", "Guest", "Client" or "Customer".
  String get clientWord => pos.clientKind;

  /// The reference's label: Room, Patient code, Prescription, Ref.
  String get clientReferenceLabel => vocabulary.clientReference;

  BusinessTypeVocabulary get vocabulary => businessProfile?.vocabulary ?? BusinessTypeVocabulary.cafeteria;

  String walkInLabel() => vocabulary.walkIn;

  List<({String value, String label})> get enabledPaymentMethods {
    final methods = <({String value, String label})>[];

    if (enableCash) {
      methods.add((value: 'cash', label: 'Cash'));
    }

    if (enableChapa) {
      methods.add((value: 'chapa', label: 'Chapa'));
    }

    if (enableTelebirr) {
      methods.add((value: 'telebirr', label: 'Telebirr'));
    }

    return methods;
  }

  OrderEntity? get activeTicket {
    if (activeTicketId == null) {
      return null;
    }

    for (final order in openOrders) {
      if (order.id == activeTicketId) {
        return order;
      }
    }

    return null;
  }

  List<OrderLineEntity> get cartLines => activeTicket?.unpaidLines ?? const [];

  String? get activeTableNumber => activeTicket?.tableNumber;

  List<DiningTableEntity> get tables {
    final grouped = <String, List<OrderEntity>>{};

    for (final order in openOrders) {
      final tableNumber = order.tableNumber ?? 'Walk-in';
      grouped.putIfAbsent(tableNumber, () => []).add(order);
    }

    final result = grouped.entries
        .map((entry) => DiningTableEntity(tableNumber: entry.key, tickets: entry.value))
        .toList();
    result.sort((a, b) => a.tableNumber.compareTo(b.tableNumber));

    return result;
  }

  String displayServicePoint(String? tableNumber) {
    final value = tableNumber ?? 'Walk-in';
    if (value == 'Walk-in') {
      return walkInLabel();
    }
    return value;
  }

  String servicePointChipLabel(String tableNumber) {
    if (tableNumber == 'Walk-in') {
      return walkInLabel();
    }
    final prefix = vocabulary.servicePoint;
    return '$prefix $tableNumber';
  }

  double get cartSubtotal => cartLines.fold<double>(0, (sum, line) => sum + line.remainingLineTotal);

  /// Taxes on the open items, as the API calculated them.
  double get cartTaxAmount => cartLines.fold<double>(0, (sum, line) => sum + line.remainingTaxAmount);

  /// What is still to collect on the active ticket (net of withholding and earlier payments).
  double get cartTotal => activeTicket?.remainingTotal ?? 0;

  PosState copyWith({
    PosStatus? status,
    List<MenuItemEntity>? menuItems,
    List<MenuItemEntity>? filteredItems,
    String? searchQuery,
    List<OrderEntity>? openOrders,
    String? activeTicketId,
    bool? isPanelExpanded,
    String? errorMessage,
    OrderEntity? lastOrder,
    FiscalInvoiceEntity? lastInvoice,
    String? focusedTableNumber,
    bool? enableCash,
    bool? enableChapa,
    bool? enableTelebirr,
    OrderWorkflowSettingsEntity? workflowSettings,
    BusinessProfileEntity? businessProfile,
    PosClient? pendingClient,
    Map<String, PosClient>? ticketClients,
    String? staffName,
    bool clearError = false,
    bool clearActiveTicket = false,
    bool clearPendingClient = false,
    bool clearLastOrder = false,
    bool clearLastInvoice = false,
    bool clearFocusedTableNumber = false,
  }) {
    return PosState(
      status: status ?? this.status,
      menuItems: menuItems ?? this.menuItems,
      filteredItems: filteredItems ?? this.filteredItems,
      searchQuery: searchQuery ?? this.searchQuery,
      openOrders: openOrders ?? this.openOrders,
      activeTicketId: clearActiveTicket ? null : activeTicketId ?? this.activeTicketId,
      isPanelExpanded: isPanelExpanded ?? this.isPanelExpanded,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      lastOrder: clearLastOrder ? null : lastOrder ?? this.lastOrder,
      lastInvoice: clearLastInvoice ? null : lastInvoice ?? this.lastInvoice,
      focusedTableNumber: clearFocusedTableNumber ? null : focusedTableNumber ?? this.focusedTableNumber,
      enableCash: enableCash ?? this.enableCash,
      enableChapa: enableChapa ?? this.enableChapa,
      enableTelebirr: enableTelebirr ?? this.enableTelebirr,
      workflowSettings: workflowSettings ?? this.workflowSettings,
      businessProfile: businessProfile ?? this.businessProfile,
      pendingClient: clearPendingClient ? null : pendingClient ?? this.pendingClient,
      ticketClients: ticketClients ?? this.ticketClients,
      staffName: staffName ?? this.staffName,
    );
  }

  @override
  List<Object?> get props => [
    status,
    menuItems,
    filteredItems,
    searchQuery,
    openOrders,
    activeTicketId,
    isPanelExpanded,
    errorMessage,
    lastOrder,
    lastInvoice,
    focusedTableNumber,
    enableCash,
    enableChapa,
    enableTelebirr,
    workflowSettings,
    businessProfile,
    pendingClient,
    ticketClients,
    staffName,
  ];
}
