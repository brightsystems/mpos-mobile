import 'package:equatable/equatable.dart';

/// Seller details printed on the invoice (branch values, organization fallback).
class FiscalSellerEntity extends Equatable {
  const FiscalSellerEntity({
    required this.legalName,
    required this.tin,
    this.subTin,
    this.vatNumber,
    this.vatRegistrationDate,
    this.email,
    this.phone,
    this.city,
    this.logoUrl,
  });

  final String legalName;
  final String tin;
  final String? subTin;
  final String? vatNumber;

  /// yyyy-MM-dd
  final String? vatRegistrationDate;
  final String? email;
  final String? phone;
  final String? city;
  final String? logoUrl;

  @override
  List<Object?> get props => [legalName, tin, subTin, vatNumber, vatRegistrationDate, email, logoUrl];
}

class FiscalInvoiceEntity extends Equatable {
  const FiscalInvoiceEntity({
    required this.id,
    required this.orderId,
    required this.status,
    this.irn,
    this.signedQr,
    this.salesReceiptRrn,
    this.salesReceiptQr,
    this.documentNumber,
    this.morDocumentType,
    this.transactionType,
    this.failureReason,
    this.submittedAt,
    this.receiptRegisteredAt,
    this.morAckDate,
    this.paymentMode,
    this.incomeWithholdAmount = 0,
    this.vatWithholdAmount = 0,
    this.seller,
    this.notifiedAt,
    this.notificationPhone,
    this.cancelledAt,
    this.cancellationReasonCode,
    this.cancellationRemark,
  });

  final String id;
  final String orderId;

  /// API status: Pending, Registered, Completed, Failed, ReceiptFailed or Cancelled.
  final String status;
  final String? irn;
  final String? signedQr;
  final String? salesReceiptRrn;
  final String? salesReceiptQr;
  final String? documentNumber;
  final String? morDocumentType;
  final String? transactionType;
  final String? failureReason;
  final DateTime? submittedAt;
  final DateTime? receiptRegisteredAt;

  /// Invoice date as acknowledged by MoR.
  final DateTime? morAckDate;

  /// CASH or CREDIT sale as registered with MoR.
  final String? paymentMode;

  /// Income withholding (3%) reported on the invoice.
  final double incomeWithholdAmount;

  /// VAT withholding (50% of VAT15, B2G) reported on the invoice.
  final double vatWithholdAmount;
  final FiscalSellerEntity? seller;
  final DateTime? notifiedAt;
  final String? notificationPhone;
  final DateTime? cancelledAt;
  final String? cancellationReasonCode;
  final String? cancellationRemark;

  String get _status => status.toLowerCase();

  /// Registered with MoR (invoice accepted; the sales receipt may or may not be in yet).
  bool get isRegistered => _status == 'registered' || _status == 'completed' || _status == 'receiptfailed';

  bool get isCancelled => _status == 'cancelled';

  bool get isFailed => _status == 'failed';

  /// No further change expected from background registration.
  bool get isSettled => isRegistered || isCancelled || isFailed;

  bool get isCreditSale => (paymentMode ?? 'CASH').toUpperCase() == 'CREDIT';

  /// The invoice date: MoR's acknowledgement date, else when it was submitted.
  DateTime? get invoiceDate => morAckDate ?? submittedAt;

  @override
  List<Object?> get props => [id, orderId, status, irn, documentNumber, cancelledAt, salesReceiptRrn, paymentMode];
}
