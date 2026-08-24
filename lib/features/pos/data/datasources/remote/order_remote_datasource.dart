import 'package:mpos_mobile/core/network/json_reader.dart';
import 'package:mpos_mobile/core/network/mpos_api_client.dart';
import 'package:mpos_mobile/features/pos/data/datasources/order_datasource.dart';
import 'package:mpos_mobile/features/pos/domain/entities/business_profile_entity.dart';
import 'package:mpos_mobile/features/pos/domain/entities/order_entity.dart';
import 'package:mpos_mobile/features/pos/domain/entities/order_workflow_settings_entity.dart';
import 'package:mpos_mobile/features/pos/domain/entities/tax_rate_entity.dart';

class OrderRemoteDatasource implements OrderDatasource {
  OrderRemoteDatasource(this._client);

  final MposApiClient _client;

  @override
  Future<OrderEntity> createOrder({required String branchId, String? clientOrderId}) async {
    final response = await _client.post(
      '/branches/$branchId/orders',
      authenticated: true,
      body: {if (clientOrderId != null) 'clientOrderId': clientOrderId},
      fromJson: (json) => _mapOrder(json as Map<String, dynamic>),
    );

    if (!response.success || response.data == null) {
      throw response.message ?? response.errors.join(', ');
    }

    return response.data!;
  }

  @override
  Future<List<OrderEntity>> getOpenOrders({required String branchId}) async {
    final response = await _client.get(
      '/branches/$branchId/orders/open',
      authenticated: true,
      fromJson: (json) {
        final items = json as List<dynamic>;
        return items.map((item) => _mapOrder(Map<String, dynamic>.from(item as Map))).toList();
      },
    );

    if (!response.success || response.data == null) {
      throw response.message ?? response.errors.join(', ');
    }

    return response.data!;
  }

  @override
  Future<OrderEntity> createTicket({required String branchId, required String tableNumber}) async {
    final response = await _client.post(
      '/branches/$branchId/orders',
      authenticated: true,
      body: {'tableNumber': tableNumber},
      fromJson: (json) => _mapOrder(json as Map<String, dynamic>),
    );

    if (!response.success || response.data == null) {
      throw response.message ?? response.errors.join(', ');
    }

    return response.data!;
  }

  @override
  Future<OrderEntity> addOrderLine({required String orderId, required String menuItemId, required int quantity}) async {
    final response = await _client.post(
      '/orders/$orderId/lines',
      authenticated: true,
      body: {'menuItemId': menuItemId, 'quantity': quantity},
      fromJson: (json) => _mapOrder(json as Map<String, dynamic>),
    );

    if (!response.success || response.data == null) {
      throw response.message ?? response.errors.join(', ');
    }

    return response.data!;
  }

  @override
  Future<OrderEntity> updateOrderLineQuantity({
    required String orderId,
    required String lineId,
    required int quantity,
  }) async {
    final response = await _client.put(
      '/orders/lines/$lineId',
      authenticated: true,
      body: {'quantity': quantity},
      fromJson: (json) => _mapOrder(json as Map<String, dynamic>),
    );

    if (!response.success || response.data == null) {
      throw response.message ?? response.errors.join(', ');
    }

    return response.data!;
  }

  @override
  Future<OrderEntity> removeOrderLine({required String orderId, required String lineId}) async {
    final response = await _client.delete(
      '/orders/lines/$lineId',
      authenticated: true,
      fromJson: (json) => _mapOrder(json as Map<String, dynamic>),
    );

    if (!response.success || response.data == null) {
      throw response.message ?? response.errors.join(', ');
    }

    return response.data!;
  }

  @override
  Future<OrderEntity> updateOrderTableNumber({required String orderId, String? tableNumber}) async {
    final response = await _client.put(
      '/orders/$orderId/table',
      authenticated: true,
      body: {'tableNumber': tableNumber},
      fromJson: (json) => _mapOrder(json as Map<String, dynamic>),
    );

    if (!response.success || response.data == null) {
      throw response.message ?? response.errors.join(', ');
    }

    return response.data!;
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
    final response = await _client.post(
      '/orders/$orderId/pay/cash',
      authenticated: true,
      body: {
        'receivedAmount': receivedAmount,
        'customerPhone': customerPhone,
        if (customerName != null && customerName.isNotEmpty) 'customerName': customerName,
        if (customerTin != null && customerTin.isNotEmpty) 'customerTin': customerTin,
        if (lineQuantities != null && lineQuantities.isNotEmpty) 'lineQuantities': lineQuantities,
      },
      fromJson: (json) => _mapOrder(json as Map<String, dynamic>),
    );

    if (!response.success || response.data == null) {
      throw response.message ?? response.errors.join(', ');
    }

    return response.data!;
  }

