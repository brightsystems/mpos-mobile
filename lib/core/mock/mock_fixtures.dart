import 'package:mpos_mobile/features/pos/domain/entities/menu_item_entity.dart';
import 'package:mpos_mobile/features/pos/domain/entities/tax_rate_entity.dart';

/// Seed-aligned demo data (matches API DevelopmentDataSeeder).
class MockFixtures {
  MockFixtures._();

  static const organizationId = '22222222-2222-2222-2222-222222222201';
  static const organizationName = 'Demo Cafe MPOS';
  static const branchId = '33333333-3333-3333-3333-333333333301';
  static const branchName = 'Bole Main';
  static const waiterUserId = '44444444-4444-4444-4444-444444444401';
  static const waiterPhone = '+251911000003';
  static const waiterName = 'Abebe Waiter';
  static const mockShiftToken = 'mock-shift-token';

  static const initialDocumentNumber = 1001;
  static const sellerLegalName = 'Demo Cafe MPOS PLC';
  static const sellerVatNumber = '0000123456';

  static const foodCategoryId = '55555555-5555-5555-5555-555555555501';
  static const drinksCategoryId = '55555555-5555-5555-5555-555555555502';
  static const dessertsCategoryId = '55555555-5555-5555-5555-555555555503';
  static const snacksCategoryId = '55555555-5555-5555-5555-555555555504';

  static const vat15 = TaxRateEntity(
    id: '99999999-9999-9999-9999-999999999901',
    name: 'VAT 15%',
    code: 'VAT15',
    ratePercent: 15,
    morTaxCode: 'VAT15',
  );

  static const exempt = TaxRateEntity(
    id: '99999999-9999-9999-9999-999999999902',
    name: 'Exempt',
    code: 'EXEMPT',
    ratePercent: 0,
    morTaxCode: 'EXEMPT',
  );

  static const zeroRated = TaxRateEntity(
    id: '99999999-9999-9999-9999-999999999903',
    name: 'Zero-rated',
    code: 'VAT0',
    ratePercent: 0,
    morTaxCode: 'VAT0',
  );

  static const _injeraImage = 'https://images.unsplash.com/photo-1604329543130-0cff9beb1fdc?w=480&h=480&fit=crop';
  static const _tibsImage = 'https://images.unsplash.com/photo-1544025162-d76694265947?w=480&h=480&fit=crop';
  static const _coffeeImage = 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=480&h=480&fit=crop';
  static const _waterImage = 'https://images.unsplash.com/photo-1523362628745-d4a15bc45fbe?w=480&h=480&fit=crop';
  static const _stewImage = 'https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=480&h=480&fit=crop';
  static const _kitfoImage = 'https://images.unsplash.com/photo-1604908176997-431836f022d0?w=480&h=480&fit=crop';
  static const _pastaImage = 'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=480&h=480&fit=crop';
  static const _juiceImage = 'https://images.unsplash.com/photo-1600271886742-f049cd451bba?w=480&h=480&fit=crop';
  static const _teaImage = 'https://images.unsplash.com/photo-1564890369478-c89ca6d9cde9?w=480&h=480&fit=crop';
  static const _pastryImage = 'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=480&h=480&fit=crop';
  static const _sambusaImage = 'https://images.unsplash.com/photo-1601050690597-df0565f95450?w=480&h=480&fit=crop';

