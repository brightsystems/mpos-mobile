import 'package:flutter_test/flutter_test.dart';

import 'package:mpos_mobile/core/mock/mock_fixtures.dart';
import 'package:mpos_mobile/features/pos/data/datasources/fake/fake_order_datasource.dart';

void main() {
  group('FakeOrderDatasource', () {
    late FakeOrderDatasource datasource;

    setUp(() {
      datasource = FakeOrderDatasource();
    });

    test('keeps multiple open tickets across multiple tables', () async {
      final table4A = await datasource.createTicket(branchId: MockFixtures.branchId, tableNumber: '4');
      final table4B = await datasource.createTicket(branchId: MockFixtures.branchId, tableNumber: '4');
      final table7 = await datasource.createTicket(branchId: MockFixtures.branchId, tableNumber: '7');

      await datasource.addOrderLine(orderId: table4A.id, menuItemId: MockFixtures.menuItems.first.id, quantity: 1);
      await datasource.addOrderLine(orderId: table4B.id, menuItemId: MockFixtures.menuItems[1].id, quantity: 1);
      await datasource.addOrderLine(orderId: table7.id, menuItemId: MockFixtures.menuItems[2].id, quantity: 2);

      final openOrders = await datasource.getOpenOrders(branchId: MockFixtures.branchId);

      expect(openOrders, hasLength(3));
      expect(openOrders.where((order) => order.tableNumber == '4'), hasLength(2));
      expect(openOrders.where((order) => order.tableNumber == '7'), hasLength(1));
    });

    test('supports quantity-based partial settlement and closes after final payment', () async {
      final ticket = await datasource.createTicket(branchId: MockFixtures.branchId, tableNumber: '9');
      await datasource.addOrderLine(orderId: ticket.id, menuItemId: MockFixtures.menuItems.first.id, quantity: 3);
      final withDrink = await datasource.addOrderLine(
        orderId: ticket.id,
        menuItemId: MockFixtures.menuItems[1].id,
        quantity: 4,
      );

      final injeraLine = withDrink.lines.firstWhere((line) => line.menuItemId == MockFixtures.menuItems.first.id);
      final tibsLine = withDrink.lines.firstWhere((line) => line.menuItemId == MockFixtures.menuItems[1].id);
      final partialPayment = await datasource.payCash(
        orderId: withDrink.id,
        receivedAmount: 552,
        customerPhone: '0911000000',
        lineQuantities: {injeraLine.id: 1, tibsLine.id: 2},
      );

      expect(partialPayment.status, 'Open');
      expect(partialPayment.unpaidLines, hasLength(2));
      expect(partialPayment.unpaidLines.firstWhere((line) => line.id == injeraLine.id).remainingQuantity, 2);
      expect(partialPayment.unpaidLines.firstWhere((line) => line.id == tibsLine.id).remainingQuantity, 2);
      expect(partialPayment.payments.single.coveredQuantities, {injeraLine.id: 1, tibsLine.id: 2});

      final finalPayment = await datasource.payCash(
        orderId: withDrink.id,
        receivedAmount: partialPayment.remainingTotal,
        customerPhone: '0911000000',
      );

      expect(finalPayment.status, 'Paid');
      expect(finalPayment.isClosed, isTrue);
      expect(finalPayment.unpaidLines, isEmpty);
      expect(finalPayment.payments, hasLength(2));
      expect(finalPayment.tableNumber, '9');
    });

    test('can move an active cart between walk-in and table groups', () async {
      final ticket = await datasource.createTicket(branchId: MockFixtures.branchId, tableNumber: 'Walk-in');
      final updated = await datasource.updateOrderTableNumber(orderId: ticket.id, tableNumber: '12');
      final walkInAgain = await datasource.updateOrderTableNumber(orderId: ticket.id, tableNumber: '');

      expect(updated.tableNumber, '12');
      expect(updated.ticketNumber, 'T1');
      expect(walkInAgain.tableNumber, 'Walk-in');
    });
  });
}
