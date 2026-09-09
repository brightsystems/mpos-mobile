import 'package:mpos_mobile/core/common/result.dart';
import 'package:mpos_mobile/core/storage/session_storage.dart';
import 'package:mpos_mobile/features/pos/data/datasources/order_datasource.dart';
import 'package:mpos_mobile/features/pos/domain/entities/business_profile_entity.dart';
import 'package:mpos_mobile/features/pos/domain/entities/order_entity.dart';
import 'package:mpos_mobile/features/pos/domain/entities/order_workflow_settings_entity.dart';
import 'package:mpos_mobile/features/pos/domain/repositories/order_repository.dart';

class OrderRepositoryImpl implements OrderRepository {
  OrderRepositoryImpl({required OrderDatasource remoteDatasource, required SessionStorage sessionStorage})
    : _remoteDatasource = remoteDatasource,
      _sessionStorage = sessionStorage;

  final OrderDatasource _remoteDatasource;
  final SessionStorage _sessionStorage;

  @override
  Future<Result<List<OrderEntity>>> getOpenOrders() async {
    try {
      final session = await _sessionStorage.loadSession();

      if (session == null) {
        return Result.failure(error: 'Not authenticated.');
      }

      final orders = await _remoteDatasource.getOpenOrders(branchId: session.branchId);

      return Result.success(data: orders);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<OrderEntity>> createTicket({required String tableNumber}) async {
    try {
      final session = await _sessionStorage.loadSession();

      if (session == null) {
        return Result.failure(error: 'Not authenticated.');
      }

      final order = await _remoteDatasource.createTicket(branchId: session.branchId, tableNumber: tableNumber);

      return Result.success(data: order);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<OrderEntity>> addItemToTicket({
    required String orderId,
    required String menuItemId,
    required int quantity,
  }) async {
    try {
      final order = await _remoteDatasource.addOrderLine(orderId: orderId, menuItemId: menuItemId, quantity: quantity);

      return Result.success(data: order);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<OrderEntity>> updateTicketLineQuantity({
    required String orderId,
    required String lineId,
    required int quantity,
  }) async {
    try {
      final order = await _remoteDatasource.updateOrderLineQuantity(
        orderId: orderId,
        lineId: lineId,
        quantity: quantity,
      );

      return Result.success(data: order);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<OrderEntity>> updateTicketLineDiscount({
    required String orderId,
    required String lineId,
    required double discount,
  }) async {
    try {
      final current = await _remoteDatasource.getOrder(orderId);
      OrderLineEntity? line;

      for (final item in current.lines) {
        if (item.id == lineId) {
          line = item;
          break;
        }
      }

      if (line == null) {
        return Result.failure(error: 'Order line not found.');
      }

      final order = await _remoteDatasource.updateOrderLineQuantity(
        orderId: orderId,
        lineId: lineId,
        quantity: line.quantity.round(),
        discount: discount,
      );

      return Result.success(data: order);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<OrderEntity>> removeTicketLine({required String orderId, required String lineId}) async {
    try {
      final order = await _remoteDatasource.removeOrderLine(orderId: orderId, lineId: lineId);

      return Result.success(data: order);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<OrderEntity>> updateTicketTableNumber({required String orderId, String? tableNumber}) async {
    try {
      final order = await _remoteDatasource.updateOrderTableNumber(orderId: orderId, tableNumber: tableNumber);

      return Result.success(data: order);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<OrderEntity>> settleTicket({
    required String orderId,
    required String paymentMethod,
    required String customerPhone,
    String? customerName,
    String? customerTin,
    double? receivedAmount,
    Map<String, int>? lineQuantities,
  }) async {
    try {
      if (paymentMethod == 'cash') {
        final order = await _remoteDatasource.getOrder(orderId);
        final paid = await _remoteDatasource.payCash(
          orderId: orderId,
          receivedAmount: receivedAmount ?? order.remainingTotal,
          customerPhone: customerPhone,
          customerName: customerName,
          customerTin: customerTin,
          lineQuantities: lineQuantities,
        );

        return Result.success(data: paid);
      }

      if (paymentMethod == 'chapa' || paymentMethod == 'telebirr') {
        final initiated = paymentMethod == 'telebirr'
            ? await _remoteDatasource.initiateTelebirr(
                orderId: orderId,
                customerPhone: customerPhone,
                customerName: customerName,
                customerTin: customerTin,
                lineQuantities: lineQuantities,
              )
            : await _remoteDatasource.initiateChapa(
                orderId: orderId,
                customerPhone: customerPhone,
                customerName: customerName,
                customerTin: customerTin,
                lineQuantities: lineQuantities,
              );

        final payments = [...initiated.order.payments, initiated.payment];

        return Result.success(
          data: OrderEntity(
            id: initiated.order.id,
            branchId: initiated.order.branchId,
            orderNumber: initiated.order.orderNumber,
            status: initiated.order.status,
            subtotal: initiated.order.subtotal,
            taxAmount: initiated.order.taxAmount,
            totalAmount: initiated.order.totalAmount,
            lines: initiated.order.lines,
            payments: payments,
            customerPhone: customerPhone,
            customerName: customerName,
            tableNumber: initiated.order.tableNumber,
            ticketNumber: initiated.order.ticketNumber,
            source: initiated.order.source,
            assignedBranchMemberUserId: initiated.order.assignedBranchMemberUserId,
            createdAt: initiated.order.createdAt,
          ),
        );
      }

      return Result.failure(error: 'Unsupported payment method.');
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<OrderEntity>> getOrder(String orderId) async {
    try {
      final order = await _remoteDatasource.getOrder(orderId);

      return Result.success(data: order);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<OrderEntity>> submitOrder({
    required String orderId,
    required String customerPhone,
    String? customerName,
    String? customerTin,
  }) async {
    try {
      final order = await _remoteDatasource.submitOrder(
        orderId: orderId,
        customerPhone: customerPhone,
        customerName: customerName,
        customerTin: customerTin,
      );
      return Result.success(data: order);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<OrderPaymentEntity>> pollPaymentStatus({
    required String paymentId,
    int maxAttempts = 30,
    Duration interval = const Duration(seconds: 2),
  }) async {
    try {
      for (var attempt = 0; attempt < maxAttempts; attempt++) {
        final status = await _remoteDatasource.getPaymentStatus(paymentId);

        if (status.status == 'Completed' || status.status == 'Failed') {
          return Result.success(data: status);
        }

        await Future<void>.delayed(interval);
      }

      return Result.failure(error: 'Payment confirmation timed out.');
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<({bool cash, bool chapa, bool telebirr})>> getPaymentMethods() async {
    try {
      final session = await _sessionStorage.loadSession();

      if (session == null) {
        return Result.failure(error: 'Not authenticated.');
      }

      final methods = await _remoteDatasource.getPaymentMethods(branchId: session.branchId);

      return Result.success(data: methods);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<OrderWorkflowSettingsEntity>> getEffectiveWorkflowSettings() async {
    try {
      final session = await _sessionStorage.loadSession();

      if (session == null) {
        return Result.failure(error: 'Not authenticated.');
      }

      final settings = await _remoteDatasource.getEffectiveWorkflowSettings(branchId: session.branchId);
      return Result.success(data: settings);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<BusinessProfileEntity>> getBusinessProfile() async {
    try {
      final session = await _sessionStorage.loadSession();

      if (session == null) {
        return Result.failure(error: 'Not authenticated.');
      }

      final profile = await _remoteDatasource.getBusinessProfile(branchId: session.branchId);
      return Result.success(data: profile);
    } catch (e) {
      return Result.failure(error: e);
    }
  }
}