  static final List<MenuItemEntity> menuItems = [
    MenuItemEntity(
      id: '66666666-6666-6666-6666-666666666601',
      categoryId: foodCategoryId,
      categoryName: 'Food',
      name: 'Injera Combo',
      price: 120,
      description: 'Mixed wat platter with beef, lentils, and greens on fresh injera',
      sku: 'FOOD-001',
      imageUrl: _injeraImage,
      taxes: const [MockFixtures.vat15],
      trackInventory: true,
      stockOnHand: 50,
      sortOrder: 1,
      updatedAt: DateTime.utc(2026, 1, 1),
    ),
    MenuItemEntity(
      id: '66666666-6666-6666-6666-666666666602',
      categoryId: foodCategoryId,
      categoryName: 'Food',
      name: 'Tibs',
      price: 180,
      description: 'Sautéed beef with onion, rosemary, and awaze',
      sku: 'FOOD-002',
      imageUrl: _tibsImage,
      taxes: const [MockFixtures.vat15],
      trackInventory: true,
      stockOnHand: 30,
      sortOrder: 2,
      updatedAt: DateTime.utc(2026, 1, 1),
    ),
    MenuItemEntity(
      id: '66666666-6666-6666-6666-666666666605',
      categoryId: foodCategoryId,
      categoryName: 'Food',
      name: 'Shiro Wat',
      price: 95,
      description: 'Creamy chickpea stew with berbere and spiced oil',
      sku: 'FOOD-003',
      imageUrl: _stewImage,
      taxes: const [MockFixtures.vat15],
      trackInventory: true,
      stockOnHand: 40,
      sortOrder: 3,
      updatedAt: DateTime.utc(2026, 1, 1),
    ),
    MenuItemEntity(
      id: '66666666-6666-6666-6666-666666666606',
      categoryId: foodCategoryId,
      categoryName: 'Food',
      name: 'Kitfo',
      price: 220,
      description: 'Minced beef tartare with mitmita, niter kibbeh, and ayib',
      sku: 'FOOD-004',
      imageUrl: _kitfoImage,
      taxes: const [MockFixtures.vat15],
      trackInventory: true,
      stockOnHand: 18,
      sortOrder: 4,
      updatedAt: DateTime.utc(2026, 1, 1),
    ),
    MenuItemEntity(
      id: '66666666-6666-6666-6666-666666666607',
      categoryId: foodCategoryId,
      categoryName: 'Food',
      name: 'Doro Wat',
      price: 210,
      description: 'Slow-cooked chicken stew with boiled egg and berbere',
      sku: 'FOOD-005',
      imageUrl: _stewImage,
      taxes: const [MockFixtures.vat15],
      trackInventory: true,
      stockOnHand: 22,
      sortOrder: 5,
      updatedAt: DateTime.utc(2026, 1, 1),
    ),
    MenuItemEntity(
      id: '66666666-6666-6666-6666-666666666608',
      categoryId: foodCategoryId,
      categoryName: 'Food',
      name: 'Beyainatu',
      price: 140,
      description: 'Vegetarian sampler with shiro, gomen, atkilt, and misir',
      sku: 'FOOD-006',
      imageUrl: _injeraImage,
      taxes: const [MockFixtures.vat15],
      trackInventory: true,
      stockOnHand: 35,
      sortOrder: 6,
      updatedAt: DateTime.utc(2026, 1, 1),
    ),
    MenuItemEntity(
      id: '66666666-6666-6666-6666-666666666609',
      categoryId: foodCategoryId,
      categoryName: 'Food',
      name: 'Firfir',
      price: 85,
      description: 'Shredded injera tossed in spicy berbere sauce',
      sku: 'FOOD-007',
      imageUrl: _injeraImage,
      taxes: const [MockFixtures.vat15],
      trackInventory: true,
      stockOnHand: 28,
      sortOrder: 7,
      updatedAt: DateTime.utc(2026, 1, 1),
    ),
    MenuItemEntity(
      id: '66666666-6666-6666-6666-666666666610',
      categoryId: foodCategoryId,
      categoryName: 'Food',
      name: 'Pasta Bolognese',
      price: 160,
      description: 'Penne with house tomato-meat sauce and parmesan',
      sku: 'FOOD-008',
      imageUrl: _pastaImage,
      taxes: const [MockFixtures.vat15],
      trackInventory: true,
      stockOnHand: 24,
      sortOrder: 8,
      updatedAt: DateTime.utc(2026, 1, 1),
    ),
    MenuItemEntity(
      id: '66666666-6666-6666-6666-666666666603',
      categoryId: drinksCategoryId,
      categoryName: 'Drinks',
      name: 'Coffee',
      price: 35,
      description: 'Traditional Ethiopian buna served in a jebena',
      sku: 'DRK-001',
      imageUrl: _coffeeImage,
      taxes: const [MockFixtures.vat15],
      trackInventory: true,
      stockOnHand: 100,
      sortOrder: 1,
      updatedAt: DateTime.utc(2026, 1, 1),
    ),
    MenuItemEntity(
      id: '66666666-6666-6666-6666-666666666611',
      categoryId: drinksCategoryId,
      categoryName: 'Drinks',
      name: 'Macchiato',
      price: 45,
      description: 'Layered espresso with steamed milk foam',
      sku: 'DRK-003',
      imageUrl: _coffeeImage,
      taxes: const [MockFixtures.vat15],
      trackInventory: true,
      stockOnHand: 80,
      sortOrder: 2,
      updatedAt: DateTime.utc(2026, 1, 1),
    ),
    MenuItemEntity(
      id: '66666666-6666-6666-6666-666666666612',
      categoryId: drinksCategoryId,
      categoryName: 'Drinks',
      name: 'Spris',
      price: 55,
      description: 'Layered avocado, mango, and papaya smoothie',
      sku: 'DRK-004',
      imageUrl: _juiceImage,
      taxes: const [MockFixtures.vat15],
      trackInventory: true,
      stockOnHand: 45,
      sortOrder: 3,
      updatedAt: DateTime.utc(2026, 1, 1),
    ),
    MenuItemEntity(
      id: '66666666-6666-6666-6666-666666666613',
      categoryId: drinksCategoryId,
      categoryName: 'Drinks',
      name: 'Fresh Mango Juice',
      price: 50,
      description: 'Cold-pressed mango with lime and ice',
      sku: 'DRK-005',
      imageUrl: _juiceImage,
      taxes: const [MockFixtures.vat15],
      trackInventory: true,
      stockOnHand: 36,
      sortOrder: 4,
      updatedAt: DateTime.utc(2026, 1, 1),
    ),
    MenuItemEntity(
      id: '66666666-6666-6666-6666-666666666614',
      categoryId: drinksCategoryId,
      categoryName: 'Drinks',
      name: 'Shai Tea',
      price: 25,
      description: 'Spiced black tea with cardamom and clove',
      sku: 'DRK-006',
      imageUrl: _teaImage,
      taxes: const [MockFixtures.vat15],
      trackInventory: true,
      stockOnHand: 120,
      sortOrder: 5,
      updatedAt: DateTime.utc(2026, 1, 1),
    ),
    MenuItemEntity(
      id: '66666666-6666-6666-6666-666666666604',
      categoryId: drinksCategoryId,
      categoryName: 'Drinks',
      name: 'Water 1L',
      price: 20,
      description: 'Still bottled water',
      sku: 'DRK-002',
      imageUrl: _waterImage,
      taxes: const [MockFixtures.exempt],
      trackInventory: true,
      stockOnHand: 200,
      sortOrder: 6,
      updatedAt: DateTime.utc(2026, 1, 1),
    ),
    MenuItemEntity(
      id: '66666666-6666-6666-6666-666666666615',
      categoryId: drinksCategoryId,
      categoryName: 'Drinks',
      name: 'Soft Drink',
      price: 30,
      description: 'Chilled cola or sprite — ask for preference',
      sku: 'DRK-007',
      imageUrl: _waterImage,
      taxes: const [MockFixtures.vat15],
      trackInventory: true,
      stockOnHand: 90,
      sortOrder: 7,
      updatedAt: DateTime.utc(2026, 1, 1),
    ),
    MenuItemEntity(
      id: '66666666-6666-6666-6666-666666666616',
      categoryId: dessertsCategoryId,
      categoryName: 'Desserts',
      name: 'Chocolate Cake Slice',
      price: 75,
      description: 'Rich layer cake with cocoa ganache',
      sku: 'DST-001',
      imageUrl: _pastryImage,
      taxes: const [MockFixtures.vat15],
      trackInventory: true,
      stockOnHand: 16,
      sortOrder: 1,
      updatedAt: DateTime.utc(2026, 1, 1),
    ),
    MenuItemEntity(
      id: '66666666-6666-6666-6666-666666666617',
      categoryId: dessertsCategoryId,
      categoryName: 'Desserts',
      name: 'Pastry Box',
      price: 60,
      description: 'Assorted baklava and puff pastries',
      sku: 'DST-002',
      imageUrl: _pastryImage,
      taxes: const [MockFixtures.vat15],
      trackInventory: true,
      stockOnHand: 20,
      sortOrder: 2,
      updatedAt: DateTime.utc(2026, 1, 1),
    ),
    MenuItemEntity(
      id: '66666666-6666-6666-6666-666666666618',
      categoryId: snacksCategoryId,
      categoryName: 'Snacks',
      name: 'Sambusa (3 pcs)',
      price: 40,
      description: 'Crispy pastry filled with seasoned minced beef',
      sku: 'SNK-001',
      imageUrl: _sambusaImage,
      taxes: const [MockFixtures.vat15],
      trackInventory: true,
      stockOnHand: 42,
      sortOrder: 1,
      updatedAt: DateTime.utc(2026, 1, 1),
    ),
    MenuItemEntity(
      id: '66666666-6666-6666-6666-666666666619',
      categoryId: snacksCategoryId,
      categoryName: 'Snacks',
      name: 'Chips & Dip',
      price: 55,
      description: 'House potato chips with spicy yogurt dip',
      sku: 'SNK-002',
      imageUrl: _sambusaImage,
      taxes: const [MockFixtures.vat15],
      trackInventory: true,
      stockOnHand: 30,
      sortOrder: 2,
      updatedAt: DateTime.utc(2026, 1, 1),
    ),
  ];

  static const List<MockOrderSummary> recentOrders = [
    MockOrderSummary(
      orderNumber: 'MOCK-0007',
      totalAmount: 335,
      status: 'Paid',
      paymentMethod: 'Chapa',
      customerPhone: '0911234567',
    ),
    MockOrderSummary(
      orderNumber: 'MOCK-0006',
      totalAmount: 180,
      status: 'Paid',
      paymentMethod: 'Cash',
      customerPhone: '0911000001',
    ),
    MockOrderSummary(
      orderNumber: 'MOCK-0005',
      totalAmount: 55,
      status: 'Paid',
      paymentMethod: 'Cash',
      customerPhone: '0911223344',
    ),
  ];

  static MenuItemEntity? menuItemById(String id) {
    for (final item in menuItems) {
      if (item.id == id) {
        return item;
      }
    }

    return null;
  }

  static double taxAmount(double subtotal, List<TaxRateEntity> taxes) {
    return calculateTaxesAmount(subtotal, taxes);
  }
}

class MockOrderSummary {
  const MockOrderSummary({
    required this.orderNumber,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    this.customerPhone,
  });

  final String orderNumber;
  final double totalAmount;
  final String status;
  final String paymentMethod;
  final String? customerPhone;
}
