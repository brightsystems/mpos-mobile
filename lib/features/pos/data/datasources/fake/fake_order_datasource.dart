import 'package:mpos_mobile/core/mock/mock_fixtures.dart';
import 'package:mpos_mobile/features/pos/data/datasources/order_datasource.dart';
import 'package:mpos_mobile/features/pos/domain/entities/business_profile_entity.dart';
import 'package:mpos_mobile/features/pos/domain/entities/order_entity.dart';
import 'package:mpos_mobile/features/pos/domain/entities/order_workflow_settings_entity.dart';
import 'package:mpos_mobile/features/pos/domain/entities/tax_rate_entity.dart';

class FakeOrderDatasource implements OrderDatasource {
  int _orderSequence = 1;
  int _lineSequence = 1;
  int _paymentSequence = 1;
  final Map<String, OrderEntity> _orders = {};
  final Map<String, int> _chapaPollCounts = {};
  final Map<String, Map<String, int>?> _paymentLineSelections = {};

  Future<void> _simulateNetwork() => Future<void>.delayed(const Duration(milliseconds: 300));

  @override
  Future<OrderEntity> createOrder({required String branchId, String? clientOrderId}) async {
    return createTicket(branchId: branchId, tableNumber: 'Walk-in');
  }

  @override
  Future<List<OrderEntity>> getOpenOrders({required String branchId}) async {
    await _simulateNetwork();

    return _orders.values.where((order) => order.branchId == branchId && !order.isClosed).toList()
      ..sort((a, b) => (a.createdAt ?? DateTime.now()).compareTo(b.createdAt ?? DateTime.now()));
  }

  @override
  Future<OrderEntity> createTicket({required String branchId, required String tableNumber}) async {
    await _simulateNetwork();

    final id = 'mock-order-${_orderSequence++}';
    final ticketNumber = _nextTicketNumber(tableNumber);
    final order = OrderEntity(
      id: id,
      branchId: branchId,
      orderNumber: 'MOCK-${id.substring(id.length - 4)}',
      status: 'Draft',
      subtotal: 0,
      taxAmount: 0,
      totalAmount: 0,
      lines: const [],
      payments: const [],
      tableNumber: tableNumber,
      ticketNumber: ticketNumber,
      createdAt: DateTime.now().toUtc(),
    );

    _orders[id] = order;

    return order;
  }

  @override
  Future<OrderEntity> addOrderLine({required String orderId, required String menuItemId, required int quantity}) async {
    await _simulateNetwork();

    final order = _requireOrder(orderId);
    final menuItem = MockFixtures.menuItemById(menuItemId);

    if (menuItem == null) {
      throw 'Menu item not found.';
    }

    if (quantity <= 0) {
      throw 'Invalid quantity.';
    }

    final lines = [...order.lines];
    lines.add(
      OrderLineEntity(
        id: 'mock-line-${_lineSequence++}',
        menuItemId: menuItemId,
        name: menuItem.name,
        unitPrice: menuItem.price,
        quantity: quantity.toDouble(),
        lineTotal: menuItem.price * quantity,
        taxes: menuItem.taxes,
        imageUrl: menuItem.imageUrl,
        stockOnHand: menuItem.stockOnHand,
        trackInventory: menuItem.trackInventory,
      ),
    );

    final updated = _recalculate(order, lines: lines);
    _orders[orderId] = updated;

    return updated;
  }

  @override
  Future<OrderEntity> updateOrderLineQuantity({
    required String orderId,
    required String lineId,
    required int quantity,
  }) async {
    await _simulateNetwork();

    final order = _requireOrder(orderId);
    final lines = [...order.lines];
    final index = lines.indexWhere((line) => line.id == lineId);

    if (index < 0) {
      throw 'Order line not found.';
    }

    final existing = lines[index];

    if (quantity <= 0) {
      lines.removeAt(index);
    } else {
      lines[index] = existing.copyWith(quantity: quantity.toDouble());
    }

    final updated = _recalculate(order, lines: lines);
    _orders[orderId] = updated;

    return updated;
  }

