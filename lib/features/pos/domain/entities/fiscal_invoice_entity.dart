import 'package:equatable/equatable.dart';

class FiscalInvoiceEntity extends Equatable {
  const FiscalInvoiceEntity({
    required this.id,
    required this.orderId,
    required this.status,
    this.irn,
    this.signedQr,
    this.salesReceiptRrn,
    this.documentNumber,
    this.transactionType,
    this.failureReason,
    this.submittedAt,
    this.notifiedAt,
    this.notificationPhone,
  });

  final String id;
  final String orderId;
  final String status;
  final String? irn;
  final String? signedQr;
  final String? salesReceiptRrn;
  final String? documentNumber;
  final String? transactionType;
  final String? failureReason;
  final DateTime? submittedAt;
  final DateTime? notifiedAt;
  final String? notificationPhone;

  bool get isSubmitted => status.toLowerCase() == 'submitted';

  @override
  List<Object?> get props => [id, orderId, status, irn, documentNumber];
}
