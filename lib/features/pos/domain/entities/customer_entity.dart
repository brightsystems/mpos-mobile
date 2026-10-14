import 'package:equatable/equatable.dart';

/// A saved buyer (Customers page). Linking one to a sale fills the invoice buyer details and
/// sets the transaction type (B2C/B2B/B2G), which drives withholding.
class CustomerEntity extends Equatable {
  const CustomerEntity({
    required this.id,
    required this.type,
    required this.transactionType,
    required this.legalName,
    this.tin,
    this.phone,
    this.isWithholdingAgent = false,
  });

  final String id;

  /// Customer, Business or Government.
  final String type;

  /// B2C, B2B or B2G.
  final String transactionType;
  final String legalName;
  final String? tin;
  final String? phone;
  final bool isWithholdingAgent;

  @override
  List<Object?> get props => [id, type, transactionType, legalName, tin, phone, isWithholdingAgent];
}
