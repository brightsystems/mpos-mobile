import 'package:flutter_test/flutter_test.dart';
import 'package:mpos_mobile/features/pos/domain/entities/business_profile_entity.dart';
import 'package:mpos_mobile/features/pos/domain/entities/menu_item_entity.dart';
import 'package:mpos_mobile/features/pos/domain/entities/order_entity.dart';
import 'package:mpos_mobile/features/pos/domain/entities/pos_client.dart';
import 'package:mpos_mobile/features/pos/domain/pos_rules.dart';

MenuItemEntity _item(String name, {String? sku, String? barcode, bool rx = false}) => MenuItemEntity(
  id: name,
  categoryId: 'c',
  categoryName: 'Medicines',
  name: name,
  price: 50,
  sku: sku,
  barcode: barcode,
  isPrescriptionOnly: rx,
);

void main() {
  group('POS block per business type', () {
    test('an older API without the block gets the type defaults', () {
      final pharmacy = BusinessProfileEntity.fromJson({'code': 'Pharmacy'});
      expect(pharmacy.pos.isList, isTrue);
      expect(pharmacy.pos.scanFirst, isTrue);
      expect(pharmacy.pos.askPrescriptionForRx, isTrue);

      final clinic = BusinessProfileEntity.fromJson({'code': 'MedicalService'});
      expect(clinic.pos.startsWithClient, isTrue);
      expect(clinic.pos.clientKind, 'Patient');
      expect(clinic.pos.clientRequired, isTrue);

      final hotel = BusinessProfileEntity.fromJson({'code': 'Hotel'});
      expect(hotel.pos.chargeToRoom, isTrue);
      expect(hotel.pos.isList, isFalse);

      final cafe = BusinessProfileEntity.fromJson({'code': 'Cafeteria'});
      expect(cafe.pos.layout, 'Grid');
      expect(cafe.pos.chargeToRoom, isFalse);
    });

    test("the API's block wins, missing fields fall back to the defaults", () {
      final shop = BusinessProfileEntity.fromJson({
        'profile': {
          'code': 'Shop',
          'pos': {'layout': 'Grid', 'quickCash': false},
        },
      });
      expect(shop.pos.layout, 'Grid');
      expect(shop.pos.quickCash, isFalse);
      expect(shop.pos.scanFirst, isTrue);
    });
  });

  group('Selling rules', () {
    final items = [_item('Paracetamol', sku: 'PARA-500'), _item('Amoxicillin', barcode: '6291041500213', rx: true)];

    test('a scanned barcode or typed SKU finds the product, case-insensitively', () {
      expect(PosRules.findByCode(items, '6291041500213')?.name, 'Amoxicillin');
      expect(PosRules.findByCode(items, ' para-500 ')?.name, 'Paracetamol');
      expect(PosRules.findByCode(items, 'unknown'), isNull);
      expect(PosRules.findByCode(items, ''), isNull);
    });

    test('clinics and consultancies need the client before the first item', () {
      final clinic = BusinessTypePos.defaultsFor('MedicalService');
      expect(PosRules.needsClient(clinic, null), isTrue);
      expect(PosRules.needsClient(clinic, const PosClient(reference: 'MRN-1')), isTrue);
      expect(PosRules.needsClient(clinic, const PosClient(name: 'Hanna')), isFalse);
      expect(PosRules.needsClient(clinic, const PosClient(customerId: 'c1')), isFalse);
      expect(PosRules.needsClient(BusinessTypePos.defaultsFor('Shop'), null), isFalse);
    });

    test('a prescription-only product asks for the prescription once per sale', () {
      final pharmacy = BusinessTypePos.defaultsFor('Pharmacy');
      expect(PosRules.needsPrescription(pharmacy, items[1], null), isTrue);
      expect(PosRules.needsPrescription(pharmacy, items[1], const PosClient(reference: 'RX-1')), isFalse);
      expect(PosRules.needsPrescription(pharmacy, items[0], null), isFalse);
      expect(PosRules.needsPrescription(BusinessTypePos.defaultsFor('Shop'), items[1], null), isFalse);
    });

    test('hotel sales with a room can be charged to it', () {
      final hotel = BusinessTypePos.defaultsFor('Hotel');
      expect(PosRules.canChargeToRoom(hotel, const PosClient(reference: '101')), isTrue);
      expect(PosRules.canChargeToRoom(hotel, const PosClient(name: 'Walk-in')), isFalse);
      expect(
        PosRules.canChargeToRoom(BusinessTypePos.defaultsFor('Cafeteria'), const PosClient(reference: '4')),
        isFalse,
      );
    });

    test('quick cash offers the exact amount and the next round notes', () {
      expect(PosRules.quickCashAmounts(137), [137, 150, 200, 500, 1000]);
      expect(PosRules.quickCashAmounts(500), [500, 550, 600, 1000]);
      expect(PosRules.quickCashAmounts(0), isEmpty);
    });
  });

  test('the client of a ticket comes from the order and fills blanks from it', () {
    const order = OrderEntity(
      id: 'o1',
      branchId: 'b',
      orderNumber: 'ORD-1',
      status: 'Draft',
      subtotal: 0,
      taxAmount: 0,
      totalAmount: 0,
      lines: [],
      payments: [],
      customerName: 'Sara',
      clientReference: '101',
    );
    final fromOrder = PosClient.fromOrder(order);
    expect(fromOrder.label(), 'Sara · 101');

    final kept = const PosClient(phone: '0911000000').mergedWith(fromOrder);
    expect(kept.name, 'Sara');
    expect(kept.reference, '101');
    expect(kept.phone, '0911000000');
  });
}
