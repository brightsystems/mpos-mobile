import 'package:mpos_mobile/core/common/result.dart';
import 'package:mpos_mobile/core/config/mpos_config.dart';
import 'package:mpos_mobile/features/pos/data/datasources/invoice_datasource.dart';
import 'package:mpos_mobile/features/pos/domain/entities/fiscal_document_pdf_entity.dart';
import 'package:mpos_mobile/features/pos/domain/entities/fiscal_invoice_entity.dart';
import 'package:mpos_mobile/features/pos/domain/entities/fiscal_memo_entity.dart';
import 'package:mpos_mobile/features/pos/domain/entities/order_entity.dart';
import 'package:mpos_mobile/features/pos/domain/repositories/invoice_repository.dart';

class InvoiceRepositoryImpl implements InvoiceRepository {
  InvoiceRepositoryImpl({required InvoiceDatasource datasource}) : _datasource = datasource;

  final InvoiceDatasource _datasource;

  @override
  Future<Result<FiscalInvoiceEntity>> submitForOrder(OrderEntity order) async {
    try {
      final invoice = await _datasource.submitForOrder(order);

      return Result.success(data: invoice);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<FiscalInvoiceEntity>> pollForOrder(
    String orderId, {
    int maxAttempts = 3,
    Duration interval = const Duration(milliseconds: 500),
  }) async {
    try {
      if (MposConfig.mockMode) {
        final invoice = await _datasource.getForOrder(orderId);

        return Result.success(data: invoice);
      }

      Object? lastError;

      for (var attempt = 0; attempt < maxAttempts; attempt++) {
        try {
          final invoice = await _datasource.getForOrder(orderId);
          final status = invoice.status.toLowerCase();

          if (status == 'submitted' || status == 'failed') {
            return Result.success(data: invoice);
          }
        } catch (e) {
          lastError = e;
          // Invoice may not exist yet while fiscal submit runs in the background,
          // or MOR may not be configured for this organization.
        }

        if (attempt < maxAttempts - 1) {
          await Future<void>.delayed(interval);
        }
      }

      return Result.failure(
        error: lastError ?? 'E-invoice is unavailable (MOR may not be configured).',
      );
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<FiscalInvoiceEntity>> getForOrder(String orderId) async {
    try {
      final invoice = await _datasource.getForOrder(orderId);

      return Result.success(data: invoice);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<FiscalInvoiceEntity>> cancelInvoice({
    required String orderId,
    required String reasonCode,
    String? remark,
  }) async {
    try {
      final invoice = await _datasource.cancelInvoice(orderId: orderId, reasonCode: reasonCode, remark: remark);

      return Result.success(data: invoice);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<FiscalDocumentPdfEntity>> getInvoicePdf(String orderId) async {
    try {
      final pdf = await _datasource.getInvoicePdf(orderId);

      return Result.success(data: pdf);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<FiscalDocumentPdfEntity>> getReceiptPdf(String orderId) async {
    try {
      final pdf = await _datasource.getReceiptPdf(orderId);

      return Result.success(data: pdf);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<List<FiscalMemoEntity>>> listMemos(String orderId) async {
    try {
      final memos = await _datasource.listMemos(orderId);

      return Result.success(data: memos);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<FiscalMemoEntity>> registerMemo({
    required String orderId,
    required String memoType,
    required String reason,
    required List<({String orderLineId, int quantity})> lines,
  }) async {
    try {
      final memo = await _datasource.registerMemo(
        orderId: orderId,
        memoType: memoType,
        reason: reason,
        lines: lines,
      );

      return Result.success(data: memo);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<FiscalDocumentPdfEntity>> getMemoPdf({required String orderId, required String memoId}) async {
    try {
      final pdf = await _datasource.getMemoPdf(orderId: orderId, memoId: memoId);

      return Result.success(data: pdf);
    } catch (e) {
      return Result.failure(error: e);
    }
  }
}
