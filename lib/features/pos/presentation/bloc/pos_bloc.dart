import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mpos_mobile/core/common/result.dart';
import 'package:mpos_mobile/core/config/mpos_config.dart';
import 'package:mpos_mobile/core/storage/session_storage.dart';
import 'package:mpos_mobile/core/usecase/no_param.dart';
import 'package:mpos_mobile/features/auth/domain/entities/auth_session_entity.dart';
import 'package:mpos_mobile/features/auth/domain/rbac.dart';
import 'package:mpos_mobile/features/pos/domain/entities/business_profile_entity.dart';
import 'package:mpos_mobile/features/pos/domain/entities/menu_item_entity.dart';
import 'package:mpos_mobile/features/pos/domain/entities/order_entity.dart';
import 'package:mpos_mobile/features/pos/domain/repositories/order_repository.dart';
import 'package:mpos_mobile/features/pos/domain/usecases/invoice_usecases.dart';
import 'package:mpos_mobile/features/pos/domain/usecases/menu_usecases.dart';
import 'package:mpos_mobile/features/pos/domain/usecases/order_usecases.dart';
import 'package:mpos_mobile/features/pos/presentation/bloc/pos_event.dart';
import 'package:mpos_mobile/features/pos/presentation/bloc/pos_state.dart';

class PosBloc extends Bloc<PosEvent, PosState> {
  PosBloc({
    required SyncBranchMenuUsecase syncBranchMenuUsecase,
    required LoadOpenOrdersUsecase loadOpenOrdersUsecase,
    required CreateTicketUsecase createTicketUsecase,
    required AddItemToTicketUsecase addItemToTicketUsecase,
    required UpdateTicketLineQuantityUsecase updateTicketLineQuantityUsecase,
    required RemoveTicketLineUsecase removeTicketLineUsecase,
    required UpdateTicketTableNumberUsecase updateTicketTableNumberUsecase,
    required SettleTicketUsecase settleTicketUsecase,
    required OrderRepository orderRepository,
    required SubmitOrderInvoiceUsecase submitOrderInvoiceUsecase,
    required PollOrderInvoiceUsecase pollOrderInvoiceUsecase,
    required SessionStorage sessionStorage,
  }) : _syncBranchMenuUsecase = syncBranchMenuUsecase,
       _loadOpenOrdersUsecase = loadOpenOrdersUsecase,
       _createTicketUsecase = createTicketUsecase,
       _addItemToTicketUsecase = addItemToTicketUsecase,
       _updateTicketLineQuantityUsecase = updateTicketLineQuantityUsecase,
       _removeTicketLineUsecase = removeTicketLineUsecase,
       _updateTicketTableNumberUsecase = updateTicketTableNumberUsecase,
       _settleTicketUsecase = settleTicketUsecase,
       _orderRepository = orderRepository,
       _submitOrderInvoiceUsecase = submitOrderInvoiceUsecase,
       _pollOrderInvoiceUsecase = pollOrderInvoiceUsecase,
       _sessionStorage = sessionStorage,
       super(const PosState()) {
    on<PosStarted>(_onStarted);
    on<PosRefreshRequested>(_onRefresh);
    on<PosSearchChanged>(_onSearchChanged);
    on<PosTableTicketCreated>(_onTableTicketCreated);
    on<PosTicketSelected>(_onTicketSelected);
    on<PosActiveTicketTableChanged>(_onActiveTicketTableChanged);
    on<PosItemAdded>(_onItemAdded);
    on<PosLineQuantityChanged>(_onLineQuantityChanged);
    on<PosLineRemoved>(_onLineRemoved);
    on<PosSplitQuantityChanged>(_onSplitQuantityChanged);
    on<PosCartCleared>(_onCartCleared);
    on<PosPanelExpandedChanged>(_onPanelExpandedChanged);
    on<PosCheckoutRequested>(_onCheckoutRequested);
    on<PosCheckoutDismissed>(_onCheckoutDismissed);
    on<PosTablesFocusCleared>(_onTablesFocusCleared);
  }

