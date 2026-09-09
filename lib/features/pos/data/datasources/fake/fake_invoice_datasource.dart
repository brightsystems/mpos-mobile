import 'package:mpos_mobile/core/mock/mock_fixtures.dart';
import 'package:mpos_mobile/features/pos/data/datasources/invoice_datasource.dart';
import 'package:mpos_mobile/features/pos/domain/entities/fiscal_document_pdf_entity.dart';
import 'package:mpos_mobile/features/pos/domain/entities/fiscal_invoice_entity.dart';
import 'package:mpos_mobile/features/pos/domain/entities/fiscal_memo_entity.dart';
import 'package:mpos_mobile/features/pos/domain/entities/order_entity.dart';

class FakeInvoiceDatasource implements InvoiceDatasource {
  final Map<String, FiscalInvoiceEntity> _invoices = {};
  int _invoiceSequence = 1;
  int _documentSequence = MockFixtures.initialDocumentNumber;

  Future<void> _simulateMor() => Future<void>.delayed(const Duration(milliseconds: 600));

  @override
  Future<FiscalInvoiceEntity> submitForOrder(OrderEntity order) async {
    await _simulateMor();

    final existing = _invoices[order.id];

    if (existing != null && existing.isSubmitted) {
      return existing;
    }

    final sequence = _invoiceSequence++;
    final now = DateTime.now().toUtc();
    final irn =
        'MOCK-IRN-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${sequence.toString().padLeft(6, '0')}';
    final documentNumber = (_documentSequence++).toString();
    final transactionType = 'B2C';
    final notificationPhone = order.customerPhone;

    final invoice = FiscalInvoiceEntity(
      id: 'mock-invoice-$sequence',
      orderId: order.id,
      status: 'Submitted',
      irn: irn,
      signedQr: 'MOCK-QR-$irn',
      documentNumber: documentNumber,
      transactionType: transactionType,
      submittedAt: now,
      notifiedAt: notificationPhone != null ? now.add(const Duration(seconds: 1)) : null,
      notificationPhone: notificationPhone,
    );

    _invoices[order.id] = invoice;

    return invoice;
  }

  @override
  Future<FiscalInvoiceEntity> getForOrder(String orderId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));

    final invoice = _invoices[orderId];

    if (invoice == null) {
      throw 'E-invoice not found for this order.';
    }

    return invoice;
  }

  @override
  Future<FiscalInvoiceEntity> cancelInvoice({
    required String orderId,
    required String reasonCode,
    String? remark,
  }) async {
    await _simulateMor();

    final invoice = _invoices[orderId];

    if (invoice == null) {
      throw 'E-invoice not found for this order.';
    }

    if (invoice.isCancelled) {
      throw 'E-invoice is already cancelled.';
    }

    final cancelled = FiscalInvoiceEntity(
      id: invoice.id,
      orderId: invoice.orderId,
      status: 'Cancelled',
      irn: invoice.irn,
      signedQr: invoice.signedQr,
      salesReceiptRrn: invoice.salesReceiptRrn,
      documentNumber: invoice.documentNumber,
      transactionType: invoice.transactionType,
      submittedAt: invoice.submittedAt,
      notifiedAt: invoice.notifiedAt,
      notificationPhone: invoice.notificationPhone,
      cancelledAt: DateTime.now().toUtc(),
      cancellationReasonCode: reasonCode,
      cancellationRemark: remark,
    );

    _invoices[orderId] = cancelled;

    return cancelled;
  }

  @override
  Future<FiscalDocumentPdfEntity> getInvoicePdf(String orderId) async {
    throw 'PDF documents are not available in mock mode.';
  }

  @override
  Future<FiscalDocumentPdfEntity> getReceiptPdf(String orderId) async {
    throw 'PDF documents are not available in mock mode.';
  }

  @override
  Future<FiscalDocumentPdfEntity> getMemoPdf({required String orderId, required String memoId}) async {
    throw 'PDF documents are not available in mock mode.';
  }

  final Map<String, List<FiscalMemoEntity>> _memos = {};
  int _memoSequence = 1;

  @override
  Future<List<FiscalMemoEntity>> listMemos(String orderId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));

    return _memos[orderId] ?? const [];
  }

  @override
  Future<FiscalMemoEntity> registerMemo({
    required String orderId,
    required String memoType,
    required String reason,
    required List<({String orderLineId, int quantity})> lines,
  }) async {
    await _simulateMor();

    final invoice = _invoices[orderId];

    if (invoice == null || !invoice.isSubmitted) {
      throw 'A submitted e-invoice is required before issuing a memo.';
    }

    final sequence = _memoSequence++;
    final memo = FiscalMemoEntity(
      id: 'mock-memo-$sequence',
      orderId: orderId,
      fiscalInvoiceId: invoice.id,
      memoType: memoType,
      reason: reason,
      status: 'Submitted',
      irn: 'MOCK-MEMO-IRN-${sequence.toString().padLeft(6, '0')}',
      documentNumber: (_documentSequence++).toString(),
      relatedDocumentNumber: invoice.documentNumber,
      transactionType: invoice.transactionType,
      submittedAt: DateTime.now().toUtc(),
      preTaxValue: 0,
      exciseValue: 0,
      taxValue: 0,
      totalValue: 0,
    );

    _memos.putIfAbsent(orderId, () => []).add(memo);

    return memo;
  }
}
