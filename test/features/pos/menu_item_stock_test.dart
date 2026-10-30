import 'package:flutter_test/flutter_test.dart';
import 'package:mpos_mobile/features/pos/domain/entities/menu_item_entity.dart';

MenuItemEntity _item({double? stock, String policy = 'Block', DateTime? expiry, bool tracked = true}) => MenuItemEntity(
  id: '1',
  categoryId: 'c',
  categoryName: 'Food',
  name: 'Tibs',
  price: 180,
  trackInventory: tracked,
  stockOnHand: stock,
  negativeStock: policy,
  nearestExpiry: expiry,
  nearExpiryDays: 30,
);

void main() {
  test('out of stock is blocked only when the business refuses such sales', () {
    expect(_item(stock: 0).isOutOfStock, isTrue);
    expect(_item(stock: 0, policy: 'Warn').isOutOfStock, isFalse);
    expect(_item(stock: 0, policy: 'Warn').sellsWithoutStock, isTrue);
    expect(_item(stock: -2, policy: 'Allow').isOutOfStock, isFalse);
    expect(_item(stock: 3).isOutOfStock, isFalse);
    expect(_item(stock: null, tracked: false).isOutOfStock, isFalse);
  });

  test('expiry warnings', () {
    final today = DateTime.now();
    expect(_item(stock: 5, expiry: today.add(const Duration(days: 10))).expiresSoon, isTrue);
    expect(_item(stock: 5, expiry: today.add(const Duration(days: 90))).expiresSoon, isFalse);
    expect(_item(stock: 5, expiry: today.subtract(const Duration(days: 2))).isExpired, isTrue);
    expect(_item(stock: 5).expiresSoon, isFalse);
  });
}
