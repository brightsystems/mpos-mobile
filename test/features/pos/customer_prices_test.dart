import 'package:flutter_test/flutter_test.dart';
import 'package:mpos_mobile/features/pos/data/pricing_api.dart';
import 'package:mpos_mobile/features/pos/domain/entities/order_entity.dart';

void main() {
  const water = OrderLineEntity(
    id: 'l1',
    menuItemId: 'water-case',
    name: 'Water case of 24',
    unitPrice: 240,
    quantity: 2,
    lineTotal: 552, // 480 + 15% VAT
    taxAmount: 72,
  );
  const spirit = OrderLineEntity(
    id: 'l2',
    menuItemId: 'spirit',
    name: 'Spirit 750ml',
    unitPrice: 320,
    quantity: 1,
    lineTotal: 368,
    taxAmount: 48,
  );

  test('lines on the price list are re-priced with their tax rate; others keep their price', () {
    expect(estimateOrderTotal([water, spirit], {'water-case': 200}), 460 + 368);
    expect(estimateOrderTotal([water, spirit], const {}), 552 + 368);
  });

  test('a line discount is kept (never more than the new amount)', () {
    const discounted = OrderLineEntity(
      id: 'l3',
      menuItemId: 'water-case',
      name: 'Water case of 24',
      unitPrice: 240,
      quantity: 1,
      discount: 40,
      lineTotal: 230, // (240 - 40) * 1.15
      taxAmount: 30,
    );
    expect(estimateOrderTotal([discounted], {'water-case': 200}), 184); // (200 - 40) * 1.15
  });

  test('customer prices and credit are read from the API', () {
    final parsed = CustomerPrices.fromJson({
      'customerId': 'c1',
      'priceListName': 'Distributor',
      'prices': {'water-case': 200, 'spirit': 300.5},
      'credit': {'owed': 1200, 'available': 800, 'creditLimit': 2000, 'overdue': 0, 'openInvoices': 2},
    });

    expect(parsed.priceListName, 'Distributor');
    expect(parsed.prices['spirit'], 300.5);
    expect(parsed.credit.hasLimit, isTrue);
    expect(parsed.credit.available, 800);

    final noLimit = CustomerPrices.fromJson({
      'prices': <String, dynamic>{},
      'credit': {'owed': 0, 'available': null, 'overdue': 0, 'openInvoices': 0},
    });
    expect(noLimit.priceListName, isNull);
    expect(noLimit.credit.hasLimit, isFalse);
  });
}