  final SyncBranchMenuUsecase _syncBranchMenuUsecase;
  final LoadOpenOrdersUsecase _loadOpenOrdersUsecase;
  final CreateTicketUsecase _createTicketUsecase;
  final AddItemToTicketUsecase _addItemToTicketUsecase;
  final UpdateTicketLineQuantityUsecase _updateTicketLineQuantityUsecase;
  final RemoveTicketLineUsecase _removeTicketLineUsecase;
  final UpdateTicketTableNumberUsecase _updateTicketTableNumberUsecase;
  final SettleTicketUsecase _settleTicketUsecase;
  final OrderRepository _orderRepository;
  final SubmitOrderInvoiceUsecase _submitOrderInvoiceUsecase;
  final PollOrderInvoiceUsecase _pollOrderInvoiceUsecase;
  final SessionStorage _sessionStorage;

  Future<AuthSessionEntity?> _session() => _sessionStorage.loadSession();

  bool _canCollectPayment(AuthSessionEntity? session) => session?.canCollectPayment ?? false;

  Future<void> _onStarted(PosStarted event, Emitter<PosState> emit) async {
    await _loadAll(emit, fullRefresh: true);
  }

  Future<void> _onRefresh(PosRefreshRequested event, Emitter<PosState> emit) async {
    await _loadAll(emit, fullRefresh: true);
  }

  Future<void> _loadAll(Emitter<PosState> emit, {required bool fullRefresh}) async {
    emit(state.copyWith(status: PosStatus.loading, clearError: true));

    final menuResult = await _syncBranchMenuUsecase(NoParam());

    if (!menuResult.isSuccess) {
      emit(
        state.copyWith(status: PosStatus.failure, errorMessage: menuResult.error?.toString() ?? 'Failed to load menu.'),
      );

      return;
    }

    final ordersResult = await _loadOpenOrdersUsecase(NoParam());

    if (!ordersResult.isSuccess) {
      emit(
        state.copyWith(
          status: PosStatus.failure,
          errorMessage: ordersResult.error?.toString() ?? 'Failed to load tickets.',
        ),
      );

      return;
    }

    final items = menuResult.data ?? [];
    final filtered = _filterItems(items, state.searchQuery);
    final openOrders = ordersResult.data ?? [];
    final activeTicketId = _resolveActiveTicketId(openOrders, preferredTicketId: state.activeTicketId);
    final methodsResult = await _orderRepository.getPaymentMethods();
    final methods = methodsResult.data;
    final workflowSettingsResult = await _orderRepository.getEffectiveWorkflowSettings();
    final workflowSettings = workflowSettingsResult.data;
    final businessProfileResult = await _orderRepository.getBusinessProfile();
    final businessProfile = businessProfileResult.data ?? BusinessProfileEntity.cafeteria;

    emit(
      state.copyWith(
        status: PosStatus.ready,
        menuItems: items,
        filteredItems: filtered,
        openOrders: openOrders,
        activeTicketId: activeTicketId,
        selectedSplitQuantities: const {},
        enableCash: methods?.cash ?? true,
        enableChapa: methods?.chapa ?? true,
        enableTelebirr: methods?.telebirr ?? false,
        workflowSettings: workflowSettings,
        businessProfile: businessProfile,
        clearError: true,
      ),
    );
  }

  void _onSearchChanged(PosSearchChanged event, Emitter<PosState> emit) {
    emit(state.copyWith(searchQuery: event.query, filteredItems: _filterItems(state.menuItems, event.query)));
  }

  Future<void> _onTableTicketCreated(PosTableTicketCreated event, Emitter<PosState> emit) async {
    final result = await _createTicketUsecase(CreateTicketParams(event.tableNumber.trim()));

    if (!result.isSuccess || result.data == null) {
      emit(state.copyWith(errorMessage: result.error?.toString() ?? 'Failed to open table ticket.'));
      return;
    }

    final nextOrders = [...state.openOrders, result.data!];
    emit(
      state.copyWith(
        openOrders: nextOrders,
        activeTicketId: result.data!.id,
        selectedSplitQuantities: const {},
        isPanelExpanded: true,
        clearError: true,
      ),
    );
  }

  void _onTicketSelected(PosTicketSelected event, Emitter<PosState> emit) {
    emit(
      state.copyWith(
        activeTicketId: event.ticketId,
        selectedSplitQuantities: const {},
        isPanelExpanded: true,
        clearError: true,
      ),
    );
  }

