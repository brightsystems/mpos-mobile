import 'package:flutter_test/flutter_test.dart';

import 'package:mpos_mobile/features/pos/domain/entities/fiscal_invoice_entity.dart';
import 'package:mpos_mobile/features/pos/domain/entities/order_entity.dart';
import 'package:mpos_mobile/features/pos/domain/entities/tax_rate_entity.dart';

OrderEntity _order({
  String status = 'Submitted',
  double? remainingAmount,
  double withholding = 0,
  double paid = 0,
  double paidQuantity = 0,
}) {
  return OrderEntity(
    id: 'o1',
    branchId: 'b1',
    orderNumber: 'ORD-1',
    status: status,
    subtotal: 25000,
    taxAmount: 3750,
    totalAmount: 28750,
    lines: [
      OrderLineEntity(
        id: 'l1',
        menuItemId: 'm1',
        name: 'Laptop',
        unitPrice: 25000,
        quantity: 1,
        lineTotal: 25000,
        paidQuantity: paidQuantity,
        taxes: const [TaxRateEntity(id: 't', name: 'VAT', code: 'VAT15', ratePercent: 15)],
        taxAmount: 3750,
      ),
    ],
    payments: const [],
    withholdingAmount: withholding,
    netPayableAmount: 28750 - withholding,
    paidAmount: paid,
    remainingAmount: remainingAmount,
  );
}

void main() {
  group('OrderEntity uses the API amounts (same as the web POS)', () {
    test('amount due is the API remaining amount, net of withholding', () {
      // B2G: 3% income + 50% of VAT withheld = 750 + 1875.
      final order = _order(remainingAmount: 26125, withholding: 2625);

      expect(order.remainingTotal, 26125);
      expect(order.netPayable, 26125);
      expect(order.isClosed, isFalse);
    });

    test('a partially paid order stays open with the remaining balance', () {
      final order = _order(remainingAmount: 18750, paid: 10000);

      expect(order.remainingTotal, 18750);
      expect(order.isClosed, isFalse);
    });

    test('line tax comes from the API, not a local recalculation', () {
      final line = _order(remainingAmount: 28750).lines.single;

      expect(line.remainingTaxAmount, 3750);
    });

    test('paid, cancelled and rejected orders are closed', () {
      expect(_order(status: 'Paid', remainingAmount: 0, paidQuantity: 1).isClosed, isTrue);
      expect(_order(status: 'Cancelled', remainingAmount: 28750).isClosed, isTrue);
      expect(_order(status: 'Rejected', remainingAmount: 28750).isClosed, isTrue);
    });

    test('an empty draft ticket is not closed', () {
      const empty = OrderEntity(
        id: 'o2',
        branchId: 'b1',
        orderNumber: 'ORD-2',
        status: 'Draft',
        subtotal: 0,
        taxAmount: 0,
        totalAmount: 0,
        lines: [],
        payments: [],
        remainingAmount: 0,
      );

      expect(empty.isClosed, isFalse);
      expect(empty.isDraft, isTrue);
    });
  });

  group('FiscalInvoiceEntity understands the API statuses', () {
    FiscalInvoiceEntity invoice(String status, {String? paymentMode}) =>
        FiscalInvoiceEntity(id: 'i', orderId: 'o', status: status, paymentMode: paymentMode);

    test('Registered, Completed and ReceiptFailed are registered with MoR', () {
      expect(invoice('Registered').isRegistered, isTrue);
      expect(invoice('Completed').isRegistered, isTrue);
      expect(invoice('ReceiptFailed').isRegistered, isTrue);
      expect(invoice('Pending').isRegistered, isFalse);
    });

    test('polling stops once the invoice is registered, failed or cancelled', () {
      expect(invoice('Pending').isSettled, isFalse);
      expect(invoice('Registered').isSettled, isTrue);
      expect(invoice('Failed').isSettled, isTrue);
      expect(invoice('Cancelled').isSettled, isTrue);
    });

    test('credit sale is read from the payment mode', () {
      expect(invoice('Registered', paymentMode: 'CREDIT').isCreditSale, isTrue);
      expect(invoice('Registered', paymentMode: 'CASH').isCreditSale, isFalse);
      expect(invoice('Registered').isCreditSale, isFalse);
    });
  });
}
