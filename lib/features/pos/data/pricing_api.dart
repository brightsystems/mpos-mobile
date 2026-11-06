import 'package:mpos_mobile/core/network/json_reader.dart';
import 'package:mpos_mobile/core/network/mpos_api_client.dart';
import 'package:mpos_mobile/features/pos/domain/entities/order_entity.dart';

/// What a customer owes on credit sales. [available] is null when no credit limit is set.
class CustomerCredit {
  const CustomerCredit({
    required this.owed,
    required this.overdue,
    required this.openInvoices,
    this.creditLimit,
    this.available,
    this.paymentTermsDays,
  });

  factory CustomerCredit.fromJson(Map<String, dynamic> json) {
    final r = JsonReader(json);
    double? opt(String key) => json[key] == null ? null : r.number(key);
    return CustomerCredit(
      owed: r.number('owed'),
      overdue: r.number('overdue'),
      openInvoices: r.integer('openInvoices'),
      creditLimit: opt('creditLimit'),
      available: opt('available'),
      paymentTermsDays: json['paymentTermsDays'] == null ? null : r.integer('paymentTermsDays'),
    );
  }

  final double owed;
  final double overdue;
  final int openInvoices;
  final double? creditLimit;
  final double? available;
  final int? paymentTermsDays;

  bool get hasLimit => available != null;
}

/// A customer's price-list prices (before tax) by product id, and their credit.
class CustomerPrices {
  const CustomerPrices({required this.prices, required this.credit, this.priceListName});

  factory CustomerPrices.fromJson(Map<String, dynamic> json) {
    final r = JsonReader(json);
    final raw = r.map('prices') ?? const <String, dynamic>{};
    final name = r.string('priceListName');
    return CustomerPrices(
      priceListName: name.isEmpty ? null : name,
      prices: {for (final e in raw.entries) e.key: JsonReader(raw).number(e.key)},
      credit: CustomerCredit.fromJson(r.map('credit') ?? const {}),
    );
  }

  final String? priceListName;
  final Map<String, double> prices;
  final CustomerCredit credit;

  /// The draft's total once its lines are priced from this list (the server re-prices on submit).
  double estimateTotal(OrderEntity order) => estimateOrderTotal(order.lines, prices);
}

/// Total of [lines] at [prices] (unlisted products keep their price), each line keeping its
/// discount and its tax rate.
double estimateOrderTotal(List<OrderLineEntity> lines, Map<String, double> prices) {
  var total = 0.0;
  for (final line in lines) {
    final price = prices[line.menuItemId];
    if (price == null || price == line.unitPrice) {
      total += line.lineTotal;
      continue;
    }
    final oldNet = line.unitPrice * line.quantity - line.discount;
    final tax = line.taxAmount ?? (line.lineTotal - oldNet);
    final rate = oldNet > 0 ? tax / oldNet : 0.0;
    final gross = price * line.quantity;
    final discount = line.discount > gross ? gross : line.discount;
    final net = gross - discount;
    total += net + net * rate;
  }
  return (total * 100).roundToDouble() / 100;
}

/// Customer prices and credit for the POS (price lists are set up on the web).
class PricingApi {
  PricingApi(this._client);

  final MposApiClient _client;

  Future<CustomerPrices> customerPrices(String organizationId, String customerId) async {
    final response = await _client.get(
      '/organizations/$organizationId/customers/$customerId/prices',
      authenticated: true,
      fromJson: (json) => CustomerPrices.fromJson(json as Map<String, dynamic>),
    );
    if (!response.success || response.data == null) {
      throw response.message ?? response.errors.join(', ');
    }
    return response.data as CustomerPrices;
  }
}