  Future<void> _onActiveTicketTableChanged(PosActiveTicketTableChanged event, Emitter<PosState> emit) async {
    final activeTicket = state.activeTicket;

    if (activeTicket == null) {
      return;
    }

    final result = await _updateTicketTableNumberUsecase(
      UpdateTicketTableNumberParams(orderId: activeTicket.id, tableNumber: event.tableNumber),
    );

    await _replaceOrderInState(emit, result, preserveSelection: true);
  }

  List<MenuItemEntity> _filterItems(List<MenuItemEntity> items, String query) {
    final trimmed = query.trim().toLowerCase();

    if (trimmed.isEmpty) {
      return items;
    }

    return items
        .where(
          (item) =>
              item.name.toLowerCase().contains(trimmed) ||
              item.categoryName.toLowerCase().contains(trimmed) ||
              (item.sku?.toLowerCase().contains(trimmed) ?? false),
        )
        .toList();
  }

  Future<void> _onItemAdded(PosItemAdded event, Emitter<PosState> emit) async {
    final tableNumber = _normalizeTableNumber(event.tableNumber);
    var targetTicket = _findOpenTicketForTable(tableNumber);

    if (targetTicket == null) {
      final created = await _createTicketUsecase(CreateTicketParams(tableNumber));

      if (!created.isSuccess || created.data == null) {
        emit(state.copyWith(errorMessage: created.error?.toString() ?? 'Failed to start a ticket.'));
        return;
      }

      targetTicket = created.data!;
      emit(
        state.copyWith(
          openOrders: [...state.openOrders, targetTicket],
          activeTicketId: targetTicket.id,
          selectedSplitQuantities: const {},
          clearError: true,
        ),
      );
    } else if (state.activeTicketId != targetTicket.id) {
      emit(state.copyWith(activeTicketId: targetTicket.id, selectedSplitQuantities: const {}, clearError: true));
    }

    final result = await _addItemToTicketUsecase(
      AddItemToTicketParams(orderId: targetTicket.id, menuItemId: event.item.id, quantity: event.quantity),
    );

    await _replaceOrderInState(emit, result, preserveSelection: true);
  }

  String _normalizeTableNumber(String? tableNumber) {
    final trimmed = tableNumber?.trim() ?? '';

    if (trimmed.isEmpty) {
      return 'Walk-in';
    }

    return trimmed;
  }

  OrderEntity? _findOpenTicketForTable(String tableNumber) {
    final activeTicket = state.activeTicket;

    if (activeTicket != null && (activeTicket.tableNumber ?? 'Walk-in') == tableNumber && !activeTicket.isClosed) {
      return activeTicket;
    }

    OrderEntity? latest;

    for (final order in state.openOrders) {
      if (order.isClosed || (order.tableNumber ?? 'Walk-in') != tableNumber) {
        continue;
      }

      if (latest == null ||
          (order.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)).isAfter(
            latest.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
          )) {
        latest = order;
      }
    }

