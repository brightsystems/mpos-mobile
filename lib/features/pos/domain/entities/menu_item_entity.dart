import 'package:equatable/equatable.dart';

import 'package:mpos_mobile/features/pos/domain/entities/tax_rate_entity.dart';

class MenuItemEntity extends Equatable {
  const MenuItemEntity({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.name,
    required this.price,
    this.description,
    this.sku,
    this.imageUrl,
    this.taxes = const [],
    this.trackInventory = false,
    this.stockOnHand,
    this.isAvailable = true,
    this.sortOrder = 0,
    this.updatedAt,
    this.nearestExpiry,
    this.negativeStock = 'Block',
    this.nearExpiryDays = 30,
  });

  final String id;
  final String categoryId;
  final String categoryName;
  final String name;
  final double price;
  final String? description;
  final String? sku;
  final String? imageUrl;
  final List<TaxRateEntity> taxes;
  final bool trackInventory;
  final double? stockOnHand;
  final bool isAvailable;
  final int sortOrder;
  final DateTime? updatedAt;

  /// Inventory module: earliest expiry of the stock on hand (null when not tracked).
  final DateTime? nearestExpiry;

  /// Inventory module: what a sale with too little stock does (Block, Warn, Allow).
  final String negativeStock;

  /// Inventory module: warn about stock expiring within this many days.
  final int nearExpiryDays;

  bool get hasNoStock => trackInventory && (stockOnHand ?? 0) <= 0;

  /// Can't be sold: unavailable, or out of stock where the business refuses such sales.
  bool get isOutOfStock {
    if (!isAvailable) {
      return true;
    }

    return hasNoStock && negativeStock == 'Block';
  }

  /// Out of stock but the business lets it be sold (stock goes negative).
  bool get sellsWithoutStock => hasNoStock && negativeStock != 'Block';

  int get stockDisplay => trackInventory ? (stockOnHand ?? 0).floor() : 999;

  bool get isExpired => nearestExpiry != null && nearestExpiry!.isBefore(_today());

  bool get expiresSoon =>
      nearestExpiry != null && !isExpired && !nearestExpiry!.isAfter(_today().add(Duration(days: nearExpiryDays)));

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  String get taxLabel => formatTaxLabel(taxes);

  @override
  List<Object?> get props => [id, name, price, stockOnHand, isAvailable, updatedAt, taxes, nearestExpiry, negativeStock];
}
