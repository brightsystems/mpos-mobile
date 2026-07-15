import 'package:mpos_mobile/features/pos/domain/entities/fiscal_invoice_entity.dart';
import 'package:mpos_mobile/features/pos/domain/entities/order_entity.dart';

abstract class InvoiceDatasource {
  Future<FiscalInvoiceEntity> submitForOrder(OrderEntity order);

  Future<FiscalInvoiceEntity> getForOrder(String orderId);
}
