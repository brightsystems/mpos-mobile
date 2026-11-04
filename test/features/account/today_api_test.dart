import 'package:flutter_test/flutter_test.dart';
import 'package:mpos_mobile/features/account/data/today_api.dart';

void main() {
  test('reads the branch day from the API (cash vs wallet, payments, open orders)', () {
    final today = BranchToday.fromJson({
      'date': '2026-11-04',
      'cashTotal': 315.0,
      'cashCount': 2,
      'walletTotal': 100.0,
      'walletCount': 1,
      'paidOrdersCount': 2,
      'payments': [
        {
          'orderId': 'o2',
          'orderNumber': 'ORD-2',
          'amount': 100.0,
          'method': 'Telebirr',
          'paidAt': '2026-11-04T08:10:00Z',
          'tableNumber': 'T1',
        },
      ],
      'openOrders': [
        {
          'orderId': 'o2',
          'orderNumber': 'ORD-2',
          'status': 'Submitted',
          'createdAt': '2026-11-04T08:00:00Z',
          'totalAmount': 500.0,
          'paidAmount': 300.0,
          'remainingAmount': 200.0,
        },
      ],
    });

    expect(today.cashTotal, 315);
    expect(today.walletTotal, 100);
    expect(today.paidOrdersCount, 2);
    expect(today.payments.single.method, 'Telebirr');
    expect(today.payments.single.tableNumber, 'T1');
    expect(today.openOrders.single.remainingAmount, 200);
  });

  test('an empty day', () {
    final today = BranchToday.fromJson({});
    expect(today.payments, isEmpty);
    expect(today.cashTotal, 0);
  });
}