  @override
  Future<OrderEntity> removeOrderLine({required String orderId, required String lineId}) async {
    await _simulateNetwork();

    final order = _requireOrder(orderId);
    final lines = order.lines.where((line) => line.id != lineId).toList();
    final updated = _recalculate(order, lines: lines);
    _orders[orderId] = updated;

    return updated;
  }

  @override
  Future<OrderEntity> updateOrderTableNumber({required String orderId, String? tableNumber}) async {
    await _simulateNetwork();

    final order = _requireOrder(orderId);
    final normalizedTable = (tableNumber == null || tableNumber.trim().isEmpty) ? 'Walk-in' : tableNumber.trim();

    if ((order.tableNumber ?? 'Walk-in') == normalizedTable) {
      return order;
    }

    final updated = order.copyWith(
      tableNumber: normalizedTable,
      ticketNumber: _nextTicketNumber(normalizedTable, excludingOrderId: order.id),
    );
    _orders[orderId] = updated;

    return updated;
  }

  @override
  Future<OrderEntity> payCash({
    required String orderId,
    required double receivedAmount,
    required String customerPhone,
    String? customerName,
    String? customerTin,
    Map<String, int>? lineQuantities,
  }) async {
    await _simulateNetwork();

    final order = _requireOrder(orderId);
    final amountToPay = _remainingAmountFor(order, lineQuantities);
    final change = receivedAmount - amountToPay;

    if (change < 0) {
      throw 'Insufficient cash received.';
    }

    final payment = OrderPaymentEntity(
      id: 'mock-pay-${_paymentSequence++}',
      method: 'Cash',
      status: 'Completed',
      amount: amountToPay,
      receivedAmount: receivedAmount,
      changeAmount: change,
      coveredLineIds: (lineQuantities?.keys ?? order.unpaidLines.map((line) => line.id)).toList(),
      coveredQuantities:
          lineQuantities ?? {for (final line in order.unpaidLines) line.id: line.remainingQuantity.round()},
    );

    final updated = _applySettlement(
      order,
      lineQuantities: lineQuantities,
      customerPhone: customerPhone,
      customerName: customerName,
      payments: [...order.payments, payment],
    );

    _orders[orderId] = updated;

    return updated;
  }

  @override
  Future<({OrderPaymentEntity payment, OrderEntity order})> initiateChapa({
    required String orderId,
    required String customerPhone,
    String? customerName,
    String? customerTin,
    Map<String, int>? lineQuantities,
  }) async {
    await _simulateNetwork();

    final order = _requireOrder(orderId);
    final paymentId = 'mock-chapa-${_paymentSequence++}';
    final txRef = 'mock-tx-$paymentId';
    final amountToPay = _remainingAmountFor(order, lineQuantities);

    final payment = OrderPaymentEntity(
      id: paymentId,
      method: 'Chapa',
      status: 'Pending',
      amount: amountToPay,
      checkoutUrl: 'https://checkout.chapa.co/mock/$paymentId',
      txRef: txRef,
      coveredLineIds: (lineQuantities?.keys ?? order.unpaidLines.map((line) => line.id)).toList(),
      coveredQuantities:
          lineQuantities ?? {for (final line in order.unpaidLines) line.id: line.remainingQuantity.round()},
    );

    _chapaPollCounts[paymentId] = 0;
    _paymentLineSelections[paymentId] = lineQuantities;

    final updated = order.copyWith(status: 'PendingPayment', customerPhone: customerPhone, customerName: customerName);

    _orders[orderId] = updated;

    return (payment: payment, order: updated);
  }