    return latest;
  }

  Future<void> _onLineQuantityChanged(PosLineQuantityChanged event, Emitter<PosState> emit) async {
    final activeTicket = state.activeTicket;

    if (activeTicket == null) {
      return;
    }

    final result = await _updateTicketLineQuantityUsecase(
      UpdateTicketLineQuantityParams(orderId: activeTicket.id, lineId: event.lineId, quantity: event.quantity),
    );

    await _replaceOrderInState(emit, result, preserveSelection: true);
  }

  Future<void> _onLineRemoved(PosLineRemoved event, Emitter<PosState> emit) async {
    final activeTicket = state.activeTicket;

    if (activeTicket == null) {
      return;
    }

    final result = await _removeTicketLineUsecase(
      RemoveTicketLineParams(orderId: activeTicket.id, lineId: event.lineId),
    );

    await _replaceOrderInState(emit, result, preserveSelection: true);
  }

  void _onSplitQuantityChanged(PosSplitQuantityChanged event, Emitter<PosState> emit) {
    final next = <String, int>{...state.selectedSplitQuantities};

    if (event.quantity <= 0) {
      next.remove(event.lineId);
    } else {
      next[event.lineId] = event.quantity;
    }

    emit(state.copyWith(selectedSplitQuantities: next));
  }

  void _onCartCleared(PosCartCleared event, Emitter<PosState> emit) {
    emit(state.copyWith(selectedSplitQuantities: const {}, isPanelExpanded: false));
  }

  void _onPanelExpandedChanged(PosPanelExpandedChanged event, Emitter<PosState> emit) {
    emit(state.copyWith(isPanelExpanded: event.isExpanded));
  }

  Future<void> _onCheckoutRequested(PosCheckoutRequested event, Emitter<PosState> emit) async {
    final activeTicket = _findOrderById(event.orderId);

    if (activeTicket == null) {
      emit(state.copyWith(errorMessage: 'Select a ticket first.'));
      return;
    }

    emit(state.copyWith(status: PosStatus.checkingOut, clearError: true));

    final session = await _session();
    final workflowSettings = state.workflowSettings;
    // Approval workflow is for create-only roles (e.g. waiter). Staff who can collect
    // payment should check out directly even when requireCashierApproval is enabled.
    final requiresApproval = workflowSettings != null &&
        !workflowSettings.isDirectPos &&
        workflowSettings.requireCashierApproval &&
        activeTicket.status == 'Draft' &&
        !_canCollectPayment(session);
    if (requiresApproval) {
      final submitted = await _orderRepository.submitOrder(
        orderId: activeTicket.id,
        customerPhone: event.customerPhone,
        customerName: event.customerName,
      );

      if (!submitted.isSuccess || submitted.data == null) {
        emit(
          state.copyWith(
            status: PosStatus.ready,
            errorMessage: submitted.error?.toString() ?? 'Failed to submit order for approval.',
          ),
        );
        return;
      }

      final submittedOrder = submitted.data!;
      emit(
        state.copyWith(
          status: PosStatus.ready,
          openOrders: _mergeUpdatedOrder(state.openOrders, submittedOrder),
          selectedSplitQuantities: const {},
          errorMessage: 'Order submitted for cashier approval.',
        ),
      );
      return;
    }

    final lineQuantities = event.selectedOnly ? event.splitQuantities ?? state.selectedSplitQuantities : null;
    final result = await _settleTicketUsecase(
      SettleTicketParams(
        orderId: activeTicket.id,
        paymentMethod: event.paymentMethod,
        customerPhone: event.customerPhone,
        customerName: event.customerName,
        receivedAmount: event.receivedAmount,
        lineQuantities: lineQuantities,
      ),
    );

    if (!result.isSuccess || result.data == null) {
      emit(state.copyWith(status: PosStatus.ready, errorMessage: result.error?.toString() ?? 'Checkout failed.'));

      return;
    }

    final order = result.data!;
    final updatedOrders = _mergeUpdatedOrder(state.openOrders, order);
    emit(state.copyWith(openOrders: updatedOrders, selectedSplitQuantities: const {}));

    if (event.paymentMethod == 'chapa' || event.paymentMethod == 'telebirr') {
      final electronicPayment = _findElectronicPayment(order, event.paymentMethod);

      if (electronicPayment == null) {
        emit(state.copyWith(status: PosStatus.ready, errorMessage: 'Electronic payment was not initialized.'));

        return;
      }

      if (MposConfig.mockMode) {
        await _completeChapaPayment(emit, orderId: order.id, paymentId: electronicPayment.id);

        return;
      }

      if (electronicPayment.checkoutUrl != null) {
        final uri = Uri.tryParse(electronicPayment.checkoutUrl!);

        if (uri != null) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }

      await _completeChapaPayment(emit, orderId: order.id, paymentId: electronicPayment.id);

      return;
    }

    await _finalizeSuccessfulSale(emit, order);
  }

  Future<void> _completeChapaPayment(
    Emitter<PosState> emit, {
    required String orderId,
    required String paymentId,
  }) async {
    emit(state.copyWith(status: PosStatus.checkingOut, clearError: true));

    final poll = await _orderRepository.pollPaymentStatus(paymentId: paymentId);

    if (!poll.isSuccess || poll.data?.status != 'Completed') {
      emit(
        state.copyWith(
          status: PosStatus.ready,
          errorMessage: poll.error?.toString() ?? 'Chapa payment was not completed.',
        ),
      );

      return;
    }

    final paidOrder = await _orderRepository.getOrder(orderId);

    if (!paidOrder.isSuccess || paidOrder.data == null) {
      emit(
        state.copyWith(
          status: PosStatus.ready,
          errorMessage: paidOrder.error?.toString() ?? 'Failed to load paid order.',
        ),
      );

      return;
    }

    final updatedOrders = _mergeUpdatedOrder(state.openOrders, paidOrder.data!);
    emit(state.copyWith(openOrders: updatedOrders, selectedSplitQuantities: const {}));

    await _finalizeSuccessfulSale(emit, paidOrder.data!);
  }

  Future<void> _finalizeSuccessfulSale(Emitter<PosState> emit, OrderEntity order) async {
    emit(state.copyWith(status: PosStatus.checkingOut, clearError: true));

    final invoiceResult = order.isClosed
        ? MposConfig.mockMode
              ? await _submitOrderInvoiceUsecase(SubmitOrderInvoiceParams(order: order))
              : await _pollOrderInvoiceUsecase(PollOrderInvoiceParams(order.id))
        : null;

    emit(
      state.copyWith(
        status: PosStatus.success,
        lastOrder: order,
        lastInvoice: invoiceResult?.data,
        activeTicketId: order.isClosed
            ? _resolveActiveTicketId(state.openOrders, excludingTicketId: order.id)
            : order.id,
        focusedTableNumber: order.isClosed ? null : (order.tableNumber ?? 'Walk-in'),
        selectedSplitQuantities: const {},
        isPanelExpanded: false,
      ),
    );

    await _loadAll(emit, fullRefresh: true);
  }

  OrderPaymentEntity? _findElectronicPayment(OrderEntity order, String paymentMethod) {
    final expected = paymentMethod.toLowerCase();

    for (final payment in order.payments) {
      if (payment.method.toLowerCase() == expected) {
        return payment;
      }
    }

    return null;
  }

  void _onCheckoutDismissed(PosCheckoutDismissed event, Emitter<PosState> emit) {
    emit(state.copyWith(status: PosStatus.ready, clearLastOrder: true, clearLastInvoice: true, clearError: true));
  }

  void _onTablesFocusCleared(PosTablesFocusCleared event, Emitter<PosState> emit) {
    emit(state.copyWith(clearFocusedTableNumber: true));
  }

  Future<void> _replaceOrderInState(
    Emitter<PosState> emit,
    Result<OrderEntity> result, {
    required bool preserveSelection,
  }) async {
    if (!result.isSuccess || result.data == null) {
      emit(state.copyWith(errorMessage: result.error?.toString() ?? 'Failed to update ticket.'));
      return;
    }

    final updated = result.data!;
    final nextSelection = preserveSelection
        ? Map<String, int>.fromEntries(
            state.selectedSplitQuantities.entries.where(
              (entry) => updated.unpaidLines.any((line) => line.id == entry.key),
            ),
          )
        : const <String, int>{};

    emit(
      state.copyWith(
        openOrders: _mergeUpdatedOrder(state.openOrders, updated),
        activeTicketId: updated.id,
        selectedSplitQuantities: nextSelection,
        clearError: true,
      ),
    );
  }

  List<OrderEntity> _mergeUpdatedOrder(List<OrderEntity> orders, OrderEntity updated) {
    final next = [...orders];
    final index = next.indexWhere((order) => order.id == updated.id);

    if (index >= 0) {
      next[index] = updated;
    } else {
      next.add(updated);
    }

    return next;
  }

  OrderEntity? _findOrderById(String orderId) {
    for (final order in state.openOrders) {
      if (order.id == orderId) {
        return order;
      }
    }

    return null;
  }

  String? _resolveActiveTicketId(List<OrderEntity> orders, {String? preferredTicketId, String? excludingTicketId}) {
    if (preferredTicketId != null &&
        orders.any((order) => order.id == preferredTicketId && order.id != excludingTicketId)) {
      return preferredTicketId;
    }

    for (final order in orders) {
      if (order.id != excludingTicketId && !order.isClosed) {
        return order.id;
      }
    }

    return null;
  }
}
