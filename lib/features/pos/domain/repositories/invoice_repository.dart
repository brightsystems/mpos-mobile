import 'package:mpos_mobile/core/common/result.dart';
import 'package:mpos_mobile/features/pos/domain/entities/fiscal_document_pdf_entity.dart';
import 'package:mpos_mobile/features/pos/domain/entities/fiscal_invoice_entity.dart';
import 'package:mpos_mobile/features/pos/domain/entities/fiscal_memo_entity.dart';
import 'package:mpos_mobile/features/pos/domain/entities/order_entity.dart';

abstract class InvoiceRepository {
  Future<Result<FiscalInvoiceEntity>> submitForOrder(OrderEntity order);

  Future<Result<FiscalInvoiceEntity>> pollForOrder(
    String orderId, {
    int maxAttempts = 20,
    Duration interval = const Duration(seconds: 1),
  });

  Future<Result<FiscalInvoiceEntity>> getForOrder(String orderId);

  Future<Result<FiscalInvoiceEntity>> cancelInvoice({
    required String orderId,
    required String reasonCode,
    String? remark,
  });

  Future<Result<FiscalDocumentPdfEntity>> getInvoicePdf(String orderId);

  Future<Result<FiscalDocumentPdfEntity>> getReceiptPdf(String orderId);

  Future<Result<List<FiscalMemoEntity>>> listMemos(String orderId);

  Future<Result<FiscalMemoEntity>> registerMemo({
    required String orderId,
    required String memoType,
    required String reason,
    required List<({String orderLineId, int quantity})> lines,
  });

  Future<Result<FiscalDocumentPdfEntity>> getMemoPdf({required String orderId, required String memoId});
}
