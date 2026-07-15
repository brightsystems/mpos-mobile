import 'package:mpos_mobile/core/network/json_reader.dart';
import 'package:mpos_mobile/core/network/mpos_api_client.dart';
import 'package:mpos_mobile/features/pos/data/datasources/invoice_datasource.dart';
import 'package:mpos_mobile/features/pos/domain/entities/fiscal_invoice_entity.dart';
import 'package:mpos_mobile/features/pos/domain/entities/order_entity.dart';

class InvoiceRemoteDatasource implements InvoiceDatasource {
  InvoiceRemoteDatasource(this._client);

  final MposApiClient _client;

  @override
  Future<FiscalInvoiceEntity> submitForOrder(OrderEntity order) async {
    return getForOrder(order.id);
  }

  @override
  Future<FiscalInvoiceEntity> getForOrder(String orderId) async {
    final response = await _client.get(
      '/orders/$orderId/invoice',
      authenticated: true,
      fromJson: (json) => _mapInvoice(json as Map<String, dynamic>),
    );

    if (!response.success || response.data == null) {
      throw response.message ?? response.errors.join(', ');
    }

    return response.data!;
  }

  FiscalInvoiceEntity _mapInvoice(Map<String, dynamic> json) {
    final reader = JsonReader(json);

    return FiscalInvoiceEntity(
      id: reader.string('id'),
      orderId: reader.string('orderId'),
      status: reader.string('status'),
      irn: reader.string('irn').isEmpty ? null : reader.string('irn'),
      signedQr: reader.string('signedQr').isEmpty ? null : reader.string('signedQr'),
      salesReceiptRrn: reader.string('salesReceiptRrn').isEmpty ? null : reader.string('salesReceiptRrn'),
      documentNumber: reader.string('documentNumber').isEmpty ? null : reader.string('documentNumber'),
      transactionType: reader.string('transactionType').isEmpty ? null : reader.string('transactionType'),
      failureReason: reader.string('failureReason').isEmpty ? null : reader.string('failureReason'),
      submittedAt: reader.dateTime('submittedAt'),
      notifiedAt: reader.dateTime('notifiedAt'),
      notificationPhone: reader.string('notificationPhone').isEmpty ? null : reader.string('notificationPhone'),
    );
  }
}