  @override
  Future<({OrderPaymentEntity payment, OrderEntity order})> initiateTelebirr({
    required String orderId,
    required String customerPhone,
    String? customerName,
    String? customerTin,
    Map<String, int>? lineQuantities,
  }) async {
    await _simulateNetwork();

    final order = _requireOrder(orderId);
    final paymentId = 'mock-telebirr-${_paymentSequence++}';
    final amountToPay = _remainingAmountFor(order, lineQuantities);

    final payment = OrderPaymentEntity(
      id: paymentId,
      method: 'Telebirr',
      status: 'Pending',
      amount: amountToPay,
      checkoutUrl: 'https://telebirr.local/mock/$paymentId',
      txRef: 'TB-$paymentId',
      coveredLineIds: (lineQuantities?.keys ?? order.unpaidLines.map((line) => line.id)).toList(),
      coveredQuantities:
          lineQuantities ?? {for (final line in order.unpaidLines) line.id: line.remainingQuantity.round()},
    );

    _chapaPollCounts[paymentId] = 0;
    _paymentLineSelections[paymentId] = lineQuantities;

    final updated = order.copyWith(status: 'PendingPayment', customerPhone: customerPhone, customerName: customerName);
    _orders[orderId] = updated;

    return (payment: payment, order: updated);
  }

  @override
  Future<({bool cash, bool chapa, bool telebirr})> getPaymentMethods({required String branchId}) async {
    await _simulateNetwork();
    return (cash: true, chapa: true, telebirr: true);
  }

