import 'package:equatable/equatable.dart';

import 'package:mpos_mobile/features/pos/domain/entities/tax_rate_entity.dart';

class OrderLineEntity extends Equatable {
  const OrderLineEntity({
    required this.id,
    required this.menuItemId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
    this.paidQuantity = 0,
    this.discount = 0,
    this.taxes = const [],
    this.taxAmount,
    this.imageUrl,
    this.stockOnHand,
    this.trackInventory = false,
  });

  final String id;
  final String menuItemId;
  final String name;
  final double unitPrice;
  final double quantity;
  final double lineTotal;
  final double paidQuantity;
  final double discount;
  final List<TaxRateEntity> taxes;

  /// Line tax as calculated by the API (excise first, other taxes on price + excise).
  /// Null for locally built lines (mock mode), which fall back to [calculateTaxesAmount].
  final double? taxAmount;
  final String? imageUrl;
  final double? stockOnHand;
  final bool trackInventory;

  double get remainingQuantity => quantity - paidQuantity;

  double get remainingLineTotal {
    if (quantity <= 0) {
      return 0;
    }

    // Discount is a whole-line amount; apportion it to the unpaid quantity.
    final proportionalDiscount = discount * (remainingQuantity / quantity);
    final total = unitPrice * remainingQuantity - proportionalDiscount;

    return total < 0 ? 0 : total;
  }

  double get remainingTaxAmount {
    final apiTax = taxAmount;

    if (apiTax == null) {
      return calculateTaxesAmount(remainingLineTotal, taxes);
    }

    return quantity <= 0 ? 0 : apiTax * (remainingQuantity / quantity);
  }

  bool get isPaid => remainingQuantity <= 0;

  OrderLineEntity copyWith({double? quantity, double? paidQuantity, double? discount, List<TaxRateEntity>? taxes}) {
    final nextQuantity = quantity ?? this.quantity;
    final nextDiscount = discount ?? this.discount;

    return OrderLineEntity(
      id: id,
      menuItemId: menuItemId,
      name: name,
      unitPrice: unitPrice,
      quantity: nextQuantity,
      lineTotal: (unitPrice * nextQuantity - nextDiscount).clamp(0, double.infinity),
      paidQuantity: paidQuantity ?? this.paidQuantity,
      discount: nextDiscount,
      taxes: taxes ?? this.taxes,
      imageUrl: imageUrl,
      stockOnHand: stockOnHand,
      trackInventory: trackInventory,
    );
  }

  @override
  List<Object?> get props => [id, menuItemId, quantity, paidQuantity, discount, taxes, taxAmount];
}

class OrderPaymentEntity extends Equatable {
  const OrderPaymentEntity({
    required this.id,
    required this.method,
    required this.status,
    required this.amount,
    this.receivedAmount,
    this.changeAmount,
    this.checkoutUrl,
    this.txRef,
    this.ussdPushed = false,
    this.coveredLineIds = const [],
    this.coveredQuantities = const {},
  });

  final String id;
  final String method;
  final String status;
  final double amount;
  final double? receivedAmount;
  final double? changeAmount;
  final String? checkoutUrl;
  final String? txRef;

  /// Telebirr: the payment prompt was pushed to the customer's phone (no checkout page needed).
  final bool ussdPushed;
  final List<String> coveredLineIds;
  final Map<String, int> coveredQuantities;

  @override
  List<Object?> get props => [id, method, status, amount, coveredLineIds, coveredQuantities];
}

/// Order statuses that are finished (no further payment or edits).
const _closedStatuses = {'Paid', 'Cancelled', 'Rejected'};

class OrderEntity extends Equatable {
  const OrderEntity({
    required this.id,
    required this.branchId,
    required this.orderNumber,
    required this.status,
    required this.subtotal,
    required this.taxAmount,
    required this.totalAmount,
    required this.lines,
    required this.payments,
    this.customerPhone,
    this.customerName,
    this.customerTin,
    this.customerId,
    this.customerEmail,
    this.tableNumber,
    this.ticketNumber,
    this.source,
    this.assignedBranchMemberUserId,
    this.createdAt,
    this.discountAmount = 0,
    this.withholdingAmount = 0,
    this.netPayableAmount,
    this.paidAmount = 0,
    this.remainingAmount,
    this.paymentMode = 'CASH',
  });

