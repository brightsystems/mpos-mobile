import 'package:mpos_mobile/features/pos/domain/entities/business_profile_entity.dart';
import 'package:mpos_mobile/features/pos/domain/entities/customer_entity.dart';
import 'package:mpos_mobile/features/pos/domain/entities/order_entity.dart';
import 'package:mpos_mobile/features/pos/domain/entities/order_workflow_settings_entity.dart';

abstract class OrderDatasource {
  Future<OrderEntity> createOrder({required String branchId, String? clientOrderId});

  Future<List<OrderEntity>> getOpenOrders({required String branchId});

  Future<OrderEntity> createTicket({required String branchId, required String tableNumber});

  Future<OrderEntity> addOrderLine({
    required String orderId,
    required String menuItemId,
    required int quantity,
    double? discount,
  });

  Future<OrderEntity> updateOrderLineQuantity({
    required String orderId,
    required String lineId,
    required int quantity,
    double? discount,
  });

  Future<OrderEntity> removeOrderLine({required String orderId, required String lineId});

  Future<OrderEntity> updateOrderTableNumber({required String orderId, String? tableNumber});

  Future<OrderEntity> payCash({
    required String orderId,
    required double receivedAmount,
    required String customerPhone,
    String? customerName,
    String? customerTin,
    Map<String, int>? lineQuantities,
    String? customerId,
    double? amount,
  });

  Future<({OrderPaymentEntity payment, OrderEntity order})> initiateChapa({
    required String orderId,
    required String customerPhone,
    String? customerName,
    String? customerTin,
    Map<String, int>? lineQuantities,
    String? customerId,
  });

  Future<({OrderPaymentEntity payment, OrderEntity order})> initiateTelebirr({
    required String orderId,
    required String customerPhone,
    String? customerName,
    String? customerTin,
    Map<String, int>? lineQuantities,
    String? customerId,
  });

  Future<({bool cash, bool chapa, bool telebirr})> getPaymentMethods({required String branchId});

  Future<OrderPaymentEntity> getPaymentStatus(String paymentId);

  Future<OrderEntity> getOrder(String orderId);

  Future<OrderEntity> submitOrder({
    required String orderId,
    String? customerPhone,
    String? customerName,
    String? customerTin,
    String? customerId,
    String paymentMode = 'CASH',
  });

  Future<OrderWorkflowSettingsEntity> getEffectiveWorkflowSettings({required String branchId});

  Future<BusinessProfileEntity> getBusinessProfile({required String branchId});

  /// Saved customers matching [query] (name, TIN or phone).
  Future<List<CustomerEntity>> searchCustomers({required String organizationId, String query = ''});
}
