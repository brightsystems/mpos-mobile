import 'dart:convert';

import 'package:mpos_mobile/core/network/json_reader.dart';
import 'package:mpos_mobile/core/network/mpos_api_client.dart';
import 'package:mpos_mobile/features/pos/data/datasources/invoice_datasource.dart';
import 'package:mpos_mobile/features/pos/domain/entities/fiscal_document_pdf_entity.dart';
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

  @override
  Future<FiscalInvoiceEntity> cancelInvoice({
    required String orderId,
    required String reasonCode,
    String? remark,
  }) async {
    final response = await _client.post(
      '/orders/$orderId/invoice/cancel',
      authenticated: true,
      body: {'reasonCode': reasonCode, 'remark': (remark == null || remark.isEmpty) ? null : remark},
      fromJson: (json) => _mapInvoice(json as Map<String, dynamic>),
    );

    if (!response.success || response.data == null) {
      throw response.message ?? response.errors.join(', ');
    }

    return response.data!;
  }

  @override
  Future<FiscalDocumentPdfEntity> getInvoicePdf(String orderId) => _getPdf('/orders/$orderId/invoice/pdf');

  @override
  Future<FiscalDocumentPdfEntity> getReceiptPdf(String orderId) => _getPdf('/orders/$orderId/receipt/pdf');

  Future<FiscalDocumentPdfEntity> _getPdf(String path) async {
    final response = await _client.get(
      path,
      authenticated: true,
      fromJson: (json) {
        final reader = JsonReader(json as Map<String, dynamic>);
        return FiscalDocumentPdfEntity(
          fileName: reader.string('fileName', fallback: 'document.pdf'),
          contentType: reader.string('contentType', fallback: 'application/pdf'),
          bytes: base64Decode(reader.string('base64')),
        );
      },
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
      cancelledAt: reader.dateTime('cancelledAt'),
      cancellationReasonCode: reader.string('cancellationReasonCode').isEmpty
          ? null
          : reader.string('cancellationReasonCode'),
      cancellationRemark: reader.string('cancellationRemark').isEmpty ? null : reader.string('cancellationRemark'),
    );
  }
}
