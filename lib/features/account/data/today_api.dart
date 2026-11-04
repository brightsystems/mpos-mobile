import 'package:mpos_mobile/core/network/mpos_api_client.dart';
import 'package:mpos_mobile/core/storage/session_storage.dart';

/// A payment collected today.
class TodayPayment {
  const TodayPayment({
    required this.orderId,
    required this.orderNumber,
    required this.amount,
    required this.method,
    required this.paidAt,
    this.customerPhone,
    this.tableNumber,
  });

  factory TodayPayment.fromJson(Map<String, dynamic> json) => TodayPayment(
    orderId: json['orderId'] as String? ?? '',
    orderNumber: json['orderNumber'] as String? ?? '',
    amount: (json['amount'] as num?)?.toDouble() ?? 0,
    method: json['method'] as String? ?? 'Cash',
    paidAt: DateTime.tryParse(json['paidAt'] as String? ?? '')?.toLocal() ?? DateTime.now(),
    customerPhone: json['customerPhone'] as String?,
    tableNumber: json['tableNumber'] as String?,
  );

  final String orderId;
  final String orderNumber;
  final double amount;
  final String method;
  final DateTime paidAt;
  final String? customerPhone;
  final String? tableNumber;
}

/// An order opened today that is still open.
class TodayOpenOrder {
  const TodayOpenOrder({
    required this.orderId,
    required this.orderNumber,
    required this.status,
    required this.createdAt,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    this.customerPhone,
    this.tableNumber,
  });

  factory TodayOpenOrder.fromJson(Map<String, dynamic> json) => TodayOpenOrder(
    orderId: json['orderId'] as String? ?? '',
    orderNumber: json['orderNumber'] as String? ?? '',
    status: json['status'] as String? ?? '',
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '')?.toLocal() ?? DateTime.now(),
    totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
    paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
    remainingAmount: (json['remainingAmount'] as num?)?.toDouble() ?? 0,
    customerPhone: json['customerPhone'] as String?,
    tableNumber: json['tableNumber'] as String?,
  );

  final String orderId;
  final String orderNumber;
  final String status;
  final DateTime createdAt;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final String? customerPhone;
  final String? tableNumber;
}

/// The branch's day (Addis Ababa) as the API counts it: payments by cash and wallet, open orders.
class BranchToday {
  const BranchToday({
    required this.cashTotal,
    required this.cashCount,
    required this.walletTotal,
    required this.walletCount,
    required this.paidOrdersCount,
    required this.payments,
    required this.openOrders,
  });

  factory BranchToday.fromJson(Map<String, dynamic> json) => BranchToday(
    cashTotal: (json['cashTotal'] as num?)?.toDouble() ?? 0,
    cashCount: (json['cashCount'] as num?)?.toInt() ?? 0,
    walletTotal: (json['walletTotal'] as num?)?.toDouble() ?? 0,
    walletCount: (json['walletCount'] as num?)?.toInt() ?? 0,
    paidOrdersCount: (json['paidOrdersCount'] as num?)?.toInt() ?? 0,
    payments: (json['payments'] as List<dynamic>? ?? const [])
        .map((e) => TodayPayment.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    openOrders: (json['openOrders'] as List<dynamic>? ?? const [])
        .map((e) => TodayOpenOrder.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
  );

  static const empty = BranchToday(
    cashTotal: 0,
    cashCount: 0,
    walletTotal: 0,
    walletCount: 0,
    paidOrdersCount: 0,
    payments: [],
    openOrders: [],
  );

  final double cashTotal;
  final int cashCount;
  final double walletTotal;
  final int walletCount;
  final int paidOrdersCount;
  final List<TodayPayment> payments;
  final List<TodayOpenOrder> openOrders;
}

class TodayApi {
  TodayApi(this._client, this._sessionStorage);

  final MposApiClient _client;
  final SessionStorage _sessionStorage;

  /// Today's figures for the signed-in branch.
  Future<BranchToday> today() async {
    final branchId = (await _sessionStorage.loadSession())?.branchId ?? '';
    if (branchId.isEmpty) {
      return BranchToday.empty;
    }
    final response = await _client.get(
      '/branches/$branchId/orders/today',
      authenticated: true,
      fromJson: (json) => BranchToday.fromJson(Map<String, dynamic>.from(json as Map)),
    );
    if (!response.success || response.data == null) {
      throw response.errors.isNotEmpty ? response.errors.first : (response.message ?? 'Could not load today.');
    }
    return response.data!;
  }
}
