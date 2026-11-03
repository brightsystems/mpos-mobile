import 'package:flutter_test/flutter_test.dart';
import 'package:mpos_mobile/features/pos/domain/entities/menu_item_entity.dart';
import 'package:mpos_mobile/features/pos/domain/pos_rules.dart';

MenuItemEntity _item(String name, String? nature) =>
    MenuItemEntity(id: name, categoryId: 'c', categoryName: 'C', name: name, price: 10, natureOfSupply: nature);

void main() {
  test('service spellings are services, anything else is goods', () {
    expect(_item('a', 'Service').isService, isTrue);
    expect(_item('b', ' services ').isService, isTrue);
    expect(_item('c', 'goods').isService, isFalse);
    expect(_item('d', null).isService, isFalse);
  });

  test('goods and services never share an order', () {
    final coffee = _item('Coffee', 'goods');
    final consulting = _item('Hourly consulting', 'Services');

    expect(PosRules.supplyMixError(coffee, []), isNull);
    expect(PosRules.supplyMixError(coffee, [_item('Tea', null)]), isNull);
    expect(PosRules.supplyMixError(consulting, [coffee]), contains('Hourly consulting is a service'));
    expect(PosRules.supplyMixError(coffee, [consulting]), contains('already has services'));
  });
}