  @override
  Future<OrderPaymentEntity> getPaymentStatus(String paymentId) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));

    final polls = (_chapaPollCounts[paymentId] ?? 0) + 1;
    _chapaPollCounts[paymentId] = polls;

    final order = _orders.values.firstWhere(
      (item) => item.payments.any((payment) => payment.id == paymentId),
      orElse: () => throw 'Payment not found.',
    );

    final amount = order.totalAmount;

    if (polls >= 1) {
      _markChapaPaid(order.id, paymentId);

      return OrderPaymentEntity(
        id: paymentId,
        method: 'Chapa',
        status: 'Completed',
        amount: amount,
        coveredLineIds: (_paymentLineSelections[paymentId]?.keys ?? const <String>[]).toList(),
        coveredQuantities: _paymentLineSelections[paymentId] ?? const {},
      );
    }

    return OrderPaymentEntity(
      id: paymentId,
      method: 'Chapa',
      status: 'Pending',
      amount: amount,
      checkoutUrl: 'https://checkout.chapa.co/mock/$paymentId',
    );
  }

  @override
  Future<OrderEntity> getOrder(String orderId) async {
    await _simulateNetwork();

    return _requireOrder(orderId);
  }

  @override
  Future<OrderEntity> submitOrder({
    required String orderId,
    required String customerPhone,
    String? customerName,
  }) async {
    await _simulateNetwork();
    final order = _requireOrder(orderId);
    final updated = order.copyWith(
      status: 'Submitted',
      customerPhone: customerPhone,
      customerName: customerName,
    );
    _orders[orderId] = updated;
    return updated;
  }

  @override
  Future<OrderWorkflowSettingsEntity> getEffectiveWorkflowSettings({required String branchId}) async {
    await _simulateNetwork();
    return OrderWorkflowSettingsEntity(
      organizationId: 'mock-org',
      branchId: branchId,
      usesBranchOverride: false,
      workflowTemplate: 'DirectPos',
      selfOrderEnabled: false,
      selfOrderMode: 'TableQr',
      requireCashierApproval: false,
      allowWalkInQr: false,
      requireTableForAssignment: false,
      cashierCanAssumeOrder: true,
    );
  }

  @override
  Future<BusinessProfileEntity> getBusinessProfile({required String branchId}) async {
    await _simulateNetwork();
    return BusinessProfileEntity.cafeteria;
  }

  OrderEntity _requireOrder(String orderId) {
    final order = _orders[orderId];

    if (order == null) {
      throw 'Order not found.';
    }

    return order;
  }

  String _nextTicketNumber(String tableNumber, {String? excludingOrderId}) {
    final openCount = _orders.values
        .where((order) => order.id != excludingOrderId && order.tableNumber == tableNumber && !order.isClosed)
        .length;

    return 'T${openCount + 1}';
  }

  void _markChapaPaid(String orderId, String paymentId) {
    final order = _requireOrder(orderId);
    final selectedLineQuantities = _paymentLineSelections[paymentId];
    final payments = order.payments
        .map(
          (payment) => payment.id == paymentId
              ? OrderPaymentEntity(
                  id: payment.id,
                  method: payment.method,
                  status: 'Completed',
                  amount: payment.amount,
                  checkoutUrl: payment.checkoutUrl,
                  txRef: payment.txRef,
                  coveredLineIds: payment.coveredLineIds,
                  coveredQuantities: payment.coveredQuantities,
                )
              : payment,
        )
        .toList();

    if (!payments.any((payment) => payment.id == paymentId)) {
      payments.add(
        OrderPaymentEntity(
          id: paymentId,
          method: 'Chapa',
          status: 'Completed',
          amount: _remainingAmountFor(order, selectedLineQuantities),
          coveredLineIds: (selectedLineQuantities?.keys ?? order.unpaidLines.map((line) => line.id)).toList(),
          coveredQuantities:
              selectedLineQuantities ?? {for (final line in order.unpaidLines) line.id: line.remainingQuantity.round()},
        ),
      );
    }

    _orders[orderId] = _applySettlement(order, lineQuantities: selectedLineQuantities, payments: payments);
  }

  OrderEntity _recalculate(OrderEntity order, {required List<OrderLineEntity> lines}) {
    var subtotal = 0.0;
    var taxAmount = 0.0;

    for (final line in lines) {
      subtotal += line.lineTotal;
      final menuItem = MockFixtures.menuItemById(line.menuItemId);
      taxAmount += MockFixtures.taxAmount(line.lineTotal, menuItem?.taxes ?? const []);
    }

    return order.copyWith(lines: lines, subtotal: subtotal, taxAmount: taxAmount, totalAmount: subtotal + taxAmount);
  }

  double _remainingAmountFor(OrderEntity order, Map<String, int>? lineQuantities) {
    final quantities =
        lineQuantities ?? {for (final line in order.unpaidLines) line.id: line.remainingQuantity.round()};
    var total = 0.0;

    for (final line in order.unpaidLines) {
      final requested = quantities[line.id] ?? 0;

      if (requested <= 0) {
        continue;
      }

      final quantity = requested > line.remainingQuantity ? line.remainingQuantity : requested.toDouble();
      final subtotal = line.unitPrice * quantity;
      final tax = calculateTaxesAmount(subtotal, line.taxes);
      total += subtotal + tax;
    }

    return total;
  }

  OrderEntity _applySettlement(
    OrderEntity order, {
    Map<String, int>? lineQuantities,
    required List<OrderPaymentEntity> payments,
    String? customerPhone,
    String? customerName,
  }) {
    final quantities =
        lineQuantities ?? {for (final line in order.unpaidLines) line.id: line.remainingQuantity.round()};

    final lines = order.lines.map((line) {
      final requested = quantities[line.id] ?? 0;

      if (requested > 0) {
        final quantityToPay = requested > line.remainingQuantity ? line.remainingQuantity : requested.toDouble();
        return line.copyWith(paidQuantity: line.paidQuantity + quantityToPay);
      }

      return line;
    }).toList();

    final updated = _recalculate(
      order.copyWith(
        customerPhone: customerPhone ?? order.customerPhone,
        customerName: customerName ?? order.customerName,
      ),
      lines: lines,
    );

    return updated.copyWith(
      status: updated.isClosed ? 'Paid' : 'Open',
      payments: payments,
      customerPhone: customerPhone ?? order.customerPhone,
      customerName: customerName ?? order.customerName,
    );
  }
}
