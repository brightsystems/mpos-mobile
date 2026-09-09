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
    this.cancelledAt,
    this.cancellationReasonCode,
    this.cancellationRemark,
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
  final DateTime? cancelledAt;
  final String? cancellationReasonCode;
  final String? cancellationRemark;

  bool get isSubmitted => status.toLowerCase() == 'submitted';

  bool get isCancelled => status.toLowerCase() == 'cancelled';

  @override
  List<Object?> get props => [id, orderId, status, irn, documentNumber, cancelledAt];
}
