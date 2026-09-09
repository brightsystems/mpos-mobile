import 'package:mpos_mobile/features/pos/domain/entities/fiscal_document_pdf_entity.dart';
import 'package:mpos_mobile/features/pos/domain/entities/fiscal_invoice_entity.dart';
import 'package:mpos_mobile/features/pos/domain/entities/fiscal_memo_entity.dart';
import 'package:mpos_mobile/features/pos/domain/entities/order_entity.dart';

abstract class InvoiceDatasource {
  Future<FiscalInvoiceEntity> submitForOrder(OrderEntity order);

  Future<FiscalInvoiceEntity> getForOrder(String orderId);

  Future<FiscalInvoiceEntity> cancelInvoice({required String orderId, required String reasonCode, String? remark});

  Future<FiscalDocumentPdfEntity> getInvoicePdf(String orderId);

  Future<FiscalDocumentPdfEntity> getReceiptPdf(String orderId);

  Future<List<FiscalMemoEntity>> listMemos(String orderId);

  Future<FiscalMemoEntity> registerMemo({
    required String orderId,
    required String memoType,
    required String reason,
    required List<({String orderLineId, int quantity})> lines,
  });

  Future<FiscalDocumentPdfEntity> getMemoPdf({required String orderId, required String memoId});
}
