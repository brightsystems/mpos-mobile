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

  bool get isCredit => memoType.toUpperCase() == 'CRE';

  String get typeLabel => isCredit ? 'Credit note' : 'Debit note';

  @override
  List<Object?> get props => [id, orderId, memoType, status, documentNumber, totalValue];
}
