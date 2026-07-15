import 'package:mpos_mobile/core/common/result.dart';
import 'package:mpos_mobile/features/pos/domain/entities/fiscal_invoice_entity.dart';
import 'package:mpos_mobile/features/pos/domain/entities/order_entity.dart';

abstract class InvoiceRepository {
  Future<Result<FiscalInvoiceEntity>> submitForOrder(OrderEntity order);

  Future<Result<FiscalInvoiceEntity>> pollForOrder(
    String orderId, {
    int maxAttempts = 20,
    Duration interval = const Duration(seconds: 1),
  });
}
