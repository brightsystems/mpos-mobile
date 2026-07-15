import 'package:mpos_mobile/core/common/result.dart';
import 'package:mpos_mobile/features/pos/domain/entities/order_entity.dart';

abstract class OrderRepository {
  Future<Result<List<OrderEntity>>> getOpenOrders();

  Future<Result<OrderEntity>> createTicket({required String tableNumber});

  Future<Result<OrderEntity>> addItemToTicket({
    required String orderId,
    required String menuItemId,
    required int quantity,
  });

  Future<Result<OrderEntity>> updateTicketLineQuantity({
    required String orderId,
    required String lineId,
    required int quantity,
  });

  Future<Result<OrderEntity>> removeTicketLine({required String orderId, required String lineId});

  Future<Result<OrderEntity>> updateTicketTableNumber({required String orderId, String? tableNumber});

  Future<Result<OrderEntity>> settleTicket({
    required String orderId,
    required String paymentMethod,
    required String customerPhone,
    String? customerName,
    String? customerTin,
    double? receivedAmount,
    Map<String, int>? lineQuantities,
  });

  Future<Result<OrderEntity>> getOrder(String orderId);

  Future<Result<OrderPaymentEntity>> pollPaymentStatus({
    required String paymentId,
    int maxAttempts = 30,
    Duration interval = const Duration(seconds: 2),
  });

  Future<Result<({bool cash, bool chapa, bool telebirr})>> getPaymentMethods();
}