  final String id;
  final String branchId;
  final String orderNumber;
  final String status;
  final double subtotal;
  final double taxAmount;
  final double totalAmount;
  final List<OrderLineEntity> lines;
  final List<OrderPaymentEntity> payments;
  final String? customerPhone;
  final String? customerName;
  final String? customerTin;

  /// Saved customer linked to the sale (sets the invoice buyer and B2B/B2G type).
  final String? customerId;

  /// Buyer email: invoices and receipts are emailed here when the business enables email.
  final String? customerEmail;
  final String? tableNumber;
  final String? ticketNumber;
  final String? source;
  final String? assignedBranchMemberUserId;
  final DateTime? createdAt;
  final double discountAmount;

  /// Withholding the buyer keeps (B2B/B2G); the invoice total is unchanged.
  final double withholdingAmount;

  /// What the buyer pays: total minus withholding (from the API; null for local mock orders).
  final double? netPayableAmount;

  /// Paid so far (partial payments).
  final double paidAmount;

  /// Still to pay: net payable minus what was paid (from the API; null for local mock orders).
  final double? remainingAmount;

  /// CASH or CREDIT sale, chosen at submit.
  final String paymentMode;

  List<OrderLineEntity> get unpaidLines => lines.where((line) => !line.isPaid).toList();

  double get remainingSubtotal => unpaidLines.fold<double>(0, (sum, line) => sum + line.remainingLineTotal);

  double get remainingTaxAmount => unpaidLines.fold<double>(0, (sum, line) => sum + line.remainingTaxAmount);

  /// Amount still to collect — the API's figure (net of withholding and earlier payments),
  /// or the unpaid lines for local mock orders.
  double get remainingTotal => remainingAmount ?? (remainingSubtotal + remainingTaxAmount);

  /// What the buyer pays in total (net of withholding).
  double get netPayable => netPayableAmount ?? totalAmount;

  bool get isDraft => status == 'Draft';

  bool get isCreditSale => paymentMode.toUpperCase() == 'CREDIT';

  bool get isClosed {
    if (_closedStatuses.contains(status)) {
      return true;
    }

    // A ticket with items is settled once every item is paid.
    return lines.isNotEmpty && unpaidLines.isEmpty;
  }

  OrderEntity copyWith({
    String? status,
    double? subtotal,
    double? taxAmount,
    double? totalAmount,
    List<OrderLineEntity>? lines,
    List<OrderPaymentEntity>? payments,
    String? customerPhone,
    String? customerName,
    String? customerTin,
    String? tableNumber,
    String? ticketNumber,
    String? source,
    String? assignedBranchMemberUserId,
    DateTime? createdAt,
  }) {
    return OrderEntity(
      id: id,
      branchId: branchId,
      orderNumber: orderNumber,
      status: status ?? this.status,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      lines: lines ?? this.lines,
      payments: payments ?? this.payments,
      customerPhone: customerPhone ?? this.customerPhone,
      customerName: customerName ?? this.customerName,
      customerTin: customerTin ?? this.customerTin,
      customerId: customerId,
      customerEmail: customerEmail,
      tableNumber: tableNumber ?? this.tableNumber,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      source: source ?? this.source,
      assignedBranchMemberUserId: assignedBranchMemberUserId ?? this.assignedBranchMemberUserId,
      createdAt: createdAt ?? this.createdAt,
      discountAmount: discountAmount,
      withholdingAmount: withholdingAmount,
      netPayableAmount: netPayableAmount,
      paidAmount: paidAmount,
      remainingAmount: remainingAmount,
      paymentMode: paymentMode,
    );
  }

  @override
  List<Object?> get props => [
    id,
    orderNumber,
    status,
    totalAmount,
    tableNumber,
    ticketNumber,
    lines,
    payments,
    paidAmount,
    remainingAmount,
    withholdingAmount,
    paymentMode,
    customerId,
  ];
}