  @override
  Future<({OrderPaymentEntity payment, OrderEntity order})> initiateChapa({
    required String orderId,
    required String customerPhone,
    String? customerName,
    String? customerTin,
    Map<String, int>? lineQuantities,
  }) async {
    final response = await _client.post(
      '/orders/$orderId/pay/chapa',
      authenticated: true,
      body: {
        'customerPhone': customerPhone,
        if (customerName != null && customerName.isNotEmpty) 'customerName': customerName,
        if (customerTin != null && customerTin.isNotEmpty) 'customerTin': customerTin,
      },
      fromJson: (json) => _mapChapaInit(json as Map<String, dynamic>),
    );

    if (!response.success || response.data == null) {
      throw response.message ?? response.errors.join(', ');
    }

    final orderResponse = await _client.get(
      '/orders/$orderId',
      authenticated: true,
      fromJson: (json) => _mapOrder(json as Map<String, dynamic>),
    );

    if (!orderResponse.success || orderResponse.data == null) {
      throw orderResponse.message ?? orderResponse.errors.join(', ');
    }

    return (payment: response.data!, order: orderResponse.data!);
  }

  @override
  Future<({OrderPaymentEntity payment, OrderEntity order})> initiateTelebirr({
    required String orderId,
    required String customerPhone,
    String? customerName,
    String? customerTin,
    Map<String, int>? lineQuantities,
  }) async {
    final response = await _client.post(
      '/orders/$orderId/pay/telebirr',
      authenticated: true,
      body: {
        'customerPhone': customerPhone,
        if (customerName != null && customerName.isNotEmpty) 'customerName': customerName,
        if (customerTin != null && customerTin.isNotEmpty) 'customerTin': customerTin,
      },
      fromJson: (json) => _mapChapaInit(json as Map<String, dynamic>, methodFallback: 'Telebirr'),
    );

    if (!response.success || response.data == null) {
      throw response.message ?? response.errors.join(', ');
    }

    final orderResponse = await _client.get(
      '/orders/$orderId',
      authenticated: true,
      fromJson: (json) => _mapOrder(json as Map<String, dynamic>),
    );

    if (!orderResponse.success || orderResponse.data == null) {
      throw orderResponse.message ?? orderResponse.errors.join(', ');
    }

    return (payment: response.data!, order: orderResponse.data!);
  }

  @override
  Future<({bool cash, bool chapa, bool telebirr})> getPaymentMethods({required String branchId}) async {
    final response = await _client.get(
      '/branches/$branchId/payment-methods',
      authenticated: true,
      fromJson: (json) {
        final reader = JsonReader(json as Map<String, dynamic>);
        return (
          cash: reader.boolean('cash', fallback: true),
          chapa: reader.boolean('chapa', fallback: true),
          telebirr: reader.boolean('telebirr', fallback: false),
        );
      },
    );

    if (!response.success || response.data == null) {
      return (cash: true, chapa: true, telebirr: false);
    }

    return response.data!;
  }

  @override
  Future<OrderPaymentEntity> getPaymentStatus(String paymentId) async {
    final response = await _client.get(
      '/payments/$paymentId',
      authenticated: true,
      fromJson: (json) => _mapPaymentStatus(json as Map<String, dynamic>),
    );

    if (!response.success || response.data == null) {
      throw response.message ?? response.errors.join(', ');
    }

    return response.data!;
  }

  @override
  Future<OrderEntity> getOrder(String orderId) async {
    final response = await _client.get(
      '/orders/$orderId',
      authenticated: true,
      fromJson: (json) => _mapOrder(json as Map<String, dynamic>),
    );

    if (!response.success || response.data == null) {
      throw response.message ?? response.errors.join(', ');
    }

    return response.data!;
  }

  @override
  Future<OrderEntity> submitOrder({
    required String orderId,
    required String customerPhone,
    String? customerName,
  }) async {
    final response = await _client.post(
      '/orders/$orderId/submit',
      authenticated: true,
      body: {
        'customerPhone': customerPhone,
        if (customerName != null && customerName.isNotEmpty) 'customerName': customerName,
      },
      fromJson: (json) => _mapOrder(json as Map<String, dynamic>),
    );

    if (!response.success || response.data == null) {
      throw response.message ?? response.errors.join(', ');
    }

    return response.data!;
  }

  @override
  Future<OrderWorkflowSettingsEntity> getEffectiveWorkflowSettings({required String branchId}) async {
    final response = await _client.get(
      '/branches/$branchId/order-workflow-settings/effective',
      authenticated: true,
      fromJson: (json) => _mapWorkflowSettings(json as Map<String, dynamic>),
    );

    if (!response.success || response.data == null) {
      throw response.message ?? response.errors.join(', ');
    }

    return response.data!;
  }

  @override
  Future<BusinessProfileEntity> getBusinessProfile({required String branchId}) async {
    final response = await _client.get(
      '/branches/$branchId/business-profile',
      authenticated: true,
      fromJson: (json) => BusinessProfileEntity.fromJson(json as Map<String, dynamic>),
    );

    if (!response.success || response.data == null) {
      throw response.message ?? response.errors.join(', ');
    }

    return response.data!;
  }

