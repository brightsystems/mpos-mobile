import 'package:equatable/equatable.dart';

class FiscalMemoLineEntity extends Equatable {
  const FiscalMemoLineEntity({
    required this.orderLineId,
    required this.lineNumber,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    required this.preTaxValue,
    required this.exciseTaxValue,
    required this.taxAmount,
    required this.taxCode,
    required this.totalLineAmount,
  });

  final String orderLineId;
  final int lineNumber;
  final String name;
  final double unitPrice;
  final double quantity;
  final double preTaxValue;
  final double exciseTaxValue;
  final double taxAmount;
  final String taxCode;
  final double totalLineAmount;

  @override
  List<Object?> get props => [orderLineId, lineNumber, quantity, totalLineAmount];
}

class FiscalMemoEntity extends Equatable {
  const FiscalMemoEntity({
    required this.id,
    required this.orderId,
    required this.memoType,
    required this.reason,
    required this.status,
    required this.preTaxValue,
    required this.exciseValue,
    required this.taxValue,
    required this.totalValue,
    this.fiscalInvoiceId,
    this.irn,
    this.signedQr,
    this.documentNumber,
    this.relatedDocumentNumber,
    this.transactionType,
    this.failureReason,
    this.submittedAt,
    this.lines = const [],
    this.stage,
    this.receiptNumber,
    this.receiptRrn,
    this.receiptError,
    this.receiptAmount = 0,
    this.refundAmount = 0,
  });

  final String id;
  final String orderId;
  final String? fiscalInvoiceId;
  final String memoType;
  final String reason;
  final String status;
  final String? irn;
  final String? signedQr;
  final String? documentNumber;
  final String? relatedDocumentNumber;
  final String? transactionType;
  final String? failureReason;
  final DateTime? submittedAt;
  final double preTaxValue;
  final double exciseValue;
  final double taxValue;
  final double totalValue;
  final List<FiscalMemoLineEntity> lines;

  /// INVOICE: issued before full payment (changed the balance); RECEIPT: issued after payment
  /// (settled by its own receipt); null for notes issued before stages existed.
  final String? stage;
  final String? receiptNumber;
  final String? receiptRrn;
  final String? receiptError;

  /// Refunded (credit note) or collected (debit note) on the note's receipt.
  final double receiptAmount;

  /// Cash refunded out of the shift (credit note on a paid order).
  final double refundAmount;

  bool get isCredit => memoType.toUpperCase() == 'CRE';

  bool get isReceiptStage => stage == 'RECEIPT';

  bool get isInvoiceStage => stage == 'INVOICE';

  /// What happened to the note's money, for the cashier.
  String get outcome {
    String amount(double v) => '${v.toStringAsFixed(2)} ETB';
    if (isInvoiceStage) {
      return isCredit
          ? 'The buyer now owes ${amount(totalValue)} less.'
          : 'The buyer now owes ${amount(totalValue)} more.';
    }
    if (!isReceiptStage) {
      return '';
    }
    if (receiptRrn == null) {
      return 'The note is registered but its receipt failed: ${receiptError ?? 'unknown error'}.';
    }
    return isCredit
        ? 'Refund ${amount(refundAmount)} to the buyer in cash. Receipt $receiptRrn.'
        : 'Collect ${amount(receiptAmount)} from the buyer. Receipt $receiptRrn.';
  }

  String get typeLabel => isCredit ? 'Credit note' : 'Debit note';

  @override
  List<Object?> get props => [id, orderId, memoType, status, documentNumber, totalValue, stage, receiptRrn];
}
