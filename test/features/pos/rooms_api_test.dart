import 'package:flutter_test/flutter_test.dart';
import 'package:mpos_mobile/features/pos/data/rooms_api.dart';

void main() {
  test('room board rows read the guest and the bill', () {
    final room = RoomBoardItem.fromJson({
      'roomId': 'r1',
      'number': '101',
      'name': 'Deluxe',
      'status': 'Occupied',
      'stayId': 's1',
      'guestName': 'Sara',
      'guestPhone': '+251911223344',
      'checkedInAt': '2026-11-03T08:00:00Z',
      'chargeCount': 2,
      'balance': 230.5,
    });

    expect(room.isOccupied, isTrue);
    expect(room.isVacant, isFalse);
    expect(room.guestName, 'Sara');
    expect(room.balance, 230.5);

    final vacant = RoomBoardItem.fromJson({'roomId': 'r2', 'number': '102', 'status': 'Vacant'});
    expect(vacant.isVacant, isTrue);
    expect(vacant.stayId, isNull);
  });

  test('a stay lists its charges and which are still to pay', () {
    final stay = StayInfo.fromJson({
      'id': 's1',
      'roomNumber': '101',
      'guestName': 'Sara',
      'guestPhone': '',
      'status': 'Open',
      'total': 330,
      'paid': 100,
      'balance': 230,
      'charges': [
        {'id': 'o1', 'orderNumber': 'ORD-1', 'netPayableAmount': 230, 'remainingAmount': 230},
        {'id': 'o2', 'orderNumber': 'ORD-2', 'totalAmount': 100, 'remainingAmount': 0},
      ],
    });

    expect(stay.isOpen, isTrue);
    expect(stay.guestPhone, isNull);
    expect(stay.charges.map((c) => c.amount), [230, 100]);
    expect(stay.openCharges.map((c) => c.orderNumber), ['ORD-1']);
  });
}