  OrderPaymentEntity _mapChapaInit(Map<String, dynamic> json, {String methodFallback = 'Chapa'}) {
    final reader = JsonReader(json);

    return OrderPaymentEntity(
      id: reader.string('paymentId'),
      method: methodFallback,
      status: 'Pending',
      amount: reader.number('amount'),
      checkoutUrl: reader.string('checkoutUrl').isEmpty ? null : reader.string('checkoutUrl'),
      txRef: reader.string('txRef').isEmpty
          ? (reader.string('outTradeNo').isEmpty ? null : reader.string('outTradeNo'))
          : reader.string('txRef'),
    );
  }

  OrderPaymentEntity _mapPaymentStatus(Map<String, dynamic> json) {
    final reader = JsonReader(json);

    return OrderPaymentEntity(
      id: reader.string('paymentId'),
      method: reader.string('method', fallback: 'Chapa'),
      status: reader.string('status'),
      amount: reader.number('amount'),
      checkoutUrl: reader.string('checkoutUrl').isEmpty ? null : reader.string('checkoutUrl'),
      txRef: reader.string('chapaTxRef').isEmpty ? null : reader.string('chapaTxRef'),
    );
  }

  OrderEntity _mapOrder(Map<String, dynamic> json) {
    final reader = JsonReader(json);

    return OrderEntity(
      id: reader.string('id'),
      branchId: reader.string('branchId'),
      orderNumber: reader.string('orderNumber'),
      status: reader.string('status'),
      subtotal: reader.number('subtotal'),
      taxAmount: reader.number('taxAmount'),
      totalAmount: reader.number('totalAmount'),
      customerPhone: reader.string('customerPhone').isEmpty ? null : reader.string('customerPhone'),
      customerName: reader.string('customerName').isEmpty ? null : reader.string('customerName'),
      lines: reader.listOfMaps('lines').map(_mapOrderLine).toList(),
      payments: reader.listOfMaps('payments').map(_mapPayment).toList(),
      tableNumber: reader.string('tableNumber').isEmpty ? null : reader.string('tableNumber'),
      ticketNumber: reader.string('ticketNumber').isEmpty ? null : reader.string('ticketNumber'),
      source: reader.string('source').isEmpty ? null : reader.string('source'),
      assignedBranchMemberUserId: reader.string('assignedBranchMemberUserId').isEmpty
          ? null
          : reader.string('assignedBranchMemberUserId'),
      createdAt: reader.dateTime('createdAt'),
    );
  }

  OrderWorkflowSettingsEntity _mapWorkflowSettings(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    return OrderWorkflowSettingsEntity(
      organizationId: reader.string('organizationId'),
      branchId: reader.string('branchId'),
      usesBranchOverride: reader.boolean('usesBranchOverride'),
      workflowTemplate: reader.string('workflowTemplate', fallback: 'DirectPos'),
      selfOrderEnabled: reader.boolean('selfOrderEnabled'),
      selfOrderMode: reader.string('selfOrderMode', fallback: 'TableQr'),
      requireCashierApproval: reader.boolean('requireCashierApproval'),
      allowWalkInQr: reader.boolean('allowWalkInQr'),
      requireTableForAssignment: reader.boolean('requireTableForAssignment'),
      cashierCanAssumeOrder: reader.boolean('cashierCanAssumeOrder', fallback: true),
    );
  }

  OrderLineEntity _mapOrderLine(Map<String, dynamic> json) {
    final reader = JsonReader(json);

    return OrderLineEntity(
      id: reader.string('id'),
      menuItemId: reader.string('menuItemId'),
      name: reader.string('name'),
      unitPrice: reader.number('unitPrice'),
      quantity: reader.number('quantity'),
      lineTotal: reader.number('lineTotal'),
      paidQuantity: reader.number('paidQuantity'),
      taxes: reader.listOfMaps('taxes').map(_mapLineTax).toList(),
      imageUrl: reader.string('imageUrl').isEmpty ? null : reader.string('imageUrl'),
      stockOnHand: reader.number('stockOnHand', fallback: -1) < 0 ? null : reader.number('stockOnHand'),
      trackInventory: reader.boolean('trackInventory'),
    );
  }

  TaxRateEntity _mapLineTax(Map<String, dynamic> json) {
    final reader = JsonReader(json);
    final mor = reader.string('morTaxCode');

    return TaxRateEntity(
      id: reader.string('id'),
      name: reader.string('name'),
      code: reader.string('code'),
      ratePercent: reader.number('ratePercent'),
      morTaxCode: mor.isEmpty ? null : mor,
    );
  }

  OrderPaymentEntity _mapPayment(Map<String, dynamic> json) {
    final reader = JsonReader(json);

    return OrderPaymentEntity(
      id: reader.string('id'),
      method: reader.string('method'),
      status: reader.string('status'),
      amount: reader.number('amount'),
      receivedAmount: reader.number('receivedAmount', fallback: -1) < 0 ? null : reader.number('receivedAmount'),
      changeAmount: reader.number('changeAmount', fallback: -1) < 0 ? null : reader.number('changeAmount'),
      coveredLineIds: const [],
    );
  }
}
